local M = {}

local fetcher = require("wyw.fetcher")
local parser = require("wyw.parser")

local FEED_URL = "https://dev.classmethod.jp/feed/"
local DAILY_URL = "https://feed.classmethod.jp/blog/daily.rss"

--- Fetch news items from DevelopersIO
---@param config table Source configuration
---@param callback function Callback function(items: table)
function M.fetch(config, callback)
  local feeds = {}

  -- Default or daily feed
  if config.use_daily then
    table.insert(feeds, { name = "DevelopersIO Daily", url = DAILY_URL })
  else
    table.insert(feeds, { name = "DevelopersIO", url = FEED_URL })
  end

  -- Author feeds
  local authors = config.authors or {}
  for _, author in ipairs(authors) do
    table.insert(feeds, {
      name = "DevIO/" .. author,
      url = "https://dev.classmethod.jp/author/" .. author .. "/feed/",
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
