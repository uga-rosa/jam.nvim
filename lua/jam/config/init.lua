local M = {
  config = {},
}

---@param opt table
function M.setup(opt)
  vim.validate({
    opt = { opt, "t" },
  })

  M.config = require("jam.config.default")
  if opt.disable_default_mappings then
    M.config.mappings = {}
  end

  for k, v in pairs(opt) do
    if k == "mappings" then
      for lhs, rhs in pairs(v) do
        M.config.mappings[lhs] = rhs
      end
    else
      M.config[k] = v
    end
  end

  vim.validate({
    ["config.keyLayout"] = { M.config.keyLayout, "s" },
    ["config.start_key"] = { M.config.start_key, "s" },
    ["config.mappings"] = { M.config.mappings, "t" },
  })

  vim.keymap.set("i", M.config.start_key, require("jam").mapping.start, {})
end

---@param name string
---@return unknown
function M.get(name)
  return M.config[name] or error("Invalid option name: " .. name)
end

return M
