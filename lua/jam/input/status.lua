local api = vim.api

local GoogleInput = require("jam.input.google_input")
local utils = require("jam.utils")

---@class InputStatus
---@field output string
---@field display string
---@field google_input GoogleInput
---@field start_pos integer[]
---@field end_col integer
---@field session Session
local InputStatus = {}

---@param session Session
---@return InputStatus
function InputStatus.new(session)
    return setmetatable({
        output = "",
        display = "",
        google_input = GoogleInput.new(),
        session = session,
    }, { __index = InputStatus })
end

function InputStatus:set_pos()
    local pos = utils.get_pos()
    self.start_pos = pos
    self.end_col = pos[2]
    self.session.start_pos = pos
end

---@param char string
function InputStatus:input(char)
    if self.session.ime_mode == "PreInput" then
        if char:find("%s") then
            return
        else
            self:set_pos()
            self.session:_mode_set("Input")
        end
    end
    self.end_col = self.end_col + 1
    local result = self.google_input:input(char)
    if result.fixed then
        self.output = self.output .. result.fixed.output
    else
        if not result.tmp_fixed and vim.tbl_isempty(result.next_candidates) then
            self.output = self.output .. result.input
        end
    end
    self:update_display()
end

function InputStatus:update_display()
    self.display = self.output .. self.google_input.input_buffer
end

function InputStatus:update_buffer()
    if self.session.ime_mode ~= "Input" then
        return
    end
    local current_line = api.nvim_get_current_line()
    current_line = utils.insert(current_line, self.display, self.start_pos[2], self.end_col)
    api.nvim_set_current_line(current_line)
    self.end_col = self.start_pos[2] + #self.display - 1
    self:goto_end()
end

function InputStatus:goto_end()
    api.nvim_win_set_cursor(0, { self.start_pos[1], self.end_col })
end

function InputStatus:backspace()
    if #self.display == 0 then
        return
    end
    local erased = utils.get_char(self.display, -1)
    if #self.google_input.input_buffer == 1 then
        self.google_input.input_buffer = ""
        self.google_input.tmp_fixed = nil
        self.google_input.next_candidates = self.google_input.rules
    elseif #self.google_input.input_buffer > 1 then
        self.google_input.input_buffer = self.google_input.input_buffer:sub(1, -#erased - 1)
        self.google_input:input(self.google_input.input_buffer)
    else
        self.output = self.output:sub(1, -#erased - 1)
    end
    self:update_display()
    self:update_buffer()
end

return InputStatus
