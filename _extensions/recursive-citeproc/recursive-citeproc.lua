--[[-- # Recursive-citeproc - Self-citing BibTeX 
bibliographies in Pandoc and Quarto

@author Julien Dutant <julien.dutant@kcl.ac.uk>
@copyright 2021-2023 Julien Dutant
@license MIT - see LICENSE file for details.
]]

-- Once we've reimplemented references(doc) this
-- should work as far back as 2.11 (--citeproc, Lua filters)
--PANDOC_VERSION:must_be_at_least '2.11'
-- for now we need
PANDOC_VERSION:must_be_at_least '2.19'

--- # Helper functions

stringify = pandoc.utils.stringify
block_to_inlines = pandoc.utils.block_to_inlines
citeproc = pandoc.utils.citeproc
references = pandoc.utils.references

---@alias metaObject
---| boolean
---| string
---| pandoc.MetaMap
---| pandoc.MetaInlines
---| pandoc.MetaBlocks
---| pandoc.List

---@alias typeName 'boolean'|'string'|'table'|'Inlines'|'Blocks'|'List'|'nil'

--- get the type of meta object (h/t Albert Krewinkel)
---@type fun(obj: metaObject): typeName
local metatype = pandoc.utils.type or
  function (obj)
    local metatag = type(obj) == 'table' and obj.t and obj.t:gsub('^Meta', '')
    return metatag and metatag ~= 'Map' and metatag or type(obj)
  end

--- ensure meta element is a (possibly empty) pandoc.List
---@param obj metaObject
---@return pandoc.List obj
function ensureList(obj)
  return obj ~=nil and (
      metatype(obj) == 'List' and obj or pandoc.List(obj)
    ) or pandoc.List:new()
end

--- # Options object

---@class Options
---@field new fun(meta: pandoc.Meta):Options create Options object
---@field allowDepth fun(depth: number):boolean depth is allowed
Options = {}

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
---@param meta metaObject
---@return pandoc.MetaMap
function Options:normalize(meta)
  return (metatype(meta) == 'table' and meta)
    or (metatype(meta) == 'string' and
    pandoc.MetaMap({ ['max-depth'] = meta}))
    or (metatype[meta] == 'Inlines' and 
    pandoc.MetaMap({ ['max-depth'] = stringify(meta)}))
end

---read: read options from doc's meta
---@param meta pandoc.Meta
function Options:read(meta)
  local opts = meta['recursive-citeproc']
    and Options:normalize(meta['recursive-citeproc'])
    or nil

  -- allowDepth(depth) must return true when depth = 1
  local userMaXDepth = opts and tonumber(opts['max-dept']) 
  local maxDepth = userMaXDepth and userMaXDepth >= 0 and userMaXDepth
    or 100
  self.allowDepth = function (depth)
    return maxDepth == 0 or maxDepth >= depth
  end

end

--- # Filter


---listRefs: returns doc's references as a list of ids
---@param doc pandoc.Pandoc
---@return string[] refsList list of ids
function listRefs(doc)
  local refs = references(doc)
  local refsList = pandoc.List:new()
  for _,item in ipairs(refs) do
    if item.id then refsList:insert(item.id) end
  end
  return refsList
end

---listNewRefs: list references in newDoc not present in oldDoc
---@param oldDoc pandoc.Pandoc
---@param newDoc pandoc.Pandoc
---@return string[] result list of ids
function listNewRefs(newDoc, oldDoc)
  local oldRefs, newRefs = listRefs(oldDoc), listRefs(newDoc)
  local result = pandoc.List:new()
  for _,ref in ipairs(newRefs) do
    if not oldRefs:find(ref) then result:insert(ref) end
  end
  return result
end

---addToNocite: add ref ids list to doc's nocite metadata
---@param newRefs string[]
---@param doc pandoc.Pandoc
---@return pandoc.Pandoc
function addToNocite(newRefs, doc)
  local nocite = ensureList(doc.meta.nocite)
  local cites = pandoc.List:new()
  for _,ref in ipairs(newRefs) do
    cites:insert(pandoc.Cite(
      pandoc.Str('@'..ref),
      {
        pandoc.Citation(ref, 'AuthorInText')
      }
    ))
  end
  nocite:insert(cites)
  doc.meta.nocite = nocite
  return doc
end

---recursiveCiteproc: fill in `nocite` field
---until producing a bibliography adds no new citations
---returns document with bibliography, expanded no-cite 
---field, and suppress-bibliography=true
---citeproc will later convert the citations in the biblio
function recursiveCiteproc(doc)
  local options = Options:new(doc.meta)
  local depth = 1
  local newDoc

  while options.allowDepth(depth) do
    depth = depth + 1
    newDoc = citeproc(doc)
    local newRefs = listNewRefs(newDoc, doc)
    if #newRefs > 0 then
      addToNocite(newRefs, doc)
    else
      break
    end
  end

  newDoc.meta['suppress-bibliography'] = true
  return newDoc

end

return {
  {
    Pandoc = recursiveCiteproc
  }
}



