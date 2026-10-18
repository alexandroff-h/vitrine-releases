#!/bin/bash
# Install Vitrine without a browser download. No sudo or system-wide security changes.
set -euo pipefail
repository="alexandroff-h/vitrine-releases"
site="https://alexandroff-h.github.io/vitrine-releases"
fail() { printf '%s\n' "$*" >&2; exit 1; }
[[ "$(uname -s)" == Darwin && "$(uname -m)" == arm64 ]] || fail 'Vitrine requires an Apple Silicon Mac.'
major="$(sw_vers -productVersion | cut -d. -f1)"
(( major >= 15 )) || fail 'Vitrine requires macOS 15 or newer.'
pgrep -x CanvasMac >/dev/null && fail 'Quit Vitrine, then run this installer again.'
parent="${VITRINE_INSTALL_DIR:-/Applications}"
if [[ ! -w "$parent" && -z "${VITRINE_INSTALL_DIR:-}" ]]; then parent="$HOME/Applications"; fi
mkdir -p "$parent"
[[ -w "$parent" ]] || fail "Cannot write to $parent"
work="$(mktemp -d "$parent/.vitrine-install.XXXXXX")"
destination="$parent/Vitrine.app"
cleanup() {
  if [[ -d "$work/previous.app" && ! -e "$destination" ]]; then
    mv "$work/previous.app" "$destination"
  fi
  rm -rf "$work"
}
trap cleanup EXIT
curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' \
  "$site/latest.txt" -o "$work/latest.txt"
tag="$(tr -d '\r\n' < "$work/latest.txt")"
[[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail 'No installable release is published yet.'
base="https://github.com/$repository/releases/download/$tag"
printf 'Downloading Vitrine %s…\n' "${tag#v}"
for asset in Vitrine.zip SHA256SUMS; do
  curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' \
    "$base/$asset" -o "$work/$asset"
done
expected="$(awk '$2 == "Vitrine.zip" {print $1}' "$work/SHA256SUMS")"
[[ "$expected" =~ ^[a-f0-9]{64}$ ]] || fail 'Invalid release checksum.'
actual="$(shasum -a 256 "$work/Vitrine.zip" | awk '{print $1}')"
[[ "$actual" == "$expected" ]] || fail 'Download checksum mismatch; nothing was installed.'
ditto -x -k "$work/Vitrine.zip" "$work/unpacked"
app="$work/unpacked/Vitrine.app"
[[ -d "$app" ]] || fail 'The archive does not contain Vitrine.app.'
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Contents/Info.plist")" == design.alexandroff.vitrine ]] || fail 'Unexpected application identifier.'
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")" == "${tag#v}" ]] || fail 'Unexpected application version.'
codesign --verify --deep --strict "$app"
# This beta is not notarized. Remove quarantine from this app only; leave Gatekeeper enabled.
xattr -dr com.apple.quarantine "$app" 2>/dev/null || true
pgrep -x CanvasMac >/dev/null && fail 'Vitrine was opened during download. Quit it and retry.'
if [[ -e "$destination" ]]; then mv "$destination" "$work/previous.app"; fi
mv "$app" "$destination"
touch "$destination"
printf 'Installed Vitrine %s in %s. Your library is unchanged.\n' "${tag#v}" "$parent"
open "$destination"
