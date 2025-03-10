local config = require "rtr.config"

---@class rtr.Rtr
---@field augroup_name string
local Rtr = {}

---@return rtr.Rtr
Rtr.new = function()
  return setmetatable({ augroup_name = "rtr" }, { __index = Rtr })
end

---@return nil
function Rtr:setup()
  ---@return boolean
  local function can_work()
    return not not (vim.fs and vim.fs.root)
  end

  if not can_work() then
    self:notify("This plugin needs vim.fs.root", vim.log.levels.ERROR)
    return
  end

  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = vim.api.nvim_create_augroup(self.augroup_name, {}),
    callback = function(ev)
      self:on_buf_win_enter(ev)
    end,
  })
end

---@param ev vim.api.keyset.create_autocmd.callback_args
function Rtr:on_buf_win_enter(ev)
  if not self:is_file(ev.buf) then
    return
  end
  if config.disabled_filetypes then
    if vim.tbl_contains(config.disabled_filetypes, vim.bo[ev.buf].filetype) then
      return
    end
  end
  if config.buf_filter and not config.buf_filter(ev.buf) then
    return
  end
  local root = vim.fs.root(ev.buf, config.root_names)
  if not root then
    self:notify(("cannot find root for buffer:  %d"):format(ev.buf))
    return
  end
  vim.cmd.lcd(root)
  self:notify("Set CWD to " .. root)
end

---@param bufnr integer
---@return boolean
function Rtr:is_file(bufnr)
  if not config.enabled_buftypes then
    return false
  end
  return vim.tbl_contains(config.enabled_buftypes, vim.bo[bufnr].buftype)
end

---@param msg string
---@param level integer?
function Rtr:notify(msg, level)
  local log_level = level or config.log_level
  if log_level then
    vim.notify("[rtr] " .. msg, log_level)
  end
end

local rtr = Rtr.new()

return {
  ---@param opts rtr.Opts?
  setup = function(opts)
    config.setup(opts)
    rtr:setup()
  end,
  rtr = rtr,
}
