#!/bin/bash
# Запускать внутри машины: orb -m aosp, потом bash vm-deps.sh
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get install -y git-core gnupg flex bison build-essential zip curl zlib1g-dev \
  libc6-dev-i386 x11proto-core-dev libx11-dev lib32z1-dev libgl1-mesa-dev libxml2-utils \
  xsltproc unzip fontconfig python3 python-is-python3 rsync tmux time

sudo curl -s https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo
sudo chmod a+x /usr/local/bin/repo
repo version | head -2

git config --global user.name  "Your Name"
git config --global user.email "you@example.com"
git config --global color.ui false
