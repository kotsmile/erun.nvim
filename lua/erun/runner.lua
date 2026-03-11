local panel = require("erun.panel")
local links = require("erun.links")

local M = {}

local run_cmd = nil
local run_job = nil
local run_id = 0

--- Get the current command.
---@return string|nil
function M.cmd()
  return run_cmd
end

--- Set the command without running it.
---@param cmd string
function M.set_cmd(cmd)
  run_cmd = cmd
end

--- Stop the currently running job, if any.
function M.stop()
  if run_job then
    vim.fn.jobstop(run_job)
    run_job = nil
  end
end

--- Read the command from the $ line in the output buffer and update run_cmd.
local function sync_cmd_from_buffer()
  local b = panel.buf()
  if not b or not vim.api.nvim_buf_is_valid(b) then
    return
  end
  local lines = vim.api.nvim_buf_get_lines(b, 3, 4, false)
  if not lines or not lines[1] then
    return
  end
  local line = lines[1]
  if line:sub(1, 2) == "$ " then
    local cmd = line:sub(3)
    if cmd ~= "" then
      run_cmd = cmd
    end
  end
end

--- Run the current command (or prompt for one).
---@param opts? {cmd?: string}
function M.run(opts)
  opts = opts or {}

  if opts.cmd then
    run_cmd = opts.cmd
  else
    sync_cmd_from_buffer()
  end

  if not run_cmd then
    local ok, input = pcall(vim.fn.input, {
      prompt = "Run command: ",
      cancelreturn = "\x00",
      completion = "customlist,v:lua.require'erun.complete'.complete",
    })
    if not ok or input == "\x00" or input == "" then
      return
    end
    run_cmd = input
    M.run()
    return
  end

  M.stop()

  run_id = run_id + 1
  local current_id = run_id

  panel.ensure(M.run, M.stop)

  local buf = panel.buf()
  local ns = panel.ns()

  local cwd = vim.fn.getcwd()
  local started_at = os.date("%a %b %d %H:%M:%S")
  local mode_line = '-*- directory: "' .. cwd .. '/" -*-'
  local started_line = "Started at " .. started_at

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { mode_line, started_line, "", "$ " .. run_cmd })
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  vim.api.nvim_buf_add_highlight(buf, ns, "ERunModeLine", 0, 0, -1)
  vim.api.nvim_buf_add_highlight(buf, ns, "ERunStarted", 1, 0, -1)
  vim.api.nvim_buf_add_highlight(buf, ns, "ERunCmd", 3, 0, -1)

  local start_time = vim.loop.hrtime()

  run_job = vim.fn.jobstart(run_cmd, {
    stdout_buffered = false,
    stderr_buffered = false,

    on_stdout = function(_, data)
      if not data then
        return
      end
      vim.schedule(function()
        if current_id ~= run_id then
          return
        end
        for _, line in ipairs(data) do
          if line ~= "" then
            vim.api.nvim_buf_set_lines(buf, -1, -1, false, { line })
            local lnum = vim.api.nvim_buf_line_count(buf) - 1
            vim.api.nvim_buf_add_highlight(buf, ns, "ERunStdout", lnum, 0, -1)
            links.highlight(buf, ns, lnum, line)
          end
        end
        panel.scroll_to_bottom()
      end)
    end,

    on_stderr = function(_, data)
      if not data then
        return
      end
      vim.schedule(function()
        if current_id ~= run_id then
          return
        end
        for _, line in ipairs(data) do
          if line ~= "" then
            vim.api.nvim_buf_set_lines(buf, -1, -1, false, { line })
            local lnum = vim.api.nvim_buf_line_count(buf) - 1
            vim.api.nvim_buf_add_highlight(buf, ns, "ERunStderr", lnum, 0, -1)
            links.highlight(buf, ns, lnum, line)
          end
        end
        panel.scroll_to_bottom()
      end)
    end,

    on_exit = function(_, code)
      run_job = nil
      vim.schedule(function()
        if current_id ~= run_id then
          return
        end
        local finished_at = os.date("%a %b %d %H:%M:%S")
        local elapsed_ns = vim.loop.hrtime() - start_time
        local elapsed_s = elapsed_ns / 1e9
        local elapsed_str
        if elapsed_s < 60 then
          elapsed_str = string.format("%.2fs", elapsed_s)
        elseif elapsed_s < 3600 then
          local m = math.floor(elapsed_s / 60)
          local s = elapsed_s - m * 60
          elapsed_str = string.format("%dm %.2fs", m, s)
        else
          local h = math.floor(elapsed_s / 3600)
          local m = math.floor((elapsed_s - h * 3600) / 60)
          local s = elapsed_s - h * 3600 - m * 60
          elapsed_str = string.format("%dh %dm %.2fs", h, m, s)
        end

        local finish_line, hl
        if code == 0 then
          finish_line = string.format("Finished at %s (elapsed %s)", finished_at, elapsed_str)
          hl = "ERunFinished"
        else
          finish_line = string.format("Exited abnormally with code %d at %s (elapsed %s)", code, finished_at, elapsed_str)
          hl = "ERunFailed"
        end

        vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "", finish_line })
        local lnum = vim.api.nvim_buf_line_count(buf) - 1
        vim.api.nvim_buf_add_highlight(buf, ns, hl, lnum, 0, -1)
        panel.scroll_to_bottom()
      end)
    end,
  })
end

return M
