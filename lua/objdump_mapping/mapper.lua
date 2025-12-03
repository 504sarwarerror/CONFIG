-- ObjDump Mapper
-- Core functionality for mapping objdump output to assembly source

local M = {}

-- State
local state = {
  enabled = false,
  namespace = nil,
  current_exe = nil,
  mappings = {},       -- instruction -> address mapping
  line_addresses = {}, -- line number -> address mapping
  buf_id = nil,
  auto_refresh_timer = nil,  -- Timer for auto-refresh
}

-- Initialize highlight group
local function init_highlight()
  -- Create highlight group for objdump addresses (yellow/gold color)
  vim.api.nvim_set_hl(0, 'ObjDumpAddr', { fg = '#e5c07b', bold = true })
end

-- Call init on load
init_highlight()

-- Get configuration
local function get_config()
  local ok, init = pcall(require, 'objdump_mapping')
  if ok then
    return init.config
  end
  return {
    objdump_cmd = 'objdump',
    objdump_flags = '-d -M intel',
    highlight = 'Comment',
    address_format = 'short',
  }
end

-- Initialize namespace
local function init_namespace()
  if not state.namespace then
    local config = get_config()
    state.namespace = vim.api.nvim_create_namespace(config.namespace_name or 'objdump_mapping')
  end
  return state.namespace
end

-- Find executables in the current directory and subdirectories
local function find_executables()
  local cwd = vim.fn.getcwd()
  local executables = {}
  
  -- Common executable patterns
  local patterns = {
    '*.exe',
    '*.out',
    '*.elf',
    '*.bin',
    '*',  -- For Unix executables without extension
  }
  
  -- Use find command to locate executables
  local cmd = string.format(
    'find "%s" -maxdepth 3 -type f \\( -perm -u=x -o -name "*.exe" -o -name "*.out" -o -name "*.elf" -o -name "*.o" \\) 2>/dev/null',
    cwd
  )
  
  local handle = io.popen(cmd)
  if handle then
    for line in handle:lines() do
      -- Filter out common non-executable files
      if not line:match('%.lua$') 
         and not line:match('%.py$')
         and not line:match('%.sh$')
         and not line:match('%.txt$')
         and not line:match('%.md$')
         and not line:match('%.json$')
         and not line:match('%.git/')
         and not line:match('node_modules/')
         and not line:match('%.DS_Store') then
        table.insert(executables, line)
      end
    end
    handle:close()
  end
  
  return executables
end

-- Run objdump on executable
local function run_objdump(exe_path)
  local config = get_config()
  local cmd = string.format('%s %s "%s" 2>/dev/null', 
    config.objdump_cmd, 
    config.objdump_flags, 
    exe_path
  )
  
  local output = {}
  local handle = io.popen(cmd)
  if handle then
    for line in handle:lines() do
      table.insert(output, line)
    end
    handle:close()
  end
  
  return output
end

-- Normalize instruction for comparison
local function normalize_instruction(instr)
  if not instr then return "" end
  
  -- Convert to lowercase
  local normalized = instr:lower()
  
  -- Remove extra whitespace
  normalized = normalized:gsub('%s+', ' ')
  normalized = normalized:gsub('^%s+', '')
  normalized = normalized:gsub('%s+$', '')
  
  -- Remove size suffixes that might differ (q, l, w, b)
  -- But be careful not to remove them from register names
  
  -- Normalize register names (sometimes displayed differently)
  -- e.g., %rax vs rax
  normalized = normalized:gsub('%%', '')
  
  -- Remove comments
  normalized = normalized:gsub('#.*$', '')
  normalized = normalized:gsub(';.*$', '')
  
  -- Trim again after comment removal
  normalized = normalized:gsub('%s+$', '')
  
  return normalized
end

-- Extract instruction from objdump line
-- Format: address: hex_bytes  instruction  operands
local function parse_objdump_line(line)
  -- Match pattern: address: bytes instruction
  -- Example: 140002770: 4c 8b 05 09 1c 00 00  movq  0x1c09(%rip), %r8
  
  local address, rest = line:match('^%s*(%x+):%s*(.+)$')
  if not address then return nil end
  
  -- Skip if rest doesn't contain instruction (just bytes continuation)
  if not rest:match('%s%s+') then
    -- Try to find instruction after hex bytes
    -- Hex bytes are separated by space, instruction starts after double space or tab
  end
  
  -- Find where hex bytes end and instruction begins
  -- Hex bytes pattern: groups of 2 hex digits separated by space
  local hex_bytes, instruction = rest:match('^([%x%s]+)%s%s+(.+)$')
  if not hex_bytes then
    hex_bytes, instruction = rest:match('^([%x%s]+)\t+(.+)$')
  end
  
  if not instruction then return nil end
  
  -- Clean up instruction
  instruction = instruction:gsub('%s+', ' ')
  instruction = instruction:gsub('^%s+', '')
  
  return {
    address = address,
    hex_bytes = hex_bytes,
    instruction = instruction,
    normalized = normalize_instruction(instruction),
  }
end

-- Parse objdump output into instruction mapping
local function parse_objdump(output)
  local mappings = {}
  
  for _, line in ipairs(output) do
    local parsed = parse_objdump_line(line)
    if parsed then
      -- Store by normalized instruction for matching
      local key = parsed.normalized
      if not mappings[key] then
        mappings[key] = {}
      end
      table.insert(mappings[key], parsed)
    end
  end
  
  return mappings
end

-- Extract instruction from source line
local function extract_source_instruction(line)
  -- Remove comments
  local without_comment = line:gsub(';.*$', '')
  without_comment = without_comment:gsub('#.*$', '')
  
  -- Remove labels
  local without_label = without_comment:gsub('^[%w_]+:%s*', '')
  
  -- Trim
  without_label = without_label:gsub('^%s+', '')
  without_label = without_label:gsub('%s+$', '')
  
  -- Skip directives
  if without_label:match('^%.') or without_label:match('^section') then
    return nil
  end
  
  -- Skip data definitions
  if without_label:match('^db%s') or without_label:match('^dw%s') 
     or without_label:match('^dd%s') or without_label:match('^dq%s') then
    return nil
  end
  
  if without_label == '' then
    return nil
  end
  
  return without_label
end

-- Match source lines to objdump addresses
local function match_source_to_objdump(buf_id, mappings)
  local lines = vim.api.nvim_buf_get_lines(buf_id, 0, -1, false)
  local line_addresses = {}
  local used_addresses = {}  -- Track used addresses to handle duplicates
  
  for line_num, line in ipairs(lines) do
    local instruction = extract_source_instruction(line)
    if instruction then
      local normalized = normalize_instruction(instruction)
      local matches = mappings[normalized]
      
      if matches then
        -- Find first unused address for this instruction
        for _, match in ipairs(matches) do
          local addr_key = match.address
          if not used_addresses[addr_key] then
            line_addresses[line_num] = {
              address = match.address,
              hex_bytes = match.hex_bytes,
              instruction = match.instruction,
            }
            used_addresses[addr_key] = true
            break
          end
        end
        
        -- If all matches used, just take the first one (instruction repeated)
        if not line_addresses[line_num] and #matches > 0 then
          line_addresses[line_num] = {
            address = matches[1].address,
            hex_bytes = matches[1].hex_bytes,
            instruction = matches[1].instruction,
          }
        end
      end
    end
  end
  
  return line_addresses
end

-- Format address for display
local function format_address(address)
  local config = get_config()
  if config.address_format == 'short' then
    -- Return last 7 characters (like 4000277)
    if #address > 7 then
      return address:sub(-7)
    end
  end
  return address
end

-- Store original statuscolumn
local original_statuscolumn = nil

-- Apply addresses using custom statuscolumn
local function apply_virtual_text(buf_id, line_addresses)
  local ns = init_namespace()
  
  -- Clear existing extmarks
  vim.api.nvim_buf_clear_namespace(buf_id, ns, 0, -1)
  
  -- Store line addresses in module state for statuscolumn access
  state.line_addresses = line_addresses
  state.buf_id = buf_id
  
  -- Save original statuscolumn
  if not original_statuscolumn then
    original_statuscolumn = vim.wo.statuscolumn
  end
  
  -- Set custom statuscolumn that shows address or line number
  vim.wo.statuscolumn = [[%!v:lua.require('objdump_mapping.mapper').statuscolumn()]]
end

-- Statuscolumn function - called for each line
function M.statuscolumn()
  local lnum = vim.v.lnum
  local buf_id = vim.api.nvim_get_current_buf()
  
  -- Only show addresses for the buffer we're tracking
  if buf_id == state.buf_id and state.line_addresses and state.line_addresses[lnum] then
    local addr = state.line_addresses[lnum].address
    -- Format to last 7 characters
    if #addr > 7 then
      addr = addr:sub(-7)
    end
    -- Return formatted address with highlight
    return '%#ObjDumpAddr#' .. addr .. ' %*'
  else
    -- Return normal line number
    return '%=%{v:lnum} '
  end
end

-- Clear virtual text from buffer
local function clear_virtual_text(buf_id)
  local ns = init_namespace()
  vim.api.nvim_buf_clear_namespace(buf_id, ns, 0, -1)
  
  -- Restore original statuscolumn
  if original_statuscolumn then
    vim.wo.statuscolumn = original_statuscolumn
  else
    vim.wo.statuscolumn = ''
  end
  
  -- Clear state
  state.line_addresses = {}
end

-- Main enable function
function M.enable()
  local buf_id = vim.api.nvim_get_current_buf()
  state.buf_id = buf_id
  
  -- Check if we have an executable selected
  if not state.current_exe then
    -- Try to find one automatically
    local executables = find_executables()
    if #executables == 0 then
      vim.notify('No executables found in project', vim.log.levels.WARN)
      return
    elseif #executables == 1 then
      state.current_exe = executables[1]
      vim.notify('Using executable: ' .. state.current_exe, vim.log.levels.INFO)
    else
      -- Multiple executables, let user choose
      M.select_executable()
      return
    end
  end
  
  -- Run objdump
  vim.notify('Running objdump on ' .. state.current_exe .. '...', vim.log.levels.INFO)
  local output = run_objdump(state.current_exe)
  
  if #output == 0 then
    vim.notify('objdump returned no output', vim.log.levels.ERROR)
    return
  end
  
  -- Parse objdump output
  state.mappings = parse_objdump(output)
  
  -- Match to source
  state.line_addresses = match_source_to_objdump(buf_id, state.mappings)
  
  -- Apply virtual text
  apply_virtual_text(buf_id, state.line_addresses)
  
  state.enabled = true
  
  -- Start auto-refresh timer (1 minute = 60000ms)
  local config = get_config()
  local interval = config.auto_refresh_interval or 60000
  if not state.auto_refresh_timer then
    M.start_auto_refresh(interval)
  end
  
  local count = 0
  for _ in pairs(state.line_addresses) do count = count + 1 end
  vim.notify(string.format('ObjDump mapping enabled: %d lines mapped', count), vim.log.levels.INFO)
end

-- Disable function
function M.disable()
  -- Stop auto-refresh timer
  M.stop_auto_refresh()
  
  if state.buf_id then
    clear_virtual_text(state.buf_id)
  end
  state.enabled = false
  state.line_addresses = {}
  vim.notify('ObjDump mapping disabled', vim.log.levels.INFO)
end

-- Toggle function
function M.toggle()
  if state.enabled then
    M.disable()
  else
    M.enable()
  end
end

-- Refresh function
function M.refresh()
  if state.enabled then
    M.enable()
  else
    vim.notify('ObjDump mapping not enabled', vim.log.levels.WARN)
  end
end

-- Select executable
function M.select_executable()
  local executables = find_executables()
  
  if #executables == 0 then
    vim.notify('No executables found in project', vim.log.levels.WARN)
    return
  end
  
  vim.ui.select(executables, {
    prompt = 'Select executable for objdump:',
    format_item = function(item)
      -- Show relative path if possible
      local cwd = vim.fn.getcwd()
      if item:sub(1, #cwd) == cwd then
        return item:sub(#cwd + 2)
      end
      return item
    end,
  }, function(choice)
    if choice then
      state.current_exe = choice
      vim.notify('Selected: ' .. choice, vim.log.levels.INFO)
      -- If already enabled, refresh
      if state.enabled or state.buf_id then
        M.enable()
      end
    end
  end)
end

-- Get current state (for debugging)
function M.get_state()
  return state
end

-- Start auto-refresh timer (default: 60 seconds = 1 minute)
function M.start_auto_refresh(interval_ms)
  interval_ms = interval_ms or 60000  -- Default 1 minute
  
  -- Stop existing timer if any
  M.stop_auto_refresh()
  
  -- Create new timer
  state.auto_refresh_timer = vim.loop.new_timer()
  state.auto_refresh_timer:start(interval_ms, interval_ms, vim.schedule_wrap(function()
    if state.enabled and state.current_exe then
      -- Silently refresh without notification spam
      local buf_id = state.buf_id
      if buf_id and vim.api.nvim_buf_is_valid(buf_id) then
        local output = run_objdump(state.current_exe)
        if #output > 0 then
          state.mappings = parse_objdump(output)
          state.line_addresses = match_source_to_objdump(buf_id, state.mappings)
          apply_virtual_text(buf_id, state.line_addresses)
        end
      end
    end
  end))
  
  vim.notify('ObjDump auto-refresh started (every ' .. (interval_ms / 1000) .. 's)', vim.log.levels.INFO)
end

-- Stop auto-refresh timer
function M.stop_auto_refresh()
  if state.auto_refresh_timer then
    state.auto_refresh_timer:stop()
    state.auto_refresh_timer:close()
    state.auto_refresh_timer = nil
    vim.notify('ObjDump auto-refresh stopped', vim.log.levels.INFO)
  end
end

return M
