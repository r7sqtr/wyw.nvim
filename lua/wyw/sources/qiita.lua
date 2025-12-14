local M = {}

local fetcher = require("wyw.fetcher")
local parser = require("wyw.parser")

local BASE_URL = "https://qiita.com"

--- Fetch news items from Qiita
---@param config table Source configuration
---@param callback function Callback function(items: table)
function M.fetch(config, callback)
  local feeds = {}

  -- Default feed (popular)
  table.insert(feeds, { name = "Qiita", url = BASE_URL .. "/popular-items/feed.atom" })

  -- Tag feeds
  local tags = config.tags or {}
  for _, tag in ipairs(tags) do
    table.insert(feeds, {
      name = "Qiita#" .. tag,
      url = BASE_URL .. "/tags/" .. tag .. "/feed.atom",
    })
  end

  -- User feeds
  local users = config.users or {}
  for _, user in ipairs(users) do
    table.insert(feeds, {
      name = "Qiita@" .. user,
      url = BASE_URL .. "/" .. user .. "/feed.atom",
    })
  end

  if #feeds == 0 then
    callback({})
    return
  end

  local results = {}
  local pending = #feeds

  for _, feed in ipairs(feeds) do
    fetcher.get(feed.url, function(data)
      if data then
        local items = parser.parse_feed(data, feed.name)
        for _, item in ipairs(items) do
          item.source = feed.name
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
