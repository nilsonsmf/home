#!/usr/bin/env bash
set -euo pipefail

groups_available=(social ia dev browsers proton utils games)
selected_groups=()
apt_updated=false
temp_dir=$(mktemp -d)
trap 'rm -rf -- "$temp_dir"' EXIT

usage() {
  cat <<'EOF'
Usage: ./install-apps.sh [--all] [--group GROUP[,GROUP...]] [--list]

Groups:
  social   Telegram, ZapZap
  ia       Codex, ChatGPT web app
  dev      Visual Studio Code, DBeaver Community
  browsers Zen Browser, Chromium
  proton   Proton Drive web app, Proton Authenticator, Proton Pass
  utils    Obsidian, Sublime Text, LocalSend, Freeplane, Cryptomator
  games    Steam, Lutris, Heroic Games Launcher
EOF
}

is_valid_group() {
  local wanted=$1 item
  for item in "${groups_available[@]}"; do
    [[ "$item" == "$wanted" ]] && return 0
  done
  return 1
}

apt_update_once() {
  if [[ "$apt_updated" == false ]]; then
    sudo apt-get update
    apt_updated=true
  fi
}

apt_install() {
  local missing=() package
  for package in "$@"; do
    dpkg-query -W -f='${db:Status-Abbrev}' "$package" 2>/dev/null | grep -q '^ii ' || missing+=("$package")
  done
  ((${#missing[@]})) || return 0
  apt_update_once
  sudo apt-get install -y "${missing[@]}"
}

ensure_flatpak() {
  command -v flatpak >/dev/null 2>&1 || apt_install flatpak
  if ! flatpak remotes --user --columns=name | grep -qx flathub; then
    flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  fi
}

flatpak_install() {
  ensure_flatpak
  flatpak install --user -y flathub "$@"
}

ensure_snap() {
  command -v snap >/dev/null 2>&1 || apt_install snapd
  sudo systemctl enable --now snapd.socket
}

snap_install() {
  local name=$1 confinement=${2:-}
  ensure_snap
  snap list "$name" >/dev/null 2>&1 && return 0
  if [[ "$confinement" == classic ]]; then
    sudo snap install "$name" --classic
  else
    sudo snap install "$name"
  fi
}

ensure_chromium() {
  command -v chromium >/dev/null 2>&1 || snap_install chromium
}

install_web_app() {
  local name=$1 slug=$2 url=$3 desktop_file="$HOME/.local/share/applications/$slug.desktop"
  ensure_chromium
  mkdir -p "$HOME/.local/share/applications"
  {
    printf '[Desktop Entry]\n'
    printf 'Type=Application\n'
    printf 'Name=%s\n' "$name"
    printf 'Exec=chromium --app=%s\n' "$url"
    printf 'Icon=chromium\n'
    printf 'Terminal=false\n'
    printf 'Categories=Network;\n'
    printf 'StartupNotify=true\n'
  } >"$temp_dir/$slug.desktop"
  install -m 0644 "$temp_dir/$slug.desktop" "$desktop_file"
  command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$HOME/.local/share/applications" || true
  printf 'installed web app: %s\n' "$name"
}

install_codex() {
  command -v codex >/dev/null 2>&1 && { echo 'ok      Codex'; return; }
  local installer="$temp_dir/install-codex.sh"
  curl -fsSL https://chatgpt.com/codex/install.sh -o "$installer"
  sh "$installer"
}

install_proton_deb() {
  local package_name=$1 manifest_url=$2 manifest="$temp_dir/$package_name.json"
  local url checksum deb
  dpkg-query -W -f='${db:Status-Abbrev}' "$package_name" 2>/dev/null | grep -q '^ii ' && { echo "ok      $package_name"; return; }
  [[ "$(dpkg --print-architecture)" == amd64 ]] || { echo "$package_name is only automated for amd64." >&2; return 1; }
  curl -fsSL "$manifest_url" -o "$manifest"
  IFS=$'\t' read -r url checksum < <(
    jq -r '[.Releases[] | select(.CategoryName == "Stable")][0].File[]
      | select(.Identifier | startswith(".deb"))
      | [.Url, .Sha512CheckSum] | @tsv' "$manifest" | head -n 1
  )
  [[ -n "$url" && -n "$checksum" ]] || { echo "No stable .deb found for $package_name." >&2; return 1; }
  deb="$temp_dir/${url##*/}"
  curl -fsSL "$url" -o "$deb"
  printf '%s  %s\n' "$checksum" "$deb" | sha512sum -c -
  apt_update_once
  sudo apt-get install -y "$deb"
}

install_group() {
  case "$1" in
    social)
      flatpak_install org.telegram.desktop com.rtosta.zapzap
      ;;
    ia)
      install_codex
      install_web_app ChatGPT chatgpt https://chatgpt.com/
      ;;
    dev)
      snap_install code classic
      flatpak_install io.dbeaver.DBeaverCommunity
      ;;
    browsers)
      flatpak_install app.zen_browser.zen
      snap_install chromium
      ;;
    proton)
      install_web_app 'Proton Drive' proton-drive https://drive.proton.me/
      install_proton_deb proton-authenticator https://proton.me/download/authenticator/linux/version.json
      flatpak_install me.proton.Pass
      ;;
    utils)
      flatpak_install md.obsidian.Obsidian org.localsend.localsend_app org.cryptomator.Cryptomator
      snap_install sublime-text classic
      apt_install freeplane
      ;;
    games)
      flatpak_install com.valvesoftware.Steam net.lutris.Lutris com.heroicgameslauncher.hgl
      ;;
  esac
}

while (($#)); do
  case "$1" in
    --all) selected_groups=("${groups_available[@]}") ;;
    --group)
      [[ $# -ge 2 ]] || { usage >&2; exit 2; }
      IFS=',' read -r -a requested <<<"$2"
      selected_groups+=("${requested[@]}")
      shift
      ;;
    --list) usage; exit ;;
    -h|--help) usage; exit ;;
    *) usage >&2; exit 2 ;;
  esac
  shift
done

if ((${#selected_groups[@]} == 0)); then
  if [[ -t 0 ]]; then
    usage
    read -r -p 'Grupos separados por vírgula (Enter = todos): ' answer
    if [[ -z "$answer" ]]; then
      selected_groups=("${groups_available[@]}")
    else
      IFS=',' read -r -a selected_groups <<<"${answer// /}"
    fi
  else
    echo 'Choose groups with --group or use --all.' >&2
    exit 2
  fi
fi

declare -A already_selected=()
normalized_groups=()
for group in "${selected_groups[@]}"; do
  is_valid_group "$group" || { echo "Unknown group: $group" >&2; usage >&2; exit 2; }
  [[ -n "${already_selected[$group]:-}" ]] && continue
  already_selected[$group]=1
  normalized_groups+=("$group")
done

for group in "${normalized_groups[@]}"; do
  printf '\n== %s ==\n' "$group"
  install_group "$group"
done

echo 'Application installation completed. Some apps may require a new login session.'
