local api = vim.api
local config = require("wyw.config")

local M = {}

---@class WywState
---@field buf number|nil
---@field win number|nil
---@field items table
---@field selected_index number
---@field ns number
---@field display_mode string
---@field loading boolean

---@type WywState
local state = {
  buf = nil,
  win = nil,
  items = {},
  selected_index = 1,
  ns = 0,
  display_mode = "float",
  loading = false,
  search_query = "",
  filtered_items = nil,
}

-- Icons
local ICONS = {
  arrow = "▸ ",
  loading = "⏳ ",
  news = "📰 ",
  link = "🔗 ",
  comments = "💬 ",
  score = "⬆ ",
}

--- Check if nui.nvim is available
local Popup = nil
local Split = nil
local function ensure_nui()
  if Popup then
    return true
  end

  local ok_popup, popup = pcall(require, "nui.popup")
  local ok_split, split = pcall(require, "nui.split")

  if ok_popup then
    Popup = popup
  end
  if ok_split then
    Split = split
  end

  return ok_popup
end

--- Format timestamp to readable date
---@param timestamp number Unix timestamp
---@return string Formatted date
local function format_date(timestamp)
  if not timestamp or timestamp == 0 then
    return ""
  end

  local now = os.time()
  local diff = now - timestamp

  if diff < 60 then
    return "just now"
  elseif diff < 3600 then
    local mins = math.floor(diff / 60)
    return mins .. "m ago"
  elseif diff < 86400 then
    local hours = math.floor(diff / 3600)
    return hours .. "h ago"
  elseif diff < 604800 then
    local days = math.floor(diff / 86400)
    return days .. "d ago"
  else
    return os.date(config.options.date_format or "%Y-%m-%d", timestamp)
  end
end

--- Setup highlights
local function setup_highlights()
  local hl = api.nvim_set_hl

  hl(0, "WywTitle", { link = "Title", default = true })
  hl(0, "WywSource", { link = "Type", default = true })
  hl(0, "WywDate", { link = "Comment", default = true })
  hl(0, "WywScore", { link = "Number", default = true })
  hl(0, "WywSelected", { link = "CursorLine", default = true })
  hl(0, "WywLoading", { link = "WarningMsg", default = true })
  hl(0, "WywBorder", { link = "FloatBorder", default = true })
end

--- Get display items (filtered or all)
---@return table items to display
local function get_display_items()
  return state.filtered_items or state.items
end

--- Render news items to buffer
local function render_items()
  if not state.buf or not api.nvim_buf_is_valid(state.buf) then
    return
  end

  api.nvim_buf_set_option(state.buf, "modifiable", true)
  api.nvim_buf_clear_namespace(state.buf, state.ns, 0, -1)

  local lines = {}
  local highlights = {}
  local display_items = get_display_items()

  -- Show search query header
  if state.search_query ~= "" then
    local search_header = "  Search: " .. state.search_query .. " (" .. #display_items .. " results)"
    table.insert(lines, search_header)
    table.insert(lines, "")
    table.insert(highlights, { line = 0, col = 0, end_col = -1, hl = "WywSource" })
  end

  if state.loading then
    table.insert(lines, "")
    table.insert(lines, "  " .. ICONS.loading .. "Loading news...")
    table.insert(lines, "")
    table.insert(highlights, { line = #lines - 2, col = 0, end_col = -1, hl = "WywLoading" })
  elseif #display_items == 0 then
    table.insert(lines, "")
    if state.search_query ~= "" then
      table.insert(lines, "  No items match your search.")
      table.insert(lines, "")
      table.insert(lines, "  Press <C-c> to clear search.")
    else
      table.insert(lines, "  No news items found.")
      table.insert(lines, "")
      table.insert(lines, "  Press 'r' to refresh.")
    end
    table.insert(lines, "")
  else
    for i, item in ipairs(display_items) do
      local is_selected = (i == state.selected_index)
      local prefix = is_selected and ICONS.arrow or "  "

      -- Title line
      local title_line = prefix .. (item.title or "No title")
      table.insert(lines, title_line)

      -- Meta line (source, date, score)
      local meta_parts = {}

      if item.source and item.source ~= "" then
        table.insert(meta_parts, "[" .. item.source .. "]")
      end

      if item.timestamp then
        table.insert(meta_parts, format_date(item.timestamp))
      end

      if item.score and item.score > 0 then
        table.insert(meta_parts, ICONS.score .. item.score)
      end

      if item.comments and item.comments > 0 then
        table.insert(meta_parts, ICONS.comments .. item.comments)
      end

      local meta_line = "    " .. table.concat(meta_parts, " · ")
      table.insert(lines, meta_line)

      -- Empty line separator
      table.insert(lines, "")

      -- Store highlight info
      local line_num = #lines - 3
      if is_selected then
        table.insert(highlights, {
          line = line_num,
          col = 0,
          end_col = -1,
          hl = "WywSelected",
        })
      end

      table.insert(highlights, {
        line = line_num,
        col = #prefix,
        end_col = #title_line,
        hl = "WywTitle",
      })

      table.insert(highlights, {
        line = line_num + 1,
        col = 0,
        end_col = -1,
        hl = "WywDate",
      })
    end
  end

  -- Set lines
  api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)

  -- Apply highlights
  for _, h in ipairs(highlights) do
    api.nvim_buf_add_highlight(state.buf, state.ns, h.hl, h.line, h.col, h.end_col)
  end

  api.nvim_buf_set_option(state.buf, "modifiable", false)

  -- Update cursor position
  if state.win and api.nvim_win_is_valid(state.win) and #state.items > 0 then
    local cursor_line = (state.selected_index - 1) * 3 + 1
    pcall(api.nvim_win_set_cursor, state.win, { cursor_line, 0 })
  end
end

--- Move selection
---@param delta number Direction (-1 for up, 1 for down)
local function move_selection(delta)
  local display_items = get_display_items()
  if #display_items == 0 then
    return
  end

  local new_index = state.selected_index + delta

  if new_index < 1 then
    new_index = #display_items
  elseif new_index > #display_items then
    new_index = 1
  end

  state.selected_index = new_index
  render_items()
end

--- Open selected item in browser
local function open_selected()
  local display_items = get_display_items()
  if #display_items == 0 or state.selected_index > #display_items then
    return
  end

  local item = display_items[state.selected_index]
  if not item or not item.url or item.url == "" then
    vim.notify("No URL for this item", vim.log.levels.WARN)
    return
  end

  -- Open URL in default browser
  local open_cmd
  if vim.fn.has("mac") == 1 then
    open_cmd = "open"
  elseif vim.fn.has("unix") == 1 then
    open_cmd = "xdg-open"
  elseif vim.fn.has("win32") == 1 then
    open_cmd = "start"
  end

  if open_cmd then
    vim.fn.jobstart({ open_cmd, item.url }, { detach = true })
  else
    vim.notify("URL: " .. item.url, vim.log.levels.INFO)
  end
end

--- Show detail for selected item
local function show_detail()
  local display_items = get_display_items()
  if #display_items == 0 or state.selected_index > #display_items then
    return
  end

  local item = display_items[state.selected_index]
  if item then
    require("wyw.detail").show(item)
  end
end

--- Open search prompt
local function open_search_prompt()
  vim.ui.input({
    prompt = "Search: ",
    default = state.search_query,
  }, function(input)
    if input == nil then
      return
    end

    state.search_query = input

    if input == "" then
      state.filtered_items = nil
    else
      local search = require("wyw.search")
      state.filtered_items = search.search(state.items, input)
    end

    state.selected_index = 1
    render_items()
  end)
end

--- Clear search
local function clear_search()
  state.search_query = ""
  state.filtered_items = nil
  state.selected_index = 1
  render_items()
end

--- Setup keymaps for the news buffer
local function setup_keymaps()
  local opts = { noremap = true, silent = true, buffer = state.buf }

  -- Navigation
  vim.keymap.set("n", "j", function() move_selection(1) end, opts)
  vim.keymap.set("n", "k", function() move_selection(-1) end, opts)
  vim.keymap.set("n", "<Down>", function() move_selection(1) end, opts)
  vim.keymap.set("n", "<Up>", function() move_selection(-1) end, opts)
  vim.keymap.set("n", "gg", function()
    state.selected_index = 1
    render_items()
  end, opts)
  vim.keymap.set("n", "G", function()
    local display_items = get_display_items()
    state.selected_index = #display_items
    render_items()
  end, opts)

  -- Actions
  vim.keymap.set("n", "<CR>", show_detail, opts)
  vim.keymap.set("n", "p", show_detail, opts)
  vim.keymap.set("n", "o", open_selected, opts)

  -- Search
  vim.keymap.set("n", "/", open_search_prompt, opts)
  vim.keymap.set("n", "<C-c>", clear_search, opts)

  -- Refresh
  vim.keymap.set("n", "r", function()
    require("wyw").refresh()
  end, opts)

  -- Close
  vim.keymap.set("n", "q", function() M.close() end, opts)
  vim.keymap.set("n", "<Esc>", function() M.close() end, opts)
end

--- Create buffer for news display
---@return number Buffer handle
local function create_buffer()
  local buf = api.nvim_create_buf(false, true)

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "wyw"

  return buf
end

--- Open floating window
local function open_float()
  local opts = config.options.ui.float

  local width = opts.width or 80
  local height = opts.height or 25
  local border = opts.border or "rounded"
  local title = opts.title or " wyw.nvim "

  -- Calculate position (centered)
  local editor_width = vim.o.columns
  local editor_height = vim.o.lines
  local row = math.floor((editor_height - height) / 2)
  local col = math.floor((editor_width - width) / 2)

  state.buf = create_buffer()
  state.ns = api.nvim_create_namespace("Wyw")

  state.win = api.nvim_open_win(state.buf, true, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = border,
    title = title,
    title_pos = "center",
  })

  vim.wo[state.win].cursorline = false
  vim.wo[state.win].number = false
  vim.wo[state.win].relativenumber = false
  vim.wo[state.win].signcolumn = "no"
  vim.wo[state.win].wrap = true
end

--- Open side panel
local function open_side()
  local opts = config.options.ui.side

  local position = opts.position or "right"
  local width = opts.width or 50

  state.buf = create_buffer()
  state.ns = api.nvim_create_namespace("Wyw")

  local split_cmd = position == "left" and "topleft" or "botright"
  vim.cmd(split_cmd .. " " .. width .. "vnew")

  state.win = api.nvim_get_current_win()
  api.nvim_win_set_buf(state.win, state.buf)

  vim.wo[state.win].number = false
  vim.wo[state.win].relativenumber = false
  vim.wo[state.win].signcolumn = "no"
  vim.wo[state.win].winfixwidth = true
  vim.wo[state.win].wrap = true
end

--- Open in buffer
local function open_buffer()
  local opts = config.options.ui.buffer

  local split = opts.split or "vertical"

  state.buf = create_buffer()
  state.ns = api.nvim_create_namespace("Wyw")

  if split == "tab" then
    vim.cmd("tabnew")
  elseif split == "horizontal" then
    vim.cmd("split")
  else
    vim.cmd("vsplit")
  end

  state.win = api.nvim_get_current_win()
  api.nvim_win_set_buf(state.win, state.buf)

  vim.wo[state.win].number = false
  vim.wo[state.win].relativenumber = false
  vim.wo[state.win].signcolumn = "no"
  vim.wo[state.win].wrap = true
end

--- Set loading state and re-render
---@param loading boolean
function M.set_loading(loading)
  state.loading = loading
  if state.buf and api.nvim_buf_is_valid(state.buf) then
    render_items()
  end
end

--- Show loading indicator (deprecated, use set_loading)
function M.show_loading()
  M.set_loading(true)
end

--- Open the news UI
---@param items table List of news items
---@param opts table|nil Options
---@param loading boolean|nil Whether to show loading state
function M.open(items, opts, loading)
  opts = opts or {}

  -- Close existing window if open
  if state.win and api.nvim_win_is_valid(state.win) then
    M.close()
  end

  setup_highlights()

  -- Determine display mode
  state.display_mode = opts.display_mode or config.options.ui.display_mode or "float"
  state.items = items or {}
  state.selected_index = 1
  state.loading = loading or false

  -- Open based on display mode
  if state.display_mode == "side" then
    open_side()
  elseif state.display_mode == "buffer" then
    open_buffer()
  else
    open_float()
  end

  -- Setup keymaps and render
  setup_keymaps()
  render_items()

  -- Auto-close on window leave for floating windows
  if state.display_mode == "float" then
    api.nvim_create_autocmd("WinLeave", {
      buffer = state.buf,
      once = true,
      callback = function()
        vim.schedule(function()
          if state.win then
            M.close()
          end
        end)
      end,
    })
  end
end

--- Refresh the news display with new items
---@param items table List of news items
function M.refresh(items)
  state.items = items or {}
  state.selected_index = 1
  state.loading = false
  state.search_query = ""
  state.filtered_items = nil
  render_items()
end

--- Close the news UI
function M.close()
  if state.win and api.nvim_win_is_valid(state.win) then
    api.nvim_win_close(state.win, true)
  end

  if state.buf and api.nvim_buf_is_valid(state.buf) then
    api.nvim_buf_delete(state.buf, { force = true })
  end

  state.win = nil
  state.buf = nil
  state.loading = false
  state.search_query = ""
  state.filtered_items = nil
end

--- Check if the UI is currently open
---@return boolean
function M.is_open()
  return state.win ~= nil and api.nvim_win_is_valid(state.win)
end

--- Start search with optional query
---@param query string|nil Initial search query
function M.start_search(query)
  if not M.is_open() then
    return
  end

  if query and query ~= "" then
    state.search_query = query
    local search = require("wyw.search")
    state.filtered_items = search.search(state.items, query)
    state.selected_index = 1
    render_items()
  else
    open_search_prompt()
  end
end

return M
