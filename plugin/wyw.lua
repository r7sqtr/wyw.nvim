if vim.g.loaded_wyw then
  return
end
vim.g.loaded_wyw = true

local function wyw()
  return require("wyw")
end

-- Main command
vim.api.nvim_create_user_command("Wyw", function(opts)
  local display_mode = nil
  if opts.args == "float" then
    display_mode = "float"
  elseif opts.args == "side" then
    display_mode = "side"
  elseif opts.args == "buffer" then
    display_mode = "buffer"
  end
  wyw().open({ display_mode = display_mode })
end, {
  nargs = "?",
  complete = function()
    return { "float", "side", "buffer" }
  end,
  desc = "Open news reader (While You Wait)",
})

-- Refresh command
vim.api.nvim_create_user_command("WywRefresh", function()
  wyw().refresh()
end, {
  desc = "Refresh news feeds",
})

-- Close command
vim.api.nvim_create_user_command("WywClose", function()
  wyw().close()
end, {
  desc = "Close news reader",
})

-- Toggle command
vim.api.nvim_create_user_command("WywToggle", function(opts)
  local display_mode = nil
  if opts.args == "float" then
    display_mode = "float"
  elseif opts.args == "side" then
    display_mode = "side"
  elseif opts.args == "buffer" then
    display_mode = "buffer"
  end
  wyw().toggle({ display_mode = display_mode })
end, {
  nargs = "?",
  complete = function()
    return { "float", "side", "buffer" }
  end,
  desc = "Toggle news reader",
})

-- Search command
vim.api.nvim_create_user_command("WywSearch", function(opts)
  local ui = require("wyw.ui")
  if ui.is_open() then
    ui.start_search(opts.args)
  else
    vim.notify("Wyw is not open. Use :Wyw first.", vim.log.levels.WARN)
  end
end, {
  nargs = "?",
  desc = "Search in news items",
})
