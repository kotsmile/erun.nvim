local M = {}

--- Executable cache: built once at setup(), never shells out during completion.
local _exe_cache = nil

local function build_exe_cache()
  _exe_cache = {}
  local seen = {}
  local path_dirs = vim.split(vim.env.PATH or "", ":", { trimempty = true })
  for _, dir in ipairs(path_dirs) do
    local ok, entries = pcall(vim.fn.readdir, dir)
    if ok then
      for _, name in ipairs(entries) do
        if not seen[name] then
          seen[name] = true
          _exe_cache[#_exe_cache + 1] = name
        end
      end
    end
  end
  table.sort(_exe_cache)
end

--- Pre-warm the executable cache in the background.
function M.warmup()
  vim.schedule(build_exe_cache)
end

local function complete_executables(prefix)
  if not _exe_cache then
    build_exe_cache()
  end
  if prefix == "" then
    return _exe_cache
  end
  local matches = {}
  for _, name in ipairs(_exe_cache) do
    if vim.startswith(name, prefix) then
      matches[#matches + 1] = name
    end
  end
  return matches
end

local function complete_files(prefix)
  local pat = (prefix == "") and "*" or (prefix .. "*")
  local files = vim.fn.glob(pat, false, true)
  for i, f in ipairs(files) do
    if vim.fn.isdirectory(f) == 1 then
      files[i] = f .. "/"
    end
  end
  return files
end

--- Completion callback for :Erun command.
--- Handles shell operators (&&, ||, |, ;) by detecting segment boundaries.
--- Executables for the first word, file paths for arguments. No shell spawned.
---@param arglead string
---@param cmdline string
---@param _cursorpos number
---@return string[]
function M.complete(arglead, cmdline, _cursorpos)
  -- strip the nvim command name to get the shell command line so far
  local args_str = cmdline:match("^%S+%s+(.*)$") or ""

  -- find the last "sub-command" boundary: after &&, ||, |, ;
  local last_segment = args_str:match("[;&|]+%s*([^;&|]*)$") or args_str

  -- figure out if arglead is the first word in this segment
  local prefix_before_lead = last_segment
  if arglead ~= "" then
    local pos = prefix_before_lead:find(vim.pesc(arglead) .. "$")
    if pos then
      prefix_before_lead = prefix_before_lead:sub(1, pos - 1)
    end
  end

  local is_first_word = not prefix_before_lead:match("%S")

  if is_first_word then
    -- first word of a segment: executables + files (like a real shell)
    local exes = complete_executables(arglead)
    local files = complete_files(arglead)
    -- merge, exes first
    local seen = {}
    local results = {}
    for _, v in ipairs(exes) do
      if not seen[v] then
        seen[v] = true
        results[#results + 1] = v
      end
    end
    for _, v in ipairs(files) do
      if not seen[v] then
        seen[v] = true
        results[#results + 1] = v
      end
    end
    return results
  end

  return complete_files(arglead)
end

return M
