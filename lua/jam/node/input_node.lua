local Node = require("jam.node.node")
local GoogleInput = require("jam.utils.google_input")

---@class InputNode: Node
---@field raw_str string
---@field output string
---@field display string
---@field status input_status
---@field gi GoogleInput
---@field prev InputNode
---@field next InputNode
---@field parent InputNodes
local InputNode = setmetatable({}, { __index = Node })

---@param col integer
---@param row integer
---@param parent InputNodes
---@param input_buffer? string
---@return InputNode
---@overload fun(parent: InputNodes): InputNode
function InputNode.new(col, row, parent, input_buffer)
  if row == nil then
    return setmetatable({ is_dummy = true, parent = col }, { __index = InputNode })
  end
  local new = setmetatable({
    start = col,
    end_ = col - 1,
    row = row,
    parent = parent,
    gi = GoogleInput.new(input_buffer),
  }, { __index = InputNode })
  new:reset()
  return new
end

function InputNode:reset()
  self.raw_str = ""
  self.output = ""
  self.display = ""
  self.status = "continued"
end

---@param char string v:char
function InputNode:input(char)
  self.raw_str = self.raw_str .. char
  local result = self.gi:input(char)
  self.status = result.status
  if result.status == "continued" then
    self.display = self.gi.input_buffer
    self:update_end()
  else
    if result.status == "finished" then
      self.output = result.fixed.output
    else
      self.output = result.input
    end
    self.display = self.output
    self:update_end()
    local next_node = InputNode.new(self.end_ + 1, self.row, self.parent, self.gi.input_buffer)
    self:insert_next(next_node)
    self.parent.selected_node = next_node
    if result.status == "mistyped" then
      result = next_node.gi:input(char)
      next_node.status = result.status
      if result.status == "mistyped" then
        -- Inputed char that doesn't exist in rules.
        self.output = self.output .. char
        self.display = self.output
        self:update_end()
      elseif result.status == "continued" then
        next_node.display = next_node.gi.input_buffer
        next_node:update_end()
      else
        next_node.output = result.fixed.output
        next_node.display = next_node.output
        next_node:update_end()
        local further_next_node = InputNode.new(next_node.end_ + 1, self.row, self.parent)
        next_node:insert_next(further_next_node)
        self.parent.selected_node = further_next_node
      end
    end
  end
end

---@param start integer
function InputNode:_update_end(start)
  self.start = start
  self.end_ = start + #self.display - 1
end

function InputNode:update_end()
  local start = self.start
  self:_update_end(start)

  local next = self.next
  while next:is_valid() do
    start = next.prev.end_ + 1
    next:_update_end(start)
    next = next.next
  end
end

return InputNode
