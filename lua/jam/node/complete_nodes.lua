local api = vim.api

local CompleteNode = require("jam.node.complete_node")
local utils = require("jam.utils")
local sa = require("jam.utils.safe_array")

---@class CompleteNodes
---@field origin string
---@field nodes CompleteNode[]
---@field selected_node CompleteNode
---@field session Session
---@field start integer
---@field end_ integer
---@field _dummy_head CompleteNode
---@field _dummy_tail CompleteNode
local CompleteNodes = {}

---@param origin string
---@param res response
---@param start_pos integer[]
---@return CompleteNodes
function CompleteNodes.new(origin, res, start_pos, session)
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
    }, { __index = CompleteNodes })

    local dummy_head = CompleteNode.new()
    local dummy_tail = CompleteNode.new()
    result._dummy_head = dummy_head
    result._dummy_tail = dummy_tail

    local prev = dummy_head
    local node
    for _, v in ipairs(res) do
        node = CompleteNode.new(v.origin, v.candidates, start_col, start_pos[1])
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
    result:update_buffer()

    dump(result)
    return result
end

function CompleteNodes:fix_nodes()
    local node = self:head()
    while not node:is_dummy() do
        table.insert(self.nodes, node)
        node = node.next
    end
end

function CompleteNodes:update_buffer()
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

---@return CompleteNode
function CompleteNodes:head()
    return self._dummy_head.next
end

---@return CompleteNode
function CompleteNodes:tail()
    return self._dummy_tail.prev
end

---@return CompleteNode
function CompleteNodes:current()
    return self.selected_node
end

---Return whether the move was successful or not.
---@return boolean
function CompleteNodes:goto_next()
    if not self.selected_node.next:is_dummy() then
        self.selected_node = self.selected_node.next
        return true
    end
    return false
end

---Return whether the move was successful or not.
---@return boolean
function CompleteNodes:goto_prev()
    if not self.selected_node.prev:is_dummy() then
        self.selected_node = self.selected_node.prev
        return true
    end
    return false
end

---@param response response
function CompleteNodes:new_response(response)
    local start = self:head().start
    for i, v in ipairs(response) do
        start = self.nodes[i]:new_candidates(v.candidates, start)
    end
    self:update_buffer()
end

return CompleteNodes
