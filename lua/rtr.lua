---@class rtr.Opts
---@field root_names string|string[]|fun(name: string): boolean default: { ".git" }
---@field disabled_filetypes string[]|false|nil default: nil
---@field enabled_buftypes string[]|false|nil default: { "", "acwrite" }
---@field buf_filter (fun(bufnr: integer): boolean)|false|nil default: nil

---@class rtr.EventInfo
---@field buf integer

---@class rtr.Rtr
---@field default_options rtr.Opts
---@field opts rtr.Opts
---@field augroup_name string
---@field cache table<string, string>
local Rtr = {}

---@return rtr.Rtr
Rtr.new = function()
  return setmetatable({
    default_options = { root_names = { ".git" }, enabled_buftypes = { "", "acwrite" } },
    augroup_name = "rtr",
    cache = {},
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

  self.opts = vim.tbl_extend("force", self.default_options, opts or {})
  vim.validate {
    root_names = { self.opts.root_names, { "string", "table", "function" } },
    disabled_filetypes = { self.opts.disabled_filetypes, orFalseOrNil "table" },
    enabled_buftypes = { self.opts.enabled_buftypes, orFalseOrNil "table" },
    buf_filter = { self.opts.buf_filter, orFalseOrNil "function" },
  }
  vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup(self.augroup_name, {}),
    ---@param ev rtr.EventInfo
    callback = function(ev)
      self:on_buf_enter(ev)
    end,
  })
end

---@param ev rtr.EventInfo
function Rtr:on_buf_enter(ev)
  if not self:is_file(ev.buf) then
    return
  end
  if self.opts.disabled_filetypes then
    local ft = vim.api.nvim_buf_get_option(ev.buf, "filetype")
    if vim.tbl_contains(self.opts.disabled_filetypes, ft) then
      return true
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
  if not self.cache[dir] then
    local root_file = vim.fs.find(self.opts.root_names, { path = dir, upward = true })[1]
    if not root_file then
      return
    end
    self.cache[dir] = vim.fs.dirname(root_file)
  end
  vim.api.nvim_set_current_dir(self.cache[dir])
  vim.notify("[rooter] Set CWD to " .. self.cache[dir], vim.log.levels.DEBUG)
end

---@param bufnr integer
---@return boolean
function Rtr:is_file(bufnr)
  if not self.opts.enabled_buftypes then
    return false
  end
  local buftype = vim.api.nvim_buf_get_option(bufnr, "buftype")
  return vim.tbl_contains(self.opts.enabled_buftypes, buftype)
end

local rtr = Rtr.new()

return {
  ---@param opts rtr.Opts?
  setup = function(opts)
    rtr:setup(opts)
  end,
  rtr = rtr,
}
