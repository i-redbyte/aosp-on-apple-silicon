#!/bin/bash
# Мелкая правка без полной пересборки. Пример: строка в утилите service.
# В машине (orb -m aosp):
#   cd ~/aosp && source build/envsetup.sh && lunch sdk_phone64_arm64-aosp_current-userdebug
#   vi frameworks/native/cmds/service/service.cpp      # правим вывод "Found N services:"
#   time m service
# На маке:
ADB="$HOME/Library/Android/sdk/platform-tools/adb"
OUT="$HOME/OrbStack/aosp/home/$(orb -m aosp whoami)/aosp/out/target/product/emu64a"
$ADB root
$ADB remount            # первый раз попросит reboot: adb reboot, потом снова adb root && adb remount
$ADB push "$OUT/system/bin/service" /system/bin/service     # 3 секунды
$ADB shell service list | head -1
# Много правок сразу: ANDROID_PRODUCT_OUT="$OUT" $ADB sync system
