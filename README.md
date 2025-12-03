# StackVisualization - Assembly Stack Visualizer for Neovim

A powerful Neovim plugin that provides real-time, dynamic visualization of assembly stack layouts with advanced error detection and analysis capabilities.

![License](https://img.shields.io/badge/license-MIT-blue.svg)

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

### Using [lazy.nvim](https://github.com/folke/lazy.nvim) (Recommended)

```lua
{
  '504sarwarerror/StackVisualization',
  config = function()
    require('stack_visualization').setup({
      -- Auto-start visualizer for assembly files
      auto_start = true,
      
      -- Keybindings
      keybindings = {
        toggle = '<leader>sv',
      },
      
      -- File types to activate on
      filetypes = { 'asm', 'nasm' },
    })
  end,
  -- Only load for assembly files
  ft = { 'asm', 'nasm' },
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  '504sarwarerror/StackVisualization',
  config = function()
    require('stack_visualization').setup({
      auto_start = true,
      keybindings = {
        toggle = '<leader>sv',
      },
    })
  end,
  ft = { 'asm', 'nasm' },
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug '504sarwarerror/StackVisualization'
```

Then in your `init.lua` or `init.vim`:

```lua
lua << EOF
require('stack_visualization').setup({
  auto_start = true,
  keybindings = {
    toggle = '<leader>sv',
  },
})
EOF
```

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/504sarwarerror/StackVisualization.git ~/.local/share/nvim/site/pack/plugins/start/StackVisualization

# Or for lazy loading
git clone https://github.com/504sarwarerror/StackVisualization.git ~/.local/share/nvim/site/pack/plugins/opt/StackVisualization
```

Then add to your config:

```lua
require('stack_visualization').setup()
```

## Configuration

### Default Configuration

```lua
require('stack_visualization').setup({
  -- Auto-start visualizer for assembly files
  auto_start = false,
  
  -- Default keybindings
  keybindings = {
    toggle = '<leader>sv',
  },
  
  -- File types to activate on
  filetypes = { 'asm', 'nasm' },
})
```

### Minimal Configuration

```lua
-- Just use defaults
require('stack_visualization').setup()
```

### Custom Keybindings

```lua
require('stack_visualization').setup({
  keybindings = {
    toggle = '<leader>as',  -- Custom toggle key
  },
})

-- Or set up your own keybindings
vim.keymap.set('n', '<F9>', ':StackViz<CR>', { desc = 'Show Stack Visualizer' })
```

## Usage

### Commands

| Command | Description |
|---------|-------------|
| `:StackViz` | Show/toggle the stack visualizer |
| `:StackVizRefresh` | Manually refresh the display |
| `:StackVizJump` | Jump to variable definition in source |
| `:StackVizTooltip` | Show detailed error tooltip |
| `:StackVizAutoReloadStart` | Start auto-reload timer |
| `:StackVizAutoReloadStop` | Stop auto-reload timer |

### Opening the Visualizer

1. **Command**: `:StackViz`
2. **Keybinding**: `<leader>sv` (default, if configured)
3. **Auto-open**: Opens automatically for `.asm`/`.s` files (if `auto_start = true`)

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
 2 OOB @64,128 • 1 Uninit @32
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

## Full Neovim Configuration Example

See [`init.lua`](init.lua) for a complete example Neovim configuration that includes:
- Complete plugin setup with lazy.nvim
- Catppuccin theme with transparency
- Assembly development tools
- Git integration
- File navigation
- And much more!

This serves as a reference for setting up a full assembly development environment.

## API Reference

### Lua API

```lua
-- Show/open the visualizer
require('stack_visualization').show()

-- Manually refresh the display
require('stack_visualization').refresh()

-- Jump to source definition
require('stack_visualization').jump()

-- Show error tooltip
require('stack_visualization').show_tooltip()

-- Start auto-reload timer
require('stack_visualization').start_auto_reload()

-- Stop auto-reload timer
require('stack_visualization').stop_auto_reload()
```

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
- Increase refresh rate in the stack_visualizer module for large files
- Disable auto-reload: `:StackVizAutoReloadStop`

## Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest new features
- Submit pull requests
- Improve documentation

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Credits

Developed for advanced assembly development workflows in Neovim.

---

**Note**: This plugin is designed for x86-64 assembly with standard calling conventions. Support for other architectures and syntaxes (AT&T, ARM, etc.) may be added in the future.
