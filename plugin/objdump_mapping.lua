-- ObjDump Mapping Plugin
-- Plugin loader for Neovim

if vim.g.loaded_objdump_mapping then
  return
end
vim.g.loaded_objdump_mapping = 1

-- Create user commands
vim.api.nvim_create_user_command('ObjDumpToggle', function()
  require('objdump_mapping.mapper').toggle()
end, { desc = 'Toggle ObjDump address mapping' })

vim.api.nvim_create_user_command('ObjDumpEnable', function()
  require('objdump_mapping.mapper').enable()
end, { desc = 'Enable ObjDump address mapping' })

vim.api.nvim_create_user_command('ObjDumpDisable', function()
  require('objdump_mapping.mapper').disable()
end, { desc = 'Disable ObjDump address mapping' })

vim.api.nvim_create_user_command('ObjDumpRefresh', function()
  require('objdump_mapping.mapper').refresh()
end, { desc = 'Refresh ObjDump address mapping' })

vim.api.nvim_create_user_command('ObjDumpSelect', function()
  require('objdump_mapping.mapper').select_executable()
end, { desc = 'Select executable for ObjDump' })
