local M = {}

--- Decode URL-encoded string (percent encoding)
---@param str string URL-encoded string
---@return string Decoded string
local function url_decode(str)
  if not str then
    return ""
  end
  -- Replace + with space
  str = str:gsub("+", " ")
  -- Decode percent-encoded characters
  str = str:gsub("%%(%x%x)", function(hex)
    return string.char(tonumber(hex, 16))
  end)
  return str
end

--- Convert Unicode codepoint to UTF-8 string
---@param codepoint number Unicode codepoint
---@return string UTF-8 encoded string
local function utf8_char(codepoint)
  if not codepoint or codepoint < 0 then
    return ""
  end

  if codepoint < 0x80 then
    -- ASCII (1 byte)
    return string.char(codepoint)
  elseif codepoint < 0x800 then
    -- 2 bytes
    return string.char(
      0xC0 + math.floor(codepoint / 0x40),
      0x80 + (codepoint % 0x40)
    )
  elseif codepoint < 0x10000 then
    -- 3 bytes
    return string.char(
      0xE0 + math.floor(codepoint / 0x1000),
      0x80 + (math.floor(codepoint / 0x40) % 0x40),
      0x80 + (codepoint % 0x40)
    )
  elseif codepoint < 0x110000 then
    -- 4 bytes
    return string.char(
      0xF0 + math.floor(codepoint / 0x40000),
      0x80 + (math.floor(codepoint / 0x1000) % 0x40),
      0x80 + (math.floor(codepoint / 0x40) % 0x40),
      0x80 + (codepoint % 0x40)
    )
  end

  return ""
end

--- Decode Unicode escape sequences like \uXXXX
---@param str string String with escaped Unicode
---@return string Decoded string
local function decode_unicode_escapes(str)
  if not str then
    return ""
  end
  -- Only decode \uXXXX format (JSON-style Unicode escape)
  str = str:gsub("\\u(%x%x%x%x)", function(hex)
    local codepoint = tonumber(hex, 16)
    return utf8_char(codepoint)
  end)
  return str
end

--- Clean HTML entities and tags from a string
---@param str string Input string
---@return string Cleaned string
function M.clean_html(str)
  if not str then
    return ""
  end

  -- Remove CDATA wrapper
  str = str:gsub("<!%[CDATA%[(.-)%]%]>", "%1")

  -- Remove HTML tags
  str = str:gsub("<[^>]+>", "")

  -- Decode common HTML entities
  local entities = {
    ["&amp;"] = "&",
    ["&lt;"] = "<",
    ["&gt;"] = ">",
    ["&quot;"] = '"',
    ["&#39;"] = "'",
    ["&apos;"] = "'",
    ["&nbsp;"] = " ",
    ["&#x27;"] = "'",
    ["&#x2F;"] = "/",
    ["&#8217;"] = "'",
    ["&#8216;"] = "'",
    ["&#8220;"] = '"',
    ["&#8221;"] = '"',
    ["&#8211;"] = "-",
    ["&#8212;"] = "--",
  }

  for entity, char in pairs(entities) do
    str = str:gsub(entity, char)
  end

  -- Decode numeric entities (decimal)
  str = str:gsub("&#(%d+);", function(n)
    local num = tonumber(n)
    if num then
      return utf8_char(num)
    end
    return ""
  end)

  -- Decode numeric entities (hex)
  str = str:gsub("&#[xX](%x+);", function(h)
    local num = tonumber(h, 16)
    if num then
      return utf8_char(num)
    end
    return ""
  end)

  -- Decode URL-encoded characters
  str = url_decode(str)

  -- Decode Unicode escapes (like \uXXXX)
  str = decode_unicode_escapes(str)

  return vim.trim(str)
end

--- Convert HTML to readable plain text (preserving structure)
---@param html string HTML content
---@return string Plain text with preserved structure
function M.html_to_text(html)
  if not html then
    return ""
  end

  -- Remove CDATA wrapper
  html = html:gsub("<!%[CDATA%[(.-)%]%]>", "%1")

  -- Remove script and style tags with content
  html = html:gsub("<script.-</script>", "")
  html = html:gsub("<style.-</style>", "")

  -- Convert block elements to newlines
  html = html:gsub("<br[^>]*>", "\n")
  html = html:gsub("<hr[^>]*>", "\n---\n")
  html = html:gsub("</p>", "\n\n")
  html = html:gsub("</div>", "\n")
  html = html:gsub("</li>", "\n")
  html = html:gsub("</tr>", "\n")
  html = html:gsub("</h[1-6]>", "\n\n")
  html = html:gsub("</blockquote>", "\n")
  html = html:gsub("<li[^>]*>", "  - ")

  -- Convert headers to emphasized text
  html = html:gsub("<h([1-6])[^>]*>(.-)</h%1>", function(_, content)
    return "\n## " .. content .. "\n"
  end)

  -- Handle code blocks
  html = html:gsub("<pre[^>]*>(.-)</pre>", function(content)
    return "\n```\n" .. content .. "\n```\n"
  end)
  html = html:gsub("<code[^>]*>(.-)</code>", "`%1`")

  -- Handle links - show URL in parentheses
  html = html:gsub('<a[^>]*href="([^"]*)"[^>]*>(.-)</a>', "%2 (%1)")

  -- Remove remaining HTML tags
  html = html:gsub("<[^>]+>", "")

  -- Decode HTML entities
  local entities = {
    ["&amp;"] = "&",
    ["&lt;"] = "<",
    ["&gt;"] = ">",
    ["&quot;"] = '"',
    ["&#39;"] = "'",
    ["&apos;"] = "'",
    ["&nbsp;"] = " ",
    ["&#x27;"] = "'",
    ["&#x2F;"] = "/",
    ["&#8217;"] = "'",
    ["&#8216;"] = "'",
    ["&#8220;"] = '"',
    ["&#8221;"] = '"',
    ["&#8211;"] = "-",
    ["&#8212;"] = "--",
    ["&hellip;"] = "...",
    ["&mdash;"] = "--",
    ["&ndash;"] = "-",
    ["&lsquo;"] = "'",
    ["&rsquo;"] = "'",
    ["&ldquo;"] = '"',
    ["&rdquo;"] = '"',
  }

  for entity, char in pairs(entities) do
    html = html:gsub(entity, char)
  end

  -- Decode numeric entities (decimal)
  html = html:gsub("&#(%d+);", function(n)
    local num = tonumber(n)
    if num then
      return utf8_char(num)
    end
    return ""
  end)

  -- Decode numeric entities (hex)
  html = html:gsub("&#[xX](%x+);", function(h)
    local num = tonumber(h, 16)
    if num then
      return utf8_char(num)
    end
    return ""
  end)

  -- Decode URL-encoded characters
  html = url_decode(html)

  -- Decode Unicode escapes (like \uXXXX)
  html = decode_unicode_escapes(html)

  -- Clean up whitespace
  html = html:gsub("[ \t]+", " ")
  html = html:gsub("\n ", "\n")
  html = html:gsub(" \n", "\n")
  html = html:gsub("\n\n\n+", "\n\n")

  return vim.trim(html)
end

--- Parse RFC 2822 date format (common in RSS)
---@param date_str string Date string
---@return number Unix timestamp
function M.parse_rfc2822_date(date_str)
  if not date_str then
    return os.time()
  end

  -- Example: "Mon, 01 Jan 2024 12:00:00 +0000"
  local months = {
    Jan = 1, Feb = 2, Mar = 3, Apr = 4, May = 5, Jun = 6,
    Jul = 7, Aug = 8, Sep = 9, Oct = 10, Nov = 11, Dec = 12,
  }

  local day, month, year, hour, min, sec = date_str:match(
    "%a+,%s+(%d+)%s+(%a+)%s+(%d+)%s+(%d+):(%d+):(%d+)"
  )

  if day and month and year then
    local m = months[month]
    if m then
      return os.time({
        year = tonumber(year),
        month = m,
        day = tonumber(day),
        hour = tonumber(hour) or 0,
        min = tonumber(min) or 0,
        sec = tonumber(sec) or 0,
      })
    end
  end

  return os.time()
end

--- Parse ISO 8601 date format (common in Atom)
---@param date_str string Date string
---@return number Unix timestamp
function M.parse_iso8601_date(date_str)
  if not date_str then
    return os.time()
  end

  -- Example: "2024-01-01T12:00:00Z" or "2024-01-01T12:00:00+00:00"
  local year, month, day, hour, min, sec = date_str:match(
    "(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)"
  )

  if year and month and day then
    return os.time({
      year = tonumber(year),
      month = tonumber(month),
      day = tonumber(day),
      hour = tonumber(hour) or 0,
      min = tonumber(min) or 0,
      sec = tonumber(sec) or 0,
    })
  end

  return os.time()
end

--- Parse date string (tries multiple formats)
---@param date_str string Date string
---@return number Unix timestamp
function M.parse_date(date_str)
  if not date_str then
    return os.time()
  end

  -- Try ISO 8601 first (Atom format)
  if date_str:match("%d+-%d+-%d+T") then
    return M.parse_iso8601_date(date_str)
  end

  -- Try RFC 2822 (RSS format)
  return M.parse_rfc2822_date(date_str)
end

--- Extract content from XML tag
---@param xml string XML content
---@param tag string Tag name
---@return string|nil Content
function M.extract_tag(xml, tag)
  -- Try with CDATA
  local content = xml:match("<" .. tag .. "[^>]*><!%[CDATA%[(.-)%]%]></" .. tag .. ">")
  if content then
    return content
  end

  -- Try without CDATA
  content = xml:match("<" .. tag .. "[^>]*>(.-)</" .. tag .. ">")
  return content
end

--- Extract href from link tag (Atom style)
---@param xml string XML content
---@return string|nil URL
function M.extract_link_href(xml)
  -- Try rel="alternate" first
  local href = xml:match('<link[^>]*rel="alternate"[^>]*href="([^"]+)"')
  if href then
    return href
  end

  -- Try any link with href
  href = xml:match('<link[^>]*href="([^"]+)"')
  return href
end

--- Extract content:encoded tag (RSS full content)
---@param xml string XML content
---@return string|nil Content
function M.extract_content_encoded(xml)
  -- Try with CDATA
  local content = xml:match("<content:encoded[^>]*><!%[CDATA%[(.-)%]%]></content:encoded>")
  if content then
    return content
  end

  -- Try without CDATA
  content = xml:match("<content:encoded[^>]*>(.-)</content:encoded>")
  return content
end

--- Parse RSS item
---@param xml string Item XML
---@param source_name string Source name
---@return table News item
function M.parse_rss_item(xml, source_name)
  local title = M.extract_tag(xml, "title")
  local link = M.extract_tag(xml, "link")
  local description = M.extract_tag(xml, "description")
  local pub_date = M.extract_tag(xml, "pubDate")
  local content_encoded = M.extract_content_encoded(xml)
  local author = M.extract_tag(xml, "author") or M.extract_tag(xml, "dc:creator")

  -- Use content:encoded for full content, fall back to description
  local full_content = content_encoded or description

  return {
    title = M.clean_html(title or ""),
    url = link or "",
    description = M.clean_html(description or ""),
    content = M.html_to_text(full_content or ""),
    timestamp = M.parse_date(pub_date),
    source = source_name,
    author = M.clean_html(author or ""),
  }
end

--- Parse Atom entry
---@param xml string Entry XML
---@param source_name string Source name
---@return table News item
function M.parse_atom_entry(xml, source_name)
  local title = M.extract_tag(xml, "title")
  local link = M.extract_link_href(xml)
  local summary = M.extract_tag(xml, "summary")
  local content = M.extract_tag(xml, "content")
  local published = M.extract_tag(xml, "published") or M.extract_tag(xml, "updated")
  local author_name = xml:match("<author[^>]*>.-<name[^>]*>(.-)</name>.-</author>")

  -- Use content for full content, fall back to summary
  local full_content = content or summary

  return {
    title = M.clean_html(title or ""),
    url = link or "",
    description = M.clean_html(summary or content or ""),
    content = M.html_to_text(full_content or ""),
    timestamp = M.parse_date(published),
    source = source_name,
    author = M.clean_html(author_name or ""),
  }
end

--- Parse RSS/Atom feed
---@param xml_data string XML content
---@param source_name string Source name
---@return table List of news items
function M.parse_feed(xml_data, source_name)
  local items = {}

  -- Try RSS format first (<item>)
  for item_xml in xml_data:gmatch("<item.->(.-)</item>") do
    local item = M.parse_rss_item(item_xml, source_name)
    if item.title ~= "" then
      table.insert(items, item)
    end
  end

  -- Try Atom format (<entry>)
  if #items == 0 then
    for entry_xml in xml_data:gmatch("<entry.->(.-)</entry>") do
      local item = M.parse_atom_entry(entry_xml, source_name)
      if item.title ~= "" then
        table.insert(items, item)
      end
    end
  end

  return items
end

return M
