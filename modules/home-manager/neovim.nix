{ config, pkgs, inputs, lib, ... }:

{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    
    # Install plugins
    plugins = with pkgs.vimPlugins; [
      # Appearance
      nvim-web-devicons
      tokyonight-nvim
      lualine-nvim
      
      # Editor enhancements
      vim-surround
      vim-commentary
      vim-repeat
      which-key-nvim
      
      # File navigation
      nvim-tree-lua
      telescope-nvim
      
      # Git integration
      vim-fugitive
      vim-gitgutter
      
      # LSP and completion
      nvim-lspconfig
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      cmp-cmdline
      cmp-vsnip
      vim-vsnip
      
      # Syntax highlighting
      (nvim-treesitter.withPlugins (plugins: with plugins; [
        tree-sitter-nix
        tree-sitter-lua
        tree-sitter-vim
        tree-sitter-bash
        tree-sitter-python
        tree-sitter-javascript
        tree-sitter-typescript
        tree-sitter-json
        tree-sitter-markdown
      ]))
    ];
    
    # Extra package dependencies
    extraPackages = with pkgs; [
      # Language servers
      nil # Nix
      pyright # Python
      nodePackages.typescript-language-server
      nodePackages.bash-language-server
      lua-language-server
      
      # Telescope dependencies
      ripgrep
      fd
      
      # Formatters and linters
      alejandra # Nix formatter
      black # Python formatter
      nodePackages.prettier # JS/TS formatter
    ];
    
    # Nvim configuration using Lua
    extraLuaConfig = ''
      -- General settings
      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.wrap = false
      vim.opt.expandtab = true
      vim.opt.tabstop = 2
      vim.opt.shiftwidth = 2
      vim.opt.softtabstop = 2
      vim.opt.ignorecase = true
      vim.opt.smartcase = true
      vim.opt.incsearch = true
      vim.opt.termguicolors = true
      vim.opt.mouse = 'a'
      vim.opt.clipboard = 'unnamedplus'
      vim.opt.breakindent = true
      vim.opt.undofile = true
      vim.opt.hlsearch = true
      vim.opt.backup = false
      vim.opt.showmode = false
      vim.opt.updatetime = 250
      vim.opt.timeoutlen = 300
      vim.opt.splitright = true
      vim.opt.splitbelow = true
      vim.opt.list = true
      vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
      vim.opt.inccommand = 'split'
      vim.opt.cursorline = true
      vim.opt.scrolloff = 10
      vim.opt.sidescrolloff = 10
      
      -- Set leader key to space
      vim.g.mapleader = ' '
      vim.g.maplocalleader = ' '
      
      -- Theme setup
      vim.cmd[[colorscheme tokyonight-night]]
      
      -- Lualine setup
      require('lualine').setup {
        options = {
          icons_enabled = true,
          theme = 'tokyonight',
          component_separators = { left = ""; right = ""; },
          section_separators = { left = ""; right = ""; }
        }
      }
      
      -- Nvim-tree setup
      require('nvim-tree').setup {
        view = {
          width = 30,
        },
        filters = {
          dotfiles = false,
        },
      }
      
      -- Telescope setup
      require('telescope').setup {
        defaults = {
          mappings = {
            i = {
              ['<C-u>'] = false,
              ['<C-d>'] = false,
            },
          },
        },
      }
      
      -- Treesitter setup
      require('nvim-treesitter.configs').setup {
        highlight = {
          enable = true,
        },
        indent = {
          enable = true,
        },
      }
      
      -- Which-key setup
      require('which-key').setup {}
      
      -- LSP setup
      local lspconfig = require('lspconfig')
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      
      -- Nix
      lspconfig.nil_ls.setup {
        capabilities = capabilities,
      }
      
      -- Python
      lspconfig.pyright.setup {
        capabilities = capabilities,
      }
      
      -- TypeScript/JavaScript
      lspconfig.tsserver.setup {
        capabilities = capabilities,
      }
      
      -- Bash
      lspconfig.bashls.setup {
        capabilities = capabilities,
      }
      
      -- Lua
      lspconfig.lua_ls.setup {
        capabilities = capabilities,
        settings = {
          Lua = {
            diagnostics = {
              globals = {'vim'},
            },
          },
        },
      }
      
      -- Global LSP mappings
      vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
      vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
      vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
      vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist)
      
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('UserLspConfig', {}),
        callback = function(ev)
          -- Buffer local mappings
          local opts = { buffer = ev.buf }
          vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
          vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
          vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
          vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, opts)
          vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, opts)
          vim.keymap.set('n', '<leader>wl', function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
          end, opts)
          vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, opts)
          vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
          vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, opts)
          vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
          vim.keymap.set('n', '<leader>f', function()
            vim.lsp.buf.format { async = true }
          end, opts)
        end,
      })
      
      -- nvim-cmp setup
      local cmp = require 'cmp'
      
      cmp.setup {
        snippet = {
          expand = function(args)
            vim.fn["vsnip#anonymous"](args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'vsnip' },
        }, {
          { name = 'buffer' },
          { name = 'path' },
        })
      }
      
      -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline({ '/', '?' }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = 'buffer' }
        }
      })
      
      -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = 'path' }
        }, {
          { name = 'cmdline' }
        })
      })
      
      -- Keymaps
      local keymap = vim.keymap.set
      
      -- Normal mode
      keymap('n', '<leader>w', '<cmd>write<cr>', { desc = 'Save' })
      keymap('n', '<leader>q', '<cmd>quit<cr>', { desc = 'Quit' })
      keymap('n', '<leader>h', '<cmd>nohlsearch<cr>', { desc = 'Clear highlights' })
      
      -- Better window navigation
      keymap('n', '<C-h>', '<C-w>h', { desc = 'Navigate to left window' })
      keymap('n', '<C-j>', '<C-w>j', { desc = 'Navigate to bottom window' })
      keymap('n', '<C-k>', '<C-w>k', { desc = 'Navigate to top window' })
      keymap('n', '<C-l>', '<C-w>l', { desc = 'Navigate to right window' })
      
      -- Resize windows
      keymap('n', '<C-Up>', '<cmd>resize +2<cr>', { desc = 'Increase window height' })
      keymap('n', '<C-Down>', '<cmd>resize -2<cr>', { desc = 'Decrease window height' })
      keymap('n', '<C-Left>', '<cmd>vertical resize -2<cr>', { desc = 'Decrease window width' })
      keymap('n', '<C-Right>', '<cmd>vertical resize +2<cr>', { desc = 'Increase window width' })
      
      -- File explorer
      keymap('n', '<leader>e', '<cmd>NvimTreeToggle<cr>', { desc = 'Toggle file explorer' })
      
      -- Telescope
      keymap('n', '<leader>ff', '<cmd>Telescope find_files<cr>', { desc = 'Find files' })
      keymap('n', '<leader>fg', '<cmd>Telescope live_grep<cr>', { desc = 'Find text' })
      keymap('n', '<leader>fb', '<cmd>Telescope buffers<cr>', { desc = 'Find buffers' })
      keymap('n', '<leader>fh', '<cmd>Telescope help_tags<cr>', { desc = 'Find help' })
      keymap('n', '<leader>fo', '<cmd>Telescope oldfiles<cr>', { desc = 'Find recent files' })
      keymap('n', '<leader>f/', '<cmd>Telescope current_buffer_fuzzy_find<cr>', { desc = 'Find in current buffer' })
      
      -- Move lines up and down
      keymap('n', '<A-j>', '<cmd>m .+1<cr>==', { desc = 'Move line down' })
      keymap('n', '<A-k>', '<cmd>m .-2<cr>==', { desc = 'Move line up' })
      keymap('i', '<A-j>', '<esc><cmd>m .+1<cr>==gi', { desc = 'Move line down' })
      keymap('i', '<A-k>', '<esc><cmd>m .-2<cr>==gi', { desc = 'Move line up' })
      keymap('v', '<A-j>', ":m '>+1<cr>gv=gv", { desc = 'Move lines down' })
      keymap('v', '<A-k>', ":m '<-2<cr>gv=gv", { desc = 'Move lines up' })
      
      -- Stay in indent mode
      keymap('v', '<', '<gv', { desc = 'Decrease indent' })
      keymap('v', '>', '>gv', { desc = 'Increase indent' })
    '';
  };
}
