local api = vim.api

local Keymap = {
    buffer_mapping = {},
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

function Keymap.store()
    Keymap.buffer_mapping = vim.tbl_map(fix, api.nvim_buf_get_keymap(0, "i"))
    for _, map in ipairs(Keymap.buffer_mapping) do
        api.nvim_buf_del_keymap(0, "i", map.lhs)
    end
end

function Keymap.restore()
    for _, m in ipairs(Keymap.buffer_mapping) do
        api.nvim_buf_set_keymap(0, "i", m.lhs, m.rhs, m.opt)
    end
end

return Keymap
