--[[-- # Recursive-citeproc - Self-citing BibTeX 
bibliographies in Pandoc and Quarto

@author Julien Dutant <julien.dutant@kcl.ac.uk>
@copyright 2021-2023 Julien Dutant
@license MIT - see LICENSE file for details.
]]

-- 2.17 for relying on `elem:walk()`, `pandoc.Inlines`, pandoc.utils.type
PANDOC_VERSION:must_be_at_least '2.17'

--- # Global Setting
DEFAULT_MAX_DEPTH = 100

--- # Helper functions

local stringify = pandoc.utils.stringify
local run_json_filter = pandoc.utils.run_json_filter
type = pandoc.utils.type
local blocks_to_inlines = pandoc.utils.blocks_to_inlines
-- we don't use pandoc.utils.references, twice slower on benchmark
references = pandoc.utils.references

-- metatype: type of a Meta element
metatype = type

-- run citeproc
local function run_citeproc (doc)
  if PANDOC_VERSION >= '2.19.1' then
    return pandoc.utils.citeproc(doc)
  elseif PANDOC_VERSION >= '2.11' then
    local args = {'--from=json', '--to=json', '--citeproc'}
    return run_json_filter(doc, 'pandoc', args)
  else
    return run_json_filter(doc, 'pandoc-citeproc', {FORMAT, '-q'})
  end
end

--- listConcat: concatenate a List of lists
---@param list pandoc.List[] list of pandoc.Lists
---@return pandoc.List result concatenated List
local function listConcat(list)
  local result = pandoc.List:new()
  for _,sublist in ipairs(list) do
    result:extend(sublist)
  end
  return result
end

---Flatten a meta value into Inlines
---in pandoc < 2.17 we only return a pandoc.List of Inline elements
---@param elem pandoc.Inlines|string|number|pandoc.Blocks|pandoc.List
---@return pandoc.Inlines result possibly empty Inlines
local function flattenToInlines(elem)
  local elemType = type(elem)
  return elemType == 'Inlines' and elem
    or elemType == 'string' 
      and pandoc.Inlines(pandoc.Str(elem))
    or elemType == 'number' 
      and pandoc.Inlines(pandoc.Str(tonumber(elem)))
    or elemType == 'Blocks' and blocks_to_inlines(elem)
    or elemType == 'List' and listConcat(
      elem:map(flattenToInlines)
    )
    or pandoc.Inlines({})
end

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

end

--- # Functions to handle lists of strings
--- could be an object that extends pandoc.List

---@alias CitationIds pandoc.List pandoc.List of strings

---create
---@param list CitationIds|nil
---@return CitationIds cids
local function cids_create(list)
  local cids = pandoc.List:new()
  if list and type(list) == 'table' or type(list) == 'List' then
    for _,item in ipairs(list) do
      if type(item) == 'string' then cids:insert(item) end
    end
  end
  return cids
end

---add Id if not already included
---@param cids CitationIds
---@param id string citation Id
---@return CitationIds
local function cids_addId(cids, id)
  if not cids:find(id) then cids:insert(id) end
  return cids
end

---add citation Ids from Cite elements in blocks
---@param cids CitationIds
---@param blocks pandoc.Blocks|pandoc.Block walkable element
---@return CitationIds
local function cids_addFromBlocks(cids, blocks)
  blocks:walk({
    Cite = function(cite)
      for _,citation in ipairs(cite.citations) do
        cids_addId(cids, citation.id)
        end
      end
  })
  return cids
end

---add citation Ids from Cite elements in doc's meta
--- (fields `nocite`, `abstract`, `thanks`)
---@param cids CitationIds
---@param doc any
---@return CitationIds
local function cids_addFromMeta(cids, doc)
  for _,key in ipairs {'nocite', 'abstract', 'thanks' } do
    if doc.meta[key] then
      cids_addFromBlocks(cids, 
        pandoc.Plain(flattenToInlines(doc.meta[key]))
      )
    end
  end
  return cids
end

---add citation Ids from pandoc.utils.references(doc)
local function cids_addFromReferences(cids, doc)
  for _,item in ipairs(references(doc)) do
    cids_addId(cids, item.id)
  end
end

--- # Filter

---listRefIds: returns doc's references as a list of ids
--- we do not use pandoc.utils.references: twice slower 
--- than collecting ref ID strings manually on benchmark.
---@param doc pandoc.Pandoc
---@return string[] refsList list of ids
local function listRefIds(doc)
  local cids = cids_create()
  -- if references then
  --   cids_addFromReferences(cids, doc)
  -- else
    cids_addFromBlocks(cids, doc.blocks)
    cids_addFromMeta(cids, doc)
  -- end
  return cids
end

---listNewRefs: list references in newDoc not present in oldDoc
---@param oldDoc pandoc.Pandoc
---@param newDoc pandoc.Pandoc
---@return CitationIds cids list of ids
local function listNewRefIds(newDoc, oldDoc)
  local oldRefs, newRefs = listRefIds(oldDoc), listRefIds(newDoc)
  local cids = cids_create()
  for _,ref in ipairs(newRefs) do
    if not oldRefs:find(ref) then cids_addId(cids, ref) end
  end
  return cids
end

---addToNocite: add ref ids list to doc's nocite metadata
---@param doc pandoc.Pandoc
---@param newRefs string[]
---@return pandoc.Pandoc
local function addToNocite(doc, newRefs)
  local inlines = flattenToInlines(doc.meta.nocite)
  for _,ref in ipairs(newRefs) do
    inlines:insert(pandoc.Space())
    inlines:insert(pandoc.Cite(
      pandoc.Str('@'..ref),
      {
        pandoc.Citation(ref, 'AuthorInText')
      }
    ))
  end
  doc.meta.nocite = pandoc.MetaInlines(inlines)
  return doc
end

---recursiveCiteproc: fill in `nocite` field
---until producing a bibliography adds no new citations
---returns document with bibliography, expanded no-cite 
---field, and suppress-bibliography=true
---citeproc will later convert the citations in the biblio
local function recursiveCiteproc(doc)
  local options = Options:new(doc.meta)
  local depth = 1
  local newDoc

  while options.allowDepth(depth) do
    depth = depth + 1
    -- DEBUG display runs
    -- print('RUN', tostring(depth-1))
    newDoc = run_citeproc(doc)
    local newRefs = listNewRefIds(newDoc, doc)
    if #newRefs > 0 then
      doc = addToNocite(doc, newRefs)
    else
      break
    end
  end

  newDoc.meta['suppress-bibliography'] = true
  return newDoc

end

--- # return filter

return {
  {
    Pandoc = recursiveCiteproc
  }
}



