local M = {}

-- Default settings
M.defaults = {
  -- News sources
  sources = {
    hackernews = {
      enabled = true,
      limit = 30,
      type = "top", -- "top" | "new" | "best" | "ask" | "show"
    },
    rss = {
      feeds = {
        -- Example: { name = "Lobsters", url = "https://lobste.rs/rss" }
      },
    },
    zenn = {
      enabled = true,
      topics = {},
      users = {},
    },
    qiita = {
      enabled = true,
      tags = {},
      users = {},
    },
    developerio = {
      enabled = true,
      use_daily = false,
      authors = {},
    },
  },

  -- UI settings
  ui = {
    display_mode = "float", -- "float" | "side" | "buffer"

    -- Floating window settings
    float = {
      width = 80,
      height = 25,
      border = "rounded",
      title = " wyw.nvim ",
    },

    -- Side panel settings
    side = {
      position = "right", -- "left" | "right"
      width = 50,
    },

    -- Buffer settings
    buffer = {
      split = "vertical", -- "vertical" | "horizontal" | "tab"
    },
  },

  -- Cache settings
  cache = {
    enabled = true,
    ttl = 300, -- Cache TTL in seconds (5 minutes)
    path = vim.fn.stdpath("cache") .. "/wyw",
  },

  -- Date format
  date_format = "%Y-%m-%d %H:%M",

  -- Request settings (for respecting robots.txt Crawl-delay)
  request = {
    delay = 1000, -- Delay between requests in milliseconds (1 second)
    -- User-Agent string (include contact info as per bot etiquette)
    user_agent = "wyw.nvim/0.1.0 (Neovim RSS Reader)",
  },

  -- Keymaps within the news window
  keymaps = {
    close = { "q", "<Esc>" },
    refresh = "r",
    open_link = "<CR>",
    next_item = "j",
    prev_item = "k",
    scroll_down = "<C-d>",
    scroll_up = "<C-u>",
  },
}

-- Store current settings
M.options = {}

-- Split dotted keys into table of parts
local function split_key(key)
  local parts = {}
  for part in key:gmatch("[^%.]+") do
    table.insert(parts, part)
  end
  return parts
end

-- Traverse a table with the provided key parts
local function resolve(tbl, parts)
  local value = tbl
  for _, part in ipairs(parts) do
    if type(value) ~= "table" then
      return nil
    end
    value = value[part]
    if value == nil then
      return nil
    end
  end
  return value
end

-- Initialize settings
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})

  -- Ensure cache directory exists
  if M.options.cache.enabled then
    vim.fn.mkdir(M.options.cache.path, "p")
  end
end

-- Retrieve configuration values. Accepts dot notation for nested keys.
function M.get(key)
  if not key or key == "" then
    return next(M.options) and M.options or M.defaults
  end

  local parts = split_key(key)
  local value = resolve(M.options, parts)
  if value ~= nil then
    return value
  end

  return resolve(M.defaults, parts)
end

return M
