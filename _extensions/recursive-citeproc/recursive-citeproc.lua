
---------------------------------------------------------
----------------Auto generated code block----------------
---------------------------------------------------------

do
    local searchers = package.searchers or package.loaders
    local origin_seacher = searchers[2]
    searchers[2] = function(path)
        local files =
        {
------------------------
-- Modules part begin --
------------------------

["CitationIdList"] = function()
--------------------
-- Module: 'CitationIdList'
--------------------
--[[ CitationIdList class
    Hold and manipulate lists of citations Ids.
]] 

--- # Helper functions

local type = pandoc.utils.type

---Concatenate a List of lists
---@param list pandoc.List[] list of pandoc.Lists
---@return pandoc.List result concatenated List
local function listConcat(list)
    local result = pandoc.List:new()
    for _,sublist in ipairs(list) do
      result:extend(sublist)
    end
    return result
end
  
---Flatten a meta value to Inlines
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
      or elemType == 'Blocks' and pandoc.utils.blocks_to_inlines(elem)
      or elemType == 'List' and listConcat(
        elem:map(flattenToInlines)
      )
      or pandoc.Inlines{}
end

-- # CitationIdList object

---@alias CitationId string Citation Identifier

---@class CitationIdList
---@field data CitationId[] list of citation ids
---@field new fun(self: CitationIdList, source?:pandoc.Pandoc|pandoc.Meta|pandoc.Blocks|pandoc.Block|CitationId[]):CitationIdList 
---@field isEmpty fun(self: CitationIdList): boolean
---@field find fun(self: CitationIdList, citationId: CitationId):boolean
---@field includes fun(self: CitationIdList, citationIdList: CitationIdList):boolean
---@field insert fun(self: CitationIdList, citationId: CitationId):nil
---@field clone fun(self: CitationIdList):CitationIdList
---@field minus fun(self: CitationIdList, citationIdList: CitationIdList):CitationIdList
---@field plus fun(self: CitationIdList, citationIdList: CitationIdList):CitationIdList
---@field addFromCitationIds fun(self: CitationIdList, list: CitationId[]):nil
---@field addFromBlocks fun(self: CitationIdList, blocks: pandoc.Blocks):nil
---@field addFromMeta fun(self: CitationIdList, meta: pandoc.Meta):nil
---@field addFromPandoc fun(self: CitationIdList, doc: pandoc.Pandoc):nil
---@field addFromReferences fun(self: CitationIdList, doc: pandoc.Pandoc):nil
---@field insertInNocite fun(self: CitationIdList, meta: pandoc.Meta):pandoc.Meta
local CitationIdList = {}

---Create an CitationIdList object
---@param source? pandoc.Pandoc|pandoc.Meta|pandoc.Blocks|pandoc.Block|CitationId[]
---@return CitationIdList 
function CitationIdList:new(source)
    o = {}
    setmetatable(o,self)
    self.__index = self

    o.data = {}

    if source then
        srcType = type(source)
        if srcType == 'Pandoc' then
            o:addFromPandoc(source)
        elseif srcType == 'Meta' then
            o:addFromMeta(source)
        elseif srcType == 'Blocks' or srcType == 'Block' then
            o:addFromBlocks(source)
        elseif srcType == 'table' then
            o:addFromCitationIds(source)
        end
    end
    
    return o
end

---Whether the list of citations is empty
---@return boolean
function CitationIdList:isEmpty()
    return #self.data == 0
end

---Whether citationId is in the list
---@param citationId CitationId
---@return boolean
function CitationIdList:find(citationId)
   for _,id in ipairs(self.data) do
        if citationId == id then
            return true
        end
   end
   return false
end

---Whether the list includes all items from citationIdList
---@param citationIdList CitationIdList
function CitationIdList:includes(citationIdList)
    result = true
    for _,id in ipairs(citationIdList.data) do
        if not self:find(id) then
            result = false
            break
        end
    end
    return result
end

---Insert citation in the list if not already present
---@param citationId CitationId
function CitationIdList:insert(citationId)
    if not self:find(citationId) then
        table.insert(self.data, citationId)
    end
end

---Get a copy of the list
---@return CitationIdList
function CitationIdList:clone()
    result = CitationIdList:new(self.data)
    return result
end

---Get a new list of citations minus those already in citationIdList
---@param citationIdList CitationIdList list of citations to remove
---@return CitationIdList result new CitationIdList
function CitationIdList:minus(citationIdList)
    result = self:clone()
    for _,id in ipairs(citationIdList) do
        result:insert(id)
    end
    return result
end

---Get a new list of citations plus those in citationIdList
---@param citationIdList CitationIdList list of citations to add
---@return CitationIdList result new CitationIdList
function CitationIdList:plus(citationIdList)
    result = CitationIdList:new()
    result:addFromCitationIds(self.data)
    result:addFromCitationIds(citationIdList.data)
    return result
end

---Add from a list of citation Ids
---@param list CitationId[]
function CitationIdList:addFromCitationIds(list)
    for _,item in ipairs(list) do
        if item and type(item) == 'string' then
            self:insert(item)
        end
    end
end

---Add citation ids found in blocks
---@param blocks pandoc.Blocks
function CitationIdList:addFromBlocks(blocks)
    blocks:walk{
        Cite = function(cite)
                for _,citation in ipairs(cite.citations) do
                    self:insert(citation.id)
                end
            end
    }
end

---Add citation ids found in selected metadata fields
---namely `title`, `subtitle`, `nocite`, `abstract`, and `thanks`
---@param meta pandoc.Meta
function CitationIdList:addFromMeta(meta)
    local keys = {'title', 'subtitle', 'nocite', 'abstract', 'thanks'}
    for _,key in ipairs(keys) do
        if meta[key] then
            self:addFromBlocks(pandoc.Plain(
                flattenToInlines(meta[key])
            ))
        end
    end
end

---Add citation Ids from a Pandoc document
---@param doc pandoc.Pandoc
function CitationIdList:addFromPandoc(doc)
    if doc.meta then
        self:addFromMeta(doc.meta)
    end
    self:addFromBlocks(doc.blocks)
end

---Add citation Ids from a Pandoc document using pandoc.utils.references
---Differences between addFromReferences and addFromPandoc:
---addFromReferences only adds citations present in the bibliography
---addFromPandoc adds citations from any cite element
---addFromReferences adds citations present in any metadata field
---addFromPandoc only adds citations in selected metadata fields
function CitationIdList:addFromReferences(doc)
    for _,item in pairs(pandoc.utils.references(doc)) do
        self:insert(item.id)
    end
end

---Insert citations in the nocite metadata field
---@param meta pandoc.Meta metadata block to modify
---@return pandoc.Meta 
function CitationIdList:insertInNocite(meta)
    local inlines = flattenToInlines(meta.nocite)
    for _,id in ipairs(self.data) do
        inlines:insert(pandoc.Space())
        inlines:insert(pandoc.Cite(
          pandoc.Str('@'..id),
          pandoc.List{
            pandoc.Citation(id, 'AuthorInText')
          }
        ))
    end
    meta.nocite = pandoc.MetaInlines(inlines)
    return meta
end

--- Use this to run command line tests with pandoc lua
-- if arg and arg[0] == debug.getinfo(1, "S").source:sub(2) then

-- else
    
    return CitationIdList

-- end
end,

["Options"] = function()
--------------------
-- Module: 'Options'
--------------------
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

end,

["log"] = function()
--------------------
-- Module: 'log'
--------------------
local FILTER_NAME = 'Recursive-Citeproc'

---log: send message to std_error
---@param type 'INFO'|'WARNING'|'ERROR'
---@param text string error message
local function log(type, text)
    local level = {INFO = 0, WARNING = 1, ERROR = 2}
    if level[type] == nil then type = 'ERROR' end
    if level[PANDOC_STATE.verbosity] <= level[type] then
        local message = '[' .. type .. '] '..FILTER_NAME..': '.. text .. '\n'
        if quarto then
            quarto.log.output(message)
        else
            io.stderr:write(message)
        end
    end
  end

return log
end,

----------------------
-- Modules part end --
----------------------
        }
        if files[path] then
            return files[path]
        else
            return origin_seacher(path)
        end
    end
end
---------------------------------------------------------
----------------Auto generated code block----------------
---------------------------------------------------------
--[[-- # Recursive-citeproc - Self-citing BibTeX 
bibliographies in Pandoc and Quarto

@author Julien Dutant <julien.dutant@kcl.ac.uk>
@copyright 2021-2024 Julien Dutant
@license MIT - see LICENSE file for details.
@release 2.0.2
]]

local log = require('log')
local Options = require('Options')
local CitationIdList = require('CitationIdList')
local stringify = pandoc.utils.stringify

--- # Settings

-- Pandoc 2.17 for relying on `elem:walk()`, `pandoc.Inlines`, pandoc.utils.type
PANDOC_VERSION:must_be_at_least '2.17'
-- Limit recursion depth; 10 should do and avoid the appearance of freezing
DEFAULT_MAX_DEPTH = 10
-- Error messages
ERROR_MESSAGES = {
  REFS_FOUND = 'I found a Div block with identifier `refs`. This probably means'
  .." that you are running Citeproc alongside this filter. If you are, don't:"
  .." this filter replaces Citeproc. If you aren't, you are using `refs` as an"
  .." identifier on some Div element. That is a bad idea, as this interferes"
  .." with Citeproc and this filter. I'm removing that element from the output.",
  MAX_DEPTH = function (depth) return 'Reached maximum depth of self-citations '
      ..'('.. tostring(depth) ..').'
      ..'Check if there are circular self-citations in your bibligraphy.'
  end
}


--- # Helper functions

---runCiteproc: run citeproc on a document
---@param doc pandoc.Pandoc
---@return pandoc.Pandoc
local function runCiteproc (doc)
  if PANDOC_VERSION >= '2.19.1' then
    return pandoc.utils.citeproc(doc)
  else
    local args = {'--from=json', '--to=json', '--citeproc'}
    local result = pandoc.utils.run_json_filter(doc, 'pandoc', args)
    return result and result
      or pandoc.Pandoc({})
  end
end

---Avoid crash with empty bibliography key
---@param meta pandoc.Meta
---@return pandoc.Meta meta
local function fixEmptyBiblio(meta)
  if meta.bibliography and stringify(meta.bibliography) == '' then
    meta.bibliography = nil
    return meta
  else
    return meta
  end
end

---Extract a Div block with a certain id from blocks.
---If found, the Div is removed from the blocks.
---@param blocks pandoc.Blocks
---@param identifier string
---@return pandoc.Blocks blocks blocks with the Div removed if found
---@return pandoc.Div|nil div Div if found, or nil 
local function extractDivById(blocks, identifier)
  if not identifier or identifier == '' then
    return blocks, nil
  end
  local result = nil
  return blocks:walk{
    Div = function(div)
      if div.identifier and div.identifier == identifier then
        result = div
        return {}
      end
    end
  }, result
end

---Generate a bibliography from a document's meta and citation list
---@param meta pandoc.Meta
---@param citationIdList? CitationIdList
local function makeBibliography(meta, citationIdList)
  minidoc = pandoc.Pandoc({}, meta)
  if citationIdList then
    minidoc.meta = citationIdList:insertInNocite(minidoc.meta)
  end
  minidoc = runCiteproc(minidoc)
  if minidoc.blocks[1] then
    return minidoc.blocks[1]
  end
end

---Typeset citations in the `refs` Div of a document
---@param doc pandoc.Pandoc document
---@return pandoc.Pandoc|nil result updated document or nil
local function typesetCitationsInRefs(doc)
  local blocks, refs = extractDivById(doc.blocks, 'refs')
  if not refs then
    return nil
  end

  -- Change identifier, otherwise Citeproc adds to this Div
  refs.identifier = 'oldRefs'

  -- run Citeprof on refs and extract result
  local tmpdoc = runCiteproc(pandoc.Pandoc(pandoc.Blocks{refs}, doc.meta))
  local _, newRefs = extractDivById(tmpdoc.blocks, 'oldRefs')

  -- Restore identifier
  newRefs.identifier = 'refs'

  -- Recreate doc
  blocks:insert(newRefs)
  doc.blocks = blocks

  return doc
end

--- # Filter

---recursiveCiteproc: fill in `nocite` field
---until producing a bibliography adds no new citations
---returns document with expanded no-cite field.
local function recursiveCiteproc(doc)
  local options = Options:new(doc.meta)
  doc.meta = fixEmptyBiblio(doc.meta) -- avoid crash on empty `bibliography` key

  -- Check if Citeproc has been applied, otherwise run it; extract bibliography.
  -- Quarto users can't avoid it but warn Pandoc users that it's redundant.
  local refs
  doc.blocks, refs = extractDivById(doc.blocks, 'refs')
  if refs then
    if not quarto then 
      log('WARNING', ERROR_MESSAGES.REFS_FOUND)
    end
  else
    doc = runCiteproc(doc)
    doc.blocks, refs = extractDivById(doc.blocks, 'refs')
  end

  -- if no bibliography or no citations in the bibliography, quick exit
  if not refs then
    return
  elseif CitationIdList:new(refs):isEmpty() then
    doc.blocks:insert(refs)
    return doc
  end

  -- Second part: the bibliography contains citations, recursion needed

  -- store citations already present in the original
  originalCites = CitationIdList:new(doc)

  -- establish extra citations by recursion. 
  -- Depends on options, doc.meta, originalCites.
  ---@param cites CitationIdList
  ---@param depth number
  ---@return CitationIdList
  local function recursion(cites, depth)
    if not options.allowDepth(depth) then
      log('WARNING', ERROR_MESSAGES.MAX_DEPTH(options.getDepth()))
      return cites
    end
    local bib = makeBibliography(doc.meta, originalCites:plus(cites))
    newCites = CitationIdList:new(bib):minus(originalCites)
    if cites:includes(newCites) then
      return cites
    else
      return recursion(newCites, depth + 1)
    end
  end

  extraCites = recursion(CitationIdList:new(), 1)

  -- Citeproc the doc. Typesets citations *in the body* and adds bibliography.
  -- Citations in the bibliography aren't typeset yet.
  doc.meta = extraCites:insertInNocite(doc.meta)
  doc = runCiteproc(doc)

  -- Typeset citations in the bibliography
  doc = typesetCitationsInRefs(doc)

  return doc

end

--- # return filter

return {
  {
    Pandoc = recursiveCiteproc
  }
}


