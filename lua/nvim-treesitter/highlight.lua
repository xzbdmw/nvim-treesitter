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

---@param bufnr integer
---@param lang string
function M.attach(bufnr, lang)
  if vim.g.vim_enter then
    vim.treesitter.start(bufnr, lang)
    vim.g.vim_enter = false
    return
  end
  require("config.utils").real_enter(function()
    begin_ts_highlight(bufnr, lang, "highligter")
  end, function()
    if not vim.api.nvim_buf_is_valid(bufnr) then
      return false
    end
    if vim.b[bufnr].ts_parse_over then
      return false
    end
    return true
  end, "treesitter-highlight")
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
