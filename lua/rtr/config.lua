---@class rtr.Opts
---@field root_names string|string[]|(fun(name: string, path: string): boolean)|nil default: { ".git" }
---@field disabled_filetypes string[]|false|nil default: nil
---@field enabled_buftypes string[]|false|nil default: { "", "acwrite" }
---@field buf_filter (fun(bufnr: integer): boolean)|false|nil default: nil
---@field log_level integer|false|nil default: nil

---@class rtr.Default: rtr.Opts
---@field root_names string|string[]|fun(name: string, path: string): boolean default: { ".git" }
---@field enabled_buftypes string[]|false default: { "", "acwrite" }

---@class rtr.Config: rtr.Default
---@field values rtr.Default
local Config = {}

---@type rtr.Default
Config.default = { root_names = { ".git" }, enabled_buftypes = { "", "acwrite" } }

---@return rtr.Config
Config.new = function()
  return setmetatable({ values = Config.default }, {
    __index = function(self, key)
      local keys = {
        root_names = true,
        default = true,
        disabled_filetypes = true,
        enabled_buftypes = true,
        buf_filter = true,
        log_level = true,
      }
      if key == "values" then
        return rawget(self, key)
      elseif keys[key] then
        return rawget(rawget(self, "values"), key)
      end
      return rawget(Config, key)
    end,
  })
end

local config = Config.new()

---@param opts? rtr.Opts
Config.setup = function(opts)
  opts = vim.tbl_extend("force", Config.default, opts or {})
  local function false_or_nil_or(typ)
    return function(v)
      return type(v) == typ or v == false or v == nil
    end,
      true,
      ("%s or false or nil"):format(typ)
  end
  if vim.fn.has "nvim-0.11" == 1 then
    vim.validate("root_names", opts.root_names, { "string", "table", "function" }, true)
    vim.validate("disabled_filetypes", opts.disabled_filetypes, false_or_nil_or "table")
    vim.validate("enabled_buftypes", opts.enabled_buftypes, false_or_nil_or "table")
    vim.validate("buf_filter", opts.buf_filter, false_or_nil_or "function")
    vim.validate("log_level", opts.log_level, false_or_nil_or "number")
  else
    vim.validate {
      root_names = { opts.root_names, { "string", "table", "function" }, true },
      disabled_filetypes = { opts.disabled_filetypes, false_or_nil_or "table" },
      enabled_buftypes = { opts.enabled_buftypes, false_or_nil_or "table" },
      buf_filter = { opts.buf_filter, false_or_nil_or "function" },
      log_level = { opts.log_level, false_or_nil_or "number" },
    }
  end
  config.values = opts
end

return config
