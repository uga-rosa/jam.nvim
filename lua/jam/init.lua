local config = require("jam.config")
local session = require("jam.session")
local utils = require("jam.utils")

local jam = {
    mapping = {},
}

---@param opt table?
function jam.setup(opt)
    config.setup(opt or {})
end

setmetatable(jam.mapping, {
    ---@param rhs function
    ---@param modes string | string[]
    ---@return table<string, function>
    __call = function(_, rhs, modes)
        modes = utils.cast2tbl(modes)
        vim.validate({
            rhs = { rhs, "f" },
            modes = { modes, "t" },
        })
        local result = {}
        for _, mode in ipairs(modes) do
            vim.validate({ mode = { mode, "s" } })
            result[mode] = rhs
        end
        return result
    end,
})

function jam.mapping.start()
    session:start()
end

function jam.mapping.backspace()
    session:backspace()
end

function jam.mapping.complete()
    session:complete()
end

function jam.mapping.convert_hira()
    session:convert_hira()
end

function jam.mapping.convert_zen_kata()
    session:convert_zen_kata()
end

function jam.mapping.convert_zen_eisuu()
    session:convert_zen_eisuu()
end

function jam.mapping.convert_han_kata()
    session:convert_han_kata()
end

function jam.mapping.convert_han_eisuu()
    session:convert_han_eisuu()
end

function jam.mapping.cancel()
    session:cancel()
end

function jam.mapping.insert_next_item()
    session:insert_item(1)
end

function jam.mapping.insert_prev_item()
    session:insert_item(-1)
end

function jam.mapping.goto_next()
    session:goto_next()
end

function jam.mapping.goto_prev()
    session:goto_prev()
end

function jam.mapping.goto_head()
    session:goto_head()
end

function jam.mapping.goto_tail()
    session:goto_tail()
end

function jam.mapping.extend()
    session:extend()
end

function jam.mapping.shorten()
    session:shorten()
end

function jam.mapping.confirm()
    session:confirm()
end

function jam.mapping.exit()
    session:exit()
end

function jam.mapping.zenkaku_space()
    session:_mode_validate("PreInput")
    utils.feedkey("　")
end

return jam
