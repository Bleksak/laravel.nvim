local config = require "laravel.config"
local environment = require "laravel.environment"
local history = require "laravel.history"
local Popup = require "nui.popup"
local Split = require "nui.split"
local api = require "laravel.api"

local ui_builders = {
  split = Split,
  popup = Popup,
}

local make_rules = { "%[(.-)%]", "CLASS:%s+(.-)\n" }

---@param text string
---@return string|nil
local function find_class(text)
  for _, rule in ipairs(make_rules) do
    local matche
    matche = text:gmatch(rule)()
    if matche then
      return matche
    end
  end

  return nil
end

---@param name string
---@param args string[]
---@param opts table|nil
return function(name, args, opts)
  opts = opts or {}
  local executable = environment.get_executable(name)
  if not executable then
    error(string.format("Executable %s not found", name), vim.log.levels.ERROR)
    return
  end

  if name == "artisan" then
    local prefix = "make:"
    if args[1]:sub(1, #prefix) == prefix or args[1] == "livewire:make" then
      local response = api.sync("artisan", args)
      if response:successful() then
        local class = find_class(response:prettyContent())
        if class then
          vim.cmd("e " .. class)
          return
        end
      else
        vim.notify(response:prettyErrors(), vim.log.levels.ERROR, {})
        return
      end
    end
  end

  local cmd = vim.fn.extend(executable, args)

  local command_option = config.options.commands_options[args[1]] or {}

  opts = vim.tbl_extend("force", command_option, opts)

  local selected_ui = opts.ui or config.options.ui.default

  local instance = ui_builders[selected_ui](opts.nui_opts or config.options.ui.nui_opts[selected_ui])

  instance:mount()

  -- This returns thhe job id
  local jobId = vim.fn.termopen(table.concat(cmd, " "))

  history.add(jobId, name, args, opts)

  vim.cmd "startinsert"
end
