local config = require("erun.config")
local links = require("erun.links")

local M = {}

local buf = -1
local win = nil
local ns = vim.api.nvim_create_namespace("erun")

--- Get the namespace id.
---@return number
function M.ns()
  return ns
end

--- Get the buffer handle (may be invalid).
---@return number
function M.buf()
  return buf
end

--- Get the window handle (may be nil or invalid).
---@return number|nil
function M.win()
  return win
end

--- Check if the panel window is currently visible.
---@return boolean
function M.is_open()
  return win ~= nil and vim.api.nvim_win_is_valid(win)
end

--- Open the file link under the cursor in the panel.
function M.open_file_link()
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = vim.api.nvim_buf_get_lines(buf, cursor[1] - 1, cursor[1], false)[1]
  if not line then
    return
  end
  local link = links.parse(line)
  if not link then
    vim.notify("No file link found on this line", vim.log.levels.WARN)
    return
  end
  vim.cmd("wincmd p")
  vim.cmd("edit " .. vim.fn.fnameescape(link.file))
  vim.api.nvim_win_set_cursor(0, { link.lnum, link.col - 1 })
end

--- Ensure the panel split and buffer exist.
---@param run_fn function Reference to the run function for the rerun keymap
---@param stop_fn function Reference to the stop function for the interrupt keymap
function M.ensure(run_fn, stop_fn)
  if win and vim.api.nvim_win_is_valid(win) then
    return
  end

  local cfg = config.values
  local prev_win = vim.api.nvim_get_current_win()

  vim.cmd(cfg.position .. " " .. cfg.size .. "split")
  win = vim.api.nvim_get_current_win()

  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "hide"

    local km = cfg.panel_keymaps
    if km.open_file then
      vim.keymap.set("n", km.open_file, M.open_file_link, { buffer = buf, nowait = true, desc = "erun: open file link" })
    end
    if km.open_file_cr then
      vim.keymap.set("n", km.open_file_cr, M.open_file_link, { buffer = buf, nowait = true, desc = "erun: open file link" })
    end
    if km.close then
      vim.keymap.set("n", km.close, function()
        M.close()
      end, { buffer = buf, nowait = true, desc = "erun: close panel" })
    end
    if km.rerun then
      vim.keymap.set("n", km.rerun, run_fn, { buffer = buf, nowait = true, desc = "erun: rerun command" })
    end
    if km.stop then
      vim.keymap.set("n", km.stop, stop_fn, { buffer = buf, nowait = true, desc = "erun: stop execution" })
    end
  end

  vim.api.nvim_win_set_buf(win, buf)

  if not cfg.focus_panel then
    vim.api.nvim_set_current_win(prev_win)
  end
end

--- Close the panel window if it is open.
function M.close()
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
    win = nil
  end
end

--- Toggle the panel open/closed.
---@param run_fn function
---@param stop_fn function
function M.toggle(run_fn, stop_fn)
  if M.is_open() then
    M.close()
  else
    M.ensure(run_fn, stop_fn)
  end
end

--- Scroll the panel window to the bottom.
function M.scroll_to_bottom()
  if win and vim.api.nvim_win_is_valid(win) then
    local line_count = vim.api.nvim_buf_line_count(buf)
    vim.api.nvim_win_set_cursor(win, { line_count, 0 })
  end
end

return M
