local session = require("jam.session")
local utils = require("jam.utils")

local action = {}

function action.start()
    session:start()
end

function action.backspace()
    session:backspace()
end

function action.complete()
    session:complete()
end

function action.convert_hira()
    session:convert_hira()
end

function action.convert_zen_kata()
    session:convert_zen_kata()
end

function action.convert_zen_eisuu()
    session:convert_zen_eisuu()
end

function action.convert_han_kata()
    session:convert_han_kata()
end

function action.convert_han_eisuu()
    session:convert_han_eisuu()
end

function action.cancel()
    session:cancel()
end

function action.insert_next_item()
    session:insert_item(1)
end

function action.insert_prev_item()
    session:insert_item(-1)
end

function action.goto_next()
    session:goto_next()
end

function action.goto_prev()
    session:goto_prev()
end

function action.goto_head()
    session:goto_head()
end

function action.goto_tail()
    session:goto_tail()
end

function action.extend()
    session:extend()
end

function action.shorten()
    session:shorten()
end

function action.confirm()
    session:confirm()
end

function action.exit()
    session:exit()
end

function action.zenkaku_space()
    session:_mode_validate("PreInput")
    utils.feedkey("　")
end

---@param rhs function
---@param modes string | string[]
---@return table<string, function>
function action.mapping(rhs, modes)
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
end

return action
