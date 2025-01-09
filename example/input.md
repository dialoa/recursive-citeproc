---
title: 'Self-citing bibliography example'
author: Julien Dutant
recursive-citeproc: 100 # optional, specify max recursive depth
bibliography: references.bib
nocite: # checks that nocite references are preserved
- '@Smith2001'
- |
 @Smith2003, @Smith2005
---

@Doe2020 illustrates a simple recursion.

@Jones2022d checks automatic a, b, c, ... added to same year
citations.

# References

