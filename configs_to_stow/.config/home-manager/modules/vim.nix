{ pkgs, config, lib, ... }:
let
  vim-maximizer = pkgs.vimUtils.buildVimPlugin {
    name = "vim-maximizer";
    src = pkgs.fetchFromGitHub {
      owner = "szw";
      repo = "vim-maximizer";
      rev = "2e54952fe91e140a2e69f35f22131219fcd9c5f1";
      sha256 = "031brldzxhcs98xpc3sr0m2yb99xq0z5yrwdlp8i5fqdgqrdqlzr";
    };
    meta.homepage = "https://github.com/szw/vim-maximizer";
  };
  previm = pkgs.vimUtils.buildVimPlugin {
    name = "previm";
    src = pkgs.fetchzip {
      url = "https://github.com/previm/previm/archive/29524dba1dfad1e77a8670b8c133af96f31582a7.tar.gz";
      hash = "sha256-11T5iz5daLPUJVElLSKg3IESxqZbpIvx9YrBgvUwY3s=";
    };
    meta.homepage = "https://github.com/previm/previm";
  };
in

{
  # ════════════════════════════════════════════════════════════════
  # NOTE TO SELF: When editing vim config, keep keybindings aligned
  # with LazyVim/Neovim conventions. Reference:
  #   https://www.lazyvim.org/keymaps
  # ════════════════════════════════════════════════════════════════

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

      # Toggle window zoom (maximize/restore)
      vim-maximizer

      # Live Markdown preview in browser
      previm

      # Node-based live Markdown preview (trial alternative)
      markdown-preview-nvim

      # High-contrast theme (colorblind-friendly)
      gruvbox
    ];

    extraConfig = ''
      " Enable filetype detection, syntax highlighting, and indentation
      filetype plugin indent on
      syntax on

      " Gruvbox theme (high-contrast variant, colorblind-friendly)
      set termguicolors
      set background=dark
      let g:gruvbox_contrast_dark = 'hard'
      let g:gruvbox_sign_column = 'bg0'

      " Force pure black background (must be set before colorscheme so it
      " fires on the initial ColorScheme event)
      autocmd ColorScheme * highlight Normal guibg=#000000 ctermbg=0

      colorscheme gruvbox

      " General settings
      set tabstop=4 shiftwidth=4 expandtab
      set number relativenumber

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

      " Disabled TS/JS formatting preferences (add to preferences dict to enable):
      "   'importModuleSpecifier': 'relative',
      "   'quoteStyle': 'single',
      "   'semicolons': 'always',

      " --- TypeScript/JavaScript ---
      if executable('typescript-language-server')
        au User lsp_setup call lsp#register_server({
              \ 'name': 'typescript-language-server',
              \ 'cmd': {server_info -> ['typescript-language-server', '--stdio']},
              \ 'whitelist': ['typescript', 'typescriptreact', 'javascript', 'javascriptreact'],
              \ 'message': 'lsp-notify',
              \ 'root_uri': {server_info -> lsp#utils#path_to_uri(
              \     lsp#utils#find_nearest_parent_file_directory(
              \         lsp#utils#get_buffer_path(),
              \         ['tsconfig.json', 'jsconfig.json', 'package.json', '.git/']
              \     )
              \ )},
              \ 'initializationOptions': {
              \   'preferences': {
              \     'includeInlayParameterNameHints': 'all',
              \     'includeInlayFunctionParameterTypeHints': v:true,
              \     'includeInlayVariableTypeHints': v:true,
              \     'includeInlayPropertyDeclarationTypeHints': v:true,
              \   }
              \ }
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

      " Live Markdown preview in browser (via previm)
      let g:previm_open_cmd = 'xdg-open'
      " Previm defaults to writing previews inside its own plugin dir,
      " which is read-only under Nix — redirect to a writable cache dir
      let g:previm_custom_preview_base_dir = $HOME . '/.cache/previm/'
      nnoremap <silent> <leader>mp :PrevimOpen<CR>
      nnoremap <silent> <leader>mr :PrevimRefresh<CR>
      " Node-based live preview (markdown-preview.nvim) — trial
      nnoremap <silent> <leader>mP :MarkdownPreviewToggle<CR>

      " Toggle window maximize/restore
      nnoremap <silent> <leader>z :MaximizerToggle<CR>
      vnoremap <silent> <leader>z :MaximizerToggle<CR>gv

      " LSP navigation (LazyVim-style)
      nnoremap gd :LspDefinition<CR>
      nnoremap gr :LspReferences<CR>
      nnoremap K :LspHover<CR>
      nnoremap ]r :LspNextReference<CR>
      nnoremap [r :LspPreviousReference<CR>

      " Quickfix toggle (LazyVim: <leader>xq)
      function! QuickfixToggle()
        if &buftype == 'quickfix'
          cclose
        else
          copen
        endif
      endfunction
      nnoremap <silent> <leader>xq :call QuickfixToggle()<CR>
      nnoremap ]q :cnext<CR>
      nnoremap [q :cprev<CR>

      " Netrw file browser settings
      let g:netrw_banner = 0
      let g:netrw_liststyle = 3
      let g:netrw_browse_split = 4
      let g:netrw_altv = 1
      let g:netrw_winsize = 25

      " Toggle file explorer sidebar (LazyVim: <leader>e)
      nnoremap <silent> <leader>e :Lexplore<CR>

      " Autocompletion
      imap <c-space> <Plug>(asyncomplete_force_refresh)
      inoremap <c-n> <Plug>(asyncomplete_skip_dup_backspace)
      let g:asyncomplete_auto_popup = 1
      let g:asyncomplete_auto_completeopt = 1
      set completeopt=menuone,preview,noinsert

      " Yank current file path to system clipboard
      "   <leader>yp  - absolute path  (/home/user/project/src/main.go)
      "   <leader>yr  - relative path  (src/main.go)
      "   <leader>yf  - filename only   (main.go)
      nnoremap <leader>yp :let @+=expand('%:p')<CR>
      nnoremap <leader>yr :let @+=expand('%')<CR>
      nnoremap <leader>yf :let @+=expand('%:t')<CR>

      " Yanks go to system clipboard
      set clipboard=unnamedplus

      " Folding: use the language's syntax structure; open fully folded
      set foldmethod=syntax
      set foldnestmax=10
      set foldlevelstart=0
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
    nodejs                     # Runtime for markdown-preview-nvim server
  ];
}
