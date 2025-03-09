---@class rtr.Opts
---@field root_names string|string[]|fun(name: string): boolean default: { ".git" }
---@field disabled_filetypes string[]|false|nil default: nil
---@field enabled_buftypes string[]|false|nil default: { "", "acwrite" }
---@field buf_filter (fun(bufnr: integer): boolean)|false|nil default: nil
---@field log_level integer|false|nil default: nil

---@class rtr.InstanceOpts: rtr.Opts
---@field enabled_buftypes string[]|false

---@class rtr.EventInfo
---@field buf integer

---@class rtr.Rtr
---@field default_options rtr.Opts
---@field opts rtr.InstanceOpts
---@field augroup_name string
local Rtr = {}

---@return rtr.Rtr
Rtr.new = function()
  return setmetatable({
    default_options = { root_names = { ".git" }, enabled_buftypes = { "", "acwrite" } },
    augroup_name = "rtr",
  }, { __index = Rtr })
end

---@param opts rtr.Opts?
---@return nil
function Rtr:setup(opts)
  ---@param typ string
  ---@return (fun(v: any): boolean), string
  local function orFalseOrNil(typ)
    return function(v)
      return type(v) == typ or v == false or v == nil
    end,
      ("should be a %s or false or nil"):format(typ)
  end

  ---@return boolean
  local function can_work()
    return not not (vim.fs and vim.fs.find)
  end

  if not can_work() then
    self:notify("This plugin needs vim.fs.find", vim.log.levels.ERROR)
    return
  end

  self.opts = vim.tbl_extend("force", self.default_options, opts or {})
  vim.validate {
    root_names = { self.opts.root_names, { "string", "table", "function" } },
    disabled_filetypes = { self.opts.disabled_filetypes, orFalseOrNil "table" },
    enabled_buftypes = { self.opts.enabled_buftypes, orFalseOrNil "table" },
    buf_filter = { self.opts.buf_filter, orFalseOrNil "function" },
    log_level = { self.opts.log_level, orFalseOrNil "number" },
  }
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = vim.api.nvim_create_augroup(self.augroup_name, {}),
    ---@param ev rtr.EventInfo
    callback = function(ev)
      self:on_buf_win_enter(ev)
    end,
  })
end

---@param ev rtr.EventInfo
function Rtr:on_buf_win_enter(ev)
  if not self:is_file(ev.buf) then
    return
  end
  if self.opts.disabled_filetypes then
    if vim.tbl_contains(self.opts.disabled_filetypes, vim.bo[ev.buf].filetype) then
      return
    end
  end
  if self.opts.buf_filter and not self.opts.buf_filter(ev.buf) then
    return
  end
  local file = vim.api.nvim_buf_get_name(ev.buf)
  if file == "" then
    return
  end
  local dir = vim.fs.dirname(file)
  local root_file = vim.fs.find(self.opts.root_names, { path = dir, upward = true })[1]
  if not root_file then
    return
  end
  local result = vim.fs.dirname(root_file)
  vim.cmd.lcd(result)
  self:notify("Set CWD to " .. result)
end

---@param bufnr integer
---@return boolean
function Rtr:is_file(bufnr)
  if not self.opts.enabled_buftypes then
    return false
  end
  return vim.tbl_contains(self.opts.enabled_buftypes, vim.bo[bufnr].buftype)
end

---@param msg string
---@param level integer?
function Rtr:notify(msg, level)
  local log_level = level or self.opts.log_level
  if log_level then
    vim.notify("[rtr] " .. msg, log_level)
  end
end

local rtr = Rtr.new()

return {
  ---@param opts rtr.Opts?
  setup = function(opts)
    rtr:setup(opts)
  end,
  rtr = rtr,
}
