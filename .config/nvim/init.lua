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
keymap({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action" })

-- Copilot (using copilot.lua API)
-- Using Alt+l as the robust hotkey we found
keymap("i", "<M-l>", function()
  require("copilot.suggestion").accept_line()
end, { silent = true, desc = "Copilot: Accept suggestion and add new line" })

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
    "awzmb/nord-darker-nvim",
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
  -- Devcontainers
  -- ===================================
  {
    "amitds1997/remote-nvim.nvim",
    -- All your previous configuration now goes inside the 'opts' table
    opts = {
      -- configuration for devpod connections
      devpod = {
        binary = "devpod",
        docker_binary = "podman",
        ---@diagnostic disable-next-line:param-type-mismatch
        ssh_config_path = vim.fn.stdpath("data") .. "/remote-nvim/ssh_config", -- Corrected path using plugin name
        search_style = "current_dir_only",                                     -- How should devcontainers be searched
        -- for dotfiles, see https://devpod.sh/docs/developing-in-workspaces/dotfiles-in-a-workspace for more information
        dotfiles = {
          -- path to your dotfiles which should be copied into devcontainers
          path = "${HOME}/.cfg",
          -- install script that should be called to install your dotfiles
          install_script = "install",
        },
        gpg_agent_forwarding = false,    -- Should GPG agent be forwarded over the network
        container_list = "running_only", -- How should docker list containers ("running_only" or "all")
      },

      -- modify the ui for the plugin's progress viewer.
      progress_view = {
        type = "popup",
      },

      -- offline mode configuration. for more details, see the "offline mode" section below.
      offline_mode = {
        enabled = false,
        no_github = false,
        -- what path should be looked at to find locally available releases
        cache_dir = vim.fn.stdpath("cache") .. "/remote-nvim/version_cache", -- Corrected path
      },

      -- remote configuration
      remote = {
        app_name = "nvim",
        -- list of directories that should be copied over
        copy_dirs = {
          -- what to copy to remote's neovim config directory
          config = {
            -- path from where data has to be copied
            base = vim.fn.stdpath("config"),
            -- directories that should be copied over. "*" means all directories. to specify a subset,
            -- use a list like {"lazy", "mason"} where "lazy", "mason" are subdirectories
            dirs = "*",
            -- under path specified in `base`.
            compression = {
              -- should compression be enabled or not
              enabled = true,
              -- any additional options that should be used for compression. any argument that
              -- is passed to `tar` (for compression) can be passed here as separate elements.
              additional_opts = {}
            },
          },
          -- what to copy to remote's neovim data directory
          data = {
            base = vim.fn.stdpath("data"),
            dirs = {},
            compression = {
              enabled = true,
            },
          },
          -- what to copy to remote's neovim cache directory
          cache = {
            base = vim.fn.stdpath("cache"),
            dirs = {},
            compression = {
              enabled = true,
            },
          },
          -- what to copy to remote's neovim state directory
          state = {
            base = vim.fn.stdpath("state"),
            dirs = {},
            compression = {
              enabled = true,
            },
          },
        },
      },

      -- you can supply your own callback that should be called to create the local client.
      -- this is the default implementation.
      -- two arguments are passed to the callback:
      -- port: local port at which the remote server is available
      -- workspace_config: workspace configuration for the host. for all the properties available,
      -- see https://github.com/amitds1997/remote-nvim.nvim/blob/main/lua/remote-nvim/providers/provider.lua#l4
      -- a sample implementation using wezterm tab is at: https://github.com/amitds1997/remote-nvim.nvim/wiki/configuration-recipes
      client_callback = function(port, _)
        require("remote-nvim.ui").float_term(("nvim --server localhost:%s --remote-ui"):format(port), function(exit_code)
          if exit_code ~= 0 then
            vim.notify(("Local client failed with exit code %s"):format(exit_code), vim.log.levels.ERROR)
          end
        end)
      end,
    }
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
          { name = "copilot" },
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
        lua = { "stylua", "luaformatter" },
        python = { "isort", "black" },
        javascript = { { "prettierd", "prettier" } },
        json = { "prettier" },
      },
      format_on_save = { timeout_ms = 500, lsp_fallback = true },
    },
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
    tag = "0.1.6",
    dependencies = { "nvim-lua/plenary.nvim" }
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
  -- ADDED correct setup for Comment.nvim
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
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        suggestion = { auto_trigger = true },
        panel = { enabled = true },
      })
    end,
  },
  {
    "zbirenbaum/copilot-cmp",
    dependencies = { "zbirenbaum/copilot.lua" },
    config = function()
      require("copilot_cmp").setup()
    end
  },
  --{ "github/copilot.vim" },
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
