#!/bin/bash
# Запускать на маке. Ставит собранный образ в Android SDK и создаёт AVD.
set -euo pipefail
SDK="$HOME/Library/Android/sdk"
OUT="$HOME/OrbStack/aosp/home/$(orb -m aosp whoami)/aosp/out/target/product/emu64a"  # ФС машины видна с мака
IMG="$SDK/system-images/aosp-local-17/default"
AVD="$HOME/.android/avd"
NAME=AOSP17_local

mkdir -p "$IMG" && (cd "$IMG" && unzip -q -o "$OUT/sdk-repo-linux-system-images.zip")
cat "$IMG/arm64-v8a/source.properties"

# В zip есть только source.properties, а Android Studio и avdmanager опознают образ
# по package.xml. Без него Device Manager пишет "Missing system image", а avdmanager
# отвечает "Package path is not valid". Кладём свой package.xml с путём пакета.
cat > "$IMG/arm64-v8a/package.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<ns2:repository xmlns:ns2="http://schemas.android.com/repository/android/common/02" xmlns:ns14="http://schemas.android.com/sdk/android/repo/sys-img2/05">
    <license id="aosp-local-license" type="text">Locally built AOSP image. Apache License 2.0 and the licenses listed in NOTICE.txt.</license>
    <localPackage path="system-images;aosp-local-17;default;arm64-v8a" obsolete="false">
        <type-details xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="ns14:sysImgDetailsType">
            <api-level>37.0</api-level>
            <extension-level>22</extension-level>
            <base-extension>true</base-extension>
            <tag><id>default</id><display>Default Android System Image</display></tag>
            <vendor><id>aosp-local</id><display>Local AOSP build</display></vendor>
            <abi>arm64-v8a</abi>
            <abis>arm64-v8a</abis>
        </type-details>
        <revision><major>1</major></revision>
        <display-name>AOSP 17 local build ARM 64 v8a System Image</display-name>
        <uses-license ref="aosp-local-license"/>
    </localPackage>
</ns2:repository>
XML
"$SDK/cmdline-tools/latest/bin/sdkmanager" --list_installed | grep aosp-local   # должен появиться пакет

# AVD можно создать и через avdmanager, но тут он описан руками, чтобы было видно, что внутри
mkdir -p "$AVD/$NAME.avd"
cat > "$AVD/$NAME.ini" <<INI
avd.ini.encoding=UTF-8
path=$AVD/$NAME.avd
path.rel=avd/$NAME.avd
target=android-37.0
INI
cat > "$AVD/$NAME.avd/config.ini" <<INI
avd.ini.encoding=UTF-8
AvdId=$NAME
avd.ini.displayname=AOSP 17 (local build)
image.sysdir.1=system-images/aosp-local-17/default/arm64-v8a/
tag.id=default
tag.display=Default
abi.type=arm64-v8a
hw.cpu.arch=arm64
target=android-37.0
hw.ramSize=4096
hw.cpu.ncore=4
hw.lcd.width=1280
hw.lcd.height=2856
hw.lcd.density=480
hw.gpu.enabled=yes
hw.gpu.mode=auto
hw.keyboard=yes
disk.dataPartition.size=6G
PlayStore.enabled=false
fastboot.forceColdBoot=yes
INI

# -writable-system нужен, чтобы потом заливать модули через adb remount/push
"$SDK/emulator/emulator" -avd $NAME -writable-system -no-snapshot &
ADB="$SDK/platform-tools/adb"
$ADB wait-for-device
until [ "$($ADB shell getprop sys.boot_completed | tr -d '\r')" = 1 ]; do sleep 2; done
$ADB shell getprop ro.build.fingerprint
