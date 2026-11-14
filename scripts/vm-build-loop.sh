#!/bin/bash
# siso (замена ninja в Android 17) под Rosetta может умереть посреди сборки с кодом 133 (SIGTRAP).
# Ни одна команда при этом не падает, лечится повторным m: сделанное сохраняется.
# Цикл перезапускает сборку только на этом коде и останавливается на настоящей ошибке.
# Запуск: tmux new -s build 'bash vm-build-loop.sh 2>&1 | tee ~/logs/build-loop.log'
for i in 1 2 3 4 5 6 7 8; do
  echo "=== attempt $i $(date -Is)"
  bash "$(dirname "$0")/vm-build.sh" > ~/logs/build.log 2>&1
  cat ~/logs/build.log >> ~/logs/build-all.log
  grep -q "build rc=0" ~/logs/build.log && { echo "=== OK $(date -Is)"; break; }
  grep -q "ninja failed with: exit status 133" ~/logs/build.log \
    || { echo "=== real failure $(date -Is)"; break; }
done
echo "=== loop done $(date -Is)"
