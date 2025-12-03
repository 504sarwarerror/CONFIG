-- DOTNVIM - Auto-loading plugin entry point
-- This file is automatically loaded by Neovim

-- Prevent loading twice
if vim.g.loaded_dotnvim then
  return
end
vim.g.loaded_dotnvim = 1

-- Create user commands
vim.api.nvim_create_user_command('StackViz', function()
  require('dotnvim').show()
end, {
  desc = 'Show Assembly Stack Visualizer'
})

vim.api.nvim_create_user_command('StackVizRefresh', function()
  require('dotnvim').refresh()
end, {
  desc = 'Refresh Stack Visualizer'
})

vim.api.nvim_create_user_command('StackVizJump', function()
  require('dotnvim').jump()
end, {
  desc = 'Jump to variable definition in source'
})

vim.api.nvim_create_user_command('StackVizTooltip', function()
  require('dotnvim').show_tooltip()
end, {
  desc = 'Show detailed error tooltip'
})

vim.api.nvim_create_user_command('StackVizAutoReloadStart', function()
  require('dotnvim').start_auto_reload()
end, {
  desc = 'Start auto-reload timer'
})

vim.api.nvim_create_user_command('StackVizAutoReloadStop', function()
  require('dotnvim').stop_auto_reload()
end, {
  desc = 'Stop auto-reload timer'
})
