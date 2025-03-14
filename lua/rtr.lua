local config = require "rtr.config"

---@class rtr.Rtr
local M = {
  augroup_name = "rtr",
}

---@return nil
function M.setup()
  ---@return boolean
  local function can_work()
    return not not (vim.fs and vim.fs.root)
  end

  if not can_work() then
    M.error "This plugin needs vim.fs.root"
    return
  end

  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = vim.api.nvim_create_augroup(M.augroup_name, {}),
    callback = M.on_buf_win_enter,
  })
end

---@param ev vim.api.keyset.create_autocmd.callback_args
function M.on_buf_win_enter(ev)
  if not M.is_file(ev.buf) then
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
    M.info("cannot find root for buffer:  %d", ev.buf)
    return
  end
  vim.cmd.lcd(root)
  M.info("Set CWD to %s", root)
end

---@param bufnr integer
---@return boolean
function M.is_file(bufnr)
  if not config.enabled_buftypes then
    return false
  end
  return vim.tbl_contains(config.enabled_buftypes, vim.bo[bufnr].buftype)
end

---@param level integer
---@param fmt string
---@param ... any
function M.notify(level, fmt, ...)
  if config.log_level == false then
    return
  end
  local log_level = config.log_level or level
  local msg = fmt:format(...)
  vim.notify("[rtr] " .. msg, log_level)
end

---@param fmt string
---@param ... any
function M.info(fmt, ...)
  M.notify(vim.log.levels.INFO, fmt, ...)
end

---@param fmt string
---@param ... any
function M.warn(fmt, ...)
  M.notify(vim.log.levels.WARN, fmt, ...)
end

---@param fmt string
---@param ... any
function M.error(fmt, ...)
  M.notify(vim.log.levels.ERROR, fmt, ...)
end

return {
  ---@param opts rtr.Opts?
  setup = function(opts)
    config.setup(opts)
    M.setup()
  end,
}
