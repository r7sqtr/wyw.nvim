# wyw.nvim

**W**hile e*Y**ou **W**ait - A Neovim plugin to read tech news while waiting for builds, tests, or deployments.

## Features

- **Multiple News Sources**
  - [Hacker News](https://news.ycombinator.com/) - Top, New, Best, Ask HN, Show HN
  - RSS/Atom feeds - Any feed you want to follow

  For Japanese tech articles:
  - [Zenn](https://zenn.dev/) - Japanese tech articles (topics & users)
  - [Qiita](https://qiita.com/) - Japanese tech articles (tags & users)
  - [DevelopersIO](https://dev.classmethod.jp/) - Classmethod tech blog

- **Flexible Display Modes**
  - Floating window - Centered overlay (default)
  - Side panel - Left or right sidebar
  - Buffer - Split or tab

- **Caching** - Configurable TTL to reduce API calls

- **Search** - Filter articles by keywords

## Requirements

- Neovim 0.8+
- `curl` (for HTTP requests)

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "username/wyw.nvim",
  cmd = { "Wyw", "WywToggle" },
  keys = {
    { "<leader>wn", "<cmd>WywToggle<cr>", desc = "Toggle News Reader" },
  },
  config = function()
    require("wyw").setup({
      -- Your configuration here
    })
  end,
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "username/wyw.nvim",
  config = function()
    require("wyw").setup()
  end
}
```

### Manual

Clone the repository to your Neovim packages directory:

```bash
git clone https://github.com/username/wyw.nvim \
  ~/.local/share/nvim/site/pack/plugins/start/wyw.nvim
```

## Quick Start

```lua
-- Minimal setup (uses defaults)
require("wyw").setup()

-- Open the news reader
vim.keymap.set("n", "<leader>wn", "<cmd>Wyw<cr>")
```

## Usage

### Commands

| Command | Description |
|---------|-------------|
| `:Wyw` | Open news reader (default mode) |
| `:Wyw float` | Open in floating window |
| `:Wyw side` | Open in side panel |
| `:Wyw buffer` | Open in buffer |
| `:WywToggle` | Toggle news reader |
| `:WywRefresh` | Refresh feeds (clear cache) |
| `:WywClose` | Close news reader |
| `:WywSearch [query]` | Search in news items |

### Keybindings (in news window)

| Key | Action |
|-----|--------|
| `j` / `k` | Navigate down/up |
| `<Down>` / `<Up>` | Navigate down/up |
| `gg` / `G` | Go to first/last item |
| `<CR>` / `p` | Open article preview |
| `o` | Open link in browser |
| `/` | Search |
| `<C-c>` | Clear search |
| `r` | Refresh feeds |
| `q` / `<Esc>` | Close window |

### Keybindings (in article preview)

| Key | Action |
|-----|--------|
| `j` / `k` | Scroll down/up |
| `<C-d>` / `<C-u>` | Scroll half page down/up |
| `gg` / `G` | Go to top/bottom |
| `o` | Open in browser |
| `q` / `<Esc>` | Close preview |

## Configuration

```lua
require("wyw").setup({
  -- News sources configuration
  sources = {
    -- Hacker News
    hackernews = {
      enabled = true,
      limit = 30,                    -- Number of stories to fetch
      type = "top",                  -- "top" | "new" | "best" | "ask" | "show"
    },

    -- RSS/Atom feeds
    rss = {
      feeds = {
        { name = "Lobsters", url = "https://lobste.rs/rss" },
        { name = "Dev.to", url = "https://dev.to/feed" },
        -- Add more feeds here
      },
    },

    -- Zenn (Japanese tech articles)
    zenn = {
      enabled = true,
      topics = { "neovim", "vim" },  -- Topics to follow
      users = {},                     -- Users to follow
    },

    -- Qiita (Japanese tech articles)
    qiita = {
      enabled = true,
      tags = { "neovim", "vim" },    -- Tags to follow
      users = {},                     -- Users to follow
    },

    -- DevelopersIO
    developerio = {
      enabled = true,
      use_daily = false,             -- Use daily digest instead of main feed
      authors = {},                   -- Authors to follow
    },
  },

  -- UI configuration
  ui = {
    display_mode = "float",          -- "float" | "side" | "buffer"

    -- Floating window settings
    float = {
      width = 80,
      height = 25,
      border = "rounded",            -- Border style
      title = " wyw.nvim ",
    },

    -- Side panel settings
    side = {
      position = "right",            -- "left" | "right"
      width = 50,
    },

    -- Buffer settings
    buffer = {
      split = "vertical",            -- "vertical" | "horizontal" | "tab"
    },
  },

  -- Cache settings
  cache = {
    enabled = true,
    ttl = 300,                       -- Cache TTL in seconds (5 minutes)
    path = vim.fn.stdpath("cache") .. "/wyw",
  },

  -- Date format (strftime)
  date_format = "%Y-%m-%d %H:%M",

  -- Request settings
  request = {
    delay = 1000,                    -- Delay between requests (ms)
    user_agent = "wyw.nvim/0.1.0 (Neovim RSS Reader)",
  },
})
```

### Example Configurations

#### Hacker News Only

```lua
require("wyw").setup({
  sources = {
    hackernews = { enabled = true, limit = 50, type = "top" },
    zenn = { enabled = false },
    qiita = { enabled = false },
    developerio = { enabled = false },
  },
})
```

#### Custom RSS Feeds

```lua
require("wyw").setup({
  sources = {
    hackernews = { enabled = false },
    zenn = { enabled = false },
    qiita = { enabled = false },
    developerio = { enabled = false },
    rss = {
      feeds = {
        { name = "Lobsters", url = "https://lobste.rs/rss" },
        { name = "Reddit/neovim", url = "https://www.reddit.com/r/neovim/.rss" },
        { name = "This Week in Rust", url = "https://this-week-in-rust.org/rss.xml" },
      },
    },
  },
})
```

## API

### Lua Functions

```lua
local wyw = require("wyw")

-- Setup with options
wyw.setup(opts)

-- Open the news reader
wyw.open({ display_mode = "float" })  -- or "side" or "buffer"

-- Close the news reader
wyw.close()

-- Toggle the news reader
wyw.toggle({ display_mode = "float" })

-- Refresh feeds (clears cache)
wyw.refresh()
```

## Highlight Groups

You can customize the appearance by setting these highlight groups:

| Highlight Group | Default Link | Description |
|----------------|--------------|-------------|
| `WywTitle` | `Title` | Article titles |
| `WywSource` | `Type` | Source name |
| `WywDate` | `Comment` | Date/time |
| `WywScore` | `Number` | Score (HN) |
| `WywSelected` | `CursorLine` | Selected item |
| `WywLoading` | `WarningMsg` | Loading message |
| `WywBorder` | `FloatBorder` | Window border |

Example:

```lua
vim.api.nvim_set_hl(0, "WywTitle", { fg = "#7aa2f7", bold = true })
vim.api.nvim_set_hl(0, "WywSource", { fg = "#9ece6a" })
```
