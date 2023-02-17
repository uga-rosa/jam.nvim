local fn = vim.fn

local utils = require("jam.utils")
local config = require("jam.config")

---@class FilterRule
---@field input string
---@field output string
---@field next_input string
local FilterRule = {}

---@param input string
---@param output string
---@param next_input string
---@return FilterRule
function FilterRule.new(input, output, next_input)
  return setmetatable({
    input = input,
    output = output,
    next_input = next_input,
  }, { __index = FilterRule })
end

---@alias input_status "finished" | "mistyped" | "continued"

---@class FilterResult
---@field input string
---@field fixed FilterRule
---@field status input_status
local FilterResult = {}

---@param input string
---@param fixed? FilterRule
---@param status input_status
---@return FilterResult
function FilterResult.new(input, fixed, status)
  return setmetatable({
    input = input,
    fixed = fixed,
    status = status,
  }, { __index = FilterResult })
end

---@class GoogleInput
---@field rules FilterRule[]
---@field input_buffer string
---@field tmp_fixed? FilterRule
---@field next_candidates FilterRule[]
local GoogleInput = {}

---@param input_buffer? string
---@return GoogleInput
function GoogleInput.new(input_buffer)
  local new = setmetatable({}, { __index = GoogleInput })
  new:reset()
  new.input_buffer = input_buffer or ""
  new:LoadFilterRules()
  return new
end

function GoogleInput:reset()
  self.input_buffer = ""
  self.tmp_fixed = nil
  self.next_candidates = {}
end

function GoogleInput:LoadFilterRules()
  local keyLayout = config.get("keyLayout")
  local fname
  if fn.filereadable(keyLayout) == 1 then
    fname = keyLayout
  elseif keyLayout == "default" or keyLayout == "azik" then
    local script_path = debug.getinfo(1, "S").source:sub(2)
    fname = fn.fnamemodify(script_path, ":h:h:h:h") .. "/data/" .. keyLayout
  else
    error(
      "keyLayout must be 'default', 'azik', or the full path of your own key layout file: "
        .. keyLayout
    )
  end
  local rules = {}
  for i, line in utils.lines(fname) do
    local input, output, next_input = unpack(vim.split(line, "%s"))
    utils.assertf(input and output, "File %s has invalid line. L#%s: %s", fname, i, line)
    table.insert(rules, FilterRule.new(input, output, next_input or ""))
  end
  table.sort(rules, function(a, b)
    return a.input < b.input
  end)
  self.rules = rules
end

---@param rules FilterRule[]
---@param i integer
---@param input string
local function cb(rules, i, input)
  return rules[i].input >= input
end

---@param rules FilterRule[]
---@param input string
---@return FilterRule? exact_match
---@return FilterRule[] candidates
local function get_by_startswith(rules, input)
  local input_next_char = input:sub(1, -2) .. string.char(input:byte(-1) + 1)
  local start = utils.binary_search(rules, input, cb)
  local end_ = utils.binary_search(rules, input_next_char, cb)
  if end_ < #rules or not vim.startswith(rules[end_].input, input) then
    end_ = end_ - 1
  end
  local candidates = {}
  local exact_match
  for i = start, end_ do
    local rule = rules[i]
    if rule.input == input then
      exact_match = rule
    else
      table.insert(candidates, rule)
    end
  end
  return exact_match, candidates
end

---@param char string
---@return FilterResult
function GoogleInput:input(char)
  vim.validate({
    char = { char, "s" },
  })
  local candidates = {}
  if #self.next_candidates > 0 then
    candidates = self.next_candidates
  else
    candidates = self.rules
  end

  local pre_input = self.input_buffer
  local input = pre_input .. char
  local tmp_fixed, next_candidates = get_by_startswith(candidates, input)
  tmp_fixed = tmp_fixed or self.tmp_fixed

  self.next_candidates = next_candidates
  if #next_candidates == 0 then
    -- No candidate rule matches further input.
    if tmp_fixed then
      -- There is a rule determined by input.
      if #tmp_fixed.input == #input then
        -- This input just matched the rule.
        self.input_buffer = tmp_fixed.next_input
      else
        -- Matched the previous rule, and now breaks that rule.
        self.input_buffer = tmp_fixed.next_input .. char
      end
      self.tmp_fixed = nil
      return FilterResult.new(input, tmp_fixed, "finished")
    else
      -- There is no fixed rule in the input so far (mistyped).
      self.input_buffer = ""
      self.tmp_fixed = nil
      return FilterResult.new(pre_input, nil, "mistyped")
    end
  else
    -- There are candidate rules that match the following input.
    self.input_buffer = input
    self.tmp_fixed = tmp_fixed
    return FilterResult.new(input, nil, "continued")
  end
end

return GoogleInput
