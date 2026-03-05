local M = {}

--- Setup erun.nvim with user options.
---@param opts? erun.Config
function M.setup(opts)
  local config = require("erun.config")
  config.setup(opts)

  -- Pre-warm executable cache
  require("erun.complete").warmup()

  -- Highlight groups (default = true so users can override)
  vim.api.nvim_set_hl(0, "ERunModeLine", { link = "Comment", default = true })
  vim.api.nvim_set_hl(0, "ERunStarted", { link = "DiagnosticInfo", default = true })
  vim.api.nvim_set_hl(0, "ERunCmd", { link = "Title", default = true })
  vim.api.nvim_set_hl(0, "ERunStdout", { link = "Normal", default = true })
  vim.api.nvim_set_hl(0, "ERunStderr", { link = "DiagnosticError", default = true })
  vim.api.nvim_set_hl(0, "ERunFinished", { link = "DiagnosticOk", default = true })
  vim.api.nvim_set_hl(0, "ERunFailed", { link = "DiagnosticError", default = true })
  vim.api.nvim_set_hl(0, "ERunLink", { link = "Underlined", default = true })

  -- User command
  vim.api.nvim_create_user_command("Erun", function(cmd_opts)
    require("erun.runner").run({ cmd = cmd_opts.args })
  end, {
    nargs = "+",
    complete = function(...)
      return require("erun.complete").complete(...)
    end,
  })

  -- Global keymap
  if config.values.keymap then
    vim.keymap.set("n", config.values.keymap, function()
      require("erun.runner").run()
    end, { desc = "erun: run command" })
  end
end

--- Run the current command or prompt for one.
---@param opts? {cmd?: string}
function M.run(opts)
  require("erun.runner").run(opts)
end

--- Stop the currently running job.
function M.stop()
  require("erun.runner").stop()
end

--- Set the command without running it.
---@param cmd string
function M.set_cmd(cmd)
  require("erun.runner").set_cmd(cmd)
end

--- Toggle the output panel open/closed.
function M.toggle()
  require("erun.panel").toggle(function()
    require("erun.runner").run()
  end)
end

--- Close the output panel.
function M.close()
  require("erun.panel").close()
end

return M
