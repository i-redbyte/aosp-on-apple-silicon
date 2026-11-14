#!/bin/bash
# Запускать на маке (Apple Silicon). Ставит OrbStack и создаёт x86-64 Ubuntu через Rosetta.
set -euo pipefail

brew install --cask orbstack
open -a OrbStack            # первый запуск дописывает настройку

# OrbStack при установке делает свой Docker-контекст активным.
# Если раньше был Colima или Docker Desktop, верните его и запретите переключение:
#   docker context use colima
#   orb config set docker.set_context false

# По умолчанию машинам дают 16 ГБ. Для AOSP нужно больше (на моём маке 48 ГБ, машине я отдал 36).
orb config set memory_mib 36864
orb config show | grep -E 'memory_mib|cpu|rosetta'
orb stop && orb start

# amd64-машина: весь userspace x86-64, его исполняет Rosetta, uname -m покажет x86_64
orb create --arch amd64 ubuntu:noble aosp
orb -m aosp bash -c 'uname -m; nproc; free -g; df -h /'

# Чтобы мак не уснул за ночь (48 часов). Крышку не закрывать, зарядку не отключать.
nohup caffeinate -ims -t 172800 >/dev/null 2>&1 &
