#!/usr/bin/env bash
# Setup script for pi agent config symlinks
# Run this on a new machine after cloning the dotfiles repo.
#
# Usage: ./setup.sh
#   or:  ./setup.sh /path/to/dotfiles/app-configs/pi

set -euo pipefail

# Source directory: where this script lives (i.e. the dotfiles pi config)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE="${1:-$SCRIPT_DIR}"

# Target directory: where pi expects its agent config
TARGET="$HOME/.pi/agent"

ITEMS=(extensions prompts skills themes settings.json)

echo "Pi config setup"
echo "  Source: $SOURCE"
echo "  Target: $TARGET"
echo ""

mkdir -p "$TARGET"

for item in "${ITEMS[@]}"; do
  src="$SOURCE/$item"
  dest="$TARGET/$item"

  if [ ! -e "$src" ]; then
    echo "⚠ Skipping $item (not found in source)"
    continue
  fi

  if [ -L "$dest" ]; then
    existing="$(readlink "$dest")"
    if [ "$existing" = "$src" ]; then
      echo "✓ $item (already linked)"
      continue
    fi
    echo "→ $item (updating symlink: $existing → $src)"
    rm "$dest"
  elif [ -e "$dest" ]; then
    echo "→ $item (backing up existing to ${dest}.bak)"
    mv "$dest" "${dest}.bak"
  else
    echo "→ $item (creating symlink)"
  fi

  ln -s "$src" "$dest"
done

echo ""
echo "Done!"
