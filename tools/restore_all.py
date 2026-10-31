#!/usr/bin/env python3
import subprocess
import sys
import time

def get_uninstalled():
    all_pkgs = set(subprocess.check_output(['adb', 'shell', 'pm', 'list', 'packages', '-u']).decode().splitlines())
    cur_pkgs = set(subprocess.check_output(['adb', 'shell', 'pm', 'list', 'packages']).decode().splitlines())
    return sorted([p.replace('package:', '').strip() for p in (all_pkgs - cur_pkgs)])

def main():
    uninstalled = get_uninstalled()
    print(f"Total uninstalled packages found: {len(uninstalled)}")
    if not uninstalled:
        print("No uninstalled packages found. All restored!")
        return

    # Prioritize critical overlays and system services
    priority_keywords = ['overlay', 'qualcomm', 'qti', 'xiaomi', 'miui', 'google']
    def sort_key(pkg):
        for idx, kw in enumerate(priority_keywords):
            if kw in pkg:
                return idx
        return len(priority_keywords)

    sorted_pkgs = sorted(uninstalled, key=sort_key)

    for i, pkg in enumerate(sorted_pkgs, 1):
        print(f"[{i}/{len(sorted_pkgs)}] Restoring {pkg}...", end=' ', flush=True)
        res = subprocess.run(
            ['adb', 'shell', f'cmd package install-existing {pkg}'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        out = res.stdout.strip()
        if 'installed for user' in out:
            print("OK")
        else:
            print(f"FAILED ({out} {res.stderr.strip()})")

    print("\nVerification:")
    remaining = get_uninstalled()
    print(f"Remaining uninstalled packages: {len(remaining)}")

if __name__ == '__main__':
    main()

