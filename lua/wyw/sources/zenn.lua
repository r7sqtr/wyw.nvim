local M = {}

local fetcher = require("wyw.fetcher")
local parser = require("wyw.parser")

local BASE_URL = "https://zenn.dev"

--- Fetch news items from Zenn
---@param config table Source configuration
---@param callback function Callback function(items: table)
function M.fetch(config, callback)
  local feeds = {}

  -- Default feed (trend)
  table.insert(feeds, { name = "Zenn", url = BASE_URL .. "/feed" })

  -- Topic feeds
  local topics = config.topics or {}
  for _, topic in ipairs(topics) do
    table.insert(feeds, {
      name = "Zenn/" .. topic,
      url = BASE_URL .. "/topics/" .. topic .. "/feed",
    })
  end

  -- User feeds
  local users = config.users or {}
  for _, user in ipairs(users) do
    table.insert(feeds, {
      name = "Zenn/@" .. user,
      url = BASE_URL .. "/" .. user .. "/feed",
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
