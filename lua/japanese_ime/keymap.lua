local api = vim.api

local sa = require("japanese_ime.utils").sa

local Keymap = {
    buffer_mappings = {},
    mappings = {},
}

local function fix(map)
    return {
        lhs = map.lhs,
        rhs = map.rhs or "",
        opt = {
            callback = map.callback,
            expr = map.expr == 1,
            noremap = map.noremap == 1,
            nowait = map.nowait == 1,
            script = map.script == 1,
            silent = map.silent == 1,
        },
    }
end

function Keymap:store()
    self.buffer_mappings = vim.tbl_map(fix, api.nvim_buf_get_keymap(0, "i"))
    for _, map in ipairs(self.buffer_mappings) do
        api.nvim_buf_del_keymap(0, "i", map.lhs)
    end
end

function Keymap:restore()
    for _, m in ipairs(self.buffer_mappings) do
        api.nvim_buf_set_keymap(0, "i", m.lhs, m.rhs, m.opt)
    end
end

---@param lhs string
---@param rhs function
---@param modes string | string[]
local function set(lhs, rhs, modes)
    vim.validate({
        lhs = { lhs, "s" },
        rhs = { rhs, "f" },
        modes = { modes, { "s", "t" } },
    })
    ---@cast modes table
    modes = type(modes) == "string" and { modes } or modes

    local mode_set = sa.new(modes):to_set()

    vim.keymap.set("i", lhs, function()
        if mode_set[vim.b.ime_mode] then
            rhs()
        end
    end, { buffer = true })
end

---@param lhs string
local function del(lhs)
    vim.keymap.del("i", lhs, { buffer = true })
end

function Keymap:set()
    sa.new(self.mappings):apply(function(x)
        set(unpack(x))
    end)
end

function Keymap:del()
    sa.new(self.mappings):apply(function(x)
        del(x[1])
    end)
end

return Keymap
