
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

local type = pandoc.utils.type

--- # Helper functions

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
---@return pandoc.Inlines|pandoc.List result possibly empty Inlines
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
---@field toStr fun(self: CitationIdList):string
---@field isEmpty fun(self: CitationIdList): boolean
---@field find fun(self: CitationIdList, citationId: CitationId):boolean
---@field includes fun(self: CitationIdList, citationIdList: CitationIdList):boolean
---@field insert fun(self: CitationIdList, citationId: CitationId):nil
---@field remove fun(self: CitationIdList, citationId: CitationId):nil
---@field clone fun(self: CitationIdList):CitationIdList
---@field minus fun(self: CitationIdList, citationIdList: CitationIdList):CitationIdList
---@field plus fun(self: CitationIdList, citationIdList: CitationIdList):CitationIdList
---@field addFromCitationIds fun(self: CitationIdList, list: CitationId[]):nil
---@field addFromCite fun(self: CitationIdList, cite: pandoc.Cite):nil
---@field addFromWalkable fun(self: CitationIdList, container: pandoc.Pandoc|pandoc.Meta|pandoc.Blocks|pandoc.Inlines):nil
---@field addFromBlock fun(self: CitationIdList, inlines: pandoc.Block):nil
---@field addFromReferences fun(self: CitationIdList, doc: pandoc.Pandoc):nil
---@field insertInNocite fun(self: CitationIdList, meta: pandoc.Meta):pandoc.Meta
local CitationIdList = {}

---Create an CitationIdList object
---@param source? pandoc.Pandoc|pandoc.Meta|pandoc.Blocks|pandoc.Block|CitationId[]
---@return CitationIdList 
function CitationIdList:new(source)
    local o = {}
    setmetatable(o,self)
    self.__index = self

    o.data = {}

    if source then
        srcType = type(source)
        if srcType == 'Pandoc' 
        or srcType == 'Meta'
        or srcType == 'Blocks'
        or srcType == 'Inlines' then
            o:addFromWalkable(source)
        elseif srcType == 'Block' then 
            o:addFromBlock(source)
        elseif srcType == 'table' then
            o:addFromCitationIds(source)
        end
    end
    
    return o
end

---convert to string
---@param separator string|nil
---@return string
function CitationIdList:toStr(separator)
    local separator = separator or ', '
    return table.concat(self.data, separator)
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
    result = CitationIdList:new()
    for _,id in ipairs(self.data) do
        if not citationIdList:find(id) then
            result:insert(id)
        end
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

---Add from a Cite element
function CitationIdList:addFromCite(cite)
    for _,citation in ipairs(cite.citations) do
        self:insert(citation.id)
    end
end

---Add citation ids found in walkable container
---@param container pandoc.Meta|pandoc.Pandoc|pandoc.Blocks
function CitationIdList:addFromWalkable(container)
    container:walk{
        Cite = function(cite)
            self:addFromCite(cite)
        end
    }
end

---Add citation ids found in block
---@param block pandoc.Block
function CitationIdList:addFromBlock(block)
    if block.content then 
        block.content:walk{
            Cite = function(cite)
                self:addFromCite(cite)
            end
        }
    end
end

---Add citation Ids from a Pandoc document
---@param doc pandoc.Pandoc
function CitationIdList:addFromPandoc(doc)
    doc:walk{
        Cite = function(cite)
            self:addFromCite(cite)
        end
    }
end

---Add citation Ids from a Pandoc document using pandoc.utils.references
---Differences between addFromReferences and addFromPandoc:
---addFromReferences only adds citations present in the bibliography database
---addFromPandoc adds any citations
---both list citations in a pre-existing* Citeproc bib, if present
function CitationIdList:addFromReferences(doc)
    for _,item in ipairs(pandoc.utils.references(doc)) do
        self:insert(item.id)
    end
end

---Insert citations in the nocite metadata field
---@param meta pandoc.Meta metadata block to modify
---@return pandoc.Meta 
function CitationIdList:insertInNocite(meta)
    local inlines = meta.nocite and flattenToInlines(meta.nocite)
        or pandoc.Inlines{}
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

["refsdiv"] = function()
--------------------
-- Module: 'refsdiv'
--------------------
--[[ refsdiv.lua

    Manipulate Citeproc's #refs Div in a document

    Citeproc adds bibliography at the end of a #refs Div. If not
    found, it creates one at the end of the document. Users can
    otherwise place it anywhere and add some content to it. 
    
    This module handles manipulating bibliography entries within
    the #refs Div without moving it or losing user's content.

    The structure of a #refs Div is as follows (Pandoc 2.17 - 3.6+)

    Div
      ( "refs"
      , [ "references" , "csl-bib-body" , "hanging-indent" ]
      , [ ( "entry-spacing" , "0" ) ]
      )
      [ Para 
          [ Str "Preamble: users can add a #refs Div, citeproc adds the entries after." ]
      , ... (more user blocks) ...
      , Div
          ( "ref-Allen2020" , [ "csl-entry" ] , [] )
          [ Para
              [ Str "Entry text" ]
          ]
      , Div
          ( "ref-Black2022" , [ "csl-entry" ] , [] )
          [ Para
              [ Str "Entry text" ]
          ]
      ]

]]

---@alias pandoc.Walkable pandoc.Pandoc|pandoc.Meta|pandoc.Blocks

-- # Settings

---Pandoc's default bibliography identifier
local REFSDIV_ID = 'refs'

---@class refsdiv 
---@field get fun(container: pandoc.Walkable, refsId: string|nil): pandoc.Div|nil get the #refs Div
---@field getEntries fun(container: pandoc.Walkable, refsId: string|nil): pandoc.Blocks get its entries
---@field removeEntries fun(container: pandoc.Walkable, refsId: string|nil): pandoc.Blocks remove its entries
---@field extractEntries fun(container: pandoc.Walkable, refsId: string|nil): pandoc.Blocks, pandoc.Blocks extract its entries
---@field rename fun(container: pandoc.Walkable, newId: string, refsId: string|nil): pandoc.Walkable rename the Div
---@field remove fun(container: pandoc.Walkable, refsId: string|nil): pandoc.Walkable remove the full Div
local refsdiv = {}

---Get references Div from a walkable container
---@param container pandoc.Walkable
---@param refsId string|nil identifier for the Refs Div (default REFSDIV_ID)
---@return pandoc.Div|nil
function refsdiv.get(container, refsId)
    local identifier = refsId and refsId ~= '' and refsId
        or REFSDIV_ID
    local result = nil
    container:walk{
    Div = function(div)
        if div.identifier and div.identifier == identifier then
            result = div
        end
    end
    }
    return result
end

---Get CSL entries from a Div in a walkable container
---@param container pandoc.Walkable walkable element containing the Refs Div
---@param refsId string|nil identifier for the Refs Div (default REFSDIV_ID)
---@return pandoc.Blocks
function refsdiv.getEntries(container, refsId)
    local identifier = refsId and refsId ~= '' and refsId
        or REFSDIV_ID
    local refsDiv = refsdiv.get(container, identifier)
    local result = pandoc.Blocks{}

    if refsDiv then
        refsDiv.content:walk{
        Div = function(div)
            if div.classes:includes('csl-entry') then
                result:insert(div)
            end 
        end
        } 
    end

    return result
end

---Extract CSL entries from a container
---@param container pandoc.Walkable walkable element containing the Refs Div
---@param refsId string|nil identifier for the Refs Div (default REFSDIV_ID)
---@return pandoc.Walkable container without any CSL entries found
---@return pandoc.Blocks result extracted CSL entries
function refsdiv.extractEntries(container, refsId)
    local identifier = refsId and refsId ~= '' and refsId
        or REFSDIV_ID
    local result = pandoc.Blocks{}

    local refsDivFilter = {
        Div = function(div)
            if div.classes:includes('csl-entry') then
                result:insert(div)
                return {} -- this erases the entry
            end
        end
    }

    local containerFilter = {
        Div = function(div)
            if div.identifier and div.identifier == identifier then
                div.content = div.content:walk( refsDivFilter )
                return div
            end
        end
    }

    return container:walk(containerFilter), result

end

---Rename the Div. Example use: rename(doc, 'stored') to store it and 
---rename(doc, 'refs', 'stored') to restore. To erase you must rename '';
---in Pandoc filters `div.identifier = nil` leaves the id unchanged.
---@param container pandoc.Walkable
---@param newId string new Id. nil can't ers
---@param refsId string|nil
---@return pandoc.Walkable container with Div renamed
function refsdiv.rename(container, newId, refsId)
    local identifier = refsId and refsId ~= '' and refsId
        or REFSDIV_ID

    return container:walk{
        Div = function(div)
            if div.identifier and div.identifier == identifier then
                div.identifier = newId
                return div
            end
        end
    }

end

---Remove references Div from a walkable container
---@param container pandoc.Walkable
---@param refsId string|nil identifier for the Refs Div (default REFSDIV_ID)
---@return pandoc.Div|nil
function refsdiv.remove(container, refsId)
    local identifier = refsId and refsId ~= '' and refsId
        or REFSDIV_ID

    return container:walk{
        Div = function(div)
            if div.identifier and div.identifier == identifier then
                return {}
            end
        end
    }

end

return refsdiv
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
@copyright 2021-2025 Philosophie.ch
@license MIT - see LICENSE file for details.
@release 2.1.0
]]

-- Pandoc 2.17 for relying on `elem:walk()`, `pandoc.Inlines`, pandoc.utils.type
PANDOC_VERSION:must_be_at_least '2.17'

local log = require('log')
local refsdiv = require('refsdiv')
local Options = require('Options')
local CitationIdList = require('CitationIdList')
local stringify = pandoc.utils.stringify

--- # Settings

-- Default depth. 10 covers most uses and ends fast if entries are missing.
local DEFAULT_MAX_DEPTH = 10
-- Error messages
local ERROR_MESSAGES = {
  REFS_FOUND = "It looks like you are running Citeproc before this filter."
  .." No need to do that: this filter replaces Citeproc.",
  MAX_DEPTH = function (depth) return 'Reached maximum depth of self-citations '
      ..'('.. tostring(depth) ..').'
      ..'Check if there are circular self-citations in your bibligraphy, '
  end,
  NOTHING_TO_DO = 'No self-citations found.'
}

--- # Helper functions

---Run citeproc on a document
---@param doc pandoc.Pandoc
---@return pandoc.Pandoc
local function citeproc(doc)
  if PANDOC_VERSION >= '2.19.1' then
    return pandoc.utils.citeproc(doc)
  else
    local args = {'--from=json', '--to=json', '--citeproc'}
    local result = pandoc.utils.run_json_filter(doc, 'pandoc', args)
    return result and result
      or pandoc.Pandoc({})
  end
end

---Avoid crash with empty but non-nil bibliography key
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

--- # Filter classes and functions

---Diagnosis of the document's pre-existing state
---@class Diagnosis
---@field hasBib boolean whether the document has a pre-existing bibliography
---@field citesInBib CitationIdList citations in the pre-existing bibliography
---@field hasCitesInBib boolean whether it has Cite elements in its bibliography
---@field nothingToDo boolean whether recursive citeproc is needed at all
---@field biblioCanBeUsed boolean whether the pre-existing biblio can be used in the first pass
local Diagnosis = {}

---Create a diagnosis
---@param doc pandoc.Pandoc document to be diagnosed
function Diagnosis:new(doc)

  local o = {}
  setmetatable(o,self)
  self.__index = self

  --is there a previous bibliography (#refs Div with CSL entries)?
  --if yes, does it contain Cite elements?
  local entries = refsdiv.getEntries(doc)

  if #entries > 0 then
    o.hasBib = true
    o.citesInBib = CitationIdList:new(entries)
    o.hasCitesInBib = not o.citesInBib:isEmpty()
  else
    o.hasBib, o.hasCitesInBib = false, false
    o.citesInBib = CitationIdList:new()
  end

  --nothing to do if there are bib entries but not Cite elements in them
  o.nothingToDo = o.hasBib and not o.hasCitesInBib 
    or false

  return o
end

-- # Main filter
 
---Main filter process
---@param doc pandoc.Pandoc
---@return pandoc.Pandoc|nil
local function recursiveCiteproc(doc)
  local options = Options:new(doc.meta, DEFAULT_MAX_DEPTH)
  local diag = Diagnosis:new(doc)

  -- if biblio, warn Pandoc users that it's unnecessary
  if diag.hasBib and not quarto then 
    log('WARNING', ERROR_MESSAGES.REFS_FOUND)
  end
  -- quick exit if nothing needs to be done
  if diag.nothingToDo then 
    log('INFO', ERROR_MESSAGES.NOTHING_TO_DO)
    return 
  end

  -- prepare document
  doc.meta = fixEmptyBiblio(doc.meta) -- fix empty string bug
  -- NB: for simplicity, we wipe out any pre-existing bibliography
  doc, _ = refsdiv.extractEntries(doc)

  -- prepare recursion
  local originalCitations = CitationIdList:new(doc)
  local originalNoCite = doc.meta.nocite and doc.meta.nocite -- store
  local newCitations = diag.citesInBib -- we already know we need to add those
  local depth = 1

  if options.debug then 
    log('INFO', 'pass 0: ', newCitations:toStr())
  end

  while true do

    -- run Citeproc with the new citations added to the original nocite
    doc.meta.nocite = originalNoCite 
    doc.meta = newCitations:insertInNocite(doc.meta)
    doc = citeproc(doc)

    -- does the generated bib contain even more citations?
    -- if not, break; otherwise consider another run.
    local citationsInBib = CitationIdList:new(refsdiv.getEntries(doc))
    if options.debug then 
      log('INFO', 'pass '..tostring(depth)..': '..citationsInBib:toStr())
    end

    if newCitations:includes(citationsInBib) then
      break
    elseif not options.allowDepth(depth + 1) then
      log('WARNING', "reached maximum recursion depth. I could not process the"
      .." following citation key(s): "
      ..citationsInBib:minus(newCitations):toStr())
      break
    else
      newCitations = citationsInBib
      depth = depth + 1
      doc,_ = refsdiv.extractEntries(doc, nil)
    end

  end

  -- Typeset citations in the bibliography
  -- TODO: try 'suppress-bibliography'
  doc = refsdiv.rename(doc, 'recursive-citeproc-stored') -- store
  doc = citeproc(doc) -- typesets citations but adds a new biblio
  doc = refsdiv.remove(doc) -- remove the generated biblio 
  doc = refsdiv.rename(doc, 'refs', 'recursive-citeproc-stored') -- restore

  return doc

end

--- # return filter

return {
  {
    Pandoc = recursiveCiteproc
  }
}


