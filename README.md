# erun.nvim

A lightweight command runner panel for Neovim. Run shell commands asynchronously and browse their output in a dedicated split with clickable file links.

## Features

- Run any shell command asynchronously from within Neovim
- Output displayed in a persistent bottom panel with syntax highlighting
- **Clickable file links** -- jump to file references in command output from [20+ languages and tools](#supported-file-link-formats) (compiler errors, test failures, grep results, etc.)
- Smart tab completion for executables and file paths (shell-operator aware)
- Elapsed time tracking with formatted duration
- Distinct highlighting for stdout, stderr, success, and failure
- Fully configurable panel size, position, and keymaps

## Requirements

- Neovim >= 0.8

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "kotsmile/erun.nvim",
  config = function()
    require("erun").setup()
  end,
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "kotsmile/erun.nvim",
  config = function()
    require("erun").setup()
  end,
}
```

### [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'kotsmile/erun.nvim'
```

```lua
require("erun").setup()
```

## Configuration

Call `setup()` with an optional table to override defaults:

```lua
require("erun").setup({
  -- Height of the output panel in lines
  size = 30,

  -- Split position: "belowright", "aboveleft", "botright", "topleft"
  position = "belowright",

  -- Global keymap to trigger run (set to false to disable)
  keymap = "<leader>r",

  -- Clear panel output before each run
  clear_env = true,

  -- Focus the panel window when it opens
  focus_panel = false,

  -- Buffer-local keymaps inside the output panel
  -- Set any key to false to disable it
  panel_keymaps = {
    open_file = "gf",      -- jump to file link under cursor
    open_file_cr = "<CR>",  -- same as above, on Enter
    close = "q",            -- close the panel
    rerun = "r",            -- rerun the last command
  },
})
```

### Default values

All options shown above are the defaults. Calling `require("erun").setup()` with no arguments uses these values as-is.

## Usage

### Commands

| Command | Description |
|---|---|
| `:Erun <cmd>` | Set and run a shell command. Supports tab completion. |

### Keymaps

| Key | Mode | Description |
|---|---|---|
| `<leader>r` | Normal | Run the stored command, or prompt for one if none is set |

### Panel keymaps (inside the output panel)

| Key | Description |
|---|---|
| `gf` | Jump to the file link under the cursor |
| `<CR>` | Jump to the file link under the cursor |
| `q` | Close the panel |
| `r` | Rerun the last command |

### Lua API

```lua
local erun = require("erun")

-- Run with the stored command (prompts if none set)
erun.run()

-- Run a specific command
erun.run({ cmd = "make test" })

-- Set a command without running it
erun.set_cmd("cargo build")

-- Stop the currently running job
erun.stop()

-- Toggle the output panel open/closed
erun.toggle()

-- Close the output panel
erun.close()
```

## Output Panel Examples

Below is what the erun output panel looks like for different scenarios. Lines are color-coded by highlight group (shown in comments on the right).

### Successful build (`make`)

```
-*- directory: "/home/user/myproject/" -*-                 # ERunModeLine (dimmed)
Started at Wed Mar 05 14:32:10                             # ERunStarted  (blue)

$ make -j8                                                 # ERunCmd      (bold)
gcc -Wall -O2 -c src/main.c -o build/main.o               # ERunStdout
gcc -Wall -O2 -c src/utils.c -o build/utils.o             # ERunStdout
gcc -o build/app build/main.o build/utils.o                # ERunStdout

Finished at Wed Mar 05 14:32:12 (elapsed 1.84s)           # ERunFinished (green)
```

### Failed C compilation (`gcc`)

```
-*- directory: "/home/user/myproject/" -*-                 # ERunModeLine
Started at Wed Mar 05 14:35:01                             # ERunStarted

$ gcc -Wall -o app src/main.c                              # ERunCmd
src/main.c:10:5: error: use of undeclared identifier 'x'  # ERunStderr (red), file link underlined
src/main.c:14:12: warning: unused variable 'y'            # ERunStderr (red), file link underlined

Exited abnormally with code 1 at Wed Mar 05 14:35:01 (elapsed 0.23s)  # ERunFailed (red)
```

Press `gf` on `src/main.c:10:5` to jump to line 10, column 5 in `src/main.c`.

### Python traceback (`pytest`)

```
-*- directory: "/home/user/webapp/" -*-                    # ERunModeLine
Started at Wed Mar 05 15:10:44                             # ERunStarted

$ pytest tests/ -v                                         # ERunCmd
tests/test_auth.py::test_login PASSED                      # ERunStdout
tests/test_auth.py::test_signup FAILED                     # ERunStdout
                                                           #
FAILURES                                                   # ERunStderr
    def test_signup():                                     # ERunStderr
>       assert create_user("") is not None                 # ERunStderr
E       AssertionError: assert None is not None            # ERunStderr
                                                           #
Traceback (most recent call last):                         # ERunStderr
  File "tests/test_auth.py", line 23, in test_signup      # ERunStderr, file link underlined
    assert create_user("") is not None                     # ERunStderr
  File "src/auth.py", line 45, in create_user             # ERunStderr, file link underlined
    raise ValueError("empty username")                     # ERunStderr

Exited abnormally with code 1 at Wed Mar 05 15:10:46 (elapsed 2.31s)  # ERunFailed
```

Press `gf` on `File "tests/test_auth.py", line 23` to jump directly to the failing test.

### Rust compilation (`cargo build`)

```
-*- directory: "/home/user/rustapp/" -*-                   # ERunModeLine
Started at Wed Mar 05 16:00:33                             # ERunStarted

$ cargo build                                              # ERunCmd
   Compiling rustapp v0.1.0 (/home/user/rustapp)          # ERunStdout
error[E0425]: cannot find value `x` in this scope          # ERunStderr
 --> src/main.rs:4:13                                      # ERunStderr, file link underlined
  |                                                        # ERunStderr
4 |     let y = x + 1;                                     # ERunStderr
  |             ^ not found in this scope                  # ERunStderr

Exited abnormally with code 101 at Wed Mar 05 16:00:35 (elapsed 1.52s)  # ERunFailed
```

### Node.js error (stack trace)

```
-*- directory: "/home/user/webapp/" -*-                    # ERunModeLine
Started at Wed Mar 05 17:22:05                             # ERunStarted

$ node src/server.js                                       # ERunCmd
Server starting on port 3000                               # ERunStdout
TypeError: Cannot read properties of undefined             # ERunStderr
    at processRequest (/home/user/webapp/src/handler.js:42:18)   # ERunStderr, file link underlined
    at Server.<anonymous> (/home/user/webapp/src/server.js:15:5) # ERunStderr, file link underlined

Exited abnormally with code 1 at Wed Mar 05 17:22:05 (elapsed 0.34s)  # ERunFailed
```

### Successful test run

```
-*- directory: "/home/user/goapp/" -*-                     # ERunModeLine
Started at Wed Mar 05 18:05:12                             # ERunStarted

$ go test ./...                                            # ERunCmd
ok      goapp/pkg/utils    0.003s                          # ERunStdout
ok      goapp/pkg/handler  0.012s                          # ERunStdout
ok      goapp/cmd/server   0.008s                          # ERunStdout

Finished at Wed Mar 05 18:05:12 (elapsed 0.45s)           # ERunFinished (green)
```

### grep / ripgrep search

```
-*- directory: "/home/user/project/" -*-                   # ERunModeLine
Started at Wed Mar 05 19:00:01                             # ERunStarted

$ rg "TODO" --vimgrep                                      # ERunCmd
src/main.rs:12:5:    // TODO: handle error case            # ERunStdout, file link underlined
src/lib.rs:87:1:     // TODO: add tests                    # ERunStdout, file link underlined
README.md:34:3:      - TODO: document API                  # ERunStdout, file link underlined

Finished at Wed Mar 05 19:00:01 (elapsed 0.05s)           # ERunFinished
```

## Examples

### Run a build command

```vim
:Erun make -j8
```

### Run tests and jump to failures

```vim
:Erun pytest -v
```

Navigate to the output panel and press `gf` or `<CR>` on any line containing a file reference to jump directly there. Works with Python tracebacks, gcc errors, cargo output, and [many more](#supported-file-link-formats).

### Use with a project-specific command

```lua
-- In your project-local config or after/ftplugin
vim.keymap.set("n", "<leader>rb", function()
  require("erun").run({ cmd = "npm run build" })
end, { desc = "Build project" })

vim.keymap.set("n", "<leader>rt", function()
  require("erun").run({ cmd = "npm test" })
end, { desc = "Run tests" })
```

### Lazy-load with lazy.nvim

```lua
{
  "kotsmile/erun.nvim",
  cmd = "Erun",
  keys = {
    { "<leader>r", function() require("erun").run() end, desc = "erun: run command" },
    { "<leader>rt", function() require("erun").toggle() end, desc = "erun: toggle panel" },
  },
  opts = {
    size = 20,
    keymap = false, -- we define our own keys above
  },
}
```

## Supported File Link Formats

erun.nvim automatically detects and makes clickable file references from many languages and tools. Press `gf` or `<CR>` on any highlighted link in the output panel to jump to that location.

| Format | Languages / Tools | Example |
|---|---|---|
| `File "path", line N` | Python | `File "app.py", line 12, in main` |
| `--> file:line:col` | Rust (cargo/rustc) | `--> src/main.rs:4:13` |
| `file(line,col)` | C#, MSBuild, VB.NET | `Program.cs(12,5): error CS1002` |
| `at Class.method(File:line)` | Java, Kotlin, Scala | `at com.example.App.main(App.java:15)` |
| `at ... (file:line:col)` | Node.js, TypeScript (stack traces) | `at Object.<anonymous> (/app.js:10:15)` |
| `in file on line N` | PHP | `in /var/www/app.php on line 12` |
| `at file line N` | Perl | `at script.pl line 12.` |
| `CMake Error at file:line` | CMake | `CMake Error at CMakeLists.txt:15` |
| `ERROR in file line:col` | Webpack | `ERROR in ./src/index.js 10:2-15` |
| `==PID== ... (file:line)` | Valgrind | `by 0x400544: main (example.c:6)` |
| `(file:line)` | Elixir (warnings) | `warning: unused (lib/app.ex:3)` |
| `file:line:col` | C/C++ (gcc/clang), Go, Haskell, Swift, Zig, Dart, TypeScript (tsc), ESLint, Pylint, flake8, Vite | `main.c:10:5: error: undeclared 'x'` |
| `file:line` | Ruby, Lua, grep, ripgrep, Make, general | `app.rb:12: syntax error` |

## Highlight Groups

All highlight groups use `default = true`, so you can override them in your colorscheme:

| Group | Default link | Used for |
|---|---|---|
| `ERunModeLine` | `Comment` | Header line showing working directory |
| `ERunStarted` | `DiagnosticInfo` | "Started at ..." line |
| `ERunCmd` | `Title` | The `$ command` line |
| `ERunStdout` | `Normal` | Standard output lines |
| `ERunStderr` | `DiagnosticError` | Standard error lines |
| `ERunFinished` | `DiagnosticOk` | Success footer line |
| `ERunFailed` | `DiagnosticError` | Failure footer line |
| `ERunLink` | `Underlined` | Clickable file:line references |

## License

MIT
