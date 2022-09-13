local api = vim.api

---@class Node
---@field start integer #byte index of col
---@field end_ integer #byte index of col
---@field row integer #lnum
---@field prev Node
---@field next Node
---@field parent Nodes
---@field is_dummy boolean
local Node = {}

function Node.new()
    return setmetatable({}, { __index = Node })
end

function Node:move()
    api.nvim_win_set_cursor(0, { self.row, self.end_ })
end

---@return boolean
function Node:is_selected()
    return self == self.parent:current()
end

---@return boolean
function Node:is_valid()
    return not self.is_dummy
end

---@return integer
function Node:get_idx()
    for i, node in ipairs(self.parent.nodes) do
        if node == self then
            return i
        end
    end
    error("Independent node")
end

function Node:delete()
    self.next.prev = self.prev
    self.prev.next = self.next
    self.parent:fix_nodes()
end

---@param node Node
function Node:insert_next(node)
    local prev = self
    local next = self.next
    node.prev = prev
    node.next = next
    next.prev = node
    prev.next = node
    self.parent:fix_nodes()
end

return Node
