#!/bin/sh
set -e

if [ "$1" = "--list" ]; then
    exec wal --theme
fi

if [ -z "$1" ]; then
    echo "Usage: theme.sh <theme-name> | --list" >&2
    exit 1
fi

ALPHA=90
BG_OPACITY=$(awk "BEGIN {printf \"%.2f\", $ALPHA/100}")
OVERRIDES="$HOME/.config/wal/theme-overrides.csv"

# Look up column N (2=ghostty,3=nvim,4=bat,5=light) for theme "$1".
# Prints empty if the row or that cell is absent. Skips comment/header lines.
lookup() {
    awk -F ',' -v name="$1" -v col="$2" '
        /^#/ { next }
        $1 == name { print $col; found=1; exit }
        END { if (!found) print "" }
    ' "$OVERRIDES"
}

# light: pywal requires -l for themes that only exist under colorschemes/light/
wal_flags="-n -a $ALPHA -o $HOME/.config/wal/postrun"
if [ "$(lookup "$1" 5)" = "light" ]; then
    wal_flags="$wal_flags -l"
fi
wal --theme "$1" $wal_flags

# ghostty: reconstruct "theme = <id>"; empty => write nothing (no fallback, matches today)
ghostty_theme=$(lookup "$1" 2)
if [ -n "$ghostty_theme" ]; then
    printf 'theme = %s\n' "$ghostty_theme" > "$HOME/.cache/wal/colors.ghostty"
    printf '\nbackground-opacity = %s\n' "$BG_OPACITY" >> "$HOME/.cache/wal/colors.ghostty"
fi

# nvim: override or the "wal" sentinel (colorscheme.lua coerces wal/empty -> "default")
nvim_theme=$(lookup "$1" 3)
if [ -n "$nvim_theme" ]; then
    echo "$nvim_theme" > "$HOME/.cache/wal/nvim_colorscheme"
else
    echo "wal" > "$HOME/.cache/wal/nvim_colorscheme"
fi

# bat: override or "base16"
bat_theme=$(lookup "$1" 4)
if [ -z "$bat_theme" ]; then
    bat_theme="base16"
fi
sed -i '' "s/--theme=.*/--theme=\"$bat_theme\"/" "$HOME/.config/bat/config"
