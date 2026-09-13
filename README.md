# home

Dotfiles for Ubuntu 26.04, KDE Plasma/Wayland and zsh.

## Managed configuration

- zsh and Oh My Zsh, with guarded integrations for pyenv, NVM, Nix, Homebrew, pnpm and Angular
- Starship with the Tokyo Night preset as the default prompt
- Oh My Posh as an optional alternative
- portable aliases and helper scripts under `~/.local/bin`
- Git defaults without disabling TLS verification

Machine-specific settings and secrets belong in `~/.config/home-shell.local.zsh`, outside this repository.

## Apply or check

```bash
cd ~/dev/home
./install.sh
exec zsh
```

The installer validates shell and prompt configuration, corrects repository file permissions, creates links and moves replaced files into a timestamped directory under `~/.local/state/home-dotfiles/backups/`.

Running it again is safe. To inspect the current state without changing anything:

```bash
./install.sh --check
```

On a clean Kubuntu installation, `install.sh` also installs the core shell tools, Oh My Zsh, Starship, Oh My Posh, JetBrainsMono Nerd Font, Flatpak support and the dependencies used by the managed helper scripts. At the end it asks whether to launch the application installer. The question can be controlled explicitly with `--with-apps` or `--no-apps`.

## Applications by group

Run the interactive selector:

```bash
./install-apps.sh
```

Or select groups explicitly:

```bash
./install-apps.sh --group social,dev,browsers
./install-apps.sh --all
```

Available groups are `social`, `ia`, `dev`, `browsers`, `proton`, `utils` and `games`. Applications use APT, official Snap packages, Flathub IDs or vendor manifests. ChatGPT and Proton Drive are official Chromium web apps because no native Linux package is published for them. Proton Authenticator packages are downloaded from Proton's current manifest and verified with its SHA-512 checksum before installation.

## Choose a prompt

Starship is the default. To select Oh My Posh locally:

```zsh
echo 'export PROMPT_ENGINE=oh-my-posh' >> ~/.config/home-shell.local.zsh
exec zsh
```

Use a Nerd Font, such as JetBrainsMono Nerd Font, in the terminal profile.

