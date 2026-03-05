local M = {}

---@class erun.Config
---@field size number Height of the output panel in lines
---@field position "belowright"|"aboveleft"|"botright"|"topleft" Split position
---@field keymap string|false Global keymap to trigger run (set to false to disable)
---@field clear_env boolean Clear panel output before each run
---@field focus_panel boolean Focus the panel window after opening
---@field panel_keymaps table<string, string|false> Buffer-local keymaps in the panel

---@type erun.Config
M.defaults = {
  size = 30,
  position = "belowright",
  keymap = "<leader>r",
  clear_env = true,
  focus_panel = false,
  panel_keymaps = {
    open_file = "gf",
    open_file_cr = "<CR>",
    close = "q",
    rerun = "r",
  },
}

---@type erun.Config
M.values = vim.deepcopy(M.defaults)

---@param opts? erun.Config
function M.setup(opts)
  M.values = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

return M
