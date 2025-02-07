local Util = require("lazy.util")
local Loader = require("lazy.core.loader")

---@type table<string, LazyTaskDef>
local M = {}

M.build = {
  skip = function(plugin)
    return not (plugin._.dirty and plugin.build)
  end,
  run = function(self)
    Loader.load(self.plugin, { task = "build" })

    local builders = self.plugin.build
    if builders then
      builders = type(builders) == "table" and builders or { builders }
      ---@cast builders (string|fun(LazyPlugin))[]
      for _, build in ipairs(builders) do
        if type(build) == "string" and build:sub(1, 1) == ":" then
          local cmd = vim.api.nvim_parse_cmd(build:sub(2), {})
          self.output = vim.api.nvim_cmd(cmd, { output = true })
        elseif type(build) == "function" then
          build(self.plugin)
        else
          local shell = vim.env.SHELL or vim.o.shell
          local shell_args = shell:find("cmd.exe", 1, true) and "/c" or "-c"

          self:spawn(shell, {
            args = { shell_args, build },
            cwd = self.plugin.dir,
          })
        end
      end
    end
  end,
}

M.docs = {
  skip = function(plugin)
    return not plugin._.dirty
  end,
  run = function(self)
    local docs = self.plugin.dir .. "/doc/"
    if Util.file_exists(docs) then
      self.output = vim.api.nvim_cmd({ cmd = "helptags", args = { docs } }, { output = true })
    end
  end,
}

return M
