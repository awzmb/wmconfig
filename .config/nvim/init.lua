-- =============================================================================
-- BOOTSTRAP LAZY.NVIM PLUGIN MANAGER
-- =============================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- =============================================================================
-- GENERAL SETTINGS
-- =============================================================================

-- Set mapleader before plugins are loaded
vim.g.mapleader = ","
vim.g.maplocalleader = "\\"

-- General options
vim.opt.encoding = "UTF-8"
vim.opt.mouse = "" -- Disable mouse
vim.opt.hidden = true -- Allow buffer switching without saving
vim.opt.backup = false -- No backup files
vim.opt.writebackup = false -- No backup files
vim.opt.swapfile = false -- No swap files
vim.opt.undofile = true -- Enable persistent undo
vim.opt.undodir = vim.fn.stdpath("data") .. "/undo//" -- Added trailing // for correct behavior

-- UI options
vim.opt.number = true -- Show line numbers
vim.opt.showmatch = true -- Highlight matching brackets
vim.opt.laststatus = 2 -- Always show the status bar
vim.opt.cmdheight = 1 -- Reduce command line height
vim.opt.updatetime = 300 -- Faster update time for plugins
vim.opt.shortmess:append("c") -- Don't pass messages to |ins-completion-menu|
vim.opt.colorcolumn = "80" -- Highlight column 80
vim.opt.cursorline = true -- Highlight the current line
vim.opt.termguicolors = true -- Enable true color support
vim.opt.signcolumn = "yes" -- Always show the sign column

-- Tabs and indentation
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoindent = true

-- Completion options
vim.opt.completeopt = { "menuone", "noselect", "noinsert" }

-- Clipboard
vim.opt.clipboard = "unnamedplus"

-- =============================================================================
-- KEYBINDINGS
-- =============================================================================
local keymap = vim.keymap.set
local opts = { silent = true } -- Use silent by default

-- Telescope (modern fuzzy finder, recommended over FZF for Neovim)
keymap("n", "<C-f>", "<cmd>Telescope find_files<cr>", opts)
keymap("n", "<C-g>", "<cmd>Telescope buffers<cr>", opts)
keymap("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", opts) -- Example for live grep

-- Neo-tree (NERDTree replacement)
keymap("n", "<C-n>", "<cmd>Neotree toggle<cr>", opts)

-- LSP (replaces CoC bindings)
keymap("n", "gd", vim.lsp.buf.definition, { desc = "Go to Definition" })
keymap("n", "gr", "<cmd>Telescope lsp_references<cr>", { desc = "Find References" })
keymap("n", "gi", vim.lsp.buf.implementation, { desc = "Go to Implementation" })
keymap("n", "K", vim.lsp.buf.hover, { desc = "Show Hover Documentation" })
keymap("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename Symbol" })
keymap("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous Diagnostic" })
keymap("n", "]d", vim.diagnostic.goto_next, { desc = "Next Diagnostic" })
keymap({"n", "v"}, "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action" })

--  Copilot
-- This maps Alt+Enter (Meta-CarriageReturn)
keymap("i", "<M-CR>", "copilot#Accept('<CR>')", { expr = true, silent = true, script = true, nowait = true })

-- Formatting
keymap({ "n", "v" }, "<leader>f", function()
    vim.lsp.buf.format({ async = true })
end, { desc = "Format Code" })

-- =============================================================================
-- PLUGINS
-- =============================================================================
require("lazy").setup({
  -- ===================================
  -- UI & Colorscheme
  -- ===================================
  {
    "arcticicestudio/nord-vim",
    priority = 1000, -- Make sure it loads first
    config = function()
      vim.cmd.colorscheme("nord")
    end,
  },
  {
    "nvim-lualine/lualine.nvim", -- Statusline replacement for vim-airline
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "nord",
        },
      })
    end,
  },

  -- ===================================
  -- LSP, Completion, and Linting (Replaces CoC and ALE)
  -- ===================================
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/nvim-cmp",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      -- List of servers to install
      local servers = {
        "pyright",
        "gopls",
        "rust_analyzer",
        "terraform-ls",
        "tflint",
        "yamlls",
        "dockerls",
        "jsonls",
        "bashls",
      }
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = servers,
        handlers = {
          function(server_name)
            require("lspconfig")[server_name].setup({
              capabilities = capabilities,
            })
          end,
        }
      })

      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
            else fallback() end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then luasnip.jump(-1)
            else fallback() end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end
  },
  {
    "stevearc/conform.nvim", -- Formatting plugin (replaces coc-prettier)
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "isort", "black" },
        javascript = { { "prettierd", "prettier" } },
        json = { "prettier" },
      },
      format_on_save = { timeout_ms = 500, lsp_fallback = true },
    },
  },

  -- ===================================
  -- File Explorer & Finder
  -- ===================================
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      vim.fn.sign_define('DiagnosticSignError',
        { text = '', texthl = 'DiagnosticSignError' })
      vim.fn.sign_define('DiagnosticSignWarn',
        { text = '', texthl = 'DiagnosticSignWarn' })
      vim.fn.sign_define('DiagnosticSignInfo',
        { text = '', texthl = 'DiagnosticSignInfo' })
      vim.fn.sign_define('DiagnosticSignHint',
        { text = '', texthl = 'DiagnosticSignHint' })

      require("neo-tree").setup({
        close_if_last_window = true,
        filesystem = {
          filtered_items = {
            visible = true,
            hide_dotfiles = false,
            hide_gitignored = true,
          },
        },
        git_status = {
          symbols = {
              added     = "",
              modified  = "",
              deleted   = "",
              renamed   = "",
              untracked = "",
              ignored   = "",
              unstaged  = "",
              staged    = "",
              conflict  = "",
          }
        }
      })
    end,
  },
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.6",
    dependencies = { "nvim-lua/plenary.nvim" }
  },
  { 'junegunn/fzf.vim' },

  -- ===================================
  -- Git Integration
  -- ===================================
  { "tpope/vim-fugitive" },
  { "lewis6991/gitsigns.nvim", config = function() require("gitsigns").setup() end },

  -- ===================================
  -- Utility & Language Support
  -- ===================================
  { "numToStr/Comment.nvim", opts = {} },
  { "github/copilot.vim" },
  { "hashivim/vim-terraform", ft = "terraform" },
  { "towolf/vim-helm", ft = "helm" },
  { "pearofducks/ansible-vim", ft = "ansible" },
  { "mracos/mermaid.vim", ft = "mermaid" },
  { "infoslack/vim-docker", ft = "dockerfile" },

  -- ===================================
  --  Other 
  -- ===================================
  { "jasonccox/vim-wayland-clipboard" },
  { 'norcalli/nvim-colorizer.lua', config = function() require'colorizer'.setup() end },
})

-- =============================================================================
-- AUTOCOMMANDS
-- =============================================================================

-- Highlight on yank
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function() vim.highlight.on_yank() end,
  group = highlight_group,
  pattern = '*',
})

-- Open Neo-tree if no file was specified on startup
local function open_neotree_on_startup()
    local stats = vim.uv.fs_stat(vim.fn.argv(0) or "")
    if stats and stats.type == "directory" then
        vim.cmd.cd(vim.fn.argv(0))
        require("neo-tree.command").execute({ toggle = true, dir = vim.fn.getcwd() })
    end
end
vim.api.nvim_create_autocmd({ "VimEnter" }, {
    pattern = "*",
    once = true,
    callback = function()
        if vim.fn.argc() > 0 then
            vim.schedule(open_neotree_on_startup)
        end
    end,
})

-- =============================================================================
-- COPILOT CONFIG
-- =============================================================================
vim.g.copilot_no_tab_map = true
vim.g.copilot_assume_mapped = true
