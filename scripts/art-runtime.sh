#!/bin/bash
# Параметры ART для всей ОС без пересборки (userdebug, root). Живут до перезагрузки.
ADB="$HOME/Library/Android/sdk/platform-tools/adb"
$ADB root
$ADB shell 'getprop | grep -E "dalvik.vm.heap"'
$ADB shell setprop dalvik.vm.heapgrowthlimit 384m
$ADB shell setprop dalvik.vm.heapstartsize 32m
$ADB shell setprop dalvik.vm.checkjni true
$ADB shell setprop dalvik.vm.extra-opts '"-verbose:gc -XX:LowMemoryMode"'
$ADB shell 'stop; start'                      # перезапуск zygote, ~12 с
sleep 15
$ADB shell 'logcat -d | grep -E "CheckJNI|zygote64: option\["'
# Проверка: ArtInfo печатает Runtime.maxMemory()/totalMemory()
#   javac --release 8 ArtInfo.java && d8 --min-api 30 --output . ArtInfo.class
#   adb push classes.dex /data/local/tmp/artinfo.dex
$ADB shell 'CLASSPATH=/data/local/tmp/artinfo.dex app_process / ArtInfo'
