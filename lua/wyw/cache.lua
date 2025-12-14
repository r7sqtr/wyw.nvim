local M = {}

-- In-memory cache
local memory_cache = {}
local cache_times = {}

--- Get cached data for a key
---@param key string Cache key
---@return table|nil Cached data or nil if not found/expired
function M.get(key)
  local config = require("wyw.config")
  if not config.options.cache or not config.options.cache.enabled then
    return nil
  end

  local ttl = config.options.cache.ttl or 300
  local cached_time = cache_times[key]

  -- Check memory cache first
  if cached_time and (os.time() - cached_time) < ttl then
    return memory_cache[key]
  end

  -- Try file cache
  local file_data = M.read_file_cache(key)
  if file_data then
    memory_cache[key] = file_data.data
    cache_times[key] = file_data.time

    -- Check if file cache is still valid
    if (os.time() - file_data.time) < ttl then
      return file_data.data
    end
  end

  return nil
end

--- Set cache data for a key
---@param key string Cache key
---@param data table Data to cache
function M.set(key, data)
  local config = require("wyw.config")
  if not config.options.cache or not config.options.cache.enabled then
    return
  end

  local now = os.time()
  memory_cache[key] = data
  cache_times[key] = now

  -- Write to file cache
  M.write_file_cache(key, data, now)
end

--- Clear all cache
function M.clear()
  memory_cache = {}
  cache_times = {}

  -- Clear file cache
  local config = require("wyw.config")
  if config.options.cache and config.options.cache.path then
    local cache_path = config.options.cache.path
    local files = vim.fn.glob(cache_path .. "/*.json", false, true)
    for _, file in ipairs(files) do
      vim.fn.delete(file)
    end
  end
end

--- Read from file cache
---@param key string Cache key
---@return table|nil { data: table, time: number } or nil
function M.read_file_cache(key)
  local config = require("wyw.config")
  if not config.options.cache or not config.options.cache.path then
    return nil
  end

  local path = config.options.cache.path .. "/" .. key .. ".json"
  local ok, content = pcall(vim.fn.readfile, path)
  if ok and content and #content > 0 then
    local decode_ok, data = pcall(vim.fn.json_decode, table.concat(content, "\n"))
    if decode_ok and data then
      return data
    end
  end
  return nil
end

--- Write to file cache
---@param key string Cache key
---@param data table Data to cache
---@param time number Cache time
function M.write_file_cache(key, data, time)
  local config = require("wyw.config")
  if not config.options.cache or not config.options.cache.path then
    return
  end

  local path = config.options.cache.path .. "/" .. key .. ".json"
  local cache_data = {
    data = data,
    time = time,
  }

  local encode_ok, json = pcall(vim.fn.json_encode, cache_data)
  if encode_ok then
    pcall(vim.fn.writefile, { json }, path)
  end
end

return M
