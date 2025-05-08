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