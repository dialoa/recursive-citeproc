---
title: 'Self-citing bibliography example'
author: Julien Dutant
recursive-citeproc: 
    max-depth: 50 # optional, specify max recursive depth
    debug: true
bibliography: references.bib
nocite: # checks that nocite references are preserved
- '@Smith2001'
- |
 @Smith2003
abstract: |
    This document illustrates self-citing bibliographies.
    The abstract is used to check that citations in 
    metadata are printed correctly [@Smith2005].
---

# Tests

## Simple recursion 

@Doe2020 illustrates a simple recursion. 

## Citations in the `nocite` metadata fields

Two more citations from Smith, namely 2001 
and 2003 appear only in the `nocite` metadata field. This checks
that they are preserved in the final document.

## Suffixes.

@Jones2022feb and @Jones2022may check that automatic suffixes are
handled correctly. In the first recursion round these citations
get suffixes a and b. Ultimately they should settle on suffixes b
and e as the cross-referred Jones 2022 entries are added
chronologically and their suffixes recalculated.

## Placement and preamble of the bibliography

We can place the bibliography at an arbitrary point of the 
document, and even add a preamble to it. The bibliography
should appear below this paragraph and start with a 
brief user preamble.

::: {#refs}

This is the user preamble for the bibliography.

:::

## Debug

Setting the filter's `debug` option to `true` in the metadata
shows the bibliography self-citations found at each recursion
round, provided Pandoc/Quarto is in verbose output mode.

