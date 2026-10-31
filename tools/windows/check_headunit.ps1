<#
.SYNOPSIS
  Reads hardware/software info from an Android head unit over ADB and suggests upgrade options.
.USAGE
  powershell -ExecutionPolicy Bypass -File .\Check-HeadUnit.ps1 [-Device 192.168.1.50:5555] [-OutDir .\reports]
  Needs adb.exe in PATH (platform-tools) and USB debugging (or adb over network) enabled.
#>
param(
    [string]$Device = "",
    [string]$OutDir = (Join-Path $PSScriptRoot "reports")
)

$ErrorActionPreference = "Stop"

# ---------- ADB helpers ----------
if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    throw "adb not found. Install Android platform-tools and add it to PATH."
}
if ($Device -match ":") { & adb connect $Device | Out-Null }

$adbArgs = @()
if ($Device) { $adbArgs = @("-s", $Device) }

$devices = (& adb devices) | Select-Object -Skip 1 | Where-Object { $_ -match "\tdevice$" }
if (-not $devices) { throw "No authorized ADB device found. Check cable/USB debugging and accept the RSA prompt." }

function Sh([string]$cmd) {
    try { ((& adb @adbArgs shell $cmd) -join "`n").Trim() } catch { "" }
}
function Prop([string]$name) { Sh "getprop $name" }
function FirstProp([string[]]$names) {
    foreach ($n in $names) { $v = Prop $n; if ($v) { return $v } }
    return ""
}

# ---------- Collect ----------
Write-Host "Collecting data from device..." -ForegroundColor Cyan

$info = [ordered]@{}
$info.Model        = FirstProp @("ro.product.model", "ro.product.device")
$info.Brand        = FirstProp @("ro.product.brand", "ro.product.manufacturer")
$info.Board        = FirstProp @("ro.product.board", "ro.board.platform", "ro.hardware")
$info.Platform     = FirstProp @("ro.board.platform", "ro.mediatek.platform")
$info.Hardware     = Prop "ro.hardware"
$info.Abi          = Prop "ro.product.cpu.abi"
$info.AndroidVer   = Prop "ro.build.version.release"
$info.Sdk          = [int]("0" + (Prop "ro.build.version.sdk"))
$info.SecurityPatch= Prop "ro.build.version.security_patch"
$info.BuildId      = Prop "ro.build.display.id"
$info.BuildDate    = Prop "ro.build.date"
$info.Fingerprint  = Prop "ro.build.fingerprint"
$info.Kernel       = Sh "uname -r"
$info.Serial       = FirstProp @("ro.serialno", "ro.boot.serialno")
$info.Dpi          = Prop "ro.sf.lcd_density"
$info.Resolution   = (Sh "wm size") -replace "Physical size: ", ""
# MCU / vendor versions: names differ per vendor, so scan common ones then grep.
$info.McuVersion   = FirstProp @("ro.mcu.version", "persist.sys.mcu.version", "ro.mcuversion", "sys.mcu.version", "ro.build.mcu")
$mcuGrep = Sh "getprop | grep -i -E 'mcu|can|firmware|zestech|sofia|px5|px6|hct|fyt|ts10|ts7'"
$info.Root         = if ((Sh "which su")) { "yes" } else { "no" }
$info.Uptime       = Sh "uptime"

# CPU
$cpuinfo = Sh "cat /proc/cpuinfo"
$cores   = ([regex]::Matches($cpuinfo, "(?m)^processor\s*:")).Count
$hwLine  = [regex]::Match($cpuinfo, "(?m)^Hardware\s*:\s*(.+)$").Groups[1].Value
$maxFreq = [int]("0" + (Sh "cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq")) / 1000
$info.CpuCores   = $cores
$info.CpuName    = $hwLine
$info.CpuMaxMHz  = [math]::Round($maxFreq)

# RAM
$mem = Sh "cat /proc/meminfo"
function MemKb($key) { [int64]("0" + [regex]::Match($mem, "(?m)^$key\s*:\s*(\d+)").Groups[1].Value) }
$ramTotalMb = [math]::Round((MemKb "MemTotal") / 1024)
$ramAvailMb = [math]::Round((MemKb "MemAvailable") / 1024)
$swapMb     = [math]::Round((MemKb "SwapTotal") / 1024)
$info.RamTotalMB = $ramTotalMb
$info.RamFreeMB  = $ramAvailMb

# Storage (/data and /sdcard)
function Storage($path) {
    $line = (Sh "df -k $path") -split "`n" | Select-Object -Last 1
    $p = $line -split "\s+"
    if ($p.Count -ge 4) { return @{ TotalMB = [math]::Round([int64]$p[1] / 1024); FreeMB = [math]::Round([int64]$p[3] / 1024) } }
    return @{ TotalMB = 0; FreeMB = 0 }
}
$data = Storage "/data"
$info.StorageTotalGB = [math]::Round($data.TotalMB / 1024, 1)
$info.StorageFreeGB  = [math]::Round($data.FreeMB / 1024, 1)

# eMMC type/speed (best effort)
$info.StorageModel = Sh "cat /sys/block/mmcblk0/device/name"

# Apps
$pkgs = (Sh "pm list packages -3") -split "`n" | ForEach-Object { $_ -replace "package:", "" } | Where-Object { $_ }
$info.UserApps = $pkgs.Count
$sysPkgs = (Sh "pm list packages -s") -split "`n"
$info.SystemApps = $sysPkgs.Count

# Heaviest memory users
$top = Sh "dumpsys meminfo | head -n 25"

# Battery/temp
$info.Temp = (Sh "cat /sys/class/thermal/thermal_zone0/temp")

# ---------- Classify ----------
$tier = "Unknown"
$chipText = ("$($info.Platform) $($info.Hardware) $($info.Board) $hwLine").ToLower()
$legacy = @("rk3188", "rk3066", "mt8127", "mt8227", "mt8163", "sc7731", "sp7731", "rk3368", "px5", "px3", "sofia")
$mid    = @("rk3399", "px6", "mt8788", "mt8183", "sc9863", "ums512", "t310", "t3")
$high   = @("sdm", "msm", "sm8", "sm6", "qcm", "kona", "lahaina", "t618", "t7", "ums9620", "sm4")

if     ($high   | Where-Object { $chipText -like "*$_*" }) { $tier = "High" }
elseif ($mid    | Where-Object { $chipText -like "*$_*" }) { $tier = "Mid" }
elseif ($legacy | Where-Object { $chipText -like "*$_*" }) { $tier = "Legacy" }
elseif ($ramTotalMb -le 2200 -and $cores -le 4) { $tier = "Legacy" }
elseif ($ramTotalMb -ge 6000 -and $cores -ge 8) { $tier = "High" }
elseif ($cores -ge 4) { $tier = "Mid" }

# ---------- Recommendation engine ----------
$findings = New-Object System.Collections.Generic.List[object]
function Add-Finding($sev, $title, $detail) { $findings.Add([pscustomobject]@{ Severity = $sev; Title = $title; Detail = $detail }) | Out-Null }

if ($ramTotalMb -lt 2200)      { Add-Finding "bad"  "RAM is very low ($ramTotalMb MB)" "Android 10+ will be slow. Stay on a light Android 8-10 build or use an Android box." }
elseif ($ramTotalMb -lt 4200)  { Add-Finding "warn" "RAM is limited ($ramTotalMb MB)" "Limit background apps. Use a light launcher." }
else                           { Add-Finding "good" "RAM is fine ($ramTotalMb MB)" "" }

if ($ramTotalMb -gt 0 -and ($ramAvailMb / $ramTotalMb) -lt 0.25) {
    Add-Finding "warn" "Only $ramAvailMb MB RAM free right now" "Too many apps/services running. Try cleanup (Option A)."
}
if ($data.TotalMB -gt 0 -and ($data.FreeMB / $data.TotalMB) -lt 0.15) {
    Add-Finding "warn" "Storage is nearly full ($($info.StorageFreeGB) GB free)" "Low free space slows the system. Remove maps/media or reset."
}
if ($info.Sdk -gt 0 -and $info.Sdk -lt 26) { Add-Finding "warn" "Old Android ($($info.AndroidVer), SDK $($info.Sdk))" "Many current apps (Google Maps, YouTube, Spotify) may stop supporting it." }
if ($info.Sdk -ge 29 -and $ramTotalMb -lt 3200) { Add-Finding "warn" "Heavy Android for the RAM" "Android $($info.AndroidVer) with $ramTotalMb MB RAM may stutter. Disable animations." }
if ($info.UserApps -gt 30) { Add-Finding "warn" "$($info.UserApps) user apps installed" "Remove unused apps, disable autostart." }
if ($info.Root -eq "yes") { Add-Finding "good" "Device is rooted" "More tuning options (debloat, ROM tweaks)." }
if (-not $info.McuVersion) { Add-Finding "info" "MCU version not found by property" "Read it in Factory settings -> About/MCU. See the vendor property dump in the report." }

$options = New-Object System.Collections.Generic.List[object]
function Add-Option($id, $name, $risk, $gain, $fit, $steps) {
    $options.Add([pscustomobject]@{ Id = $id; Name = $name; Risk = $risk; Gain = $gain; Fit = $fit; Steps = $steps }) | Out-Null
}

$aFit = if ($ramAvailMb -lt 600 -or $info.UserApps -gt 25 -or $data.FreeMB -lt 2000) { "Strongly recommended" } else { "Worth trying" }
Add-Option "A" "Clean up + optimize (no flashing)" "Low" "Medium" $aFit @(
    "Backup contacts/offline maps, then factory reset (or remove unused apps).",
    "Set animation scales to 0.5x and background process limit to 2-3.",
    "Run: adb shell pm disable-user --user 0 <package> on unused OEM apps.",
    "Use a light car launcher (AGAMA, CarWebGuru)."
)

$bFit = if ($info.Sdk -lt 28 -and $tier -ne "Legacy") { "Recommended" } else { "If vendor has a matching model build" }
Add-Option "B" "Official firmware update from the vendor" "Low" "Medium" $bFit @(
    "Send the vendor: model '$($info.Model)', board '$($info.Board)', build '$($info.BuildId)', MCU '$($info.McuVersion)'.",
    "Get the matching firmware + MCU file, verify MD5.",
    "Flash with the right tool (RKDevTool / SP Flash Tool) on stable 12V power."
)

$cFit = switch ($tier) { "Legacy" { "Not advised (little ROM support, brick risk)" } "Mid" { "Possible if a ROM exists for your exact chip + MCU" } default { "Optional" } }
Add-Option "C" "Custom/lighter ROM" "Medium-High" "High" $cFit @(
    "Only use a ROM built for chip '$($info.Board)' and your exact main-unit model.",
    "Back up the original firmware first (RKDevTool dump).",
    "Re-enter CAN-bus/steering/camera settings from your photos after flashing."
)

$dFit = switch ($tier) { "Legacy" { "Best value for a weak chip" } "Mid" { "Good if still laggy after A" } default { "Usually not needed" } }
Add-Option "D" "Add an Android box / replace unit" "Low" "Very high" $dFit @(
    "Android box via USB/HDMI or wireless CarPlay/Android Auto adapter.",
    "Or replace the unit with Qualcomm 6-8 core, 6-8 GB RAM, matching Xpander harness/CAN decoder."
)

# ---------- Output ----------
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$base  = Join-Path $OutDir "headunit-$stamp"

$report = [ordered]@{
    CollectedAt = (Get-Date).ToString("s")
    Tier        = $tier
    Info        = $info
    VendorProps = $mcuGrep
    TopMemory   = $top
    Findings    = $findings
    Options     = $options
    UserPackages= $pkgs
}
$report | ConvertTo-Json -Depth 6 | Set-Content "$base.json" -Encoding UTF8

function H($s) { [System.Net.WebUtility]::HtmlEncode([string]$s) }
$rows = ($info.GetEnumerator() | ForEach-Object { "<tr><th>$(H $_.Key)</th><td>$(H $_.Value)</td></tr>" }) -join "`n"
$fHtml = ($findings | ForEach-Object { "<div class='f $($_.Severity)'><b>$(H $_.Title)</b><br>$(H $_.Detail)</div>" }) -join "`n"
$oHtml = ($options | ForEach-Object {
    $steps = ($_.Steps | ForEach-Object { "<li>$(H $_)</li>" }) -join ""
    "<div class='o'><h3>Option $($_.Id): $(H $_.Name)</h3><p><span>Risk: $($_.Risk)</span><span>Gain: $($_.Gain)</span><span class='fit'>$(H $_.Fit)</span></p><ol>$steps</ol></div>"
}) -join "`n"

$html = @"
<!doctype html><html><head><meta charset="utf-8"><title>Head unit report</title>
<style>
body{font-family:Segoe UI,Arial,sans-serif;background:#0f1420;color:#e6e9f2;max-width:960px;margin:24px auto;padding:0 16px}
h1{margin-bottom:4px}.tier{display:inline-block;padding:4px 12px;border-radius:12px;background:#3b5bdb;font-weight:600}
table{width:100%;border-collapse:collapse;background:#171d2e;border-radius:8px;overflow:hidden}
th,td{padding:6px 10px;border-bottom:1px solid #232b42;text-align:left;font-size:14px;word-break:break-all}th{width:200px;color:#9aa6c8}
.f{padding:10px 14px;margin:8px 0;border-radius:8px;border-left:4px solid}.good{background:#12281d;border-color:#2fbf71}.warn{background:#2c2411;border-color:#f0b429}.bad{background:#2d1517;border-color:#e5484d}.info{background:#142033;border-color:#4c9aff}
.o{background:#171d2e;border-radius:10px;padding:4px 16px;margin:12px 0}.o span{margin-right:12px;color:#9aa6c8;font-size:13px}.o .fit{color:#7ee0a6;font-weight:600}
pre{background:#171d2e;padding:12px;border-radius:8px;overflow:auto;font-size:12px}
</style></head><body>
<h1>Head unit report</h1><p>Class: <span class="tier">$tier</span> &nbsp; $(H $info.Brand) $(H $info.Model) &middot; Android $(H $info.AndroidVer) &middot; $ramTotalMb MB RAM &middot; $($info.StorageTotalGB) GB storage</p>
<h2>Findings</h2>$fHtml
<h2>Upgrade options</h2>$oHtml
<h2>Device details</h2><table>$rows</table>
<h2>Vendor/MCU properties</h2><pre>$(H $mcuGrep)</pre>
<h2>Memory snapshot</h2><pre>$(H $top)</pre>
</body></html>
"@
$html | Set-Content "$base.html" -Encoding UTF8

# ---------- Console summary ----------
Write-Host ""
Write-Host "== $($info.Brand) $($info.Model) | Android $($info.AndroidVer) | $($info.Board) | $cores cores | RAM $ramTotalMb MB | ROM $($info.StorageTotalGB) GB | Class: $tier ==" -ForegroundColor Green
foreach ($f in $findings) { Write-Host (" [{0}] {1}" -f $f.Severity.ToUpper(), $f.Title) }
Write-Host ""
foreach ($o in $options) { Write-Host (" Option {0}: {1} -> {2}" -f $o.Id, $o.Name, $o.Fit) -ForegroundColor Yellow }
Write-Host "`nReport: $base.html"
Start-Process "$base.html"
