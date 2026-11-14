#!/bin/bash
# Исходники держим внутри Linux-машины (регистрозависимая ФС, быстрее, чем общая папка мака).
# Запускать в tmux, чтобы пережить обрыв сессии:  mkdir -p ~/logs; tmux new -s sync 'bash vm-sync.sh 2>&1 | tee ~/logs/sync.log'
mkdir -p ~/aosp ~/logs && cd ~/aosp

echo "init start $(date -Is)"
/usr/bin/time -v repo init --partial-clone --no-use-superproject \
  -b android-latest-release -u https://android.googlesource.com/platform/manifest

echo "sync start $(date -Is)"
/usr/bin/time -v repo sync -c -j8
echo "sync rc=$? $(date -Is)"

# Повтор для упавших (prebuilts/tools и system/extras проходят со второго раза):
repo sync -c -j2 prebuilts/tools system/extras
du -sh ~/aosp
