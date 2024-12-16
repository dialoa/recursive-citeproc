local stringify = pandoc.utils.stringify
local metatype = pandoc.utils.type

--- # Options object

---@class Options
---@field new fun(meta: pandoc.Meta):Options create Options object
---@field allowDepth fun(depth: number):boolean depth is allowed
local Options = {}

---create an Options object
---@param meta pandoc.Meta
---@return object Options
function Options:new(meta)
  o = {}
  setmetatable(o,self)
  self.__index = self

  o:read(meta)
  
  return o
end

--- normalize: normalize user options
--- simple string is assumed to be max-depth
--- maxdepth alias of max-depth
---@param meta metaObject
---@return pandoc.MetaMap
function Options:normalize(meta)
  --- ensure its a map; single value assumed to be max-depth
  meta = (metatype(meta) == 'table' and meta)
    or (metatype(meta) == 'string' and
    pandoc.MetaMap({ ['max-depth'] = meta}))
    or (metatype(meta) == 'Inlines' and 
    pandoc.MetaMap({ ['max-depth'] = stringify(meta)}))

  --- provide alias(es)
  aliases = { ['max-depth'] = 'maxdepth' }

  for key,alias in pairs(aliases) do
    meta[key] = meta[key] == nil and meta[alias] ~= nil and meta[alias]
      or meta[key]
  end

  --- 

  return meta

end

---read: read options from doc's meta
---treat maxdepth as alias for max-depth
---@param meta pandoc.Meta
function Options:read(meta)
  local opts = meta['recursive-citeproc']
    and Options:normalize(meta['recursive-citeproc'])
    or nil

  -- allowDepth(depth) must return true when depth = 1
  local userMaXDepth = opts and tonumber(opts['max-depth'])
  local maxDepth = userMaXDepth and userMaXDepth >= 0 and userMaXDepth
    or DEFAULT_MAX_DEPTH
  self.allowDepth = function (depth)
    return maxDepth == 0 or maxDepth >= depth
  end

  self.getDepth = function()
    return maxDepth
  end

end

return Options
