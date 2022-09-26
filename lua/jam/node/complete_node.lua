local api = vim.api

local Node = require("jam.node.node")
local utf8 = require("jam.utils.utf8")
local utils = require("jam.utils")
local pum = require("jam.utils.pum")

---@alias complete_items { word: string }[]

---@class CompleteNode: Node
---@field prev CompleteNode
---@field next CompleteNode
---@field parent CompleteNodes
---@field origin string
---@field candidates complete_items
---@field selected_candidate string
---@field cursor integer
---@field session Session
---@field skip_count integer
local CompleteNode = setmetatable({}, { __index = Node })

---@param array string[]
---@param marker string[]
---@return complete_items
local function array_to_complete_items(array, marker)
    local candidates = {}
    for i, w in ipairs(array) do
        candidates[i] = { word = w, menu = marker[i] }
    end
    return candidates
end

---@param origin string
---@param candidates string[]
---@param col integer
---@param row integer
---@param parent CompleteNodes
---@param session Session
---@return CompleteNode
---@overload fun(): CompleteNode
function CompleteNode.new(origin, candidates, col, row, parent, session)
    if origin == nil then
        -- dummy node
        return setmetatable({ is_dummy = true }, { __index = CompleteNode })
    end

    vim.validate({
        origin = { origin, "s" },
        candidates = { candidates, "t" },
        col = { col, "n" },
        row = { row, "n" },
    })

    local new = {
        origin = origin,
        candidates = array_to_complete_items(candidates, session.marker),
        selected_candidate = candidates[1],
        start = col,
        end_ = col + #candidates[1] - 1,
        row = row,
        parent = parent,
        session = session,
        skip_count = 0,
    }
    return setmetatable(new, { __index = CompleteNode })
end

---@param candidates complete_items
---@param marker string[]
---@return integer
local function max_width(candidates, marker)
    local max = api.nvim_strwidth(candidates[1].word .. marker[1])
    for i = 2, #candidates do
        local width = api.nvim_strwidth(candidates[i].word .. marker[i])
        if max < width then
            max = width
        end
    end
    return max + 1
end

function CompleteNode:complete()
    self:move()
    pum.set_option("max_width", max_width(self.candidates, self.session.marker))
    pum.open(self.start, self.candidates)
    self.cursor = 1

    for i = 1, #self.candidates do
        local m = self.session.marker[i]
        vim.keymap.set("i", m, function()
            self:cursor_set(i)
        end, { buffer = true })
    end
end

function CompleteNode:close()
    for i = 1, #self.candidates do
        local m = self.session.marker[i]
        vim.keymap.del("i", m, { buffer = true })
    end
    pum.close()
end

---@param x number
---@param min number
---@param max number
---@return number
---@return boolean looped
local function loop(x, min, max)
    if x < min then
        return max, true
    elseif max < x then
        return min, true
    end
    return x, false
end

---@param delta 1 | -1
function CompleteNode:insert_relative(delta)
    pum.map.insert_relative(delta)

    self.cursor = loop(self.cursor + delta, 0, #self.candidates)
    local index = self.cursor == 0 and 1 or self.cursor
    local selected = self.candidates[index].word
    self.selected_candidate = selected
    self.end_ = self.start + #selected - 1
    self.skip_count = assert(utf8.len(selected))

    local next = self.next
    while next:is_valid() do
        next.start = next.prev.end_ + 1
        next.end_ = next.start + #next.selected_candidate - 1
        next = next.next
    end
    self.parent.end_ = self.parent:tail().end_
end

---@param cursor integer
function CompleteNode:cursor_set(cursor)
    if cursor ~= self.cursor then
        self:insert_relative(cursor - self.cursor)
    end
end

---Fired on InsertCharPre
---@return boolean
function CompleteNode:_skip()
    if self.skip_count > 0 then
        self.skip_count = self.skip_count - 1
        return true
    end
    return false
end

function CompleteNode:extend()
    if self.next:is_valid() then
        local next_char = utils.get_char(self.next.origin, 1)
        self.origin = self.origin .. next_char
        self.end_ = self.end_ + #next_char

        self.next.origin = self.next.origin:sub(#next_char + 1)
        if self.next.origin == "" then
            self.next:delete()
        else
            self.next.start = self.next.start + #next_char
        end

        self.session:complete()
    end
end

function CompleteNode:shorten()
    if utf8.len(self.origin) > 1 then
        local last_char = utils.get_char(self.origin, -1)
        self.origin = self.origin:sub(1, -(#last_char + 1))
        self.end_ = self.end_ - #last_char

        if self.next:is_valid() then
            self.next.origin = last_char .. self.next.origin
            self.next.start = self.next.start - #last_char
        else
            local next_node = CompleteNode.new(
                last_char,
                { last_char },
                self.end_ + 1,
                self.row,
                self.parent,
                self.session
            )
            self:insert_next(next_node)
        end

        self.session:complete()
    end
end

---@param new_candidates string[]
---@param start integer
---@return integer
function CompleteNode:new_candidates(new_candidates, start)
    self.candidates = array_to_complete_items(new_candidates, self.session.marker)
    self.candidates_idx = 1
    self.selected_candidate = new_candidates[1]
    self.start = start
    self.end_ = start + #new_candidates[1] - 1
    return self.end_ + 1
end

return CompleteNode
