vim.opt.swapfile = false
vim.opt.rtp:prepend("/Users/kotsmile/proj/kotsmile/erun.nvim")
vim.opt.rtp:prepend("/tmp/screenkey.nvim")
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "no"
vim.opt.cmdheight = 1
vim.opt.laststatus = 2
require("erun").setup({ size = 12, focus_panel = false })
require("screenkey").setup({
  win_opts = {
    relative = "editor",
    anchor = "SE",
    width = 50,
    height = 4,
    border = "rounded",
  },
  group_mappings = false,
  clear_after = 1,
})
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    vim.cmd("Screenkey")
  end,
})
