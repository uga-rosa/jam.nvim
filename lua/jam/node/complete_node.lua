local api = vim.api

local utf8 = require("jam.utils.utf8")
local utils = require("jam.utils")
local pum = require("jam.utils.pum")

---@alias complete_items {word: string}[]

---@class CompleteNode
---@field origin string
---@field candidates complete_items
---@field selected_candidate string
---@field start integer #byte index of col
---@field end_ integer #byte index of col
---@field row integer #lnum
---@field prev CompleteNode
---@field next CompleteNode
---@field parent CompleteNodes
---@field session Session
local CompleteNode = {}

---@param a string[]
---@return complete_items
local function array2complete_items(a)
    return vim.tbl_map(function(c)
        return { word = c }
    end, a)
end

---@param origin string
---@param candidates string[]
---@param start_col integer
---@param start_row integer
---@return CompleteNode
---@overload fun(): CompleteNode
function CompleteNode.new(origin, candidates, start_col, start_row)
    if origin == nil then
        -- dummy node
        return setmetatable({}, { __index = CompleteNode })
    end

    vim.validate({
        origin = { origin, "s" },
        candidates = { candidates, "t" },
        start_col = { start_col, "n" },
        start_row = { start_row, "n" },
    })

    local new = {
        origin = origin,
        candidates = array2complete_items(candidates),
        selected_candidate = candidates[1],
        start = start_col,
        end_ = start_col + #candidates[1] - 1,
        row = start_row,
    }
    return setmetatable(new, { __index = CompleteNode })
end

function CompleteNode:is_dummy()
    return self.origin == nil
end

function CompleteNode:is_valid()
    return not self:is_dummy()
end

function CompleteNode:complete()
    self:move()
    pum.open(self.start, self.candidates)
end

---@param delta integer
function CompleteNode:insert_relative(delta)
    pum.map.insert_relative(delta)
    local selected = pum.selected_word()
    self.selected_candidate = selected
    self.end_ = self.start + #selected - 1

    local next = self.next
    while next:is_valid() do
        next.start = next.prev.end_ + 1
        next.end_ = next.start + #next.selected_candidate - 1
        next = next.next
    end
    self.parent.end_ = self.parent:tail().end_
end

function CompleteNode:move()
    api.nvim_win_set_cursor(0, { self.row, self.end_ })
end

function CompleteNode:extend()
    if self.next:is_valid() then
        local next_char = utils.get_char(self.next.origin, 1)
        print(next_char)
        self.origin = self.origin .. next_char
        self.end_ = self.end_ + #next_char

        self.next.origin = self.next.origin:sub(#next_char + 1)
        if self.next.origin == "" then
            self.next.next.prev = self
            self.next = self.next.next
            self.parent:fix_nodes()
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
            local new = CompleteNode.new(last_char, {}, self.end_ + 1, self.row)
            self.next.prev = new
            new.next = self.next
            self.next = new
            new.prev = self
            self.parent:fix_nodes()
        end

        self.session:complete()
    end
end

---@param new_candidates string[]
---@param start integer
---@return integer
function CompleteNode:new_candidates(new_candidates, start)
    self.candidates = array2complete_items(new_candidates)
    self.selected_candidate = new_candidates[1]
    self.start = start
    self.end_ = start + #new_candidates[1] - 1
    return self.end_ + 1
end

return CompleteNode
