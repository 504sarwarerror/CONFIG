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

-- Format bytes
local function format_bytes(bytes)
  if bytes >= 1024 then return string.format("%.1fK", bytes / 1024)
  else return tostring(bytes) .. "B" end
end

-- Parse assembly file for stack information
local function parse_assembly(lines)
  local functions = {}
  local current_func = nil
  local line_map = {} -- Map line numbers to LIST of variables accessed
  
  -- Map 32-bit registers to 64-bit parents
  local reg_parents = {
    eax="rax", ax="rax", al="rax",
    ebx="rbx", bx="rbx", bl="rbx",
    ecx="rcx", cx="rcx", cl="rcx",
    edx="rdx", dx="rdx", dl="rdx",
    esi="rsi", si="rsi", sil="rsi",
    edi="rdi", di="rdi", dil="rdi",
    ebp="rbp", bp="rbp", bpl="rbp",
    esp="rsp", sp="rsp", spl="rsp",
    r8d="r8", r8w="r8", r8b="r8",
    r9d="r9", r9w="r9", r9b="r9",
    r10d="r10", r10w="r10", r10b="r10",
    r11d="r11", r11w="r11", r11b="r11",
    r12d="r12", r12w="r12", r12b="r12",
    r13d="r13", r13w="r13", r13b="r13",
    r14d="r14", r14w="r14", r14b="r14",
    r15d="r15", r15w="r15", r15b="r15",
  }

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
        register_map = {}, -- Track which registers point to stack
        register_usage = {}, -- Track all register operations
        access_order = {}, -- Track access order for pattern analysis
        hints = {}, -- Optimization hints
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
      
      -- Track ALL register operations with better context
      
      -- Helper to update register and optionally its parent
      local function update_reg(reg, info)
        if not current_func.register_usage[reg] then
          current_func.register_usage[reg] = {operations = {}, latest = nil}
        end
        
        -- Store in operations array for history
        table.insert(current_func.register_usage[reg].operations, info)
        
        -- Also keep as latest for final state
        current_func.register_usage[reg].latest = info
        
        -- Propagate to parent (e.g. eax -> rax)
        local parent = reg_parents[reg]
        if parent then
          if not current_func.register_usage[parent] then
            current_func.register_usage[parent] = {operations = {}, latest = nil}
          end
          -- Create a copy for the parent
          local parent_info = vim.deepcopy(info)
          table.insert(current_func.register_usage[parent].operations, parent_info)
          current_func.register_usage[parent].latest = parent_info
        end
      end
      
      -- CALL operations - track return value in rax
      -- Case-insensitive match for 'call'
      local call_target = trimmed:match("^[Cc][Aa][Ll][Ll]%s+(.+)")
      if call_target then
        -- Extract just the function name
        -- Handle various formats: func, func(args), [func], etc.
        local func_name = call_target:match("^([%w_@?]+)") -- Basic name
        
        if not func_name then
           -- Try to handle *[name] or similar
           func_name = call_target:match("%*?%[?([%w_@?]+)%]?")
        end
        
        func_name = func_name or call_target
        
        -- Function calls typically return in rax (only track the full register)
        update_reg("rax", {
          type = "call",
          line = i,
          value = func_name,
          display = func_name
        })
      end
      
      -- MOV operations (more robust): allow size prefixes, ptr keywords and memory/register forms
      local mov_full_dest, mov_full_src = trimmed:match("^mov%s+([^,]+),%s*(.+)")
      if mov_full_dest and mov_full_src then
        local function trim(s) return s and s:match("^%s*(.-)%s*$") or s end
        local mov_dest = trim(mov_full_dest)
        local mov_src = trim(mov_full_src)
        local display_value = mov_src
        local value_type = "mov"

        -- Detect stack memory accesses (rbp-relative), allow + or - offsets
        local stack_src = mov_src:match("%[rbp%-(%d+)%]") or mov_src:match("%[rbp%+%s*(%d+)%]")
        local stack_dest = mov_dest:match("%[rbp%-(%d+)%]") or mov_dest:match("%[rbp%+%s*(%d+)%]")

        -- Extract pure register names if the operand is a simple register (e.g., 'rax', 'eax', 'r10d')
        local src_reg = mov_src:match("^(%w+)$")
        local dest_reg = mov_dest:match("^(%w+)$")

        if stack_src then
          display_value = string.format("[rbp-%s]", stack_src)
          value_type = "stack_load"
        elseif src_reg then
          -- Prefer exact register info; if not available, try parent register
          local src_info = current_func.register_usage[src_reg] and current_func.register_usage[src_reg].latest
          if not src_info then
            local parent = reg_parents[src_reg]
            if parent then src_info = current_func.register_usage[parent] and current_func.register_usage[parent].latest end
          end

          if src_info and src_info.type == "call" then
            display_value = src_info.display
            value_type = "call"
          else
            -- If source is a register but not from a call, mark as reg_move
            value_type = "reg_move"
          end
        elseif mov_src:match("^%d+$") or mov_src:match("^0x[%x]+$") then
          value_type = "immediate"
        else
          value_type = "mov"
        end

        -- Update destination register if it's a register
        if dest_reg then
          update_reg(dest_reg, {
            type = value_type,
            line = i,
            value = mov_src,
            display = display_value
          })
        end

        -- If moving RAX (or its subregister) into stack slot, propagate call info to that variable
        if stack_dest then
          local off_num = tonumber(stack_dest)
          -- Ensure variable entry exists
          if not current_func.variables[off_num] then
            current_func.variables[off_num] = {
              offset = off_num,
              type = "unknown",
              usage = {},
              def_line = i,
              reads = {},
              writes = {},
              access_count = 0,
            }
          end
          local var = current_func.variables[off_num]
          table.insert(var.writes, i)
          var.access_count = var.access_count + 1

          -- If source register carries a call result, record the usage
          local src_is_rax = (src_reg == "rax") or (reg_parents[src_reg] == "rax")
          if src_is_rax then
            local rax_info = current_func.register_usage["rax"] and current_func.register_usage["rax"].latest
            if rax_info and rax_info.type == "call" then
              table.insert(var.usage, rax_info.display)
            end
          end
        end
      end
      
      -- LEA operations (register pointing to stack)
      local lea_reg, lea_offset = trimmed:match("lea%s+(%w+),%s*%[rbp%-(%d+)%]")
      if lea_reg and lea_offset then
        current_func.register_map[lea_reg] = tonumber(lea_offset)
        update_reg(lea_reg, {
          type = "lea",
          line = i,
          value = string.format("[rbp-%s]", lea_offset),
          display = string.format("&[rbp-%s]", lea_offset)
        })
      end
      
      -- ADD/SUB operations
      local add_dest, add_src = trimmed:match("add%s+(%w+),%s*(.+)")
      if add_dest and add_src then
        update_reg(add_dest, {
          type = "add",
          line = i,
          value = add_src,
          display = string.format("+%s", add_src)
        })
      end
      
      local sub_dest, sub_src = trimmed:match("sub%s+(%w+),%s*(.+)")
      if sub_dest and sub_src and sub_dest ~= "rsp" then -- Ignore stack allocation
        update_reg(sub_dest, {
          type = "sub",
          line = i,
          value = sub_src,
          display = string.format("-%s", sub_src)
        })
      end
      
      -- Find ALL rbp-relative accesses in the line
      for offset in trimmed:gmatch("%[rbp%-(%d+)%]") do
        local off_num = tonumber(offset)
        
        if not line_map[i] then line_map[i] = {} end
        table.insert(line_map[i], off_num)
        table.insert(current_func.access_order, off_num)
        
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
            access_count = 0,
          }
        end
        
        local var = current_func.variables[off_num]
        var.access_count = var.access_count + 1
        
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
  
  -- Post-process: Check for uninitialized reads and generate hints
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
      
      -- Hint: Single-use variables
      if var.access_count == 1 then
        table.insert(func.hints, {
          type = "single_use",
          offset = offset,
          message = string.format("[rbp-%d] used only once - consider using register", offset)
        })
      end
    end
    
    -- Analyze access patterns
    if #func.access_order > 3 then
      local is_sequential = true
      for i = 2, #func.access_order do
        if math.abs(func.access_order[i] - func.access_order[i-1]) > 64 then
          is_sequential = false
          break
        end
      end
      
      if not is_sequential then
        table.insert(func.hints, {
          type = "random_access",
          message = "Random stack access pattern - may cause cache misses"
        })
      end
    end
    
    -- Hint: Large stack allocation
    if func.stack_size > 4096 then
      table.insert(func.hints, {
        type = "large_stack",
        message = string.format("Large stack (%s) - consider heap allocation", format_bytes(func.stack_size))
      })
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
local function generate_lines(functions, width, active_offsets, cursor_line)
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
    
    -- Enhanced Cursor-Aware Register Tracking Panel (topmost)
    if vim.tbl_count(func.register_usage) > 0 and cursor_line then
      local current_regs = {}
      for reg, usage in pairs(func.register_usage) do
        local current_op = nil
        for _, op in ipairs(usage.operations) do
          if op.line <= cursor_line then
            if not current_op or op.line > current_op.line then
              current_op = op
            end
          end
        end
        if current_op then current_regs[reg] = current_op end
      end

      local final_regs = {}
      for reg, usage in pairs(func.register_usage) do
        if usage.latest then final_regs[reg] = usage.latest end
      end

      local reg_states = {}
      local all_regs = {}
      for reg, _ in pairs(current_regs) do all_regs[reg] = true end
      for reg, _ in pairs(final_regs) do all_regs[reg] = true end

      for reg, _ in pairs(all_regs) do
        local current_info = current_regs[reg]
        local final_info = final_regs[reg]
        local state = { reg = reg, current = current_info, final = final_info, changed = false }
        if current_info and final_info then
          if current_info.line ~= final_info.line or current_info.display ~= final_info.display then state.changed = true end
        elseif not current_info and final_info then
          state.changed = true
        elseif current_info and not final_info then
          state.changed = true
        end
        table.insert(reg_states, state)
      end

      local filtered_states = {}
      local skip_subregs = {}
      for _, state in ipairs(reg_states) do
        local reg = state.reg
        if reg == "rax" then skip_subregs["eax"] = true; skip_subregs["ax"] = true; skip_subregs["al"] = true
        elseif reg == "rbx" then skip_subregs["ebx"] = true; skip_subregs["bx"] = true; skip_subregs["bl"] = true
        elseif reg == "rcx" then skip_subregs["ecx"] = true; skip_subregs["cx"] = true; skip_subregs["cl"] = true
        elseif reg == "rdx" then skip_subregs["edx"] = true; skip_subregs["dx"] = true; skip_subregs["dl"] = true
        elseif reg == "rsi" then skip_subregs["esi"] = true; skip_subregs["si"] = true; skip_subregs["sil"] = true
        elseif reg == "rdi" then skip_subregs["edi"] = true; skip_subregs["di"] = true; skip_subregs["dil"] = true
        elseif reg == "rbp" then skip_subregs["ebp"] = true; skip_subregs["bp"] = true; skip_subregs["bpl"] = true
        elseif reg == "rsp" then skip_subregs["esp"] = true; skip_subregs["sp"] = true; skip_subregs["spl"] = true
        elseif reg:match("^r(%d+)$") then local num = reg:match("^r(%d+)$"); skip_subregs["r" .. num .. "d"] = true; skip_subregs["r" .. num .. "w"] = true; skip_subregs["r" .. num .. "b"] = true end
      end
      for _, state in ipairs(reg_states) do if not skip_subregs[state.reg] then table.insert(filtered_states, state) end end

      if #filtered_states > 0 then
        local reg_order = {rax=1, rbx=2, rcx=3, rdx=4, rsi=5, rdi=6, r8=7, r9=8, r10=9, r11=10, r12=11, r13=12, r14=13, r15=14}
        table.sort(filtered_states, function(a, b)
          local order_a = reg_order[a.reg] or 99
          local order_b = reg_order[b.reg] or 99
          if order_a == order_b then return a.reg < b.reg end
          return order_a < order_b
        end)

        table.insert(lines, string.rep("─", w))
        local header_regs = string.format(" Registers @ Line %d ", cursor_line)
        table.insert(lines, header_regs)
        table.insert(highlights, {line = #lines, col = 0, hl = "Title"})
        table.insert(lines, string.rep("─", w))

        for _, state in ipairs(filtered_states) do
          local reg_line
          if state.current and state.final and state.changed then
            reg_line = string.format(" %s = %s → %s", state.reg, state.current.display, state.final.display)
          elseif state.current and state.final then
            reg_line = string.format(" %s = %s", state.reg, state.current.display)
          elseif not state.current and state.final then
            reg_line = string.format(" %s = (not set) → %s", state.reg, state.final.display)
          elseif state.current and not state.final then
            reg_line = string.format(" %s = %s → (cleared)", state.reg, state.current.display)
          else
            reg_line = string.format(" %s = ?", state.reg)
          end
          if #reg_line > w then reg_line = reg_line:sub(1, w - 3) .. "..." end
          table.insert(lines, reg_line)
          local hl = state.changed and "WarningMsg" or "Number"
          table.insert(highlights, {line = #lines, col = 0, hl = hl})
          if state.current then jump_map[#lines] = state.current.line elseif state.final then jump_map[#lines] = state.final.line end
        end
      end
    end

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
  
  local cursor_line = nil
  if source_win ~= -1 then
    local win_id = vim.fn.win_getid(source_win)
    cursor_line = vim.api.nvim_win_get_cursor(win_id)[1]
  end
  
  local viz_lines, highlights = generate_lines(functions, width, active_offsets, cursor_line)
  
  vim.api.nvim_buf_set_option(stack_buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(stack_buf, 0, -1, false, viz_lines)
  vim.api.nvim_buf_set_option(stack_buf, 'modifiable', false)
  
  local ns_id = vim.api.nvim_create_namespace('stack_viz')
  vim.api.nvim_buf_clear_namespace(stack_buf, ns_id, 0, -1)
  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(stack_buf, ns_id, hl.hl, hl.line - 1, 0, -1)
  end
  
  -- Auto-scroll to active variable in the visualizer window
  if active_offsets and #active_offsets > 0 and stack_win and vim.api.nvim_win_is_valid(stack_win) then
    -- Find the first line that corresponds to an active offset
    for line_num, target_line in pairs(jump_map) do
      if target_line then
        -- Get the line content to check if it's an active variable
        local line_content = viz_lines[line_num]
        if line_content then
          for _, active_off in ipairs(active_offsets) do
            local pattern = "%[rbp%-" .. active_off .. "%]"
            if line_content:match(pattern) then
              -- Found the active variable line
              local current_win = vim.api.nvim_get_current_win()
              vim.api.nvim_set_current_win(stack_win)
              
              -- Only center if the cursor position changed
              local current_cursor = vim.api.nvim_win_get_cursor(stack_win)[1]
              if current_cursor ~= line_num then
                vim.api.nvim_win_set_cursor(stack_win, {line_num, 0})
                vim.cmd('normal! zz') -- Center the line in the window
              end
              
              vim.api.nvim_set_current_win(current_win) -- Return to original window
              return
            end
          end
        end
      end
    end
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
