if vim.g.loaded_erun then
  return
end
vim.g.loaded_erun = true

-- The plugin is activated through require("erun").setup(opts).
-- This file ensures the plugin directory is recognized by Neovim's
-- runtime path and prevents double-loading.
