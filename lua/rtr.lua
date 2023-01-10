---@class rtr.Opts
---@field root_names string[] default: { ".git" }
---@field enabled_buftypes string[] default: { "", "acwrite" }

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
    group = vim.api.nvim_create_augroup("rtr", {}),
    cache = {},
  }, { __index = Rtr })
end

---@param opts rtr.Opts?
---@return nil
function Rtr:setup(opts)
  self.opts = vim.tbl_extend("force", self.default_options, opts or {})
  vim.api.nvim_create_autocmd("BufEnter", {
    group = self.group,
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
  local buftype = vim.api.nvim_buf_get_option(bufnr, "buftype")
  return vim.tbl_contains(self.opts.enabled_buftypes, buftype)
end

local rooter = Rtr.new()

return {
  ---@param opts rtr.Opts?
  setup = function(opts)
    rooter:setup(opts)
  end,
}
