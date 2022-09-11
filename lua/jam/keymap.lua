local api = vim.api

local config = require("jam.config")
local utils = require("jam.utils")
local sa = require("jam.utils.safe_array")

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
end

---@param lhs string | string[]
---@param rhs function | table<string, function>
---@param modes? string | string[]
local function set(lhs, rhs, modes)
    lhs = type(lhs) == "string" and { lhs } or lhs
    vim.validate({
        lhs = { lhs, "t" },
    })
    ---@cast lhs string[]
    if modes ~= nil then
        modes = type(modes) == "string" and { modes } or modes
        vim.validate({
            rhs = { rhs, "f" },
            modes = { modes, "t" },
        })
        ---@cast modes string[]
        local mode_set = sa.new(modes):to_set()

        for _, l in ipairs(lhs) do
            vim.keymap.set("i", l, function()
                if mode_set[vim.b.ime_mode] then
                    rhs()
                else
                    utils.feedkey(l)
                end
            end, { buffer = true })
        end
    else
        vim.validate({ rhs = { rhs, "t" } })
        ---@cast rhs table<string, function>
        for _, l in ipairs(lhs) do
            vim.keymap.set("i", l, function()
                if rhs[vim.b.ime_mode] then
                    rhs[vim.b.ime_mode]()
                else
                    utils.feedkey(l)
                end
            end, { buffer = true })
        end
    end
end

---@param lhs string | string[]
local function del(lhs)
    lhs = type(lhs) == "string" and { lhs } or lhs
    vim.validate({
        lhs = { lhs, "t" },
    })
    ---@cast lhs string[]
    for _, l in ipairs(lhs) do
        vim.keymap.del("i", l, { buffer = true })
    end
end

function Keymap:set()
    sa.new(config.get("mappings")):apply(function(x)
        set(unpack(x))
    end)
end

function Keymap:del()
    sa.new(config.get("mappings")):apply(function(x)
        del(x[1])
    end)
end

return Keymap
