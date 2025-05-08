--[[ Options class

  Parse and hold filter options

  ]] 

local stringify = pandoc.utils.stringify
local metatype = pandoc.utils.type

--- # Options object

---@class Options
---@field new fun(meta: pandoc.Meta):Options create Options object
---@field allowDepth fun(depth: number):boolean depth is allowed
---@field getDepth fun():number returns max depth (error messages)
---@field debug boolean debug mode
---@field suppressBiblio boolean suppress-bibliography mode
local Options = {}

---create an Options object
---@param meta pandoc.Meta
---@param default_max_depth number
---@return object Options
function Options:new(meta, default_max_depth)
  o = {}
  setmetatable(o,self)
  self.__index = self

  o:read(meta, default_max_depth)
  
  return o
end

--- normalize: normalize user options. No value check, we just 
--- handle aliases and return options as a map.
---@param meta metaObject
---@return pandoc.MetaMap
function Options:normalize(meta)

  --- look for 'rciteproc' or its aliases
  local opts = (meta.rciteproc and meta.rciteproc)
    or (meta['recursive-citeproc'] and meta['recursive-citeproc'])
    or (meta.recursiveciteproc and meta.recursiveciteproc)
    or pandoc.MetaMap{}

  --- ensure opts a map; single value assumed to be max-depth
  opts = (metatype(opts) == 'table' and opts)
    or ((metatype(opts) == 'Inlines' or metatype(opts) == 'string')
      and pandoc.MetaMap({ ['max-depth'] = stringify(opts)}))
    or pandoc.MetaMap{}

  --- provide alias(es)
  aliases = { ['max-depth'] = 'maxdepth' }

  for key,alias in pairs(aliases) do
    opts[key] = opts[key] == nil and opts[alias] ~= nil and opts[alias]
      or opts[key]
  end

  return opts

end

---read: read options from doc's meta
---@param meta pandoc.Meta
---@param default_max_depth number
function Options:read(meta, default_max_depth)
  local opts = Options:normalize(meta)

  -- Option: max-depth

  local userMaXDepth = opts['max-depth'] and (
    metatype(opts['max-depth']) == 'Inlines' and tonumber(stringify(opts['max-depth']))
    or tonumber(opts['max-depth'])
  )
  local maxDepth = userMaXDepth and userMaXDepth >=0 and userMaXDepth
    or default_max_depth

  self.getDepth = function()
    return maxDepth
  end

  -- whether a depth is allowed; returns true when depth = 1
  self.allowDepth = function (depth)
    return maxDepth == 0 or maxDepth >= depth
  end

  -- Option: debug

  self.debug = opts.debug and opts.debug == true or false

  -- Option: suppress-bibliography

  self.suppressBiblio = meta['suppress-bibliography'] and
    meta['suppress-bibliography'] == true or false

end

return Options
