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



