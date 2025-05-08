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