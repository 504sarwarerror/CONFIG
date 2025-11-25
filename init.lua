-- Python provider for plugins like UltiSnips
vim.g.python3_host_prog = '/usr/local/bin/python3'

vim.g.polyglot_disabled = { 'asm' }

-- Leader keys (set early so plugin configs can use <leader> mappings)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ============================================================================
-- PLUGIN SPECIFICATIONS
-- ============================================================================
require("lazy").setup({
  -- File Explorer (minimal)
  { 'preservim/nerdtree' },

  -- Fuzzy File Finder
  { 'junegunn/fzf', build = ':call fzf#install()' },
  { 'junegunn/fzf.vim' },
  -- Telescope (Fuzzy Finder)
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.2',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local ok, telescope = pcall(require, 'telescope')
      if not ok then
        return
      end
      telescope.setup({
        defaults = {
          mappings = {
            i = { ['<esc>'] = require('telescope.actions').close },
          },
        },
      })
      -- Keymaps for common pickers
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope: Find files' })
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope: Live grep' })
      vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope: Buffers' })
      vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope: Help' })
    end,
  },
  -- Which-key (keybinding helper)
  {
    'folke/which-key.nvim',
    config = function()
      local ok, wk = pcall(require, 'which-key')
      if not ok then
        return
      end
      wk.setup({})
      -- Register leader groups using the NEW spec format
      wk.add({
        { "<leader>d", group = "diff" },
        { "<leader>f", group = "file" },
        { "<leader>g", group = "git" },
        { "<leader>h", group = "hop" },
        { "<leader>o", group = "opencode" },
        { "<leader>p", group = "project" },
      })
    end,
  },

  -- Auto Pairs
  -- Use a modern Lua autopairs plugin instead of the legacy Vimscript one
  {
    'windwp/nvim-autopairs',
    config = function()
      local ok, npairs = pcall(require, 'nvim-autopairs')
      if not ok then return end
      npairs.setup({
        check_ts = true,
        disable_filetype = { 'TelescopePrompt', 'vim' },
      })
    end,
  },

  -- Commenting
  { 'tpope/vim-commentary' },

  -- Assembly Syntax Highlighting
  { 'ARM9/arm-syntax-vim' },

  -- Hex Editor
  { 'fidian/hexmode' },

  -- Better Syntax & Indenting
  { 'sheerun/vim-polyglot' },

  -- Modern Purple Color Schemes
  { 'catppuccin/nvim', name = 'catppuccin' },
  { 'joshdick/onedark.vim' },
  { 'folke/tokyonight.nvim' },

  -- Snippet Engine (for common assembly patterns)
  { 'SirVer/ultisnips' },
  { 'honza/vim-snippets' },

  -- Completion framework + Copilot integration
  { 'hrsh7th/nvim-cmp' },
  { 'hrsh7th/cmp-nvim-lsp' },
  { 'hrsh7th/cmp-buffer' },
  { 'hrsh7th/cmp-path' },
  { 'saadparwaiz1/cmp_luasnip' },
  { 'L3MON4D3/LuaSnip' },

  -- Copilot (Lua implementation) and helper libs
  { 'nvim-lua/plenary.nvim' },
  { 'MunifTanjim/nui.nvim' },
  { 'zbirenbaum/copilot.lua' },
  { 'github/copilot.vim' },
  { 'zbirenbaum/copilot-cmp' },

  -- Status Line
  { 'nvim-lualine/lualine.nvim' },
  -- Icons for Status Line
  { 'nvim-tree/nvim-web-devicons' },

  -- Git Signs (minimal git diff in gutter)
  { 'airblade/vim-gitgutter' },

  -- Registers Preview (see register contents easily)
  { 'junegunn/vim-peekaboo' },

  -- === VISUAL & PRODUCTIVITY PLUGINS ===
  -- Better notifications
  { 'rcarriga/nvim-notify' },

  -- Optional icons provider to satisfy which-key healthcheck
  { 'echasnovski/mini.icons', branch = 'main' },

  -- Inline image preview plugin removed per user request

  -- Modern indent guides (replaces indentLine)
  { 'lukas-reineke/indent-blankline.nvim' },

  -- Start screen with recent files
  { 'goolord/alpha-nvim' },

  -- Highlight word under cursor
  { 'RRethy/vim-illuminate' },

  -- Highlight TODO comments
  { 'folke/todo-comments.nvim' },

  -- Cursor line color based on mode
  { 'mvllow/modes.nvim' },

  -- === FAST NAVIGATION PLUGINS ===
  -- Hop - Jump to any word/line/character on screen
  { 'phaazon/hop.nvim' },

  -- Vim-sneak - 2-character search motion (alternative to Leap)
  { 'justinmk/vim-sneak' },

  -- Harpoon - Quick file navigation (mark important files)
  -- Harpoon plugin removed per user request

  -- === AI DIFF VISUALIZATION (No build required!) ===
  -- diffview.nvim - Shows git diffs and AI changes side-by-side
  { 'sindrets/diffview.nvim' },

  -- gitsigns.nvim - Modern git signs with inline diff preview
  { 'lewis6991/gitsigns.nvim' },

  -- === OPENCODE.NVIM (AI Assistant) ===
  {
    'NickvanDyke/opencode.nvim',
    dependencies = {
      'folke/snacks.nvim',
    },
  },

  -- Snacks.nvim (required for opencode)
  {
    'folke/snacks.nvim',
    opts = {
      input = {},
      picker = {},
      terminal = {},
    },
  },
  -- Assembly LSP and syntax plugins (provided repos)
  { 'bergercookie/asm-lsp' },
  {
    'folke/drop.nvim',
    -- Load on demand (no automatic show at startup)
    opts = {
      theme = "matrix",
      max = 75,
      interval = 100,
      screensaver = 1000 * 60 * 5,
        -- Do not auto-show on startup based on filetype. Load/show manually via keymaps.
        filetypes = {},
      winblend = 0,
    },
  },
})

-- Basic settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.mouse = "a"
vim.opt.expandtab = false  -- Use tabs for assembly
vim.opt.tabstop = 8        -- 8-space tabs (assembly standard)
vim.opt.shiftwidth = 8
vim.opt.smartindent = true
vim.opt.wrap = false       -- No line wrapping
vim.opt.cursorline = true  -- Highlight current line

-- Enable syntax highlighting
vim.cmd("syntax enable")

-- Enable filetype detection
vim.cmd("filetype plugin indent on")

-- NASM assembly syntax
vim.g.asmsyntax = "nasm"

-- Force .asm files to use nasm syntax
vim.cmd([[
autocmd BufRead,BufNewFile *.asm set filetype=nasm
autocmd BufRead,BufNewFile *.s set filetype=nasm
]])

-- Catppuccin (Modern Purple Theme)
local ok, catppuccin = pcall(require, "catppuccin")
if ok then
  catppuccin.setup({
    flavour = "mocha", -- mocha, macchiato, frappe, latte
    transparent_background = true,
    show_end_of_buffer = false,
    term_colors = true,
    styles = {
      comments = { "italic" },
      conditionals = { "italic" },
    },
    color_overrides = {
      mocha = {
        base = "#000000",
        mantle = "#000000",
        crust = "#000000",
      },
    },
    integrations = {
      gitgutter = true,
      nerdtree = true,
    },
  })
  vim.cmd("colorscheme catppuccin")
else
  vim.cmd("colorscheme default")
end

vim.opt.background = "dark"

-- Extra transparency for clean look
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
vim.api.nvim_set_hl(0, "NERDTreeNormal", { bg = "none" })

-- NERDTree settings (minimal)
vim.g.NERDTreeShowHidden = 1
vim.g.NERDTreeMinimalUI = 1
vim.g.NERDTreeIgnore = { [[\\.git$]], [[\\.o$]], [[\\.out$]], [[\\.DS_Store]] }

-- Auto-open NERDTree on launch
vim.cmd([[
  autocmd VimEnter * NERDTree | wincmd p
  autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif
]])

-- Lualine Configuration
local ok_lualine, lualine = pcall(require, "lualine")
if ok_lualine then
  lualine.setup({
    options = {
      theme = "catppuccin",
      component_separators = '|',
      section_separators = '',
    },
  })
end
vim.opt.showmode = false  -- Don't show mode (lualine shows it)

-- ============================================================================
-- OPENCODE.NVIM CONFIGURATION
-- ============================================================================
local ok_opencode, _ = pcall(require, "opencode")
if ok_opencode then
  vim.g.opencode_opts = {
    -- IMPORTANT: Enable permission requests
    events = {
      reload = true,
      permission = true,  -- This makes it ask before applying changes
    },
    -- Don't auto-apply changes
    provider = {
      name = "snacks",
      opts = {
        -- Opencode will wait for your approval
      },
    },
  }
  
  -- Required for auto-reload
  vim.o.autoread = true
end

-- Opencode accept/reject keymaps
vim.keymap.set('n', '<leader>oa', ':w<CR>', { desc = "Accept opencode changes", noremap = true, silent = true })
vim.keymap.set('n', '<leader>or', 'u', { desc = "Reject opencode changes (undo)", noremap = true, silent = true })
vim.keymap.set('n', '<leader>od', ':DiffviewOpen<CR>', { desc = "View opencode diff", noremap = true, silent = true })

-- ============================================================================
-- DIFFVIEW.NVIM - AI DIFF VISUALIZATION (Simple, No Build Required!)
-- ============================================================================

-- diffview.nvim - Shows git diffs and AI changes side-by-side
local ok_diffview, diffview = pcall(require, "diffview")
if ok_diffview then
  diffview.setup({
    enhanced_diff_hl = true,  -- Better diff highlighting
    view = {
      default = {
        layout = "diff2_horizontal",  -- Side-by-side view
        winbar_info = true,
      },
      merge_tool = {
        layout = "diff3_horizontal",
      },
    },
    file_panel = {
      listing_style = "tree",
      tree_options = {
        flatten_dirs = true,
        folder_statuses = "only_folded",
      },
      win_config = {
        position = "left",
        width = 35,
      },
    },
    key_bindings = {
      view = {
        ["]x"]         = "select_next_entry",
        ["[x"]         = "select_prev_entry",
        ["<leader>co"] = "conflict_choose('ours')",
        ["<leader>ct"] = "conflict_choose('theirs')",
        ["<leader>cb"] = "conflict_choose('both')",
        ["<leader>ca"] = "conflict_choose('all')",
      },
      file_panel = {
        ["j"]          = "next_entry",
        ["k"]          = "prev_entry",
        ["<cr>"]       = "select_entry",
        ["<tab>"]      = "select_next_entry",
        ["<s-tab>"]    = "select_prev_entry",
      },
    },
  })
  
  -- Keymaps for diffview
  vim.keymap.set("n", "<leader>do", ":DiffviewOpen<CR>", { desc = "Open Diffview", silent = true })
  vim.keymap.set("n", "<leader>dc", ":DiffviewClose<CR>", { desc = "Close Diffview", silent = true })
  vim.keymap.set("n", "<leader>dh", ":DiffviewFileHistory %<CR>", { desc = "File History", silent = true })
  vim.keymap.set("n", "<leader>dt", ":DiffviewToggleFiles<CR>", { desc = "Toggle Files", silent = true })
end

-- ============================================================================
-- GITSIGNS.NVIM - INLINE DIFF PREVIEW
-- ============================================================================

-- gitsigns.nvim - Modern git signs with inline diff preview
local ok_gitsigns, gitsigns = pcall(require, "gitsigns")
if ok_gitsigns then
  gitsigns.setup({
    signs = {
      add          = { text = '+' },
      change       = { text = '~' },
      delete       = { text = '-' },
      topdelete    = { text = '‾' },
      changedelete = { text = '~' },
      untracked    = { text = '┆' },
    },
    signcolumn = true,
    numhl      = false,
    linehl     = false,
    word_diff  = false,
    watch_gitdir = {
      interval = 1000,
      follow_files = true
    },
    attach_to_untracked = true,
    current_line_blame = false,
    current_line_blame_opts = {
      virt_text = true,
      virt_text_pos = 'eol',
      delay = 1000,
    },
    preview_config = {
      border = 'rounded',
      style = 'minimal',
      relative = 'cursor',
      row = 0,
      col = 1
    },
    on_attach = function(bufnr)
      local gs = package.loaded.gitsigns
      
      -- Navigation (replaces vim-gitgutter keymaps)
      vim.keymap.set('n', ']c', function()
        if vim.wo.diff then return ']c' end
        vim.schedule(function() gs.next_hunk() end)
        return '<Ignore>'
      end, {expr=true, buffer = bufnr, desc = "Next change"})
      
      vim.keymap.set('n', '[c', function()
        if vim.wo.diff then return '[c' end
        vim.schedule(function() gs.prev_hunk() end)
        return '<Ignore>'
      end, {expr=true, buffer = bufnr, desc = "Previous change"})
      
      -- Actions
      vim.keymap.set('n', '<leader>hs', gs.stage_hunk, {buffer = bufnr, desc = "Stage hunk"})
      vim.keymap.set('n', '<leader>hr', gs.reset_hunk, {buffer = bufnr, desc = "Reset hunk"})
      vim.keymap.set('n', '<leader>hp', gs.preview_hunk, {buffer = bufnr, desc = "Preview hunk"})
      vim.keymap.set('n', '<leader>hb', function() gs.blame_line{full=true} end, {buffer = bufnr, desc = "Blame line"})
      vim.keymap.set('n', '<leader>hd', gs.diffthis, {buffer = bufnr, desc = "Diff this"})
      
      -- Text object for hunks
      vim.keymap.set({'o', 'x'}, 'ih', ':<C-U>Gitsigns select_hunk<CR>', {buffer = bufnr, desc = "Select hunk"})
    end
  })
end

-- ============================================================================
-- VISUAL & PRODUCTIVITY PLUGINS CONFIGURATION
-- ============================================================================

-- nvim-notify - Beautiful notifications
local ok_notify, notify = pcall(require, "notify")
if ok_notify then
  vim.notify = notify
  notify.setup({
    background_colour = "#000000",
    fps = 60,
    icons = {
      DEBUG = "",
      ERROR = "",
      INFO = "",
      TRACE = "✎",
      WARN = ""
    },
    level = 2,
    minimum_width = 50,
    render = "default",
    stages = "fade_in_slide_out",
    timeout = 3000,
    top_down = true
  })
end

-- indent-blankline.nvim - Modern indent guides
local ok_indent, indent = pcall(require, "ibl")
if ok_indent then
  indent.setup({
    indent = {
      char = "▏",
      tab_char = "▏",
    },
    scope = {
      enabled = true,
      show_start = true,
      show_end = false,
    },
    exclude = {
      filetypes = { 'nerdtree', 'help', 'alpha', 'dashboard', 'neo-tree', 'Trouble', 'lazy' },
    },
  })
end

-- alpha-nvim - Start screen
local ok_alpha, alpha = pcall(require, "alpha")
if ok_alpha then
  local dashboard = require("alpha.themes.dashboard")
  
  -- Set header (Anime character Braille ASCII art)
  dashboard.section.header.val = {
    "⠀⠀⠀⠀           ⣾⣿⣿⣿⣿⣷⢸⣿⣿⡜⢯⣷⡌⡻⣿⣿⣿⣆⢈⠻⠿⢿⣿⣿⣿⣿⣿⣿⣷⣦⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
    "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡁⢳⣿⣿⣿⣿⣿⣿⡜⣿⣿⣧⢀⢻⣷⠰⠈⢿⣿⣿⣧⢣⠉⠑⠪⢙⠿⠿⠿⠿⠿⠿⠿⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
    "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣱⡇⡞⣿⣿⣿⣿⣿⣿⡇⣿⣿⡏⡄⣧⠹⡇⠧⠈⢻⣿⣿⡇⢧⢢⠀⠀⠑⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
    "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣇⢃⢿⣿⣿⣿⣿⣿⣷⣿⣿⠇⢃⣡⣤⡹⠐⣿⣀⢻⣿⣿⢸⡎⠳⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
    "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣾⣿⣿⠘⡸⣿⣿⣿⣿⣿⣿⣿⡿⣰⣿⣿⢟⡷⠈⠋⠃⠎⢿⣿⡏⣿⠀⠘⢆⠀⠀⠀⠀⠀",
    "⠀⠀⠀⠀⠀⠀⠀⠀⠀⡐⢹⣿⣿⡐⢡⢹⣿⣿⣿⣿⡏⣿⢣⣿⣿⡑⠁⠔⠀⠉⠉⠢⡘⣿⡇⣿⡇⠀⡀⠡⡀⠀⠀⠀⠀⠀⠀⠀⠀",
    "⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇⠘⣿⣿⣇⠇⢣⢻⣿⣿⣿⡇⢇⣾⣿⣿⡆⢸⣤⡀⠚⢂⠀⢡⢿⡇⣿⡇⠀⢿⠀⠀⠄⠀⠀⠀",
    "⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⠠⠹⣿⣿⡘⣆⢣⠻⣿⣿⢈⣾⣿⣿⣿⣶⣸⣏⢀⣬⣋⡼⣠⢸⢹⣿⡇⢠⣼⠙⡄⠀⠀⠀⠀⠀",
    "⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⡇⠁⠹⣿⣇⠹⡃⠃⠙⡇⠘⢿⣿⣿⣿⣿⣿⣏⣓⣉⣭⣴⣿⠘⢸⣿⠁⠘⠋⠀⠹⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
    "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢷⠀⠀⠈⢿⣇⠂⣷⠄⠐⠀⠘⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢠⢸⡏⠀⢀⣠⣴⣾⣿⣶⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
    "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢆⠀⠀⠀⠙⠆⠈⠢⠲⠥⣰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⡞⣸⠁⠀⢸⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀",
    "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠄⠃⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀",
    "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⣿⣿⣿⣿⡏⠹⣿⣿⡿⠫⠊⠀⠀⠀⣶⠀⢻⣿⣿⣿⣿⡿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
    "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠛⠻⠿⠿⠿⢋⠀⠀⠀⠀⢀⣼⣿⡆⠈⣿⣿⣿⡟⣱⡷⠀⠀⠀⠀⠀⠀⠀⠀",
    "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢁⣁⡀⠨⣛⠿⠶⠄⢀⣠⣾⣿⣿⣷⠀⢹⣿⡟⣴⠈⢃⣶⠔⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
    "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⡄⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠈⣿⣿⡿⠀⡀⣿⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
    "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢙⠻⣿⣿⢀⠙⠻⠿⣿⣿⣿⣿⣿⣿⡇⠁⣿⠟⡀⠈⣧⢰⣿⠆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
    "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠿⠴⠮⣥⠻⢧⣤⣄⣀⡉⢩⣭⣍⣃⣀⣩⠎⢀⣼⠉⣼⡯⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
    "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠑⠁⣛⠓⢒⣒⣢⡭⢁⡈⠿⠿⠟⠹⠛⠁⠀⠀⠀⠰⠃⠂⠀⠀⠀",
  }
  
  -- Set menu
  dashboard.section.buttons.val = {
    dashboard.button("e", "  New file", ":ene <BAR> startinsert <CR>"),
    dashboard.button("f", "  Find file", ":Files<CR>"),
    dashboard.button("r", "  Recent files", ":History<CR>"),
    dashboard.button("s", "  Settings", ":e ~/.config/nvim/init.lua<CR>"),
    dashboard.button("q", "  Quit", ":qa<CR>"),
  }
  
  -- Set footer
  local function footer()
    return "FUCK, I'M BALLS DEEP NOW"
  end
  dashboard.section.footer.val = footer()
  
  dashboard.section.footer.opts.hl = "Type"
  dashboard.section.header.opts.hl = "Include"
  dashboard.section.buttons.opts.hl = "Keyword"
  
  dashboard.opts.opts.noautocmd = true
  alpha.setup(dashboard.opts)
end

-- nvim-various-textobjs - Advanced text objects


-- todo-comments.nvim - Highlight TODOs
local ok_todo, todo = pcall(require, "todo-comments")
if ok_todo then
  todo.setup()
end





-- modes.nvim - Cursor line color
local ok_modes, modes = pcall(require, "modes")
if ok_modes then
  modes.setup({
    colors = {
      copy = "#f5c359",
      delete = "#c75c6a",
      insert = "#78ccc5",
      visual = "#9745be",
    },
    line_opacity = 0.15,
    set_cursor = true,
    set_cursorline = true,
    set_number = true,
    ignore = { 'NvimTree', 'TelescopePrompt' }
  })
end

-- vim-illuminate configuration
vim.g.Illuminate_delay = 100
vim.g.Illuminate_highlightUnderCursor = 1

-- ============================================================================
-- NAVIGATION PLUGINS CONFIGURATION
-- ============================================================================



-- Hop.nvim - Visual jump to any location
local ok_hop, hop = pcall(require, "hop")
if ok_hop then
  hop.setup({ keys = 'etovxqpdygfblzhckisuran' })
end





-- Vim-sneak configuration
vim.g['sneak#label'] = 1  -- Label mode for easier targeting

-- Harpoon keymaps removed per user request

-- GitHub Copilot & CMP Configuration
-- GitHub Copilot & CMP Configuration
local ok_copilot, copilot = pcall(require, "copilot")
if ok_copilot then
  -- Avoid Tab conflicts (we want CMP + luasnip to control Tab behavior)
  vim.g.copilot_no_tab_map = true

  copilot.setup({
    suggestion = {
      enabled = true,
      auto_trigger = true,
      keymap = {
        accept = "<C-CR>",       -- Accept suggestion (Ctrl+Enter)
        accept_word = "<C-w>",
        accept_line = "<C-l>",
        next = "<C-]>",
        prev = "<C-[>",
        dismiss = "<C-/>",
      },
    },
    panel = {
      enabled = true,
      auto_refresh = true,
      keymap = {
        open = "<C-p>",
        accept = "<M-CR>",
        refresh = "gr",
        discard = "<C-x>",
      },
    },
  })
end

local ok_copilot_cmp, copilot_cmp = pcall(require, "copilot_cmp")
if ok_copilot_cmp then
  copilot_cmp.setup()
end

local ok_cmp, cmp = pcall(require, "cmp")
if ok_cmp then
  cmp.setup({
    snippet = {
      expand = function(args)
        require('luasnip').lsp_expand(args.body)
      end,
    },
    mapping = cmp.mapping.preset.insert({
      ['<C-b>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<C-e>'] = cmp.mapping.abort(),
      ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
      ['<Tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        else
          fallback()
        end
      end, { 'i', 's' }),
      ['<S-Tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        else
          fallback()
        end
      end, { 'i', 's' }),
    }),
    sources = cmp.config.sources({
      { name = 'copilot' },
      { name = 'nvim_lsp' },
      { name = 'luasnip' },
    }, {
      { name = 'buffer' },
      { name = 'path' },
    })
  })
end

-- Copilot preview helper (preview AI changes, then accept/reject)
pcall(function()
  local ok_preview, _ = pcall(require, "copilot_preview")
  if ok_preview then
    vim.keymap.set('i', '<C-j>', function() require('copilot_preview').accept_and_preview() end, { noremap = true, silent = true, desc = "Copilot accept+preview" })
    vim.keymap.set('n', '<leader>pa', function() require('copilot_preview').apply_accept() end, { noremap = true, silent = true, desc = "Accept AI preview" })
    vim.keymap.set('n', '<leader>pr', function() require('copilot_preview').revert_to_tmp() end, { noremap = true, silent = true, desc = "Reject AI preview" })
  end
end)

-- UltiSnips (snippet shortcuts) - adjusted to not conflict with Copilot
vim.g.UltiSnipsExpandTrigger = '<c-j>'
vim.g.UltiSnipsJumpForwardTrigger = '<c-j>'
vim.g.UltiSnipsJumpBackwardTrigger = '<c-k>'

-- GitGutter (minimal git signs)
vim.g.gitgutter_sign_added = '+'
vim.g.gitgutter_sign_modified = '~'
vim.g.gitgutter_sign_removed = '-'
vim.opt.updatetime = 100  -- Faster git updates

-- Hexmode settings
vim.g.hexmode_patterns = '*.bin,*.exe,*.dat,*.o'
vim.g.hexmode_autodetect = 1

-- ============================================================================
-- KEY MAPPINGS
-- ============================================================================

vim.g.mapleader = " "

-- File Explorer
vim.keymap.set('n', '<C-n>', ':NERDTreeToggle<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>e', ':NERDTreeToggle<CR>', { noremap = true, silent = true })

-- Fuzzy File Finder
vim.keymap.set('n', '<C-p>', ':Files<CR>', { noremap = true, silent = true })
-- Move direct <leader>p mapping to <leader>pp to avoid prefix conflicts with other <leader>p* mappings
vim.keymap.set('n', '<leader>pp', ':Files<CR>', { noremap = true, silent = true, desc = 'FZF: Files' })

-- Quick save and quit
vim.keymap.set('n', '<leader>w', ':w<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>q', ':q<CR>', { noremap = true, silent = true })

-- Quick exit insert mode
vim.keymap.set('i', 'jj', '<Esc>', { noremap = true, silent = true })

-- ============================================================================
-- NAVIGATION PLUGIN KEYMAPS
-- ============================================================================

-- Hop.nvim keymaps
vim.keymap.set('n', '<leader>hw', ':HopWord<CR>', { noremap = true, silent = true, desc = "Hop to Word" })
vim.keymap.set('n', '<leader>hl', ':HopLine<CR>', { noremap = true, silent = true, desc = "Hop to Line" })
vim.keymap.set('n', '<leader>hc', ':HopChar1<CR>', { noremap = true, silent = true, desc = "Hop to Char" })
vim.keymap.set('n', '<leader>hp', ':HopPattern<CR>', { noremap = true, silent = true, desc = "Hop to Pattern" })



-- Harpoon keymaps removed per user request

-- ============================================================================
-- ASSEMBLY-SPECIFIC KEYMAPS
-- ============================================================================

-- Assembly-specific: Compile and run shortcuts
vim.keymap.set('n', '<F5>', ':!nasm -f macho64 % -o %:r.o && ld %:r.o -o %:r -lSystem && ./%:r<CR>', { noremap = true })
vim.keymap.set('n', '<F6>', ':!nasm -f macho64 % -o %:r.o && ld %:r.o -o %:r -lSystem<CR>', { noremap = true })
vim.keymap.set('n', '<F7>', ':!lldb %:r<CR>', { noremap = true })  -- Debug with LLDB
vim.keymap.set('n', '<F8>', ':!objdump -d %:r<CR>', { noremap = true })  -- Disassemble

-- Hex mode toggle (moved to avoid clashing with Hop prefix)
vim.keymap.set('n', '<leader>hx', ':Hexmode<CR>', { noremap = true, silent = true })

-- View registers (peekaboo shows when you press " or @)
-- GitGutter navigation
vim.keymap.set('n', '[c', ':GitGutterPrevHunk<CR>', { noremap = true, silent = true })
vim.keymap.set('n', ']c', ':GitGutterNextHunk<CR>', { noremap = true, silent = true })

-- Comment toggle: 'gcc' in normal mode, 'gc' in visual mode

-- Assembly helper: Convert hex to decimal
vim.cmd([[
function! HexToDec()
  let hex = expand('<cword>')
  let hex = substitute(hex, '^0x', '', '')
  let dec = str2nr(hex, 16)
  echo hex . ' = ' . dec
endfunction
]])
vim.keymap.set('n', '<leader>x', ':call HexToDec()<CR>', { noremap = true, silent = true })

-- Assembly helper: Show ASCII value
vim.cmd([[
function! ShowAscii()
  let char = getline('.')[col('.')-1]
  echo "'" . char . "' = " . char2nr(char) . " (0x" . printf('%x', char2nr(char)) . ")"
endfunction
]])
vim.keymap.set('n', '<leader>a', ':call ShowAscii()<CR>', { noremap = true, silent = true })

-- ============================================================================
-- COMMON EDITING KEYMAPS (Copy, Paste, Cut, Select All, Indent)
-- ============================================================================

-- Opencode.nvim keymaps (Ctrl+A and Ctrl+X reserved for opencode)
vim.keymap.set({ "n", "x" }, "<C-a>", function() require("opencode").ask("@this: ", { submit = true }) end, { desc = "Ask opencode" })
vim.keymap.set({ "n", "x" }, "<C-x>", function() require("opencode").select() end, { desc = "Execute opencode action…" })
vim.keymap.set({ "n", "x" }, "ga", function() require("opencode").prompt("@this") end, { desc = "Add to opencode" })
vim.keymap.set({ "n", "t" }, "<C-.>", function() require("opencode").toggle() end, { desc = "Toggle opencode" })

-- Restore increment/decrement (since we're using Ctrl+A/X for opencode)
vim.keymap.set('n', '+', '<C-a>', { desc = 'Increment', noremap = true })
vim.keymap.set('n', '-', '<C-x>', { desc = 'Decrement', noremap = true })

-- Copy (Ctrl+C in visual and insert modes, yank to system clipboard)
vim.keymap.set('v', '<C-c>', '"+y', { noremap = true, silent = true, desc = "Copy to clipboard" })
vim.keymap.set('i', '<C-c>', '<C-o>"+yy', { noremap = true, silent = true, desc = "Copy line to clipboard" })

-- Paste (Ctrl+V in insert and visual modes only)
vim.keymap.set('i', '<C-v>', '<C-r>+', { noremap = true, silent = true, desc = "Paste from clipboard" })
vim.keymap.set('v', '<C-v>', '"+p', { noremap = true, silent = true, desc = "Paste from clipboard" })

-- Drop.nvim keymaps: show, hide, toggle
vim.keymap.set('n', '<leader>pd', function()
  local ok, drop = pcall(require, 'drop')
  if ok and drop and type(drop.show) == 'function' then
    pcall(drop.show)
  end
end, { noremap = true, silent = true, desc = 'Show Drop' })

vim.keymap.set('n', '<leader>ph', function()
  local ok, drop = pcall(require, 'drop')
  if ok and drop and type(drop.hide) == 'function' then
    pcall(drop.hide)
  end
end, { noremap = true, silent = true, desc = 'Hide Drop' })

vim.keymap.set('n', '<leader>pt', function()
  local ok_dropdrop, dropdrop = pcall(require, 'drop.drop')
  local ok_drop, drop = pcall(require, 'drop')
  if not ok_drop or not ok_dropdrop then
    return
  end
  if dropdrop and dropdrop.timer then
    pcall(drop.hide)
  else
    pcall(drop.show)
  end
end, { noremap = true, silent = true, desc = 'Toggle Drop' })
-- Cut (Ctrl+X in visual and insert modes, cut to system clipboard)
vim.keymap.set('v', '<C-x>', '"+d', { noremap = true, silent = true, desc = "Cut to clipboard" })
vim.keymap.set('i', '<C-x>', '<C-o>"+dd', { noremap = true, silent = true, desc = "Cut line to clipboard" })

-- Select All (Ctrl+A in insert mode only - keeps opencode's Ctrl+A in normal mode)
vim.keymap.set('i', '<C-a>', '<C-o>ggVG', { noremap = true, silent = true, desc = "Select all" })

-- Indent/Unindent in visual mode (Tab and Shift+Tab)
vim.keymap.set('v', '<Tab>', '>gv', { noremap = true, silent = true, desc = "Indent selection" })
vim.keymap.set('v', '<S-Tab>', '<gv', { noremap = true, silent = true, desc = "Unindent selection" })

-- Indent/Unindent in normal mode (Tab and Shift+Tab on current line)
vim.keymap.set('n', '<Tab>', '>>', { noremap = true, silent = true, desc = "Indent line" })
vim.keymap.set('n', '<S-Tab>', '<<', { noremap = true, silent = true, desc = "Unindent line" })

-- Undo and Redo (Ctrl+Z and Ctrl+Shift+Z)
vim.keymap.set('n', '<C-z>', 'u', { noremap = true, silent = true, desc = "Undo" })
vim.keymap.set('i', '<C-z>', '<C-o>u', { noremap = true, silent = true, desc = "Undo" })
vim.keymap.set('n', '<C-S-z>', '<C-r>', { noremap = true, silent = true, desc = "Redo" })
vim.keymap.set('i', '<C-S-z>', '<C-o><C-r>', { noremap = true, silent = true, desc = "Redo" })
