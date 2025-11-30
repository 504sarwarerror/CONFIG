-- Stack Visualizer for Assembly Code
-- Advanced dynamic stack visualization with Runtime Error Detection

local M = {}
local timer = nil
local source_buf = nil
local stack_buf = nil
local stack_win = nil

-- Module-level map for interactive jump: stack_line -> source_line
local jump_map = {}

-- Configuration
local config = {
  refresh_rate = 5000, -- 5 seconds
  -- Known unsafe functions that can cause buffer overflows
  unsafe_funcs = {
    "strcpy", "lstrcpy", "lstrcpyA", "lstrcpyW",
    "strcat", "lstrcat", "lstrcatA", "lstrcatW",
    "gets", "scanf", "wscanf", "sscanf", "swscanf",
    "sprintf", "wsprintf", "swprintf", "vsprintf", "vswprintf",
    "strncpy", "wcsncpy", "strncat", "wcsncat",
  }
}

-- Helper: Check for unsafe usage (only known dangerous functions)
local function is_unsafe(usage_list)
  for _, u in ipairs(usage_list) do
    local func_lower = u:lower()
    for _, unsafe in ipairs(config.unsafe_funcs) do
      if func_lower:match(unsafe:lower()) then
        return true
      end
    end
  end
  return false
end

-- Helper: Get size from type
local function get_type_size(vtype)
  if vtype == "byte" then return 1
  elseif vtype == "word" then return 2
  elseif vtype == "dword" then return 4
  elseif vtype == "qword" then return 8
  elseif vtype == "string" then return 32 -- Heuristic for strings
  else return 8 end -- Default to qword/pointer size
end

-- Parse assembly file for stack information
local function parse_assembly(lines)
  local functions = {}
  local current_func = nil
  local line_map = {} -- Map line numbers to LIST of variables accessed
  
  for i, line in ipairs(lines) do
    local trimmed = line:match("^%s*(.-)%s*$")
    
    -- Detect function labels
    local func_name = trimmed:match("^([%w_]+):")
    if func_name and not func_name:match("^%.") then
      current_func = {
        name = func_name,
        stack_size = 0,
        variables = {},
        saved_regs = {},
        start_line = i,
        has_calls = false,
        errors = {},
      }
      functions[func_name] = current_func
    end
    
    if current_func then
      current_func.end_line = i
      
      -- Stack allocation (only use the first sub rsp)
      local sub_amt = trimmed:match("sub%s+rsp,%s*(%d+)")
      if sub_amt and current_func.stack_size == 0 then
        current_func.stack_size = tonumber(sub_amt)
      end
      
      -- Track pushed registers
      local push_reg = trimmed:match("push%s+(%w+)")
      if push_reg then
        table.insert(current_func.saved_regs, push_reg)
      end
      
      -- Track calls
      if trimmed:match("call%s+") then
        current_func.has_calls = true
      end
      
      -- Find ALL rbp-relative accesses in the line
      for offset in trimmed:gmatch("%[rbp%-(%d+)%]") do
        local off_num = tonumber(offset)
        
        if not line_map[i] then line_map[i] = {} end
        table.insert(line_map[i], off_num)
        
        -- Check for out-of-bounds access
        if current_func.stack_size > 0 and off_num > current_func.stack_size then
          table.insert(current_func.errors, {
            type = "out_of_bounds",
            line = i,
            offset = off_num,
            message = string.format("Access [rbp-%d] exceeds stack size %d", off_num, current_func.stack_size)
          })
        end
        
        -- Check for return address tampering (accessing above RBP)
        if off_num < 0 or trimmed:match("%[rbp%+%d+%]") then
          table.insert(current_func.errors, {
            type = "return_tamper",
            line = i,
            message = "Accessing above RBP (return address area)"
          })
        end
        
        if not current_func.variables[off_num] then
          current_func.variables[off_num] = {
            offset = off_num,
            type = "unknown",
            usage = {},
            def_line = i,
            reads = {},
            writes = {},
          }
        end
        
        local var = current_func.variables[off_num]
        
        -- Track reads vs writes
        if trimmed:match("mov%s+[^,]+,%s*%[rbp%-" .. off_num .. "%]") or
           trimmed:match("lea%s+[^,]+,%s*%[rbp%-" .. off_num .. "%]") then
          table.insert(var.reads, i)
        end
        if trimmed:match("mov%s+%[rbp%-" .. off_num .. "%]") then
          table.insert(var.writes, i)
        end
        
        -- Detect type
        if trimmed:match("mov%s+byte") then var.type = "byte"
        elseif trimmed:match("mov%s+word") then var.type = "word"
        elseif trimmed:match("mov%s+dword") then var.type = "dword"
        elseif trimmed:match("mov%s+qword") or trimmed:match("lea") then var.type = "qword"
        end
        
        -- Track usage
        local func_call = trimmed:match("call%s+([%w_]+)")
        if func_call and not vim.tbl_contains(var.usage, func_call) then
          table.insert(var.usage, func_call)
        end
        
        -- Detect string operations
        if trimmed:match("lstrcpy") or trimmed:match("lstrcat") then
          var.type = "string"
        end
      end
    end
  end
  
  -- Post-process: Check for uninitialized reads
  for fname, func in pairs(functions) do
    for offset, var in pairs(func.variables) do
      if #var.reads > 0 and #var.writes == 0 then
        table.insert(func.errors, {
          type = "uninitialized",
          offset = offset,
          line = var.reads[1],
          message = string.format("[rbp-%d] read before write", offset)
        })
      end
    end
  end
  
  return functions, line_map
end

-- Calculate variable ranges with Gaps
local function calculate_ranges(variables, total_stack, errors)
  local sorted = {}
  for _, v in pairs(variables) do
    table.insert(sorted, v)
  end
  table.sort(sorted, function(a, b) return a.offset < b.offset end)
  
  -- Build error lookup by offset
  local error_by_offset = {}
  for _, err in ipairs(errors or {}) do
    if err.offset then
      if not error_by_offset[err.offset] then
        error_by_offset[err.offset] = {}
      end
      table.insert(error_by_offset[err.offset], err)
    end
  end
  
  local ranges = {}
  for i, var in ipairs(sorted) do
    local next_offset = sorted[i + 1] and sorted[i + 1].offset or total_stack
    local space_available = next_offset - var.offset
    local type_size = get_type_size(var.type)
    
    -- Check for out of bounds
    local is_oob = false
    local var_errors = error_by_offset[var.offset] or {}
    for _, err in ipairs(var_errors) do
      if err.type == "out_of_bounds" then
        is_oob = true
        break
      end
    end
    
    -- Variable Entry
    table.insert(ranges, {
      kind = "var",
      offset = var.offset,
      size = type_size,
      vtype = var.type,
      usage = var.usage,
      def_line = var.def_line,
      unsafe = is_unsafe(var.usage),
      uninitialized = (#var.reads > 0 and #var.writes == 0),
      out_of_bounds = is_oob,
      errors = var_errors,
    })
    
    -- Gap Entry
    if space_available > type_size then
      table.insert(ranges, {
        kind = "gap",
        offset = var.offset + type_size,
        size = space_available - type_size,
      })
    end
  end
  
  return ranges
end

-- Get color based on error type and size
local function get_color(item, is_active)
  if item.kind == "gap" then return "Comment" end
  if is_active then return "Search" end
  
  -- Different colors for different error types
  if item.out_of_bounds then return "ErrorMsg" end -- Red
  if item.uninitialized then return "WarningMsg" end -- Yellow/Orange
  if item.unsafe then return "DiagnosticError" end -- Bright Red
  
  local size = item.size
  if size >= 1024 then return "ErrorMsg"
  elseif size >= 512 then return "WarningMsg"
  elseif size >= 64 then return "String"
  elseif size >= 8 then return "Number"
  else return "Comment" end
end

-- Format bytes
local function format_bytes(bytes)
  if bytes >= 1024 then return string.format("%.1fK", bytes / 1024)
  else return tostring(bytes) .. "B" end
end

-- Calculate cell height
local function calc_height(size, max_size, num_info_lines)
  -- Base height on number of info lines to ensure everything is visible
  local min_height = num_info_lines
  
  -- Add scaling based on size for visual emphasis
  local ratio = size / max_size
  local scaled_height = math.floor(num_info_lines + ratio * 3)
  
  return math.max(min_height, math.min(scaled_height, 8))
end

-- Generate stack visualization lines
local function generate_lines(functions, width, active_offsets)
  local lines = {}
  local highlights = {}
  local w = math.max(40, width)
  jump_map = {} -- Reset jump map
  
  -- Helper to check if offset is active
  local function is_active_offset(offset)
    if not active_offsets then return false end
    for _, off in ipairs(active_offsets) do
      if off == offset then return true end
    end
    return false
  end
  
  for fname, func in pairs(functions) do
    if func.stack_size == 0 then goto continue end
    
    local ranges = calculate_ranges(func.variables, func.stack_size, func.errors)
    if #ranges == 0 then goto continue end
    
    -- Stats
    local used_bytes = 0
    for _, r in ipairs(ranges) do if r.kind == "var" then used_bytes = used_bytes + r.size end end
    local efficiency = (used_bytes / func.stack_size) * 100
    
    -- Find max size for scaling
    local max_size = 0
    for _, r in ipairs(ranges) do
      if r.size > max_size then max_size = r.size end
    end
    
    -- Function Header
    local header = string.format(" %s • %s (%.0f%%) ", fname, format_bytes(func.stack_size), efficiency)
    local pad = math.floor((w - #header) / 2)
    
    table.insert(lines, string.rep("─", w))
    table.insert(lines, string.rep(" ", pad) .. header)
    table.insert(highlights, {line = #lines, col = 0, hl = "Function"})
    
    -- Error Summary with Details
    if #func.errors > 0 then
      local error_counts = {
        out_of_bounds = {},
        uninitialized = {},
        return_tamper = 0
      }
      
      -- Collect unique offsets
      for _, err in ipairs(func.errors) do
        if err.type == "return_tamper" then
          error_counts.return_tamper = error_counts.return_tamper + 1
        elseif err.offset then
          if not error_counts[err.type][err.offset] then
            error_counts[err.type][err.offset] = true
          end
        end
      end
      
      -- Build compact error message
      local error_parts = {}
      
      local oob_count = vim.tbl_count(error_counts.out_of_bounds)
      if oob_count > 0 then 
        local offsets = {}
        for offset, _ in pairs(error_counts.out_of_bounds) do
          table.insert(offsets, offset)
        end
        table.sort(offsets)
        local offset_str = table.concat(vim.tbl_map(function(o) return tostring(o) end, offsets), ",")
        table.insert(error_parts, string.format("%d OOB @%s", oob_count, offset_str))
      end
      
      local uninit_count = vim.tbl_count(error_counts.uninitialized)
      if uninit_count > 0 then 
        local offsets = {}
        for offset, _ in pairs(error_counts.uninitialized) do
          table.insert(offsets, offset)
        end
        table.sort(offsets)
        local offset_str = table.concat(vim.tbl_map(function(o) return tostring(o) end, offsets), ",")
        table.insert(error_parts, string.format("%d Uninit @%s", uninit_count, offset_str))
      end
      
      if error_counts.return_tamper > 0 then 
        table.insert(error_parts, error_counts.return_tamper .. " RetAddr")
      end
      
      local error_msg = " ⚠ " .. table.concat(error_parts, " • ") .. " "
      local pad_e = math.floor((w - #error_msg) / 2)
      table.insert(lines, string.rep(" ", pad_e) .. error_msg)
      table.insert(highlights, {line = #lines, col = 0, hl = "ErrorMsg"})
    end
    
    -- Alignment Check
    local total_pushed = 8 + (#func.saved_regs * 8) + func.stack_size
    if total_pushed % 16 ~= 0 then
      local warning = " ⚠ MISALIGNED "
      local pad_w = math.floor((w - #warning) / 2)
      table.insert(lines, string.rep(" ", pad_w) .. warning)
      table.insert(highlights, {line = #lines, col = 0, hl = "ErrorMsg"})
    end
    
    -- Return Address
    table.insert(lines, string.rep("─", w))
    table.insert(lines, " Return Address (8B)")
    table.insert(highlights, {line = #lines, col = 0, hl = "Comment"})
    
    -- Saved Registers
    if #func.saved_regs > 0 then
      table.insert(lines, string.rep("─", w))
      for _, reg in ipairs(func.saved_regs) do
        local reg_info = string.format(" Saved %s (8B)", reg)
        table.insert(lines, reg_info)
        table.insert(highlights, {line = #lines, col = 0, hl = "Special"})
      end
    end
    
    -- RBP Marker
    table.insert(lines, string.rep("─", w))
    table.insert(lines, " RBP (Base Pointer)")
    table.insert(highlights, {line = #lines, col = 0, hl = "Keyword"})
    
    -- Stack Variables & Gaps
    for i, r in ipairs(ranges) do
      table.insert(lines, string.rep("─", w))
      
      local info_lines = {}
      local is_active = false
      
      if r.kind == "var" then
        is_active = is_active_offset(r.offset)
        local offset_str = string.format("[rbp-%d]", r.offset)
        local size_str = format_bytes(r.size)
        local type_str = r.vtype ~= "unknown" and r.vtype or ""
        
        table.insert(info_lines, string.format("%s • %s", offset_str, size_str))
        if type_str ~= "" then table.insert(info_lines, type_str) end
        
        -- Show specific error types with distinct markers (no emojis)
        if r.out_of_bounds then 
          table.insert(info_lines, "[!] Out of Bounds") 
        end
        if r.uninitialized then 
          table.insert(info_lines, "[!] Uninitialized") 
        end
        if r.unsafe then 
          table.insert(info_lines, "[!] Unsafe Usage") 
        end
        
        if is_active then table.insert(info_lines, "◄ ACTIVE") end
        if #r.usage > 0 then
          local usage = "→ " .. table.concat(r.usage, ", ")
          if #usage > w - 4 then usage = usage:sub(1, w - 7) .. "..." end
          table.insert(info_lines, usage)
        end
      else
        -- Gap
        table.insert(info_lines, "GAP")
        table.insert(info_lines, format_bytes(r.size))
      end
      
      local height = calc_height(r.size, max_size, #info_lines)
      
      -- Render cell
      local start_line = math.floor((height - #info_lines) / 2)
      for h = 1, height do
        local info_idx = h - start_line
        local content = ""
        if info_idx >= 1 and info_idx <= #info_lines then
          content = info_lines[info_idx]
        end
        
        local pad_left = math.floor((w - #content) / 2)
        local line = string.rep(" ", pad_left) .. content
        table.insert(lines, line)
        table.insert(highlights, {line = #lines, col = 0, hl = get_color(r, is_active)})
        
        -- Map line to source for jump
        if r.kind == "var" and r.def_line then
          jump_map[#lines] = r.def_line
        end
      end
    end
    
    -- RSP Marker
    table.insert(lines, string.rep("─", w))
    table.insert(lines, " RSP (Stack Pointer)")
    table.insert(highlights, {line = #lines, col = 0, hl = "Keyword"})
    
    table.insert(lines, string.rep("─", w))
    table.insert(lines, "")
    
    ::continue::
  end
  
  return lines, highlights
end

-- Jump to source definition
function M.jump()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  local target_line = jump_map[cursor_line]
  
  if target_line and source_buf and vim.api.nvim_buf_is_valid(source_buf) then
    local win_id = vim.fn.bufwinnr(source_buf)
    if win_id ~= -1 then
      vim.cmd(win_id .. 'wincmd w')
      vim.api.nvim_win_set_cursor(0, {target_line, 0})
      vim.cmd('normal! zz') -- Center view
    end
  else
    vim.notify("No source link for this cell", vim.log.levels.INFO)
  end
end

-- Refresh the visualization
function M.refresh()
  if not stack_buf or not vim.api.nvim_buf_is_valid(stack_buf) then return end
  if not source_buf or not vim.api.nvim_buf_is_valid(source_buf) then return end
  
  local width = 40
  if stack_win and vim.api.nvim_win_is_valid(stack_win) then
    width = vim.api.nvim_win_get_width(stack_win)
  end
  
  local lines = vim.api.nvim_buf_get_lines(source_buf, 0, -1, false)
  local functions, line_map = parse_assembly(lines)
  
  if vim.tbl_count(functions) == 0 then return end
  
  local source_win = vim.fn.bufwinnr(source_buf)
  local active_offsets = nil
  if source_win ~= -1 then
    local win_id = vim.fn.win_getid(source_win)
    local cursor_line = vim.api.nvim_win_get_cursor(win_id)[1]
    active_offsets = line_map[cursor_line]
  end
  
  local viz_lines, highlights = generate_lines(functions, width, active_offsets)
  
  vim.api.nvim_buf_set_option(stack_buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(stack_buf, 0, -1, false, viz_lines)
  vim.api.nvim_buf_set_option(stack_buf, 'modifiable', false)
  
  local ns_id = vim.api.nvim_create_namespace('stack_viz')
  vim.api.nvim_buf_clear_namespace(stack_buf, ns_id, 0, -1)
  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(stack_buf, ns_id, hl.hl, hl.line - 1, 0, -1)
  end
end

-- Show tooltip with detailed error information
function M.show_tooltip()
  if not stack_buf or not vim.api.nvim_buf_is_valid(stack_buf) then return end
  
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
  
  -- Clear previous tooltips
  local ns_id = vim.api.nvim_create_namespace('stack_viz_tooltip')
  vim.api.nvim_buf_clear_namespace(stack_buf, ns_id, 0, -1)
  
  local target_line = jump_map[cursor_line]
  if not target_line or not source_buf or not vim.api.nvim_buf_is_valid(source_buf) then
    return
  end
  
  -- Get the line content to find errors
  local lines = vim.api.nvim_buf_get_lines(source_buf, 0, -1, false)
  local functions, _ = parse_assembly(lines)
  
  -- Find errors for this line
  local error_msgs = {}
  for _, func in pairs(functions) do
    for _, err in ipairs(func.errors) do
      if err.line == target_line then
        table.insert(error_msgs, err.message)
      end
    end
  end
  
  if #error_msgs > 0 then
    -- Show as virtual text with better formatting
    for i, msg in ipairs(error_msgs) do
      vim.api.nvim_buf_set_extmark(stack_buf, ns_id, cursor_line - 1, 0, {
        virt_text = {{" 💡 " .. msg, "DiagnosticInfo"}},
        virt_text_pos = "eol",
        priority = 100,
      })
    end
  end
end

-- Open or update visualization
function M.show()
  local current_buf = vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(current_buf)
  
  if filename:match("%.asm$") or filename:match("%.s$") then
    source_buf = current_buf
  end
  
  if not source_buf then
    vim.notify("No assembly file selected", vim.log.levels.WARN)
    return
  end
  
  if not stack_win or not vim.api.nvim_win_is_valid(stack_win) then
    vim.cmd('vsplit')
    stack_win = vim.api.nvim_get_current_win()
    
    if not stack_buf or not vim.api.nvim_buf_is_valid(stack_buf) then
      stack_buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_option(stack_buf, 'buftype', 'nofile')
      vim.api.nvim_buf_set_option(stack_buf, 'bufhidden', 'hide')
      vim.api.nvim_buf_set_option(stack_buf, 'swapfile', false)
      vim.api.nvim_buf_set_name(stack_buf, 'Stack Visualizer')
      
      -- Keybindings
      vim.api.nvim_buf_set_keymap(stack_buf, 'n', 'q', ':q<CR>', {noremap = true, silent = true})
      vim.keymap.set('n', '<CR>', function() M.jump() end, { buffer = stack_buf, noremap = true, silent = true })
      vim.keymap.set('n', 'K', function() M.show_tooltip() end, { buffer = stack_buf, noremap = true, silent = true, desc = 'Show error details' })
    end
    
    vim.api.nvim_win_set_buf(stack_win, stack_buf)
    vim.api.nvim_win_set_option(stack_win, 'number', false)
    vim.api.nvim_win_set_option(stack_win, 'relativenumber', false)
    vim.api.nvim_win_set_option(stack_win, 'wrap', false)
    vim.api.nvim_win_set_width(stack_win, 50)
    
    -- Set faster updatetime for quicker tooltips
    vim.api.nvim_win_set_option(stack_win, 'updatetime', 500)
    
    vim.api.nvim_create_autocmd("WinResized", {
      buffer = stack_buf,
      callback = function() M.refresh() end,
    })
    
    vim.api.nvim_create_autocmd({"CursorMoved", "CursorMovedI"}, {
      buffer = source_buf,
      callback = function() M.refresh() end,
    })
    
    -- Add hover tooltip on cursor hold
    vim.api.nvim_create_autocmd("CursorHold", {
      buffer = stack_buf,
      callback = function() M.show_tooltip() end,
    })
  end
  
  M.refresh()
end

-- Auto-reload
function M.start_auto_reload()
  if timer then timer:stop() end
  timer = vim.loop.new_timer()
  timer:start(0, config.refresh_rate, vim.schedule_wrap(function()
    if stack_win and vim.api.nvim_win_is_valid(stack_win) then
      M.refresh()
    end
  end))
end

function M.stop_auto_reload()
  if timer then timer:stop() timer = nil end
end

return M
