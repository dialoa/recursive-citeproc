---
title: 'Self-citing bibliography example'
author: Julien Dutant
recursive-citeproc: 
    max-depth: 50 # optional, specify max recursive depth
    debug: false
bibliography: references.bib
nocite: # checks that nocite references are preserved
- '@Smith2001'
- |
 @Smith2003, @Smith2005
---

@Doe2020 illustrates a simple recursion. We also include some of 
Smith's work in the `nocite` metadata field to check that this
field is preserved.

@Jones2022b and @Jones2022e check that automatic suffixes a,
b, c, ... are handled correctly. In the first recursion round
these citations get suffixes a and b. Ultimately they should
settle on suffixes b and e as the cross-referred Jones 2022 
entries are added chronologically and their suffixes recalculated.

In debug mode the bibliography is printed at each stage of 
recursion. Activate it by including `debug: true` within the 
filter's metadata options.

# References

