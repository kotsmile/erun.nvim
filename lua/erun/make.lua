local M = {}

--- Parse Makefile targets from the Makefile in the given directory.
---@param dir? string Directory to look for Makefile (defaults to cwd)
---@return string[] targets List of target names
function M.parse_targets(dir)
  dir = dir or vim.fn.getcwd()
  local makefile = dir .. "/Makefile"
  if vim.fn.filereadable(makefile) ~= 1 then
    return {}
  end

  local lines = vim.fn.readfile(makefile)
  local targets = {}
  local seen = {}

  for _, line in ipairs(lines) do
    -- Skip comments and empty lines
    if not line:match("^#") and not line:match("^%s*$") then
      -- Match target definitions: "target:" or "target: deps"
      -- Skip pattern rules (containing %), .PHONY, and variable assignments
      local target = line:match("^([%w_%-%.]+)%s*:")
      if target and not target:match("%%") and not target:match("^%.") and not seen[target] then
        seen[target] = true
        targets[#targets + 1] = target
      end
    end
  end

  return targets
end

--- Complete make targets for tab completion.
---@param arglead string Current argument being typed
---@return string[]
function M.complete(arglead)
  local targets = M.parse_targets()
  if arglead == "" then
    return targets
  end
  local matches = {}
  for _, t in ipairs(targets) do
    if vim.startswith(t, arglead) then
      matches[#matches + 1] = t
    end
  end
  return matches
end

--- Check if a target exists in the Makefile.
---@param target string
---@return boolean
function M.validate_target(target)
  local targets = M.parse_targets()
  for _, t in ipairs(targets) do
    if t == target then
      return true
    end
  end
  return false
end

return M
