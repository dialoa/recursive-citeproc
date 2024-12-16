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