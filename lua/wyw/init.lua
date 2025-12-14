local M = {}

M.version = "0.1.0"
M._initialized = false

--- Setup wyw.nvim with user options
---@param opts table|nil User configuration options
function M.setup(opts)
  local config = require("wyw.config")
  config.setup(opts)
  M._initialized = true
end

--- Open the news reader
---@param opts table|nil Options for opening (display_mode: "float"|"side"|"buffer")
function M.open(opts)
  if not M._initialized then
    M.setup()
  end

  opts = opts or {}
  local ui = require("wyw.ui")
  local sources = require("wyw.sources")

  -- Open UI first with loading state
  ui.open({}, opts, true) -- true = loading state

  -- Fetch feeds asynchronously, then update UI
  sources.fetch_all(function(items)
    vim.schedule(function()
      ui.refresh(items)
    end)
  end)
end

--- Refresh news feeds (clear cache and refetch)
function M.refresh()
  local cache = require("wyw.cache")
  local ui = require("wyw.ui")

  if not ui.is_open() then
    M.open()
    return
  end

  cache.clear()
  ui.set_loading(true)

  local sources = require("wyw.sources")
  sources.fetch_all(function(items)
    vim.schedule(function()
      ui.refresh(items)
    end)
  end)
end

--- Close the news reader
function M.close()
  local ui = require("wyw.ui")
  ui.close()
end

--- Toggle the news reader
function M.toggle(opts)
  local ui = require("wyw.ui")
  if ui.is_open() then
    M.close()
  else
    M.open(opts)
  end
end

return M
