#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
backup_root="${XDG_STATE_HOME:-$HOME/.local/state}/home-dotfiles/backups"
backup_dir="$backup_root/$(date +%Y%m%d-%H%M%S)"
backup_created=false
apps_mode=ask

core_packages=(
  zsh git curl ca-certificates jq unzip fontconfig
  eza bat fd-find ripgrep zsh-autosuggestions
  ffmpeg pandoc texlive-latex-base texlive-latex-recommended
  flatpak plasma-discover-backend-flatpak
)

managed_files=(
  ".zshrc:$HOME/.zshrc"
  ".bash_aliases:$HOME/.bash_aliases"
  ".gitconfig:$HOME/.gitconfig"
  "aliases.zsh:$HOME/.oh-my-zsh/custom/aliases.zsh"
  "config/oh-my-posh/dark-powerline.omp.json:$HOME/.config/oh-my-posh/dark-powerline.omp.json"
  "config/starship.toml:$HOME/.config/starship.toml"
  "bin/md2pdf:$HOME/.local/bin/md2pdf"
  "bin/openURL:$HOME/.local/bin/openURL"
  "bin/restart-kdeconnect.sh:$HOME/.local/bin/restart-kdeconnect.sh"
  "bin/video2gif:$HOME/.local/bin/video2gif"
  "bin/window2gif:$HOME/.local/bin/window2gif"
)

usage() {
  cat <<EOF
Usage: $0 [--apply] [--with-apps|--no-apps]
       $0 --check
EOF
}

require_supported_system() {
  [[ -r /etc/os-release ]] || { echo 'Cannot identify the operating system.' >&2; exit 1; }
  # shellcheck disable=SC1091
  source /etc/os-release
  if [[ "${ID:-}" != ubuntu && " ${ID_LIKE:-} " != *' ubuntu '* && "${ID:-}" != kubuntu ]]; then
    echo "This installer supports Kubuntu/Ubuntu; detected: ${PRETTY_NAME:-unknown}." >&2
    exit 1
  fi
}

install_core_packages() {
  local missing=() package
  for package in "${core_packages[@]}"; do
    dpkg-query -W -f='${db:Status-Abbrev}' "$package" 2>/dev/null | grep -q '^ii ' || missing+=("$package")
  done
  if ((${#missing[@]})); then
    echo "Installing core packages: ${missing[*]}"
    sudo apt-get update
    sudo apt-get install -y "${missing[@]}"
  else
    echo 'ok      core APT packages'
  fi
}

install_oh_my_zsh() {
  if [[ -d "$HOME/.oh-my-zsh/.git" ]]; then
    echo 'ok      Oh My Zsh'
  elif [[ -e "$HOME/.oh-my-zsh" ]]; then
    echo '~/.oh-my-zsh exists but is not a Git checkout; leaving it unchanged.' >&2
  else
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
  fi
}

install_starship() {
  command -v starship >/dev/null 2>&1 && { echo 'ok      Starship'; return; }
  local temp_dir installer
  temp_dir=$(mktemp -d)
  installer="$temp_dir/install-starship.sh"
  curl -fsSL https://starship.rs/install.sh -o "$installer"
  sh "$installer" --yes --bin-dir "$HOME/.local/bin"
}

install_oh_my_posh() {
  command -v oh-my-posh >/dev/null 2>&1 && { echo 'ok      Oh My Posh'; return; }
  local temp_dir installer
  temp_dir=$(mktemp -d)
  installer="$temp_dir/install-oh-my-posh.sh"
  curl -fsSL https://ohmyposh.dev/install.sh -o "$installer"
  sh "$installer" -d "$HOME/.local/bin"
}

install_nerd_font() {
  fc-list 2>/dev/null | grep -qi 'JetBrainsMono Nerd Font' && { echo 'ok      JetBrainsMono Nerd Font'; return; }
  local temp_dir metadata url digest archive
  temp_dir=$(mktemp -d)
  metadata="$temp_dir/release.json"
  archive="$temp_dir/JetBrainsMono.zip"
  curl -fsSL https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest -o "$metadata"
  url=$(jq -r '.assets[] | select(.name == "JetBrainsMono.zip") | .browser_download_url' "$metadata")
  digest=$(jq -r '.assets[] | select(.name == "JetBrainsMono.zip") | .digest // empty' "$metadata")
  [[ -n "$url" && "$url" != null ]] || { echo 'JetBrainsMono.zip was not found in the Nerd Fonts release.' >&2; return 1; }
  curl -fsSL "$url" -o "$archive"
  if [[ "$digest" == sha256:* ]]; then
    printf '%s  %s\n' "${digest#sha256:}" "$archive" | sha256sum -c -
  fi
  mkdir -p "$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
  unzip -oq "$archive" -d "$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
  fc-cache -f "$HOME/.local/share/fonts"
}

detect_kde() {
  local desktop="${XDG_CURRENT_DESKTOP:-} ${XDG_SESSION_DESKTOP:-}"
  [[ "$desktop" == *KDE* || "$desktop" == *Plasma* ]] && return 0
  local pkg
  for pkg in plasma-desktop plasma-workspace kde-plasma-desktop; do
    dpkg-query -W -f='${db:Status-Abbrev}' "$pkg" 2>/dev/null | grep -q '^ii ' && return 0
  done
  return 1
}

install_kde_fix_cedilla() {
  if ! detect_kde; then
    echo 'skip    kde-fix-cedilla (no KDE session detected)'
    return
  fi
  local target="$HOME/.local/bin/fix-kde-cedilla"
  if [[ -s "$target" ]]; then
    echo 'ok      kde-fix-cedilla'
    return
  fi
  mkdir -p "$HOME/.local/bin"
  curl -fsSL https://raw.githubusercontent.com/nilsonsmf/kde-fix-cedilla/main/fix-kde-cedilla.sh -o "$target"
  chmod 0755 "$target"
  echo 'installed kde-fix-cedilla'
  "$target" || echo 'kde-fix-cedilla reported errors; see output above.' >&2
}

validate_repo() {
  local failed=0
  zsh -n "$repo_dir/.zshrc" "$repo_dir/aliases.zsh" || failed=1
  bash -n "$repo_dir/install.sh" "$repo_dir/install-apps.sh" "$repo_dir/bin/"* || failed=1
  jq empty "$repo_dir/config/oh-my-posh/dark-powerline.omp.json" || failed=1
  if command -v starship >/dev/null 2>&1; then
    STARSHIP_CONFIG="$repo_dir/config/starship.toml" starship explain >/dev/null || failed=1
  else
    echo 'missing starship (required for the default prompt)' >&2
    failed=1
  fi
  if command -v oh-my-posh >/dev/null 2>&1; then
    oh-my-posh config export --config "$repo_dir/config/oh-my-posh/dark-powerline.omp.json" >/dev/null || failed=1
  else
    echo 'missing Oh My Posh (required for the alternative prompt)' >&2
    failed=1
  fi
  return "$failed"
}

check_permissions() {
  local failed=0 file mode
  for file in "$repo_dir/install.sh" "$repo_dir/install-apps.sh" "$repo_dir/bin/"*; do
    mode=$(stat -c '%a' "$file")
    [[ "$mode" == 755 ]] || { printf 'mode    %s (expected 755, found %s)\n' "$file" "$mode" >&2; failed=1; }
  done
  for file in "$repo_dir/.zshrc" "$repo_dir/.bash_aliases" "$repo_dir/.gitconfig" \
    "$repo_dir/aliases.zsh" "$repo_dir/config/starship.toml" \
    "$repo_dir/config/oh-my-posh/dark-powerline.omp.json"; do
    mode=$(stat -c '%a' "$file")
    [[ "$mode" == 644 ]] || { printf 'mode    %s (expected 644, found %s)\n' "$file" "$mode" >&2; failed=1; }
  done
  [[ "$failed" == 0 ]] && echo 'ok      repository permissions'
  return "$failed"
}

fix_permissions() {
  chmod 0755 "$repo_dir/install.sh" "$repo_dir/install-apps.sh" "$repo_dir/bin/"*
  chmod 0644 "$repo_dir/.zshrc" "$repo_dir/.bash_aliases" "$repo_dir/.gitconfig" \
    "$repo_dir/aliases.zsh" "$repo_dir/config/starship.toml" \
    "$repo_dir/config/oh-my-posh/dark-powerline.omp.json"
}

link_file() {
  local source_path=$1 target_path=$2 relative
  mkdir -p -- "$(dirname -- "$target_path")"
  if [[ -L "$target_path" && "$(readlink -- "$target_path")" == "$source_path" ]]; then
    printf 'ok      %s\n' "$target_path"
    return
  fi
  if [[ -e "$target_path" || -L "$target_path" ]]; then
    relative=${target_path#"$HOME"/}
    mkdir -p -- "$backup_dir/$(dirname -- "$relative")"
    mv -- "$target_path" "$backup_dir/$relative"
    backup_created=true
    printf 'backup  %s\n' "$target_path"
  fi
  ln -s -- "$source_path" "$target_path"
  printf 'link    %s -> %s\n' "$target_path" "$source_path"
}

check_installation() {
  local failed=0 item source_path target_path package
  for package in "${core_packages[@]}"; do
    dpkg-query -W -f='${db:Status-Abbrev}' "$package" 2>/dev/null | grep -q '^ii ' || { echo "missing package: $package"; failed=1; }
  done
  [[ -d "$HOME/.oh-my-zsh" ]] || { echo 'missing: Oh My Zsh'; failed=1; }
  command -v starship >/dev/null 2>&1 || { echo 'missing: Starship'; failed=1; }
  command -v oh-my-posh >/dev/null 2>&1 || { echo 'missing: Oh My Posh'; failed=1; }
  fc-list 2>/dev/null | grep -qi 'JetBrainsMono Nerd Font' || { echo 'missing: JetBrainsMono Nerd Font'; failed=1; }
  if detect_kde; then
    [[ -s "$HOME/.local/bin/fix-kde-cedilla" ]] || { echo 'missing: kde-fix-cedilla (KDE session detected)'; failed=1; }
  fi
  validate_repo || failed=1
  check_permissions || failed=1
  for item in "${managed_files[@]}"; do
    source_path="$repo_dir/${item%%:*}"
    target_path=${item#*:}
    if [[ -L "$target_path" && "$(readlink -- "$target_path")" == "$source_path" ]]; then
      printf 'ok      %s\n' "$target_path"
    else
      printf 'pending %s\n' "$target_path"
      failed=1
    fi
  done
  return "$failed"
}

while (($#)); do
  case "$1" in
    --apply) ;;
    --check) require_supported_system; check_installation; exit ;;
    --with-apps) apps_mode=yes ;;
    --no-apps) apps_mode=no ;;
    -h|--help) usage; exit ;;
    *) usage >&2; exit 2 ;;
  esac
  shift
done

require_supported_system
fix_permissions
install_core_packages
install_oh_my_zsh
install_starship
install_oh_my_posh
install_nerd_font
install_kde_fix_cedilla
validate_repo
check_permissions

for item in "${managed_files[@]}"; do
  link_file "$repo_dir/${item%%:*}" "${item#*:}"
done

if [[ "$backup_created" == true ]]; then
  printf '\nBackup: %s\n' "$backup_dir"
fi

if [[ "$apps_mode" == ask && -t 0 ]]; then
  read -r -p 'Deseja instalar aplicativos por grupos agora? [s/N] ' answer
  [[ "$answer" =~ ^[sSyY]$ ]] && apps_mode=yes || apps_mode=no
fi
if [[ "$apps_mode" == yes ]]; then
  "$repo_dir/install-apps.sh"
elif [[ "$apps_mode" == ask ]]; then
  echo 'Sessão não interativa: aplicativos ignorados. Use --with-apps para instalá-los.'
fi

printf '\nConfiguração aplicada. Recarregue com: exec zsh\n'
