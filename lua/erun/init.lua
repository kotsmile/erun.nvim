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
  vim.api.nvim_set_hl(0, "ERunMakeWarn", { link = "DiagnosticWarn", default = true })

  -- User command
  vim.api.nvim_create_user_command("Erun", function(cmd_opts)
    require("erun.runner").run({ cmd = cmd_opts.args })
  end, {
    nargs = "+",
    complete = function(...)
      return require("erun.complete").complete(...)
    end,
  })

  -- Make command
  vim.api.nvim_create_user_command("Emake", function(cmd_opts)
    local make = require("erun.make")
    local target = cmd_opts.args

    if target ~= "" and vim.fn.filereadable("Makefile") == 1 then
      if not make.validate_target(target) then
        vim.notify("Emake: target '" .. target .. "' not found in Makefile", vim.log.levels.WARN)
      end
    elseif vim.fn.filereadable("Makefile") ~= 1 then
      vim.notify("Emake: no Makefile found in " .. vim.fn.getcwd(), vim.log.levels.WARN)
    end

    local cmd = "make"
    if target ~= "" then
      cmd = cmd .. " " .. target
    end
    require("erun.runner").run({ cmd = cmd })
  end, {
    nargs = "?",
    complete = function(arglead, _, _)
      return require("erun.make").complete(arglead)
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
  end, function()
    require("erun.runner").stop()
  end)
end

--- Close the output panel.
function M.close()
  require("erun.panel").close()
end

return M
