local M = {}

--- A pattern entry: { name, find_fn(line, start) -> {file, lnum, col, s, e} | nil }
--- `s` and `e` are 1-indexed byte positions of the full match in the line (for highlighting).
--- Patterns are tried in order; more specific patterns come first to avoid false positives.
---@alias erun.LinkMatch {file: string, lnum: number, col: number}
---@alias erun.LinkResult {file: string, lnum: number, col: number, s: number, e: number}

-- Helper: make a path absolute relative to cwd if it isn't already
local function resolve_path(file)
  if file:sub(1, 1) == "/" then
    return file
  end
  -- Strip leading ./ if present
  if file:sub(1, 2) == "./" then
    file = file:sub(3)
  end
  return vim.fn.getcwd() .. "/" .. file
end

-- Helper: check if a file is readable (with path resolution)
local function is_readable(file)
  if vim.fn.filereadable(file) == 1 then
    return true, file
  end
  local resolved = resolve_path(file)
  if vim.fn.filereadable(resolved) == 1 then
    return true, resolved
  end
  return false, file
end

---------------------------------------------------------------------------
-- Pattern definitions
---------------------------------------------------------------------------
-- Each pattern function scans `line` starting from byte position `start`
-- and returns the first match as {file, lnum, col, s, e} or nil.
-- `s` = start of the highlighted region, `e` = end of highlighted region.
---------------------------------------------------------------------------

local patterns = {}

-- 1. Python: File "path", line N (, in ...)
--    e.g.  File "app.py", line 12, in main
--    e.g.  File "/home/user/app.py", line 5
patterns[#patterns + 1] = {
  name = "python",
  find = function(line, start)
    local s, e, file, lnum = line:find('File "([^"]+)", line (%d+)', start)
    if s then
      return { file = file, lnum = tonumber(lnum), col = 1, s = s, e = e }
    end
    return nil
  end,
}

-- 2. Rust: --> file:line:col
--    e.g.   --> src/main.rs:4:13
patterns[#patterns + 1] = {
  name = "rust",
  find = function(line, start)
    local s, e, file, lnum, col = line:find("%-%->#?%s+([^:][^:]-):(%d+):(%d+)", start)
    if s then
      return { file = file, lnum = tonumber(lnum), col = tonumber(col), s = s, e = e }
    end
    return nil
  end,
}

-- 3. C# / MSBuild: file(line,col): ...
--    e.g.  Program.cs(12,5): error CS1002
patterns[#patterns + 1] = {
  name = "csharp",
  find = function(line, start)
    local s, e, file, lnum, col = line:find("([%w_.%-%/\\]+[%w_.%-])%((%d+),(%d+)%)", start)
    if s then
      return { file = file, lnum = tonumber(lnum), col = tonumber(col), s = s, e = e }
    end
    -- file(line): ... (no col)
    local s2, e2, file2, lnum2 = line:find("([%w_.%-%/\\]+[%w_.%-])%((%d+)%)", start)
    if s2 then
      return { file = file2, lnum = tonumber(lnum2), col = 1, s = s2, e = e2 }
    end
    return nil
  end,
}

-- 4. Java/Kotlin/Scala stack trace: at package.Class.method(File.java:line)
--    e.g.  at com.example.App.main(App.java:15)
patterns[#patterns + 1] = {
  name = "java",
  find = function(line, start)
    local s, e, file, lnum = line:find("at%s+[%w.$]+%(([%w_.%-]+):(%d+)%)", start)
    if s then
      return { file = file, lnum = tonumber(lnum), col = 1, s = s, e = e }
    end
    return nil
  end,
}

-- 5. Node.js/TypeScript stack trace: at ... (file:line:col)
--    e.g.  at Object.<anonymous> (/home/user/app.js:10:15)
--    e.g.  at Module._compile (node:internal/modules/cjs/loader:1198:14)
patterns[#patterns + 1] = {
  name = "nodejs",
  find = function(line, start)
    local s, e, file, lnum, col = line:find("at%s+.-%s*%(([^:%(%)]+):(%d+):(%d+)%)", start)
    if s and not file:match("^node:") then
      return { file = file, lnum = tonumber(lnum), col = tonumber(col), s = s, e = e }
    end
    return nil
  end,
}

-- 6. PHP: in /path/file.php on line N
--    e.g.  Fatal error: ... in /var/www/app.php on line 12
patterns[#patterns + 1] = {
  name = "php",
  find = function(line, start)
    local s, e, file, lnum = line:find("in%s+(%S+)%s+on%s+line%s+(%d+)", start)
    if s then
      return { file = file, lnum = tonumber(lnum), col = 1, s = s, e = e }
    end
    return nil
  end,
}

-- 7. Perl: at file line N
--    e.g.  Undefined subroutine &main::foo called at script.pl line 12.
patterns[#patterns + 1] = {
  name = "perl",
  find = function(line, start)
    local s, e, file, lnum = line:find("at%s+(%S+)%s+line%s+(%d+)", start)
    if s then
      return { file = file, lnum = tonumber(lnum), col = 1, s = s, e = e }
    end
    return nil
  end,
}

-- 8. CMake: CMake Error/Warning at file:line
--    e.g.  CMake Error at CMakeLists.txt:15 (find_package):
patterns[#patterns + 1] = {
  name = "cmake",
  find = function(line, start)
    local s, e, file, lnum = line:find("CMake%s+%w+%s+at%s+([^:]+):(%d+)", start)
    if s then
      return { file = file, lnum = tonumber(lnum), col = 1, s = s, e = e }
    end
    return nil
  end,
}

-- 9. Webpack: ERROR in ./file line:col-end or @ ./file line:col
--    e.g.  ERROR in ./src/index.js 10:2-15
patterns[#patterns + 1] = {
  name = "webpack",
  find = function(line, start)
    -- ERROR in ./file N:N
    local s, e, file, lnum, col = line:find("ERROR%s+in%s+(%S+)%s+(%d+):(%d+)", start)
    if s then
      return { file = file, lnum = tonumber(lnum), col = tonumber(col), s = s, e = e }
    end
    -- @ ./file N:N
    local s2, e2, file2, lnum2, col2 = line:find("@%s+(%S+)%s+(%d+):(%d+)", start)
    if s2 then
      return { file = file2, lnum = tonumber(lnum2), col = tonumber(col2), s = s2, e = e2 }
    end
    return nil
  end,
}

-- 10. Valgrind: ==PID== ... (file:line)
--     e.g.  ==12345==    by 0x400544: main (example.c:6)
patterns[#patterns + 1] = {
  name = "valgrind",
  find = function(line, start)
    local s, e, file, lnum = line:find("==%d+==.-%(([%w_.%-%/]+[%w_.%-]):(%d+)%)", start)
    if s then
      return { file = file, lnum = tonumber(lnum), col = 1, s = s, e = e }
    end
    return nil
  end,
}

-- 11. Elixir warning: (file:line)
--     e.g.  warning: variable "x" is unused (lib/app.ex:3)
patterns[#patterns + 1] = {
  name = "elixir_paren",
  find = function(line, start)
    local s, e, file, lnum = line:find("%(([%w_.%-%/]+%.[%w]+):(%d+)%)", start)
    if s then
      return { file = file, lnum = tonumber(lnum), col = 1, s = s, e = e }
    end
    return nil
  end,
}

-- 12. Generic file:line:col (most common: C/C++, Go, Haskell, Swift, Zig, Dart,
--     ESLint, Pylint, flake8, tsc, Vite/esbuild, Elixir compile errors, etc.)
--     e.g.  main.c:10:5: error: ...
--     e.g.  src/main.zig:4:13: error: ...
patterns[#patterns + 1] = {
  name = "file_line_col",
  find = function(line, start)
    local s, e, file, lnum, col = line:find("([%.%/]?[%w_.%-%/\\]+[%w_.%-]):(%d+):(%d+)", start)
    if s then
      return { file = file, lnum = tonumber(lnum), col = tonumber(col), s = s, e = e }
    end
    return nil
  end,
}

-- 13. Generic file:line (Ruby, Lua, grep, ripgrep, Make, etc.)
--     e.g.  app.rb:12: syntax error
--     e.g.  script.lua:14: attempt to call a nil value
--     This is the broadest pattern, must be last.
patterns[#patterns + 1] = {
  name = "file_line",
  find = function(line, start)
    local s, e, file, lnum = line:find("([%.%/]?[%w_.%-%/\\]+[%w_.%-]):(%d+)", start)
    if s then
      return { file = file, lnum = tonumber(lnum), col = 1, s = s, e = e }
    end
    return nil
  end,
}

---------------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------------

--- Parse a line for a file link using all known patterns.
--- Returns the first match that points to a readable file.
---@param line string
---@return erun.LinkMatch|nil
function M.parse(line)
  for _, pat in ipairs(patterns) do
    local start = 1
    while true do
      local result = pat.find(line, start)
      if not result then
        break
      end
      local readable, resolved = is_readable(result.file)
      if readable then
        return {
          file = resolved,
          lnum = result.lnum,
          col = result.col,
        }
      end
      start = result.s + 1
    end
  end
  return nil
end

--- Apply ERunLink highlights to all file-link patterns found on a buffer line.
---@param buf number
---@param ns number
---@param lnum number 0-indexed line number
---@param line string
function M.highlight(buf, ns, lnum, line)
  local highlighted = {} -- track ranges to avoid overlapping highlights

  for _, pat in ipairs(patterns) do
    local start = 1
    while true do
      local result = pat.find(line, start)
      if not result then
        break
      end

      -- Check this range doesn't overlap with an already-highlighted range
      local dominated = false
      for _, range in ipairs(highlighted) do
        if result.s <= range.e and result.e >= range.s then
          dominated = true
          break
        end
      end

      if not dominated then
        vim.api.nvim_buf_add_highlight(buf, ns, "ERunLink", lnum, result.s - 1, result.e)
        highlighted[#highlighted + 1] = { s = result.s, e = result.e }
      end

      start = result.s + 1
    end
  end
end

return M
