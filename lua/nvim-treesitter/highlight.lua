local configs = require "nvim-treesitter.configs"

local M = {}

---@param config TSModule
---@param lang string
---@return boolean
local function should_enable_vim_regex(config, lang)
  local additional_hl = config.additional_vim_regex_highlighting
  local is_table = type(additional_hl) == "table"

  ---@diagnostic disable-next-line: param-type-mismatch
  return additional_hl and (not is_table or vim.tbl_contains(additional_hl, lang))
end

function begin_ts_highlight(bufnr, lang, owner)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  vim.treesitter.start(bufnr, lang)
  pcall(function()
    local win = vim.fn.win_findbuf(bufnr)[1]
    if not type(win) == "number" and not vim.api.nvim_win_is_valid(win) then
      return
    end
    require("treesitter-context").context_force_update(bufnr, win)
  end)
end

local vim_enter = true

---@param bufnr integer
---@param lang string
function M.attach(bufnr, lang)
  if vim_enter then
    vim.treesitter.start(bufnr, lang)
    vim_enter = false
    return
  end
  local timer = vim.loop.new_timer()
  vim.defer_fn(function()
    local is_active = timer:is_active()
    if is_active then
      vim.notify("Timer haven't been closed!", vim.log.levels.ERROR)
    end
  end, 2000)
  local has_start = false
  local timout = function(opts)
    local force = opts.force
    local time = opts.time
    if not vim.api.nvim_buf_is_valid(bufnr) then
      if timer:is_active() then
        timer:close()
      end
      return
    end
    if (not force) and has_start then
      return
    end
    if timer:is_active() then
      timer:close()
      -- haven't start
      has_start = true
      -- __AUTO_GENERATED_PRINT_VAR_START__
      print([==[ts do not start in ]==], vim.inspect(time)) -- __AUTO_GENERATED_PRINT_VAR_END__
      begin_ts_highlight(bufnr, lang, "highligter")
    end
  end
  vim.defer_fn(function()
    timout { force = false, time = 100 }
  end, 100)
  vim.defer_fn(function()
    timout { force = true, time = 1000 }
  end, 1000)
  local col = vim.fn.screencol()
  local row = vim.fn.screenrow()
  timer:start(1, 2, function()
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(bufnr) then
        if timer:is_active() then
          timer:close()
        end
        return
      end
      if has_start then
        return
      end
      local new_col = vim.fn.screencol()
      local new_row = vim.fn.screenrow()
      if new_row ~= row or new_col ~= col then
        if timer:is_active() then
          timer:close()
          has_start = true
          begin_ts_highlight(bufnr, lang, "highligter")
        end
      end
    end)
  end)
end

---@param bufnr integer
function M.detach(bufnr)
  vim.treesitter.stop(bufnr)
end

---@deprecated
function M.start(...)
  vim.notify(
    "`nvim-treesitter.highlight.start` is deprecated: use `nvim-treesitter.highlight.attach` or `vim.treesitter.start`",
    vim.log.levels.WARN
  )
  M.attach(...)
end

---@deprecated
function M.stop(...)
  vim.notify(
    "`nvim-treesitter.highlight.stop` is deprecated: use `nvim-treesitter.highlight.detach` or `vim.treesitter.stop`",
    vim.log.levels.WARN
  )
  M.detach(...)
end

return M
