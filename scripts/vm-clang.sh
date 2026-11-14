#!/bin/bash
# clang через partial clone не ставится: git докачивает недостающие деревья по одному
# объекту за запрос, repo сдаётся через ~6 минут. Клонируем его отдельно, без истории.
set -euo pipefail
cd ~/aosp/prebuilts/clang/host
rmdir linux-x86 2>/dev/null || rm -rf linux-x86
/usr/bin/time -f "clang clone: %E" git clone --progress --depth=1 --single-branch \
  -b android17-release \
  https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86 linux-x86
du -sh linux-x86
