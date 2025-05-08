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



