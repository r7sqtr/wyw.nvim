local api = vim.api
local config = require("wyw.config")

local M = {}

local detail_state = {
  buf = nil,
  win = nil,
  item = nil,
}

--- Wrap text to specified width (simple version - no splitting within words)
---@param text string Text to wrap
---@param width number Max display width
---@return table Array of lines
function M.wrap_text(text, width)
  local result = {}

  -- Split by existing newlines first
  for line in vim.gsplit(text, "\n", { plain = true }) do
    if line == "" then
      table.insert(result, "")
    else
      local current_line = ""

      for word in line:gmatch("%S+") do
        local test_line = current_line == "" and word or (current_line .. " " .. word)
        local test_width = vim.fn.strdisplaywidth(test_line)

        if test_width <= width then
          current_line = test_line
        else
          if current_line ~= "" then
            table.insert(result, current_line)
          end
          -- If single word is too long, just add it as-is (don't split UTF-8)
          current_line = word
        end
      end

      if current_line ~= "" then
        table.insert(result, current_line)
      end
    end
  end

  return #result > 0 and result or { "" }
end

--- Format timestamp to readable date
---@param timestamp number Unix timestamp
---@return string Formatted date
local function format_date(timestamp)
  if not timestamp or timestamp == 0 then
    return ""
  end
  return os.date(config.options.date_format or "%Y-%m-%d %H:%M", timestamp)
end

--- Open URL in browser
function M.open_url()
  if not detail_state.item or not detail_state.item.url then
    vim.notify("No URL available", vim.log.levels.WARN)
    return
  end

  local open_cmd
  if vim.fn.has("mac") == 1 then
    open_cmd = "open"
  elseif vim.fn.has("unix") == 1 then
    open_cmd = "xdg-open"
  elseif vim.fn.has("win32") == 1 then
    open_cmd = "start"
  end

  if open_cmd then
    vim.fn.jobstart({ open_cmd, detail_state.item.url }, { detach = true })
  end
end

--- Close detail window
function M.close()
  if detail_state.win and api.nvim_win_is_valid(detail_state.win) then
    api.nvim_win_close(detail_state.win, true)
  end

  detail_state.win = nil
  detail_state.buf = nil
  detail_state.item = nil
end

--- Render content to buffer
---@param content string Content to display
local function render_content(content)
  if not detail_state.buf or not api.nvim_buf_is_valid(detail_state.buf) then
    return
  end

  local item = detail_state.item
  local lines = {}
  local width = 78

  table.insert(lines, string.rep("=", width))
  table.insert(lines, "")

  -- Title
  local title = item.title or "No Title"
  table.insert(lines, "  " .. title)

  table.insert(lines, "")
  table.insert(lines, string.rep("-", width))
  table.insert(lines, "")

  -- Metadata
  if item.source then
    table.insert(lines, "  Source: " .. item.source)
  end

  if item.author and item.author ~= "" then
    table.insert(lines, "  Author: " .. item.author)
  end

  if item.timestamp then
    table.insert(lines, "  Date:   " .. format_date(item.timestamp))
  end

  if item.score and item.score > 0 then
    table.insert(lines, "  Score:  " .. item.score)
  end

  if item.comments and item.comments > 0 then
    table.insert(lines, "  Comments: " .. item.comments)
  end

  table.insert(lines, "")

  -- URL
  if item.url then
    table.insert(lines, "  URL: " .. item.url)
  end

  table.insert(lines, "")
  table.insert(lines, string.rep("=", width))
  table.insert(lines, "")

  -- Content (let Neovim handle wrapping to preserve UTF-8)
  if content and content ~= "" then
    for line in vim.gsplit(content, "\n", { plain = true }) do
      table.insert(lines, " " .. line)
    end
  else
    table.insert(lines, "  (No content available)")
  end

  table.insert(lines, "")
  table.insert(lines, string.rep("=", width))
  table.insert(lines, "")

  -- Help text
  local help_parts = { "[o] Open in browser", "[q/Esc] Close", "[j/k] Scroll" }
  table.insert(lines, "  " .. table.concat(help_parts, "  "))

  -- Write to buffer
  vim.bo[detail_state.buf].modifiable = true
  api.nvim_buf_set_lines(detail_state.buf, 0, -1, false, lines)
  vim.bo[detail_state.buf].modifiable = false
end

--- Show article detail in floating window
---@param item table News item
function M.show(item)
  if not item then
    return
  end

  -- Close existing detail window
  M.close()

  detail_state.item = item
  detail_state.buf = api.nvim_create_buf(false, true)

  vim.bo[detail_state.buf].buftype = "nofile"
  vim.bo[detail_state.buf].bufhidden = "wipe"
  vim.bo[detail_state.buf].filetype = "wyw"

  -- Initial content (from RSS feed)
  local initial_content = item.content or item.description or ""
  render_content(initial_content)

  -- Calculate window size
  local width = 82
  local win_width = math.min(width, vim.o.columns - 4)
  local win_height = math.min(40, vim.o.lines - 4)
  local row = math.floor((vim.o.lines - win_height) / 2)
  local col = math.floor((vim.o.columns - win_width) / 2)

  detail_state.win = api.nvim_open_win(detail_state.buf, true, {
    relative = "editor",
    row = row,
    col = col,
    width = win_width,
    height = win_height,
    style = "minimal",
    border = "rounded",
    title = " Article ",
    title_pos = "center",
  })

  -- Enable scrolling
  vim.wo[detail_state.win].wrap = true
  vim.wo[detail_state.win].linebreak = true
  vim.wo[detail_state.win].cursorline = false

  -- Setup keymaps
  local opts = { noremap = true, silent = true, buffer = detail_state.buf }
  vim.keymap.set("n", "q", function() M.close() end, opts)
  vim.keymap.set("n", "<Esc>", function() M.close() end, opts)
  vim.keymap.set("n", "o", function() M.open_url() end, opts)

  -- Scroll keymaps
  vim.keymap.set("n", "j", "<C-e>", opts)
  vim.keymap.set("n", "k", "<C-y>", opts)
  vim.keymap.set("n", "<C-d>", "<C-d>", opts)
  vim.keymap.set("n", "<C-u>", "<C-u>", opts)
  vim.keymap.set("n", "gg", "gg", opts)
  vim.keymap.set("n", "G", "G", opts)

  -- Setup highlights
  api.nvim_set_hl(0, "WywDetailTitle", { link = "Title", default = true })
  api.nvim_set_hl(0, "WywDetailLabel", { link = "Label", default = true })
  api.nvim_set_hl(0, "WywDetailUrl", { link = "Underlined", default = true })
end

return M
