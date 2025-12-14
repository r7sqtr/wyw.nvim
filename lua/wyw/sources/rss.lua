local M = {}

local fetcher = require("wyw.fetcher")
local parser = require("wyw.parser")

--- Fetch news items from RSS feeds
---@param config table Source configuration
---@param callback function Callback function(items: table)
function M.fetch(config, callback)
  local feeds = config.feeds or {}

  if #feeds == 0 then
    callback({})
    return
  end

  local results = {}
  local pending = #feeds

  for _, feed in ipairs(feeds) do
    fetcher.get(feed.url, function(data)
      if data then
        local items = parser.parse_feed(data, feed.name or feed.url)
        for _, item in ipairs(items) do
          table.insert(results, item)
        end
      end

      pending = pending - 1
      if pending == 0 then
        callback(results)
      end
    end)
  end
end

return M
