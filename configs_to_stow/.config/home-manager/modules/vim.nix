{ pkgs, ... }:

{
  # Vim with Nix syntax highlighting and LSP support
  # ===================================================
  # This module enables vim with:
  #   - syntax on: general syntax highlighting
  #   - vim-nix: syntax highlighting, indentation, and folding for Nix files
  #   - nil LSP server: diagnostics, completions, and formatting for Nix
  #
  # For other languages, add more vimPlugins and adjust the LSP registrations.

  programs.vim = {
    enable = true;

    plugins = with pkgs.vimPlugins; [
      # Nix syntax highlighting and indentation
      vim-nix

      # Async LSP client for Vim 8+
      vim-lsp

      # Asynchronous autocompletion integrated with LSP
      asyncomplete-vim
      asyncomplete-lsp-vim
    ];

    # Vim configuration
    extraConfig = ''
      " Enable filetype detection, syntax highlighting, and indentation
      filetype plugin indent on
      syntax on

      " Nix-specific settings
      " Shiftwidth: indentation level (2 spaces)
      " tabstop:   a tab character displayed as 2 spaces
      " expandtab: use spaces instead of tab characters
      au BufRead,BufNewFile *.nix setlocal shiftwidth=2 tabstop=2 expandtab

      " LSP configuration
      " nil is a lightweight LSP server for Nix with no dependencies on Nixpkgs
      " internals. It provides:
      "   - Diagnostics (syntax errors, warnings)
      "   - Completions
      "   - Find references / Go to definition
      "   - Automatic formatting on save (BufWritePre)
      if executable('nil')
        au User lsp_setup call lsp#register_server({
              \ 'name': 'nil',
              \ 'cmd': {server_info -> ['nil', '--stdio']},
              \ 'whitelist': ['nix'],
              \ 'message': 'lsp-notify',
              \ 'stderr': '/dev/null',
              \ })
        " Format Nix files automatically on save
        autocmd BufWritePre *.nix LspDocumentFormatSync
      endif

      " Netrw file browser settings
      let g:netrw_banner = 0          " Remove the banner
      let g:netrw_liststyle = 3       " Tree view
      let g:netrw_browse_split = 4    " Open files in previous window
      let g:netrw_altv = 1            " Open splits to the right
      let g:netrw_winsize = 25        " Width in percent

      " Autocompletion using LSP sources
      " asyncomplete integrates with vim-lsp out of the box
      imap <c-space> <Plug>(asyncomplete_force_refresh)
      inoremap <c-n> <Plug>(asyncomplete_skip_dup_backspace)
      let g:asyncomplete_auto_popup = 1
      let g:asyncomplete_auto_completeopt = 1
      set completeopt=menuone,preview,noinsert
    '';
  };

  home.packages = with pkgs; [
    nil  # Nix language server: https://github.com/oxalica/nil
  ];
}
