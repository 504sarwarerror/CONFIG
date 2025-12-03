-- ============================================================================
-- EXAMPLE NEOVIM CONFIGURATION
-- ============================================================================
-- This is a complete example Neovim configuration showing how to set up
-- a full assembly development environment with the DOTNVIM plugin.
--
-- To use this configuration:
-- 1. Copy this file to ~/.config/nvim/init.lua
-- 2. Install lazy.nvim (it will auto-install on first run)
-- 3. Open Neovim and run :Lazy sync
--
-- Or just use parts of this config that you need!
-- ============================================================================

vim.g.python3_host_prog = '/usr/local/bin/python3'

vim.g.polyglot_disabled = { 'asm' }


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




require("lazy").setup({
  
  { 'preservim/nerdtree' },

  
  { 'junegunn/fzf', build = ':call fzf#install()' },
  { 'junegunn/fzf.vim' },
  
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
      
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope: Find files' })
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope: Live grep' })
      vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope: Buffers' })
      vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope: Help' })
    end,
  },
  
  {
    'folke/which-key.nvim',
    config = function()
      local ok, wk = pcall(require, 'which-key')
      if not ok then
        return
      end
      wk.setup({})
      
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

  
  { 'tpope/vim-commentary' },

  
  { 'ARM9/arm-syntax-vim' },

  
  { 'fidian/hexmode' },

  
  { 'sheerun/vim-polyglot' },

  
  { 'catppuccin/nvim', name = 'catppuccin' },
  { 'joshdick/onedark.vim' },
  { 'folke/tokyonight.nvim' },

  
  { 'SirVer/ultisnips' },
  { 'honza/vim-snippets' },

  
  { 'hrsh7th/nvim-cmp' },
  { 'hrsh7th/cmp-nvim-lsp' },
  { 'hrsh7th/cmp-buffer' },
  { 'hrsh7th/cmp-path' },
  { 'saadparwaiz1/cmp_luasnip' },
  { 'L3MON4D3/LuaSnip' },

  
  { 'nvim-lua/plenary.nvim' },
  { 'MunifTanjim/nui.nvim' },
  {
    'github/copilot.vim',
    config = function()
      vim.g.copilot_no_tab_map = true
      vim.api.nvim_set_keymap('i', '<C-J>', 'copilot#Accept("\\<CR>")', { expr = true, replace_keycodes = false, noremap = true })
    end,
  },
  
  { 'nvim-lualine/lualine.nvim' },
  
  { 'nvim-tree/nvim-web-devicons' },

  
  { 'airblade/vim-gitgutter' },

  
  { 'junegunn/vim-peekaboo' },

  
  
  { 'rcarriga/nvim-notify' },

  
  { 'echasnovski/mini.icons', branch = 'main' },

  

  
  { 'lukas-reineke/indent-blankline.nvim' },

  
  { 'goolord/alpha-nvim' },

  
  { 'RRethy/vim-illuminate' },

  
  { 'folke/todo-comments.nvim' },

  
  { 'mvllow/modes.nvim' },

  
  
  { 'phaazon/hop.nvim' },

  
  { 'justinmk/vim-sneak' },

  
  

  
  

  
  { 'lewis6991/gitsigns.nvim' },

  
  {
    'NickvanDyke/opencode.nvim',
    dependencies = {
      'folke/snacks.nvim',
    },
  },

  
  {
    'folke/snacks.nvim',
    opts = {
      input = {},
      picker = {},
      terminal = {},
    },
  },
  
  { 'bergercookie/asm-lsp' },
  {
    'folke/drop.nvim',
    
    opts = {
      theme = "stars",
      max = 75,
      interval = 100,
      screensaver = 1000 * 60 * 5,
        
        filetypes = {},
      winblend = 0,
    },
  },
})


vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.mouse = "a"
vim.opt.expandtab = false  
vim.opt.tabstop = 8        
vim.opt.shiftwidth = 8
vim.opt.smartindent = true
vim.opt.wrap = false       
vim.opt.cursorline = true  


vim.cmd("syntax enable")


vim.cmd("filetype plugin indent on")


vim.g.asmsyntax = "nasm"


vim.cmd([[
autocmd BufRead,BufNewFile *.asm set filetype=nasm
autocmd BufRead,BufNewFile *.s set filetype=nasm
]])


local ok, catppuccin = pcall(require, "catppuccin")
if ok then
  catppuccin.setup({
    flavour = "mocha", 
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


vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
vim.api.nvim_set_hl(0, "NERDTreeNormal", { bg = "none" })


vim.g.NERDTreeShowHidden = 1
vim.g.NERDTreeMinimalUI = 1
vim.g.NERDTreeIgnore = { [[\\.git$]], [[\\.o$]], [[\\.out$]], [[\\.DS_Store]] }


vim.cmd([[
  autocmd VimEnter * NERDTree | wincmd p
  autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif
]])


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
vim.opt.showmode = false  







local ok_opencode, opencode = pcall(require, "opencode")
if ok_opencode and type(opencode.setup) == "function" then
  opencode.setup({
  preferred_picker = nil, 
  preferred_completion = nil, 
  default_global_keymaps = true, 
  default_mode = 'build', 
  keymap_prefix = '<leader>o', 
  keymap = {
    editor = {
      ['<leader>og'] = { 'toggle' }, 
      ['<leader>oi'] = { 'open_input' }, 
      ['<leader>oI'] = { 'open_input_new_session' }, 
      ['<leader>oo'] = { 'open_output' }, 
      ['<leader>ot'] = { 'toggle_focus' }, 
      ['<leader>oT'] = { 'timeline' }, 
      ['<leader>oq'] = { 'close' }, 
      ['<leader>os'] = { 'select_session' }, 
      ['<leader>oR'] = { 'rename_session' }, 
      ['<leader>op'] = { 'configure_provider' }, 
      ['<leader>oz'] = { 'toggle_zoom' }, 
      ['<leader>ov'] = { 'paste_image'}, 
      ['<leader>od'] = { 'diff_open' }, 
      ['<leader>o]'] = { 'diff_next' }, 
      ['<leader>o['] = { 'diff_prev' }, 
      ['<leader>oc'] = { 'diff_close' }, 
      ['<leader>ora'] = { 'diff_revert_all_last_prompt' }, 
      ['<leader>ort'] = { 'diff_revert_this_last_prompt' }, 
      ['<leader>orA'] = { 'diff_revert_all' }, 
      ['<leader>orT'] = { 'diff_revert_this' }, 
      ['<leader>orrr'] = { 'diff_restore_snapshot_file' }, 
      ['<leader>orR'] = { 'diff_restore_snapshot_all' }, 
      ['<leader>ox'] = { 'swap_position' }, 
      ['<leader>opa'] = { 'permission_accept' }, 
      ['<leader>opA'] = { 'permission_accept_all' }, 
      ['<leader>opd'] = { 'permission_deny' }, 
    },
    input_window = {
      ['<cr>'] = { 'submit_input_prompt', mode = { 'n', 'i' } }, 
      ['<esc>'] = { 'close' }, 
      ['<C-c>'] = { 'cancel' }, 
      ['~'] = { 'mention_file', mode = 'i' }, 
      ['@'] = { 'mention', mode = 'i' }, 
      ['/'] = { 'slash_commands', mode = 'i' }, 
      ['#'] = { 'context_items', mode = 'i' }, 
      ['<M-v>'] = { 'paste_image', mode = 'i' }, 
      ['<C-i>'] = { 'focus_input', mode = { 'n', 'i' } }, 
      ['<tab>'] = { 'toggle_pane', mode = { 'n', 'i' } }, 
      ['<up>'] = { 'prev_prompt_history', mode = { 'n', 'i' } }, 
      ['<down>'] = { 'next_prompt_history', mode = { 'n', 'i' } }, 
      ['<M-m>'] = { 'switch_mode' }, 
    },
    output_window = {
      ['<esc>'] = { 'close' }, 
      ['<C-c>'] = { 'cancel' }, 
      [']]'] = { 'next_message' }, 
      ['[['] = { 'prev_message' }, 
      ['<tab>'] = { 'toggle_pane', mode = { 'n', 'i' } }, 
      ['i'] = { 'focus_input', 'n' }, 
      ['<leader>oS'] = { 'select_child_session' }, 
      ['<leader>oD'] = { 'debug_message' }, 
      ['<leader>oO'] = { 'debug_output' }, 
      ['<leader>ods'] = { 'debug_session' }, 
    },
    permission = {
      accept = 'a', 
      accept_all = 'A', 
      deny = 'd', 
    },
    session_picker = {
      rename_session = { '<C-r>' }, 
      delete_session = { '<C-d>' }, 
      new_session = { '<C-n>' }, 
    },
    timeline_picker = {
      undo = { '<C-u>', mode = { 'i', 'n' } }, 
      fork = { '<C-f>', mode = { 'i', 'n' } }, 
    },
    history_picker = {
      delete_entry = { '<C-d>', mode = { 'i', 'n' } }, 
      clear_all = { '<C-X>', mode = { 'i', 'n' } }, 
    }
  },
  ui = {
    position = 'right', 
    input_position = 'bottom', 
    window_width = 0.40, 
    zoom_width = 0.8, 
    input_height = 0.15, 
    display_model = true, 
    display_context_size = true, 
    display_cost = true, 
    window_highlight = 'Normal:OpencodeBackground,FloatBorder:OpencodeBorder', 
    icons = {
      preset = 'nerdfonts', 
      overrides = {}, 
    },
    output = {
      tools = {
        show_output = true, 
      },
      rendering = {
        markdown_debounce_ms = 250, 
        on_data_rendered = nil, 
      },
    },
    input = {
      text = {
        wrap = false, 
      },
    },
    completion = {
      file_sources = {
        enabled = true,
        preferred_cli_tool = 'server', 
        ignore_patterns = {
          '^%.git/',
          '^%.svn/',
          '^%.hg/',
          'node_modules/',
          '%.pyc$',
          '%.o$',
          '%.obj$',
          '%.exe$',
          '%.dll$',
          '%.so$',
          '%.dylib$',
          '%.class$',
          '%.jar$',
          '%.war$',
          '%.ear$',
          'target/',
          'build/',
          'dist/',
          'out/',
          'deps/',
          '%.tmp$',
          '%.temp$',
          '%.log$',
          '%.cache$',
        },
        max_files = 10,
        max_display_length = 50, 
      },
    },
  },
  context = {
    enabled = true, 
    cursor_data = {
      enabled = false, 
    },
    diagnostics = {
      info = false, 
      warn = true, 
      error = true, 
    },
    current_file = {
      enabled = true, 
    },
    selection = {
      enabled = true, 
    },
  },
  debug = {
    enabled = false, 
  },
  prompt_guard = nil, 

  
  hooks = {
    on_file_edited = nil, 
    on_session_loaded = nil, 
    on_done_thinking = nil, 
    on_permission_requested = nil, 
  },
})

  
  vim.o.autoread = true
end









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
      
      
      vim.keymap.set('n', '<leader>hs', gs.stage_hunk, {buffer = bufnr, desc = "Stage hunk"})
      vim.keymap.set('n', '<leader>hr', gs.reset_hunk, {buffer = bufnr, desc = "Reset hunk"})
      vim.keymap.set('n', '<leader>hp', gs.preview_hunk, {buffer = bufnr, desc = "Preview hunk"})
      vim.keymap.set('n', '<leader>hb', function() gs.blame_line{full=true} end, {buffer = bufnr, desc = "Blame line"})
      vim.keymap.set('n', '<leader>hd', gs.diffthis, {buffer = bufnr, desc = "Diff this"})
      
      
      vim.keymap.set({'o', 'x'}, 'ih', ':<C-U>Gitsigns select_hunk<CR>', {buffer = bufnr, desc = "Select hunk"})
    end
  })
end






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


local ok_alpha, alpha = pcall(require, "alpha")
if ok_alpha then
  local dashboard = require("alpha.themes.dashboard")
  
  
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
  
  
  dashboard.section.buttons.val = {
    dashboard.button("e", "  New file", ":ene <BAR> startinsert <CR>"),
    dashboard.button("f", "  Find file", ":Files<CR>"),
    dashboard.button("r", "  Recent files", ":History<CR>"),
    dashboard.button("s", "  Settings", ":e ~/.config/nvim/init.lua<CR>"),
    dashboard.button("q", "  Quit", ":qa<CR>"),
  }
  
  
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

local ok_todo, todo = pcall(require, "todo-comments")
if ok_todo then
  todo.setup()
end

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


vim.g.Illuminate_delay = 100
vim.g.Illuminate_highlightUnderCursor = 1

local ok_hop, hop = pcall(require, "hop")
if ok_hop then
  hop.setup({ keys = 'etovxqpdygfblzhckisuran' })
end

vim.g['sneak#label'] = 1  

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
      ['<CR>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
          return cmp.confirm({ select = true })
        end
        return fallback()
      end, { 'i', 's' }),
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
      { name = 'nvim_lsp' },
      { name = 'luasnip' },
    }, {
      { name = 'buffer' },
      { name = 'path' },
    })
  })
end


vim.g.UltiSnipsExpandTrigger = '<c-j>'
vim.g.UltiSnipsJumpForwardTrigger = '<c-j>'
vim.g.UltiSnipsJumpBackwardTrigger = '<c-k>'


vim.g.gitgutter_sign_added = '+'
vim.g.gitgutter_sign_modified = '~'
vim.g.gitgutter_sign_removed = '-'
vim.opt.updatetime = 100  


vim.g.hexmode_patterns = '*.bin,*.exe,*.dat,*.o'
vim.g.hexmode_autodetect = 1





vim.g.mapleader = " "


vim.keymap.set('n', '<C-n>', ':NERDTreeToggle<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>e', ':NERDTreeToggle<CR>', { noremap = true, silent = true })


vim.keymap.set('n', '<C-p>', ':Files<CR>', { noremap = true, silent = true })

vim.keymap.set('n', '<leader>pp', ':Files<CR>', { noremap = true, silent = true, desc = 'FZF: Files' })


vim.keymap.set('n', '<leader>w', ':w<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>q', ':q<CR>', { noremap = true, silent = true })


vim.keymap.set('i', 'jj', '<Esc>', { noremap = true, silent = true })






vim.keymap.set('n', '<leader>hw', ':HopWord<CR>', { noremap = true, silent = true, desc = "Hop to Word" })
vim.keymap.set('n', '<leader>hl', ':HopLine<CR>', { noremap = true, silent = true, desc = "Hop to Line" })
vim.keymap.set('n', '<leader>hc', ':HopChar1<CR>', { noremap = true, silent = true, desc = "Hop to Char" })
vim.keymap.set('n', '<leader>hp', ':HopPattern<CR>', { noremap = true, silent = true, desc = "Hop to Pattern" })










vim.keymap.set('n', '<F5>', ':!nasm -f macho64 % -o %:r.o && ld %:r.o -o %:r -lSystem && ./%:r<CR>', { noremap = true })
vim.keymap.set('n', '<F6>', ':!nasm -f macho64 % -o %:r.o && ld %:r.o -o %:r -lSystem<CR>', { noremap = true })
vim.keymap.set('n', '<F7>', ':!lldb %:r<CR>', { noremap = true })  
vim.keymap.set('n', '<F8>', ':!objdump -d %:r<CR>', { noremap = true })  


vim.keymap.set('n', '<leader>hx', ':Hexmode<CR>', { noremap = true, silent = true })



vim.keymap.set('n', '[c', ':GitGutterPrevHunk<CR>', { noremap = true, silent = true })
vim.keymap.set('n', ']c', ':GitGutterNextHunk<CR>', { noremap = true, silent = true })




vim.cmd([[
function! HexToDec()
  let hex = expand('<cword>')
  let hex = substitute(hex, '^0x', '', '')
  let dec = str2nr(hex, 16)
  echo hex . ' = ' . dec
endfunction
]])
vim.keymap.set('n', '<leader>x', ':call HexToDec()<CR>', { noremap = true, silent = true })


vim.cmd([[
function! ShowAscii()
  let char = getline('.')[col('.')-1]
  echo "'" . char . "' = " . char2nr(char) . " (0x" . printf('%x', char2nr(char)) . ")"
endfunction
]])
vim.keymap.set('n', '<leader>a', ':call ShowAscii()<CR>', { noremap = true, silent = true })











local function _opencode_call(fn)
  return function()
    local ok, opencode = pcall(require, 'opencode')
    if not ok or not opencode then return end
    local f = opencode[fn]
    if type(f) == 'function' then pcall(f) end
  end
end

vim.keymap.set({'n','i'}, '<leader>og', _opencode_call('toggle'), { noremap = true, silent = true, desc = 'Opencode: Toggle UI' })
vim.keymap.set({'n','i'}, '<leader>oi', _opencode_call('open_input'), { noremap = true, silent = true, desc = 'Opencode: Open input' })
vim.keymap.set({'n','i'}, '<leader>oo', _opencode_call('open_output'), { noremap = true, silent = true, desc = 'Opencode: Open output' })
vim.keymap.set({'n','i'}, '<leader>od', _opencode_call('diff_open'), { noremap = true, silent = true, desc = 'Opencode: Open diff' })



vim.keymap.set('n', '+', '<C-a>', { desc = 'Increment', noremap = true })
vim.keymap.set('n', '-', '<C-x>', { desc = 'Decrement', noremap = true })


vim.keymap.set('v', '<C-c>', '"+y', { noremap = true, silent = true, desc = "Copy to clipboard" })
vim.keymap.set('i', '<C-c>', '<C-o>"+yy', { noremap = true, silent = true, desc = "Copy line to clipboard" })


vim.keymap.set('i', '<C-v>', '<C-r>+', { noremap = true, silent = true, desc = "Paste from clipboard" })
vim.keymap.set('v', '<C-v>', '"+p', { noremap = true, silent = true, desc = "Paste from clipboard" })


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

vim.keymap.set('v', '<C-x>', '"+d', { noremap = true, silent = true, desc = "Cut to clipboard" })
vim.keymap.set('i', '<C-x>', '<C-o>"+dd', { noremap = true, silent = true, desc = "Cut line to clipboard" })


vim.keymap.set('i', '<C-a>', '<C-o>ggVG', { noremap = true, silent = true, desc = "Select all" })


vim.keymap.set('v', '<Tab>', '>gv', { noremap = true, silent = true, desc = "Indent selection" })
vim.keymap.set('v', '<S-Tab>', '<gv', { noremap = true, silent = true, desc = "Unindent selection" })


vim.keymap.set('n', '<Tab>', '>>', { noremap = true, silent = true, desc = "Indent line" })
vim.keymap.set('n', '<S-Tab>', '<<', { noremap = true, silent = true, desc = "Unindent line" })


vim.keymap.set('n', '<C-z>', 'u', { noremap = true, silent = true, desc = "Undo" })
vim.keymap.set('i', '<C-z>', '<C-o>u', { noremap = true, silent = true, desc = "Undo" })
vim.keymap.set('n', '<C-S-z>', '<C-r>', { noremap = true, silent = true, desc = "Redo" })
vim.keymap.set('i', '<C-S-z>', '<C-o><C-r>', { noremap = true, silent = true, desc = "Redo" })


-- ============================================================================
-- DOTNVIM PLUGIN SETUP (Stack Visualizer)
-- ============================================================================
-- This shows how to configure the DOTNVIM plugin in your config
-- If you installed via a plugin manager, this is all you need!

-- Option 1: Minimal setup (use defaults)
-- require('dotnvim').setup()

-- Option 2: Custom setup with auto-start
require('dotnvim').setup({
  auto_start = true,  -- Auto-open for assembly files
  keybindings = {
    toggle = '<leader>sv',
  },
  filetypes = { 'asm', 'nasm' },
})
