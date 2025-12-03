-- ObjDump Mapping Plugin
-- Maps objdump output to assembly source files

local M = {}

-- Default configuration
M.config = {
  -- Auto-start mapping for assembly files
  auto_start = false,
  
  -- Default keybindings
  keybindings = {
    toggle = '<leader>om',      -- Toggle objdump mapping
    refresh = '<leader>or',     -- Refresh mapping
    select_exe = '<leader>oe',  -- Select executable
  },
  
  -- File types to activate on
  filetypes = { 'asm', 'nasm', 's' },
  
  -- objdump command (use llvm-objdump or objdump)
  objdump_cmd = 'objdump',
  
  -- objdump flags
  objdump_flags = '-d -M intel',
  
  -- Namespace for virtual text
  namespace_name = 'objdump_mapping',
  
  -- Virtual text highlight group
  highlight = 'Comment',
  
  -- Address format (short = last 7 chars, full = complete address)
  address_format = 'short',
  
  -- Auto-refresh interval in milliseconds (default: 60000 = 1 minute)
  auto_refresh_interval = 60000,
}

-- Setup function for user configuration
function M.setup(opts)
  -- Merge user config with defaults
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
  
  -- Set up keybindings
  if M.config.keybindings.toggle then
    vim.keymap.set('n', M.config.keybindings.toggle, function()
      require('objdump_mapping.mapper').toggle()
    end, { 
      noremap = true, 
      silent = true, 
      desc = 'Toggle ObjDump Mapping' 
    })
  end
  
  if M.config.keybindings.refresh then
    vim.keymap.set('n', M.config.keybindings.refresh, function()
      require('objdump_mapping.mapper').refresh()
    end, { 
      noremap = true, 
      silent = true, 
      desc = 'Refresh ObjDump Mapping' 
    })
  end
  
  if M.config.keybindings.select_exe then
    vim.keymap.set('n', M.config.keybindings.select_exe, function()
      require('objdump_mapping.mapper').select_executable()
    end, { 
      noremap = true, 
      silent = true, 
      desc = 'Select Executable for ObjDump' 
    })
  end
  
  -- Auto-start if configured
  if M.config.auto_start then
    vim.api.nvim_create_autocmd('FileType', {
      pattern = M.config.filetypes,
      callback = function()
        require('objdump_mapping.mapper').enable()
      end,
      group = vim.api.nvim_create_augroup('ObjDumpMappingAutoStart', { clear = true }),
    })
  end
end

-- Export mapper functions
function M.toggle()
  require('objdump_mapping.mapper').toggle()
end

function M.enable()
  require('objdump_mapping.mapper').enable()
end

function M.disable()
  require('objdump_mapping.mapper').disable()
end

function M.refresh()
  require('objdump_mapping.mapper').refresh()
end

function M.select_executable()
  require('objdump_mapping.mapper').select_executable()
end

function M.start_auto_refresh(interval_ms)
  require('objdump_mapping.mapper').start_auto_refresh(interval_ms)
end

function M.stop_auto_refresh()
  require('objdump_mapping.mapper').stop_auto_refresh()
end

return M
