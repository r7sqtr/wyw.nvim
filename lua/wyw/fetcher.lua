local M = {}

local config = require("wyw.config")

-- Track last request time for rate limiting
local last_request_time = 0

--- Async HTTP GET using curl with temp file to preserve UTF-8
--- Respects rate limiting based on config.request.delay
---@param url string The URL to fetch
---@param callback function Callback function(data: string|nil)
function M.get(url, callback)
  local delay = config.get("request.delay") or 1000
  local now = vim.loop.now()
  local elapsed = now - last_request_time

  -- If not enough time has passed, schedule the request
  if elapsed < delay and last_request_time > 0 then
    local wait_time = delay - elapsed
    vim.defer_fn(function()
      M.get(url, callback)
    end, wait_time)
    return
  end

  last_request_time = vim.loop.now()
  -- Create a temp file for output
  local tmpfile = vim.fn.tempname()
  local user_agent = config.get("request.user_agent") or "wyw.nvim/0.1.0 (Neovim RSS Reader)"

  vim.fn.jobstart({
    "curl",
    "-sL",
    "--max-time", "10",
    "-H", "User-Agent: " .. user_agent,
    "-H", "Accept-Charset: utf-8",
    "-o", tmpfile,
    url,
  }, {
    on_exit = function(_, code)
      vim.schedule(function()
        if code == 0 then
          -- Read the temp file
          local file = io.open(tmpfile, "r")
          if file then
            local content = file:read("*all")
            file:close()
            -- Delete temp file
            os.remove(tmpfile)
            if content and content ~= "" then
              callback(content)
            else
              callback(nil)
            end
          else
            os.remove(tmpfile)
            callback(nil)
          end
        else
          os.remove(tmpfile)
          callback(nil)
        end
      end)
    end,
  })
end

--- Fetch multiple URLs in parallel
---@param urls table<string, string> Map of key -> url
---@param callback function Callback function(results: table<string, string|nil>)
function M.get_all(urls, callback)
  local results = {}
  local pending = 0

  for key, _ in pairs(urls) do
    pending = pending + 1
  end

  if pending == 0 then
    callback({})
    return
  end

  for key, url in pairs(urls) do
    M.get(url, function(data)
      results[key] = data
      pending = pending - 1
      if pending == 0 then
        callback(results)
      end
    end)
  end
end

return M
