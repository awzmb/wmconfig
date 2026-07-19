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

-- Ensure Mason binaries are in PATH
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH

-- General options
vim.opt.encoding = "UTF-8"
vim.opt.mouse = ""                                    -- Disable mouse
vim.opt.hidden = true                                 -- Allow buffer switching without saving
vim.opt.backup = false                                -- No backup files
vim.opt.writebackup = false                           -- No backup files
vim.opt.swapfile = false                              -- No swap files
vim.opt.undofile = true                               -- Enable persistent undo
vim.opt.undodir = vim.fn.stdpath("data") .. "/undo//" -- Added trailing // for correct behavior

-- UI options
vim.opt.number = true         -- Show line numbers
vim.opt.showmatch = true      -- Highlight matching brackets
vim.opt.laststatus = 2        -- Always show the status bar
vim.opt.cmdheight = 1         -- Reduce command line height
vim.opt.updatetime = 300      -- Faster update time for plugins
vim.opt.shortmess:append("c") -- Don't pass messages to |ins-completion-menu|
vim.opt.colorcolumn = "80"    -- Highlight column 80
vim.opt.cursorline = true     -- Highlight the current line
vim.opt.termguicolors = true  -- Enable true color support
vim.opt.signcolumn = "yes"    -- Always show the sign column

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
-- MASON PACKAGE LISTS
-- =============================================================================

-- List of language servers with the CORRECT lspconfig names
local servers = {
  "pyright",
  "gopls",
  "rust_analyzer",
  "terraformls",
  "lua_ls",
  "yamlls",
  "dockerls",
  "jsonls",
  "bashls",
  "helm_ls",
}

-- List of other tools (linters, formatters, etc.)
local linters = {
  "tflint",
  "tfsec",
  "luacheck",
  "luaformatter",
  "kube-linter",
  "hclfmt",
}

-- This logic correctly maps the lspconfig name (e.g., "lua_ls")
-- to the mason package name (e.g., "lua-language-server") for installation.
local mason_pkg_map = {
  ["lua_ls"] = "lua-language-server",
  ["terraformls"] = "terraform-ls",
  ["helm_ls"] = "helm-ls",
  ["rust_analyzer"] = "rust-analyzer",
}

-- Create the final list of packages for Mason to install.
-- We create a new table to avoid modifying the original `servers` and `linters` tables.
local ensure_installed = {}
for _, pkg in ipairs(servers) do table.insert(ensure_installed, pkg) end
for _, pkg in ipairs(linters) do table.insert(ensure_installed, pkg) end

-- Apply the package name mapping.
for i, pkg in ipairs(ensure_installed) do
  if mason_pkg_map[pkg] then
    ensure_installed[i] = mason_pkg_map[pkg]
  end
end

-- =============================================================================
-- KEYBINDINGS
-- =============================================================================
local keymap = vim.keymap.set
local opts = { silent = true } -- Use silent by default

-- Telescope (modern fuzzy finder, recommended over FZF for Neovim)
keymap("n", "<C-f>", "<cmd>Telescope find_files<cr>", opts)
-- keymap("n", "<C-g>", "<cmd>Telescope buffers<cr>", opts)
keymap("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", opts) -- Example for live grep

-- Neo-tree (NERDTree replacement)
keymap("n", "<C-n>", "<cmd>Neotree toggle<cr>", opts)

-- remote-nvim: open the remote/devcontainer picker (visual <C-p> is AI-improve)
keymap("n", "<C-p>", "<cmd>RemoteStart<cr>", { silent = true, desc = "Remote: connect / devcontainer menu" })

-- LSP (replaces CoC bindings)
keymap("n", "gd", vim.lsp.buf.definition, { desc = "Go to Definition" })
keymap("n", "gr", "<cmd>Telescope lsp_references<cr>", { desc = "Find References" })
keymap("n", "gi", vim.lsp.buf.implementation, { desc = "Go to Implementation" })
keymap("n", "K", vim.lsp.buf.hover, { desc = "Show Hover Documentation" })
keymap("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename Symbol" })
keymap("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous Diagnostic" })
keymap("n", "]d", vim.diagnostic.goto_next, { desc = "Next Diagnostic" })
keymap({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action" })

-- AI assistant (CodeCompanion) keymaps live in the plugin spec below.

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
  -- {
  --   "awzmb/nord-darker-nvim",
  --   priority = 1000, -- Make sure it loads first
  --   config = function()
  --     vim.cmd.colorscheme("nord")
  --   end,
  -- },
  {
    'shaunsingh/nord.nvim',
    config = function()
      vim.g.nord_contrast = false
      vim.g.nord_borders = false
      vim.g.nord_disable_background = true
      vim.g.nord_italic = false
      vim.g.nord_uniform_diff_background = false
      vim.g.nord_bold = false
      require('nord.colors').nord0_gui = '#242933'
      require('nord').set()
      local colors = require('nord.colors')
      require('nord.util').highlight('LspInlayHint',
        { fg = colors.nord3_gui_bright, style = 'bold' }
      )
      require('nord.util').highlight('WinSeparator', { fg = colors.nord2_gui })
    end
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
  -- Devcontainers
  -- ===================================
  {
    "amitds1997/remote-nvim.nvim",
    version = "*", -- pin to releases (plugin ships breaking changes on main)
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-telescope/telescope.nvim",
    },
    cmd = { "RemoteStart", "RemoteStop", "RemoteInfo", "RemoteCleanup", "RemoteLog" },
    -- Only non-default values are set; everything else uses the plugin defaults.
    opts = {
      devpod = {
        docker_binary = "podman", -- default is "docker"
        dotfiles = {
          path = "${HOME}/.cfg",
          install_script = "install",
        },
      },
      remote = {
        -- compress the config upload (default false); faster sync over the wire
        copy_dirs = { config = { compression = { enabled = true } } },
      },
    },
  },

  -- ===================================
  -- LSP, Completion, and Linting
  -- ===================================
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
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

      require("mason").setup({
        -- `ensure_installed` is the list of mapped package names for Mason.
        ensure_installed = ensure_installed
      })

      -- Configure mason-lspconfig to ONLY set up the Language Servers
      require("mason-lspconfig").setup({
        -- This MUST be the `servers` list with the original lspconfig names.
        ensure_installed = servers,
        handlers = {
          function(server_name)
            require("lspconfig")[server_name].setup({
              capabilities = capabilities,
            })
          end,
        }
      })

      -- CMP setup
      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
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
      formatters = {
        hclfmt = { command = "hclfmt", stdin = true },
      },
      formatters_by_ft = {
        lua = { "stylua", "luaformatter" },
        python = { "isort", "black" },
        javascript = { { "prettierd", "prettier" } },
        json = { "prettier" },
        hcl = { "hclfmt" },
      },
      format_on_save = { timeout_ms = 500, lsp_fallback = true },
    },
  },
  {
    "spacedentist/resolve.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
  },
  -- Linting tflint, tfsec, etc.
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufWritePost", "InsertLeave" },
    config = function()
      require("lint").linters_by_ft = {
        terraform = { "tflint", "tfsec" },
        lua = { "luacheck" },
        kubernetes = { "kube-linter" },
      }
      -- Set up linting to run automatically
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("nvim-lint-auto", { clear = true }),
        callback = function()
          require("lint").try_lint()
        end,
      })
    end,
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
    lazy = false,
    config = function()
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
    version = "*",
    dependencies = { "nvim-lua/plenary.nvim" }
  },
  {
    "folke/trouble.nvim",
    opts = {}, -- for default options, refer to the configuration section for custom setup.
    cmd = "Trouble",
    keys = {
      {
        "<C-T>",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<C-B>",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        "<C-S>",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "Symbols (Trouble)",
      },
      {
        "<C-L>",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        desc = "LSP Definitions / references / ... (Trouble)",
      },
      {
        "<C-O>",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "Location List (Trouble)",
      },
      {
        "<C-Q>",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Quickfix List (Trouble)",
      },
    },
  },
  { 'junegunn/fzf' },
  { 'junegunn/fzf.vim' },

  -- ===================================
  -- Git Integration
  -- ===================================
  { "tpope/vim-fugitive" },
  { "lewis6991/gitsigns.nvim", config = function() require("gitsigns").setup() end },
  {
    "f-person/git-blame.nvim",
    opts = {
      enabled = true,
      message_template = " <summary> • <date> • <author> • <<sha>>",
      date_format = "%m-%d-%Y %H:%M:%S",
      virtual_text_column = 1,
    },
  },

  -- ===================================
  -- Utility & Language Support
  -- ===================================
  -- {
  --   'akinsho/bufferline.nvim',
  --   version = "*",
  --   dependencies = 'nvim-tree/nvim-web-devicons',
  --   config = function()
  --     require("bufferline").setup {}
  --   end,
  -- },
  {
    'CRAG666/betterTerm.nvim',
    keys = {
      {
        mode = { 'n', 't' },
        '<C-;>',
        function()
          require('betterTerm').open()
        end,
        desc = 'Open BetterTerm 0',
      },
      {
        mode = { 'n', 't' },
        '<C-/>',
        function()
          require('betterTerm').open(1)
        end,
        desc = 'Open BetterTerm 1',
      },
      {
        '<leader>tt',
        function()
          require('betterTerm').select()
        end,
        desc = 'Select terminal',
      }
    },
    opts = {
      prefix = "Term",
      position = "bot",
      size = math.floor(vim.o.lines / 2),
      startInserted = true,
      show_tabs = true,
      -- new_tab_mapping = "<C-t>",
      -- jump_tab_mapping = "<C-$tab>",
      active_tab_hl = "TabLineSel",
      inactive_tab_hl = "TabLine",
      new_tab_hl = "BetterTermSymbol",
      new_tab_icon = "+",
      index_base = 0,
    }
  },
  {
    "NeogitOrg/neogit",
    lazy = true,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
      "nvim-telescope/telescope.nvim",
    },
    cmd = "Neogit",
    keys = {
      { "<C-g>", "<cmd>Neogit<cr>", desc = "Show Neogit UI" }
    }
  },
  {
    'nvim-treesitter/nvim-treesitter',
    -- main branch is the rewrite required by Neovim 0.12+; the old master
    -- branch ships markdown injection queries that crash 0.12's highlighter.
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      -- yaml + markdown parsers are required by render-markdown.nvim and by
      -- CodeCompanion to parse its markdown prompt frontmatter.
      require('nvim-treesitter').install({ 'markdown', 'markdown_inline', 'yaml' })
      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'markdown', 'yaml' },
        -- pcall: install() is async, parser may not exist on first open.
        callback = function() pcall(vim.treesitter.start) end,
      })
    end,
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {},
  },
  {
    "numToStr/Comment.nvim",
    config = function()
      -- Load the plugin
      require("Comment").setup()

      -- Create the NERDCommenter-style keymaps
      local keymap = vim.keymap.set
      local opts = { silent = true, noremap = true }

      -- Map <leader>cc to toggle the current line in Normal mode
      keymap("n", "<leader>cc", function()
        require("Comment.api").toggle.linewise.current()
      end, opts)

      -- Map <leader>cc to toggle the selected lines in Visual mode
      keymap("v", "<leader>cc", function()
        require("Comment.api").toggle.linewise(vim.fn.visualmode())
      end, opts)
    end,
  },
  {
    -- Auth-only: provides the GitHub Copilot OAuth token (run `:Copilot auth` once)
    -- that CodeCompanion's `copilot` adapter reads from ~/.config/github-copilot/.
    -- Inline suggestions and panel are disabled; CodeCompanion is the assistant.
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    config = function()
      require("copilot").setup({
        suggestion = { enabled = false },
        panel = { enabled = false },
      })
    end,
  },
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
    keys = {
      { "<C-p>",      "<cmd>CodeCompanion /improve<cr>",   mode = "v",          desc = "AI: Improve selection" },
      { "<leader>aa", "<cmd>CodeCompanionActions<cr>",     mode = { "n", "v" }, desc = "AI: Actions" },
      { "<leader>ac", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "AI: Toggle chat" },
    },
    opts = {
      strategies = {
        chat = { adapter = "copilot" },
        inline = { adapter = "copilot" },
      },
      prompt_library = {
        ["Improve"] = {
          interaction = "chat",
          description = "Improve the selected code",
          opts = { modes = { "v" }, alias = "improve", is_slash_cmd = true, auto_submit = false },
          prompts = {
            {
              role = "system",
              content = "You are an expert programmer. Improve the user's code for clarity, "
                  .. "correctness, performance and idioms, then briefly explain the key changes.",
            },
            {
              role = "user",
              content = function(context)
                local code = require("codecompanion.helpers.code").get_code(context.start_line, context.end_line)
                return "Please improve this code:\n\n```" .. context.filetype .. "\n" .. code .. "\n```"
              end,
            },
          },
        },
      },
    },
  },
  { "hashivim/vim-terraform",         ft = "terraform" },
  { "towolf/vim-helm",                ft = "helm" },
  { "pearofducks/ansible-vim",        ft = "ansible" },
  { "mracos/mermaid.vim",             ft = "mermaid" },
  { "infoslack/vim-docker",           ft = "dockerfile" },

  -- ===================================
  --  Other
  -- ===================================
  { "jasonccox/vim-wayland-clipboard" },
  { 'norcalli/nvim-colorizer.lua',    config = function() require 'colorizer'.setup() end },
})

-- =============================================================================
-- USER COMMANDS
-- =============================================================================

-- Mason Install All command (to install all LSP servers and tools in container)
vim.api.nvim_create_user_command("MasonInstallAll", function()
  vim.cmd("MasonInstall " .. table.concat(ensure_installed, " "))
end, {})

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
    if vim.fn.argc() == 0 then
      -- No arguments were given, so open the tree in the current directory
      vim.schedule(function()
        require("neo-tree.command").execute({ toggle = true, dir = vim.fn.getcwd() })
      end)
    else
      -- Arguments WERE given. Run your original check.
      vim.schedule(open_neotree_on_startup)
    end
  end,
})

-- Disable italics in Neo-tree (Corrected version that preserves colors)
local noItalicsNeoTreeGroup = vim.api.nvim_create_augroup("NoItalicsNeoTree", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  pattern = "neo-tree",
  group = noItalicsNeoTreeGroup,
  desc = "Disable italics and preserve colors in NeoTree window",
  callback = function()
    local highlights_to_disable_italics = {
      "NeoTreeDirectoryName",
      "NeoTreeDirectoryIcon",
      "NeoTreeSymbolicLinkTarget",
      "NeoTreeRootName",
      "NeoTreeGitAdded",
      "NeoTreeGitDeleted",
      "NeoTreeGitUnstaged",
      "NeoTreeGitModified",
      "NeoTreeGitConflict",
      "NeoTreeGitIgnored",
      "NeoTreeGitUntracked",
      "NeoTreeGitStaged",
      "NeoTreeTitleBar",
      "NeoTreeFileName",
    }

    for _, group in ipairs(highlights_to_disable_italics) do
      -- We must get the current highlight properties first, otherwise we lose the colors.
      -- The 'true' argument resolves all links (e.g., gets the colors from 'Directory').
      -- We use pcall in case a specific highlight group doesn't exist.
      local success, hl_info = pcall(vim.api.nvim_get_hl_by_name, group, true)

      if success and hl_info then
        -- hl_info is now a table with all existing properties like { fg = 'blue', ... }
        -- We just modify the italic key.
        hl_info.italic = false

        -- Now, we set the highlight using the *full* definition,
        -- which preserves all the original colors.
        vim.api.nvim_set_hl(0, group, hl_info)
      end
    end
  end,
})
