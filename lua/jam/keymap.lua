local api = vim.api

local config = require("jam.config")
local utils = require("jam.utils")

local Keymap = {
    buffer_mappings = {},
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
    self.buffer_mappings = {}
end

---@param lhs string
---@param rhs table<string, function>
local function set(lhs, rhs)
    vim.validate({
        lhs = { lhs, "s" },
        rhs = { rhs, "t" },
    })

    vim.keymap.set("i", lhs, function()
        if rhs[vim.b.ime_mode] then
            rhs[vim.b.ime_mode]()
        else
            utils.feedkey(lhs)
        end
    end, { buffer = true })
end

---@param lhs string
local function del(lhs)
    vim.validate({
        lhs = { lhs, "s" },
    })
    vim.keymap.del("i", lhs, { buffer = true })
end

function Keymap:set()
    for lhs, rhs in pairs(config.get("mappings")) do
        set(lhs, rhs)
    end
end

function Keymap:del()
    for lhs, _ in pairs(config.get("mappings")) do
        del(lhs)
    end
end

return Keymap
