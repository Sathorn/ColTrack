#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="/home/sath/projects/ColTrack"
DST_DIR="/mnt/d/Battle.net/World of Warcraft/_retail_/Interface/AddOns/ColTrack"

mkdir -p "$DST_DIR"

rsync -av --delete --delete-excluded \
  --exclude '/.git' \
  --exclude '/.idea' \
  --exclude '/.vscode' \
  --exclude '/scripts' \
  --exclude '*.py' \
  --exclude '*.psd' \
  --exclude '*.xcf' \
  --exclude '*.kra' \
  --include '*/' \
  --include '/ColTrack.lua' \
  --include '/ColTrack.toc' \
  --include '/Images/*.tga' \
  --include '/Textures/*.tga' \
  --include '/Libs/**.lua' \
  --exclude '*' \
  "$SRC_DIR/" "$DST_DIR/"

echo "Synced to: $DST_DIR"
