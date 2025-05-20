
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

## 📦 Folder Structure

```
dotfiles/
├── bash/
│   └── .bash_aliases
├── git/
│   └── .gitconfig
├── bin/
│   └── bin/
│       └── generate_commit_history.sh
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
