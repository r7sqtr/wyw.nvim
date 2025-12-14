# wyw.nvim

**W**hile **Y**ou **W**ait - AIの思考時間やテストの待ち時間にテックニュースを読むためのNeovimプラグイン

## 機能

- **ニュースソース**
  - [Hacker News](https://news.ycombinator.com/) - Top, New, Best, Ask HN, Show HN
  - [Zenn](https://zenn.dev/) - 日本語テック記事（トピック・ユーザー指定可）
  - [Qiita](https://qiita.com/) - 日本語テック記事（タグ・ユーザー指定可）
  - [DevelopersIO](https://dev.classmethod.jp/) - Classmethodテックブログ
  - RSS/Atomフィード - 任意のフィードを購読可能

- **表示モード**
  - フローティングウィンドウ - 中央にオーバーレイ表示（デフォルト）
  - サイドパネル - 左右のサイドバーとして表示
  - バッファ - 分割またはタブで表示

- **キャッシュ** - 設定可能なTTLでAPIコールを削減

- **検索機能** - キーワードで記事をフィルタリング

## 必要条件

- Neovim 0.8以上
- `curl`（HTTPリクエスト用）

## インストール

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "r7sqtr/wyw.nvim",
  cmd = { "Wyw", "WywToggle" },
  keys = {
    { "<leader>wo", "<cmd>Wyw<cr>", desc = "Open Wyw" },
    { "<leader>wn", "<cmd>WywToggle<cr>", desc = "Toggle Wyw" },
  },
  config = function()
    ~~~
  end,
}
```

## 使い方

### コマンド

| コマンド | 説明 |
|---------|------|
| `:Wyw` | ニュースリーダーを開く |
| `:Wyw float` | フローティングウィンドウで開く |
| `:Wyw side` | サイドパネルで開く |
| `:Wyw buffer` | バッファで開く |
| `:WywToggle` | ニュースリーダーの表示/非表示を切り替え |
| `:WywRefresh` | フィードを更新（キャッシュクリア） |
| `:WywClose` | ニュースリーダーを閉じる |
| `:WywSearch [query]` | ニュース内を検索 |

### キーバインド（ニュースウィンドウ内）

| キー | 操作 |
|------|------|
| `j` / `k` | 下/上に移動 |
| `<Down>` / `<Up>` | 下/上に移動 |
| `gg` / `G` | 最初/最後のアイテムに移動 |
| `<CR>` / `p` | 記事プレビューを開く |
| `o` | ブラウザでリンクを開く |
| `/` | 検索 |
| `<C-c>` | 検索をクリア |
| `r` | フィードを更新 |
| `q` / `<Esc>` | ウィンドウを閉じる |

### キーバインド（記事プレビュー内）

| キー | 操作 |
|------|------|
| `j` / `k` | 下/上にスクロール |
| `<C-d>` / `<C-u>` | 半ページ下/上にスクロール |
| `gg` / `G` | 先頭/末尾に移動 |
| `o` | ブラウザで開く |
| `q` / `<Esc>` | プレビューを閉じる |

## 設定

```lua
require("wyw").setup({
  -- ニュースソースの設定
  sources = {
    -- Hacker News
    hackernews = {
      enabled = true,
      limit = 30,                    -- 取得する記事数
      type = "top",                  -- "top" | "new" | "best" | "ask" | "show"
    },

    -- RSS/Atomフィード
    rss = {
      feeds = {
        { name = "Lobsters", url = "https://lobste.rs/rss" },
        { name = "Dev.to", url = "https://dev.to/feed" },
        -- フィードを追加
      },
    },

    -- Zenn
    zenn = {
      enabled = true,
      topics = { "neovim", "vim" },  -- フォローするトピック
      users = {},                     -- フォローするユーザー
    },

    -- Qiita
    qiita = {
      enabled = true,
      tags = { "neovim", "vim" },    -- フォローするタグ
      users = {},                     -- フォローするユーザー
    },

    -- DevelopersIO
    developerio = {
      enabled = true,
      use_daily = false,             -- デイリーダイジェストを使用
      authors = {},                   -- フォローする著者
    },
  },

  -- UI設定
  ui = {
    display_mode = "float",          -- "float" | "side" | "buffer"

    -- フローティングウィンドウ設定
    float = {
      width = 80,
      height = 25,
      border = "rounded",            -- ボーダースタイル
      title = " wyw.nvim ",
    },

    -- サイドパネル設定
    side = {
      position = "right",            -- "left" | "right"
      width = 50,
    },

    -- バッファ設定
    buffer = {
      split = "vertical",            -- "vertical" | "horizontal" | "tab"
    },
  },

  -- キャッシュ設定
  cache = {
    enabled = true,
    ttl = 300,                       -- キャッシュTTL（秒）（5分）
    path = vim.fn.stdpath("cache") .. "/wyw",
  },

  -- 日付フォーマット（strftime形式）
  date_format = "%Y-%m-%d %H:%M",

  -- リクエスト設定
  request = {
    delay = 1000,                    -- リクエスト間の遅延（ミリ秒）
    user_agent = "wyw.nvim/0.1.0 (Neovim RSS Reader)",
  },
})
```

### 設定例

#### Hacker Newsのみ

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

#### 日本語テックニュース

```lua
require("wyw").setup({
  sources = {
    hackernews = { enabled = false },
    zenn = {
      enabled = true,
      topics = { "neovim", "rust", "typescript" },
    },
    qiita = {
      enabled = true,
      tags = { "neovim", "rust", "typescript" },
    },
    developerio = { enabled = true },
  },
})
```

#### カスタムRSSフィード

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

### Lua関数

```lua
local wyw = require("wyw")

-- オプションを指定してセットアップ
wyw.setup(opts)

-- ニュースリーダーを開く
wyw.open({ display_mode = "float" })  -- または "side"、"buffer"

-- ニュースリーダーを閉じる
wyw.close()

-- ニュースリーダーの表示/非表示を切り替え
wyw.toggle({ display_mode = "float" })

-- フィードを更新（キャッシュクリア）
wyw.refresh()
```

## ハイライトグループ

以下のハイライトグループを設定することで見た目をカスタマイズできます：

| ハイライトグループ | デフォルトリンク | 説明 |
|------------------|-----------------|------|
| `WywTitle` | `Title` | 記事タイトル |
| `WywSource` | `Type` | ソース名 |
| `WywDate` | `Comment` | 日時 |
| `WywScore` | `Number` | スコア（HN） |
| `WywSelected` | `CursorLine` | 選択中のアイテム |
| `WywLoading` | `WarningMsg` | ローディングメッセージ |
| `WywBorder` | `FloatBorder` | ウィンドウボーダー |

設定例：

```lua
vim.api.nvim_set_hl(0, "WywTitle", { fg = "#7aa2f7", bold = true })
vim.api.nvim_set_hl(0, "WywSource", { fg = "#9ece6a" })
```

