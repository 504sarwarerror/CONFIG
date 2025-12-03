-- DOTNVIM - Assembly Stack Visualizer Plugin
-- Main plugin module

local M = {}

-- Default configuration
M.config = {
  -- Auto-start visualizer for assembly files
  auto_start = false,
  
  -- Default keybindings
  keybindings = {
    toggle = '<leader>sv',
  },
  
  -- File types to activate on
  filetypes = { 'asm', 'nasm' },
}

-- Setup function for user configuration
function M.setup(opts)
  -- Merge user config with defaults
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
  
  -- Set up auto-commands if auto_start is enabled
  if M.config.auto_start then
    vim.api.nvim_create_autocmd('FileType', {
      pattern = M.config.filetypes,
      callback = function()
        require('dotnvim.stack_visualizer').show()
      end,
      group = vim.api.nvim_create_augroup('DOTNVIMAutoStart', { clear = true }),
    })
  end
  
  -- Set up keybindings if provided
  if M.config.keybindings.toggle then
    vim.keymap.set('n', M.config.keybindings.toggle, function()
      require('dotnvim.stack_visualizer').show()
    end, { 
      noremap = true, 
      silent = true, 
      desc = 'Toggle Stack Visualizer' 
    })
  end
end

-- Export stack visualizer functions
function M.show()
  require('dotnvim.stack_visualizer').show()
end

function M.refresh()
  require('dotnvim.stack_visualizer').refresh()
end

function M.jump()
  require('dotnvim.stack_visualizer').jump()
end

function M.show_tooltip()
  require('dotnvim.stack_visualizer').show_tooltip()
end

function M.start_auto_reload()
  require('dotnvim.stack_visualizer').start_auto_reload()
end

function M.stop_auto_reload()
  require('dotnvim.stack_visualizer').stop_auto_reload()
end

return M
