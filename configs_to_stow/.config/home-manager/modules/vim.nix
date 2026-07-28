{ pkgs, ... }:

{
  # Vim with LSP support for multiple languages
  # ===================================================
  # LSP servers included:
  #   - nil:              Nix
  #   - pyright:          Python
  #   - gopls:            Go
  #   - rust-analyzer:    Rust
  #   - typescript-language-server: TypeScript/JavaScript
  #   - bash-language-server: Bash/Shell
  #   - clangd:           C/C++
  #   - lua-language-server: Lua

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

    extraConfig = ''
      " Enable filetype detection, syntax highlighting, and indentation
      filetype plugin indent on
      syntax on

      " General settings
      set tabstop=4 shiftwidth=4 expandtab

      " Filetype-specific indentation
      au BufRead,BufNewFile *.nix setlocal shiftwidth=2 tabstop=2 expandtab
      au BufRead,BufNewFile *.go setlocal noexpandtab tabstop=4 shiftwidth=4
      au BufRead,BufNewFile *.rs setlocal shiftwidth=4 tabstop=4 expandtab
      au BufRead,BufNewFile *.lua setlocal shiftwidth=2 tabstop=2 expandtab
      au BufRead,BufNewFile *.ts,*.tsx,*.js,*.jsx setlocal shiftwidth=2 tabstop=2 expandtab
      au BufRead,BufNewFile *.sh,*.bash setlocal shiftwidth=2 tabstop=2 expandtab
      au BufRead,BufNewFile *.c,*.cpp,*.h setlocal shiftwidth=4 tabstop=4 expandtab

      " LSP configuration helper
      function! RegisterLSP(name, cmd, whitelist)
        if executable(a:cmd[0])
          au User lsp_setup call lsp#register_server({
                \ 'name': a:name,
                \ 'cmd': {server_info -> a:cmd},
                \ 'whitelist': a:whitelist,
                \ 'message': 'lsp-notify',
                \ })
        endif
      endfunction

      " --- Nix ---
      if executable('nil')
        au User lsp_setup call lsp#register_server({
              \ 'name': 'nil',
              \ 'cmd': {server_info -> ['nil', '--stdio']},
              \ 'whitelist': ['nix'],
              \ 'message': 'lsp-notify',
              \ })
        autocmd BufWritePre *.nix LspDocumentFormatSync
      endif

      " --- Python ---
      if executable('pyright')
        au User lsp_setup call lsp#register_server({
              \ 'name': 'pyright',
              \ 'cmd': {server_info -> ['pyright-langserver', '--stdio']},
              \ 'whitelist': ['python'],
              \ 'message': 'lsp-notify',
              \ })
      endif

      " --- Go ---
      if executable('gopls')
        au User lsp_setup call lsp#register_server({
              \ 'name': 'gopls',
              \ 'cmd': {server_info -> ['gopls']},
              \ 'whitelist': ['go'],
              \ 'message': 'lsp-notify',
              \ })
        autocmd BufWritePre *.go LspDocumentFormatSync
      endif

      " --- Rust ---
      if executable('rust-analyzer')
        au User lsp_setup call lsp#register_server({
              \ 'name': 'rust-analyzer',
              \ 'cmd': {server_info -> ['rust-analyzer']},
              \ 'whitelist': ['rust'],
              \ 'message': 'lsp-notify',
              \ })
      endif

      " --- TypeScript/JavaScript ---
      if executable('typescript-language-server')
        au User lsp_setup call lsp#register_server({
              \ 'name': 'typescript-language-server',
              \ 'cmd': {server_info -> ['typescript-language-server', '--stdio']},
              \ 'whitelist': ['typescript', 'typescriptreact', 'javascript', 'javascriptreact'],
              \ 'message': 'lsp-notify',
              \ })
      endif

      " --- Bash/Shell ---
      if executable('bash-language-server')
        au User lsp_setup call lsp#register_server({
              \ 'name': 'bash-language-server',
              \ 'cmd': {server_info -> ['bash-language-server', 'start']},
              \ 'whitelist': ['sh', 'bash'],
              \ 'message': 'lsp-notify',
              \ })
      endif

      " --- C/C++ ---
      if executable('clangd')
        au User lsp_setup call lsp#register_server({
              \ 'name': 'clangd',
              \ 'cmd': {server_info -> ['clangd', '--background-index']},
              \ 'whitelist': ['c', 'cpp', 'objc', 'objcpp'],
              \ 'message': 'lsp-notify',
              \ })
      endif

      " --- Lua ---
      if executable('lua-language-server')
        au User lsp_setup call lsp#register_server({
              \ 'name': 'lua-language-server',
              \ 'cmd': {server_info -> ['lua-language-server']},
              \ 'whitelist': ['lua'],
              \ 'message': 'lsp-notify',
              \ })
      endif

      " Netrw file browser settings
      let g:netrw_banner = 0
      let g:netrw_liststyle = 3
      let g:netrw_browse_split = 4
      let g:netrw_altv = 1
      let g:netrw_winsize = 25

      " Autocompletion
      imap <c-space> <Plug>(asyncomplete_force_refresh)
      inoremap <c-n> <Plug>(asyncomplete_skip_dup_backspace)
      let g:asyncomplete_auto_popup = 1
      let g:asyncomplete_auto_completeopt = 1
      set completeopt=menuone,preview,noinsert

      " Yanks go to system clipboard
      set clipboard=unnamedplus
    '';
  };

  home.packages = with pkgs; [
    xclip                      # Clipboard support for Vim
    nil                        # Nix
    pyright                    # Python
    gopls                      # Go
    rust-analyzer              # Rust
    typescript-language-server # TypeScript/JavaScript
    bash-language-server       # Bash/Shell
    clang-tools                # C/C++ (provides clangd)
    lua-language-server        # Lua
  ];
}
