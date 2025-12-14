local M = {}

local fetcher = require("wyw.fetcher")

-- Hacker News API base URL
local API_BASE = "https://hacker-news.firebaseio.com/v0"

-- Story type mapping
local STORY_TYPES = {
  top = "topstories",
  new = "newstories",
  best = "beststories",
  ask = "askstories",
  show = "showstories",
}

--- Fetch news items from Hacker News
---@param config table Source configuration
---@param callback function Callback function(items: table)
function M.fetch(config, callback)
  local story_type = STORY_TYPES[config.type or "top"] or "topstories"
  local limit = config.limit or 30

  -- Fetch story IDs
  local url = API_BASE .. "/" .. story_type .. ".json"

  fetcher.get(url, function(data)
    if not data then
      callback({})
      return
    end

    local ok, ids = pcall(vim.fn.json_decode, data)
    if not ok or not ids or type(ids) ~= "table" then
      callback({})
      return
    end

    -- Limit the number of stories to fetch
    local fetch_count = math.min(limit, #ids)
    if fetch_count == 0 then
      callback({})
      return
    end

    local items = {}
    local pending = fetch_count

    -- Fetch individual stories
    for i = 1, fetch_count do
      local item_url = API_BASE .. "/item/" .. ids[i] .. ".json"

      fetcher.get(item_url, function(item_data)
        if item_data then
          local item_ok, item = pcall(vim.fn.json_decode, item_data)
          if item_ok and item and item.title then
            table.insert(items, {
              title = item.title,
              url = item.url or ("https://news.ycombinator.com/item?id=" .. item.id),
              author = item.by or "",
              score = item.score or 0,
              comments = item.descendants or 0,
              timestamp = item.time or os.time(),
              source = "Hacker News",
              id = item.id,
            })
          end
        end

        pending = pending - 1
        if pending == 0 then
          -- Sort by score (descending)
          table.sort(items, function(a, b)
            return (a.score or 0) > (b.score or 0)
          end)
          callback(items)
        end
      end)
    end
  end)
end

return M
