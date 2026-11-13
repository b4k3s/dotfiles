#!/bin/sh
set -e

cd "$(dirname "$0")"

if ! command -v stow >/dev/null 2>&1; then
    command -v brew >/dev/null 2>&1 || { echo "need Homebrew (https://brew.sh) or stow installed first" >&2; exit 1; }
    echo "installing GNU Stow via Homebrew..."
    brew install stow
fi

# repo itself is the stow package; its parent dir is the stow-dir —
# works regardless of what the clone directory is named
stow -d ".." -t "$HOME" -v "$(basename "$PWD")"

# LibreWolf's real profile dir has a per-install random hash, so stow can't
# reach it directly — find the active profile from profiles.ini and symlink in.
librewolf_ini="$HOME/Library/Application Support/LibreWolf/profiles.ini"
if [ -f "$librewolf_ini" ]; then
    profile_rel=$(awk '/^\[Install/{f=1; next} f && /^Default=/{print substr($0, 9); exit} /^\[/{f=0}' "$librewolf_ini")
    if [ -n "$profile_rel" ]; then
        profile_dir="$HOME/Library/Application Support/LibreWolf/$profile_rel"
        chrome_dir="$profile_dir/chrome"
        mkdir -p "$chrome_dir"
        ln -sf "$PWD/.config/librewolf/chrome/userChrome.css" "$chrome_dir/userChrome.css"
        ln -sf "$PWD/.config/librewolf/user.js" "$profile_dir/user.js"
        # Firefox ignores a symlinked userContent.css, so it and the generated sheets it
        # imports are hard links. Git replaces a file when a checkout changes it, which
        # leaves the profile copy stale, so re-run this after switching branches.
        for css in userContent.css gh.css yt.css wp.css; do
            if [ -f "$PWD/.config/librewolf/chrome/$css" ]; then
                ln -f "$PWD/.config/librewolf/chrome/$css" "$chrome_dir/$css"
            fi
        done
        echo "linked LibreWolf userChrome/userContent/user.js into $profile_dir"
    else
        echo "no default profile found in $librewolf_ini, skipping LibreWolf links"
    fi
else
    echo "LibreWolf profiles.ini not found, skipping LibreWolf links"
fi
