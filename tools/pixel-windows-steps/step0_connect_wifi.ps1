<#
.SYNOPSIS
  [STEP 0 - WIRELESS DEBUGGING CONNECT FOR GOOGLE PIXEL]
  Auto-downloads ADB if missing, pairs (adb pair) and connects (adb connect) over Wi-Fi.

.USAGE
  powershell -ExecutionPolicy Bypass -File .\step0_connect_wifi.ps1 -PairAddress "192.168.1.19:40889" -PairCode "766823"
#>

param(
    [string]$PairAddress = "192.168.1.19:40889",
    [string]$PairCode = "766823",
    [string]$ConnectPort = ""
)

$ErrorActionPreference = "Continue"

# 1. Auto-download ADB if missing
if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    $WorkDir = "C:\adb_work"
    $AdbExe = "$WorkDir\platform-tools\adb.exe"
    if (-not (Test-Path $AdbExe)) {
        Write-Host "[*] ADB not found. Downloading Google Platform-Tools (~12MB)..." -ForegroundColor Yellow
        New-Item -ItemType Directory -Force -Path $WorkDir | Out-Null
        $ZipPath = "$WorkDir\platform-tools.zip"
        Invoke-WebRequest -Uri "https://dl.google.com/android/repository/platform-tools-latest-windows.zip" -OutFile $ZipPath
        Expand-Archive -Path $ZipPath -DestinationPath $WorkDir -Force
        Remove-Item $ZipPath -Force
    }
    $env:Path = "$WorkDir\platform-tools;" + $env:Path
}

$IP = ($PairAddress -split ":")[0]

Write-Host "`n[1/2] Pairing with $PairAddress using code $PairCode..." -ForegroundColor Cyan
& adb pair $PairAddress $PairCode

Start-Sleep -Seconds 2
$devCheck = (& adb devices) | Select-Object -Skip 1 | Where-Object { $_ -match "\tdevice$" }
if ($devCheck) {
    Write-Host "`n[OK] Auto-connected via mDNS!" -ForegroundColor Green
    & adb devices -l
    exit 0
}

Write-Host "`n[2/2] Paired! Now look at the main 'Wireless debugging' screen on your Pixel" -ForegroundColor Yellow
Write-Host "      (under 'IP address & port': ${IP}:XXXXX)" -ForegroundColor Yellow
if (-not $ConnectPort) {
    $ConnectPort = Read-Host "Enter the 5-digit Port shown after $IP (e.g. 38123)"
}
$ConnectPort = $ConnectPort.Trim()

if ($ConnectPort) {
    Write-Host "[*] Connecting to ${IP}:${ConnectPort}..." -ForegroundColor Cyan
    & adb connect "${IP}:${ConnectPort}"
    & adb devices -l
}
