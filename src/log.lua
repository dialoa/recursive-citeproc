local FILTER_NAME = 'Recursive-Citeproc'

---log: send message to std_error
---@param type 'INFO'|'WARNING'|'ERROR'
---@param text string error message
local function log(type, text)
    local level = {INFO = 0, WARNING = 1, ERROR = 2}
    if level[type] == nil then type = 'ERROR' end
    if level[PANDOC_STATE.verbosity] <= level[type] then
        io.stderr:write(
            '[' .. type .. '] '..FILTER_NAME..': '.. text .. '\n'
        )
    end
  end

return log