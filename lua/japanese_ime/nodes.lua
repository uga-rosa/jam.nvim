local api = vim.api

local utf8 = require("japanese_ime.utf8")
local pum = require("japanese_ime.pum")
local _utils = require("japanese_ime.utils")
local sa = _utils.sa
local utils = _utils.utils

---@alias complete_items {word: string}[]

---@class CandidateNode
---@field origin string
---@field candidates complete_items
---@field selected_candidate string
---@field start integer #byte index of col
---@field end_ integer #byte index of col
---@field row integer #lnum
---@field prev CandidateNode
---@field next CandidateNode
---@field parent CandidateNodes
---@field session Session
local CandidateNode = {}

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
---@return CandidateNode
---@overload fun(): CandidateNode
function CandidateNode.new(origin, candidates, start_col, start_row)
    if origin == nil then
        -- dummy node
        return setmetatable({}, { __index = CandidateNode })
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
    return setmetatable(new, { __index = CandidateNode })
end

function CandidateNode:is_dummy()
    return self.origin == nil
end

function CandidateNode:complete()
    self:move()
    pum.open(self.start, self.candidates)
end

---@param delta integer
function CandidateNode:insert_relative(delta)
    pum.map.insert_relative(delta)
    local selected = pum.selected_word()
    self.selected_candidate = selected
    self.end_ = self.start + #selected - 1

    local next = self.next
    while not next:is_dummy() do
        next.start = next.prev.end_ + 1
        next.end_ = next.start + #next.selected_candidate - 1
        next = next.next
    end
    self.parent.end_ = self.parent:tail().end_
end

function CandidateNode:move()
    api.nvim_win_set_cursor(0, { self.row, self.end_ })
end

---@param n integer
---@return string
function CandidateNode:get_char(n)
    local start = utf8.offset(self.origin, n)
    if not start then
        error("Out of bounds")
    end
    if n == -1 then
        return self.origin:sub(start)
    end
    local end_ = utf8.offset(self.origin, n + 1)
    if not end_ then
        error("Out of bounds")
    end
    return self.origin:sub(start, end_)
end

function CandidateNode:extend()
    if not self.next:is_dummy() then
        local next_char = self.next:get_char(1)
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

function CandidateNode:shorten()
    if utf8.len(self.origin) > 1 then
        local last_char = self:get_char(-1)
        self.origin = self.origin:sub(1, -(#last_char + 1))
        self.end_ = self.end_ - #last_char

        if not self.next:is_dummy() then
            self.next.origin = last_char .. self.next.origin
            self.next.start = self.next.start - #last_char
        else
            local new = CandidateNode.new(last_char, {}, self.end_ + 1, self.row)
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
function CandidateNode:new_candidates(new_candidates, start)
    self.candidates = array2complete_items(new_candidates)
    self.selected_candidate = new_candidates[1]
    self.start = start
    self.end_ = start + #new_candidates[1] - 1
    return self.end_ + 1
end

---@class CandidateNodes
---@field origin string
---@field nodes CandidateNode[]
---@field selected_node CandidateNode
---@field session Session
---@field start integer
---@field end_ integer
---@field _dummy_head CandidateNode
---@field _dummy_tail CandidateNode
local CandidateNodes = {}

---@param origin string
---@param res response
---@param start_pos integer[]
---@return CandidateNodes
function CandidateNodes.new(origin, res, start_pos, session)
    vim.validate({
        req = { res, "t" },
        start_pos = { start_pos, "t" },
        start_row = { start_pos[1], "n" },
        start_col = { start_pos[2], "n" },
    })
    assert(#res > 0)
    local start_col = start_pos[2]

    local result = setmetatable({
        origin = origin,
        nodes = {},
        session = session,
        start = start_col,
        end_ = start_col + #origin - 1,
    }, { __index = CandidateNodes })

    local dummy_head = CandidateNode.new()
    local dummy_tail = CandidateNode.new()
    result._dummy_head = dummy_head
    result._dummy_tail = dummy_tail

    local prev = dummy_head
    local node
    for _, v in ipairs(res) do
        node = CandidateNode.new(v.origin, v.candidates, start_col, start_pos[1])
        node.parent = result
        node.session = session
        node.prev = prev
        prev.next = node
        start_col = node.end_ + 1
        prev = node
    end
    node.next = dummy_tail
    dummy_tail.prev = node

    result.selected_node = node

    result:fix_nodes()
    result:update_current_line()

    return result
end

function CandidateNodes:fix_nodes()
    local node = self:head()
    while not node:is_dummy() do
        table.insert(self.nodes, node)
        node = node.next
    end
end

function CandidateNodes:update_current_line()
    local text = sa.new(self.nodes)
        :map(function(node)
            return node.selected_candidate
        end)
        :concat()
    local current_line = api.nvim_get_current_line()
    local new_line = utils.insert(current_line, text, self.start, self.end_)
    api.nvim_set_current_line(new_line)
    self.start = self:head().start
    self.end_ = self:tail().end_
end

---@return CandidateNode
function CandidateNodes:head()
    return self._dummy_head.next
end

---@return CandidateNode
function CandidateNodes:tail()
    return self._dummy_tail.prev
end

---@return CandidateNode
function CandidateNodes:current()
    return self.selected_node
end

---Return whether the move was successful or not.
---@return boolean
function CandidateNodes:goto_next()
    if not self.selected_node.next:is_dummy() then
        self.selected_node = self.selected_node.next
        return true
    end
    return false
end

---Return whether the move was successful or not.
---@return boolean
function CandidateNodes:goto_prev()
    if not self.selected_node.prev:is_dummy() then
        self.selected_node = self.selected_node.prev
        return true
    end
    return false
end

---@param response response
function CandidateNodes:new_response(response)
    local start = self:head().start
    for i, v in ipairs(response) do
        start = self.nodes[i]:new_candidates(v.candidates, start)
    end
    self:update_current_line()
end

return CandidateNodes
