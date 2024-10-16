local view = {}

function view:new(view_finder)
  local instance = {
    finder = view_finder,
  }
  setmetatable(instance, self)
  self.__index = self

  return instance
end

function view:commands()
  return { "view_finder" }
end

function view:handle()
  self.finder:handle(vim.api.nvim_get_current_buf())
end

return view
