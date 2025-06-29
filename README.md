
<!-- ````markdown -->
# 🛠️ Dotfiles – Bash, Git, and CLI Utilities

This is my personal dotfiles setup for Linux systems (primarily Linux Mint), using [GNU Stow](https://www.gnu.org/software/stow/) for easy symlink management and git for version control.

---

## 📁 Included

- `.bash_aliases` – useful command aliases for better terminal productivity
- `.gitconfig` – Git configuration with user identity, aliases, etc.
- `bin/` – custom scripts added to `~/bin` for quick access
- e.g., `generate_commit_history.sh` for quick Git summaries

---

## 🔧 How to Use (on a new machine)

1. **Install GNU Stow**
   ```bash
   sudo apt install stow
   ```

2. **Clone the repository**

   ```bash
   git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```

3. **Stow your configs**

   ```bash
   stow bash
   stow git
   stow bin
   ```

   This will:

   * Link `.bash_aliases` to `~/.bash_aliases`
   * Link `.gitconfig` to `~/.gitconfig`
   * Link all custom scripts to `~/bin`

4. **Reload your terminal config**

   ```bash
   source ~/.bashrc
   ```

---

## XDG Base Directory Structure

To keep the home directory clean, this setup now follows the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html). Configurations are stored in `~/.config/` where possible.

The new folder structure is:

```
dotfiles/
├── bash/
│   └── .bash_aliases
├── git/
│   └── .config/
│       └── git/
│           └── config
├── tmux/
│   └── .config/
│       └── tmux/
│           └── tmux.conf
└── bin/
    └── bin/
        └── generate_commit_history.sh
```

### Adding New Dotfiles

To add a new application's configuration (e.g., for `nvim`):

1.  Create the package directory: `mkdir nvim`
2.  Create the target directory structure inside it: `mkdir -p nvim/.config/nvim`
3.  Place your configuration file at the target path: `mv ~/my-nvim-config nvim/.config/nvim/init.vim`
4.  Stow the new package: `stow nvim`

### Unlinking (Removing) Packages

To remove the symlinks for a package, use the `-D` flag:

```bash
stow -D git
stow -D tmux
```

---

## ✅ Why use GNU Stow?

It makes it super easy to:

* Apply or remove individual config groups (like bash, git, etc.)
* Keep your home directory clean
* Avoid manual copying of dotfiles

---

## 🌐 License

MIT — feel free to use, fork, or modify!

---

## 🔗 Author

Maintained by [SYED SADIQ ALI](https://linkedin.com/in/sadiqonlink)
Follow on [LinkedIn](https://linkedin.com/in/sadiqonlink) or [GitHub](https://github.com/SadiqOnGithub)
