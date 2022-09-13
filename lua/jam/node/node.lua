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

return Node
