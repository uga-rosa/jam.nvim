local session = require("japanese_ime.session")
local keymap = require("japanese_ime.keymap")

local action = {}

function action.start()
    session:start()
    keymap:store()
    keymap:set()
end

function action.backspace()
    session:backspace()
end

function action.complete()
    session:complete()
end

function action.insert_next_item()
    session:insert_item(1)
end

function action.insert_prev_item()
    session:insert_item(-1)
end

function action.next()
    session:move(1)
end

function action.prev()
    session:move(-1)
end

function action.extend()
    session.completeNodes:current():extend()
end

function action.shorten()
    session.completeNodes:current():shorten()
end

function action.confirm()
    session:confirm()
end

function action.exit()
    session:exit()
    keymap:del()
    keymap:restore()
end

return action
