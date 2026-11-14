#!/bin/bash
# Сборка образа эмулятора arm64 для мака.
# ВАЖНО для Android 17: nsjail НЕ переименовывать. Soong ссылается на
# prebuilts/build-tools/linux-x86/bin/nsjail как на исходник тестового genrule
# и падает без него. Сборка сама увидит, что nsjail под OrbStack не работает,
# и напишет "Build sandboxing disabled due to nsjail error".
cd ~/aosp
source build/envsetup.sh
lunch sdk_phone64_arm64-aosp_current-userdebug
echo "build start $(date -Is)"
/usr/bin/time -v m emu_img_zip WITH_DEXPREOPT=false
echo "build rc=$? $(date -Is)"
du -sh ~/aosp/out
ls -la out/target/product/emu64a/sdk-repo-linux-system-images.zip
