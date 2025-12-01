Neovim plugin that provides real-time, dynamic visualization of assembly stack layouts with advanced error detection and analysis capabilities.
## Features

### Core Functionality
- **Real-time Stack Visualization**: Automatically parses assembly code and displays stack layout
- **Dynamic Updates**: Highlights active stack variables as you move through code
- **Interactive Navigation**: Jump from visualizer to source code with `<CR>`
- **Error Detection**: Identifies common assembly programming errors

### Advanced Analysis
- **Out-of-Bounds Detection**: Catches stack accesses beyond allocated space
- **Uninitialized Variable Detection**: Warns when reading before writing
- **Unsafe Function Detection**: Identifies dangerous functions like `strcpy`, `gets`, etc.
- **Return Address Tampering Detection**: Alerts when accessing above RBP
- **Stack Alignment Checking**: Verifies 16-byte alignment requirements

### Visualization Features
- **Color-Coded Display**: Different colors for errors, warnings, and normal variables
- **Size-Based Scaling**: Visual cell height reflects variable size
- **Register Tracking**: Shows current register values and stack pointers
- **Gap Detection**: Identifies unused stack space
- **Efficiency Metrics**: Displays stack usage percentage

### Optimization Hints
- **Single-Use Variables**: Suggests using registers instead of stack
- **Random Access Patterns**: Warns about potential cache misses
- **Large Stack Allocations**: Recommends heap allocation for large buffers

## Installation

### Prerequisites
- Neovim 0.7+ (for Lua API support)
- Assembly files with `.asm` or `.s` extension

### Step 1: Copy the Module

```bash
# Create the lua directory if it doesn't exist
mkdir -p ~/.config/nvim/lua

# Copy the stack visualizer module
cp stack_visualizer.lua ~/.config/nvim/lua/
```

### Step 2: Configure Neovim

Add the following to your `~/.config/nvim/init.lua`:

```lua
-- Stack Visualizer for Assembly Development
vim.api.nvim_create_user_command('StackViz', function()
  require('stack_visualizer').show()
end, {})

-- Optional: Add keybindings
vim.keymap.set('n', '<leader>sv', ':StackViz<CR>', { 
  noremap = true, 
  silent = true, 
  desc = 'Show Stack Visualization' 
})

-- Optional: Auto-start for assembly files
vim.api.nvim_create_autocmd('FileType', {
  pattern = {'asm', 'nasm'},
  callback = function()
    require('stack_visualizer').show()
  end,
})
```

### Step 3: Reload Configuration

```vim
:source ~/.config/nvim/init.lua
```

Or restart Neovim.

## Usage

### Opening the Visualizer

1. **Command**: `:StackViz`
2. **Keybinding**: `<leader>sv` (if configured)
3. **Auto-open**: Opens automatically for `.asm`/`.s` files (if configured)

### Navigation

| Key | Action |
|-----|--------|
| `<CR>` | Jump to variable definition in source code |
| `K` | Show detailed error tooltip |
| `q` | Close visualizer window |

### Understanding the Display

```
────────────────────────────────────────────
         main • 512B (75%)
 ⚠ 2 OOB @64,128 • 1 Uninit @32
────────────────────────────────────────────
 Return Address (8B)
────────────────────────────────────────────
 Saved rbx (8B)
────────────────────────────────────────────
 rcx = &[rbp-64]
 rdx = 100
────────────────────────────────────────────
 RBP (Base Pointer)
────────────────────────────────────────────
[rbp-32] • 32B
string
[!] Uninitialized
→ lstrcpy
────────────────────────────────────────────
GAP
16B
────────────────────────────────────────────
[rbp-64] • 8B ◄ ACTIVE
qword
────────────────────────────────────────────
 RSP (Stack Pointer)
────────────────────────────────────────────
```

### Color Coding

- **Red (ErrorMsg)**: Out-of-bounds access or critical errors
- **Yellow/Orange (WarningMsg)**: Uninitialized variables or large allocations
- **Bright Red (DiagnosticError)**: Unsafe function usage
- **Blue (String)**: Medium-sized variables (64-512 bytes)
- **Green (Number)**: Small variables (8-64 bytes)
- **Gray (Comment)**: Gaps and metadata
- **Yellow (Search)**: Currently active variable

## Configuration

### Adjusting Refresh Rate

```lua
-- In stack_visualizer.lua, modify the config table:
local config = {
  refresh_rate = 5000, -- milliseconds (default: 5000)
  unsafe_funcs = {
    -- Add or remove unsafe functions
    "strcpy", "gets", "scanf", -- etc.
  }
}
```

### Customizing Window Size

The visualizer window opens at 50 columns wide by default. Resize it manually or modify:

```lua
-- In stack_visualizer.lua, line ~780:
vim.api.nvim_win_set_width(stack_win, 50) -- Change to desired width
```

### Adding Custom Unsafe Functions

Edit the `unsafe_funcs` table in `stack_visualizer.lua`:

```lua
unsafe_funcs = {
  "strcpy", "lstrcpy", "lstrcpyA", "lstrcpyW",
  "strcat", "lstrcat", "lstrcatA", "lstrcatW",
  "gets", "scanf", "wscanf", "sscanf", "swscanf",
  "sprintf", "wsprintf", "swprintf", "vsprintf", "vswprintf",
  "strncpy", "wcsncpy", "strncat", "wcsncat",
  -- Add your custom functions here
  "my_unsafe_function",
}
```

## Error Detection Details

### Out-of-Bounds Access
Detects when code accesses stack memory beyond the allocated `sub rsp, N` size:

```asm
sub rsp, 32        ; Allocate 32 bytes
mov rax, [rbp-64]  ; ERROR: Access beyond 32 bytes
```

### Uninitialized Variables
Warns when reading from stack locations before writing:

```asm
mov rax, [rbp-8]   ; ERROR: Read before write
mov [rbp-8], 100   ; Should write first
```

### Return Address Tampering
Detects dangerous accesses above RBP:

```asm
mov rax, [rbp+8]   ; WARNING: Accessing return address area
```

### Unsafe Functions
Identifies buffer overflow-prone functions:

```asm
lea rcx, [rbp-32]
call lstrcpy       ; WARNING: Unsafe function
```

## Advanced Features

### Register Tracking

The visualizer tracks all register operations and displays:
- Current register values
- Stack pointers (registers pointing to stack locations)
- Loaded values from stack

### Optimization Hints

Automatically suggests optimizations:
- **Single-use variables**: Use registers instead
- **Random access patterns**: Reorganize for cache efficiency
- **Large allocations**: Consider heap instead of stack

### Interactive Tooltips

Hover over any stack variable and press `K` to see:
- Detailed error messages
- Line numbers of problematic code
- Suggested fixes

## Troubleshooting

### Visualizer Not Updating
- Ensure you're in an assembly file (`.asm` or `.s`)
- Check that the file contains valid function labels (e.g., `main:`)
- Verify stack allocation with `sub rsp, N`

### No Errors Detected
- The visualizer only detects errors it can statically analyze
- Some runtime errors may not be visible
- Ensure your assembly follows standard conventions (RBP-based addressing)

### Performance Issues
- Increase `refresh_rate` in config for large files
- Disable auto-reload: `require('stack_visualizer').stop_auto_reload()`

## Examples

### Basic Stack Frame

```asm
main:
    push rbp
    mov rbp, rsp
    sub rsp, 32          ; Allocate 32 bytes
    
    mov qword [rbp-8], 100    ; Local variable
    mov rax, [rbp-8]          ; Read it back
    
    add rsp, 32
    pop rbp
    ret
```

### Detected Error Example

```asm
main:
    push rbp
    mov rbp, rsp
    sub rsp, 16          ; Only 16 bytes allocated
    
    lea rcx, [rbp-32]    ; ERROR: Out of bounds!
    call lstrcpy         ; WARNING: Unsafe function!
    
    add rsp, 16
    pop rbp
    ret
```

## API Reference

### Functions

```lua
-- Show/open the visualizer
require('stack_visualizer').show()

-- Manually refresh the display
require('stack_visualizer').refresh()

-- Jump to source definition
require('stack_visualizer').jump()

-- Show error tooltip
require('stack_visualizer').show_tooltip()

-- Start auto-reload timer
require('stack_visualizer').start_auto_reload()

-- Stop auto-reload timer
require('stack_visualizer').stop_auto_reload()
```

## Contributing

Feel free to extend the visualizer with:
- Additional error detection patterns
- Support for other assembly syntaxes (AT&T, ARM, etc.)
- Custom visualization themes
- Integration with debuggers

## License

This plugin is provided as-is for educational and development purposes.

## Credits

Developed for advanced assembly development workflows in Neovim.
