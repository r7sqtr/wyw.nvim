local M = {}

--- Search items by query
---@param items table Array of news items
---@param query string Search query
---@param opts table|nil Options { case_sensitive: boolean, fields: string[] }
---@return table Matched items
function M.search(items, query, opts)
  opts = opts or {}
  local case_sensitive = opts.case_sensitive or false
  local fields = opts.fields or { "title", "description", "source" }

  if not query or query == "" then
    return items
  end

  local pattern = query
  if not case_sensitive then
    pattern = pattern:lower()
  end

  local results = {}

  for _, item in ipairs(items) do
    local matched = false

    for _, field in ipairs(fields) do
      local value = item[field]
      if value and type(value) == "string" then
        local search_value = case_sensitive and value or value:lower()
        if search_value:find(pattern, 1, true) then
          matched = true
          break
        end
      end
    end

    if matched then
      table.insert(results, item)
    end
  end

  return results
end

--- Convert query to highlight pattern
---@param query string Search query
---@return string Lua pattern
function M.to_highlight_pattern(query)
  local escaped = query:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
  return escaped
end

return M
