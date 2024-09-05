---@class LaravelCompletionSource
---@field configs LaravelConfigsProvider
---@field env LaravelEnvironment
---@field views LaravelViewsProvider
---@field routes LaravelRouteProvider
local source = {}

function source:new(env, views, configs, routes)
  local instance = {
    env = env,
    views = views,
    configs = configs,
    routes = routes,
  }

  setmetatable(instance, self)
  self.__index = self

  return instance
end

---Return whether this source is available in the current context or not (optional).
---@return boolean
function source:is_available()
  return self.env:is_active()
end

---Return the debug name of this source (optional).
---@return string
function source:get_debug_name()
  return "laravel"
end

function source:get_keyword_pattern()
  return [[\k\+]]
end

---Return trigger characters for triggering completion (optional).
function source:get_trigger_characters()
  return { '"', "'" }
end

function source:complete(params, callback)
  local text = params.context.cursor_before_line

  if text:match("view%([%'|%\"]") or text:match("View::make%([%'|%\"]") then
    self.views:get(function(views)
      callback({
        items = vim
            .iter(views)
            :map(function(view)
              return {
                label = string.format("%s (view)", view.name),
                insertText = view.name,
                kind = vim.lsp.protocol.CompletionItemKind["Value"],
                documentation = view.path,
              }
            end)
            :totable(),
        isIncomplete = false,
      })
    end)

    return
  end

  if text:match("config%([%'|%\"]") then
    self.configs:keys(function(configs)
      callback({
        items = vim
            .iter(configs)
            :map(function(config)
              return {
                label = string.format("%s (config)", config),
                insertText = config,
                kind = vim.lsp.protocol.CompletionItemKind["Value"],
                documentation = config,
              }
            end)
            :totable(),
        isIncomplete = false,
      })
    end)

    return
  end

  if text:match("route%([%'|%\"]") then
    self.routes:get(function(routes)
      callback({
        items = vim
            .iter(routes)
            :filter(function(route)
              return route.name ~= nil
            end)
            :map(function(route)
              return {
                label = string.format("%s (route)", route.name),
                insertText = route.name,
                kind = vim.lsp.protocol.CompletionItemKind["Value"],
                documentation = string.format(
                  [[ # Route: %s
  - methods: %s
  - uri: %s
  - middleware: %s
]],
                  route.name,
                  table.concat(route.methods, " | "),
                  route.uri,
                  table.concat(route.middlewares or { "None" }, " | ")
                ),
              }
            end)
            :totable(),
        isIncomplete = false,
      })
    end)

    return
  end

  callback({ items = {} })
end

return source
