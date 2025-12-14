local M = {}

local cache = require("wyw.cache")

-- Registry of available sources
M.sources = {}

--- Register a news source
---@param name string Source name
---@param source table Source module with fetch(config, callback) function
function M.register(name, source)
  M.sources[name] = source
end

--- Initialize built-in sources
function M.init()
  M.register("hackernews", require("wyw.sources.hackernews"))
  M.register("rss", require("wyw.sources.rss"))
  M.register("zenn", require("wyw.sources.zenn"))
  M.register("qiita", require("wyw.sources.qiita"))
  M.register("developerio", require("wyw.sources.developerio"))
end

--- Fetch from all enabled sources
---@param callback function Callback function(items: table)
function M.fetch_all(callback)
  -- Initialize sources if not done
  if not next(M.sources) then
    M.init()
  end

  local config = require("wyw.config")
  local results = {}
  local pending = 0

  -- Count enabled sources
  for name, _ in pairs(M.sources) do
    local source_config = config.options.sources and config.options.sources[name]
    if source_config and source_config.enabled ~= false then
      pending = pending + 1
    end
  end

  if pending == 0 then
    callback({})
    return
  end

  -- Fetch from each enabled source
  for name, source in pairs(M.sources) do
    local source_config = config.options.sources and config.options.sources[name]

    if source_config and source_config.enabled ~= false then
      -- Check cache first
      local cached = cache.get(name)

      if cached then
        results[name] = cached
        pending = pending - 1
        if pending == 0 then
          callback(M.merge_results(results))
        end
      else
        source.fetch(source_config, function(items)
          -- Cache the results
          if items and #items > 0 then
            cache.set(name, items)
          end

          results[name] = items or {}
          pending = pending - 1

          if pending == 0 then
            callback(M.merge_results(results))
          end
        end)
      end
    end
  end
end

--- Merge results from all sources and sort by timestamp
---@param results table<string, table> Results from each source
---@return table Merged and sorted items
function M.merge_results(results)
  local all = {}

  for _, items in pairs(results) do
    for _, item in ipairs(items) do
      table.insert(all, item)
    end
  end

  -- Sort by timestamp (newest first)
  table.sort(all, function(a, b)
    return (a.timestamp or 0) > (b.timestamp or 0)
  end)

  return all
end

return M
