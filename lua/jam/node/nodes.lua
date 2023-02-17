local utils = require("jam.utils")

---@class Nodes
---@field nodes Node[]
---@field selected_node Node
---@field _dummy_head Node
---@field _dummy_tail Node
---@field row integer 1-index
---@field start integer 1-index
---@field end_ integer 1-index
local Nodes = {}

---@return Node
function Nodes:current()
  return self.selected_node
end

---@return Node
function Nodes:head()
  return self._dummy_head.next
end

---@return Node
function Nodes:tail()
  return self._dummy_tail.prev
end

---@return boolean
function Nodes:is_head()
  return self:current() == self:head()
end

---@return boolean
function Nodes:is_tail()
  return self:current() == self:tail()
end

function Nodes:fix_nodes()
  self.nodes = {}
  local node = self:head()
  while node:is_valid() do
    table.insert(self.nodes, node)
    node = node.next
  end
end

---@param idx integer
---@return Node
function Nodes:get_by_idx(idx)
  if idx == 0 then
    return self._dummy_head
  elseif idx == #self.nodes + 1 then
    return self._dummy_tail
  else
    utils.range_validate(self.nodes, idx)
    return self.nodes[idx]
  end
end

---@return boolean
function Nodes:goto_prev()
  if self:current().prev:is_valid() then
    self.selected_node = self:current().prev
    return true
  end
  return false
end

---@return boolean
function Nodes:goto_next()
  if self:current().next:is_valid() then
    self.selected_node = self:current().next
    return true
  end
  return false
end

---@return boolean
function Nodes:goto_head()
  if not self:is_head() then
    self.selected_node = self:head()
    return true
  end
  return false
end

---@return boolean
function Nodes:goto_tail()
  if not self:is_tail() then
    self.selected_node = self:tail()
    return true
  end
  return false
end

return Nodes
