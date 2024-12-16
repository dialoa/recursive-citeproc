Recursive-citeproc
==================================================================

[![GitHub build status][CI badge]][CI workflow]

[Pandoc][]/[Quarto][] filter for self-citing BibTeX bibliographies.

[CI badge]: https://img.shields.io/github/actions/workflow/status/dialoa/recursive-citeproc/ci.yaml?branch=main
[CI workflow]: https://github.com/dialoa/recursive-citeproc/actions/workflows/ci.yaml

[BibTeX]: https://ctan.math.illinois.edu/biblio/bibtex/base/btxdoc.pdf
[Citeproc]: https://github.com/jgm/citeproc
[CSLs]: https://citationstyles.org/
[Pandoc]: https://pandoc.org
[Quarto]: https://quarto.org

Overview
------------------------------------------------------------------

[BibTeX's documentation][BibTeX] allows self-citing
bibliographies, that is bibliography entries citing other
bibliography entries in note, title or abstract fields. These
aren't handled properly by [Pandoc][]'s and [Quarto][]'s internal
bibliography engine, Citeproc. This filter extends Citeproc's
abilities to cover self-citing bibliographies. 

The filter acts as drop-in replacement for Citeproc. It still runs
Citeproc in the background: bibliography style files are applied
as expected.

Background
------------------------------------------------------------------

BibTeX bibliographies can *self-cite*: one bibliography entry
may cite another entry. That is done in two ways: the `crossref`
field to cite a collection from which an entry is extracted
 (see the [BibTeX's documentation][BibTeX]), or by entering
 citation commands, e.g. in a note field:

 ```bibtex
@incollection{Doe:2000,
    author = 'Jane Doe',
    title = 'What are Fish Even Doing Down There',
    crossref = 'Snow:2000',
}
@book{Snow:2010,
    editor = 'Jane Snow',
    title = 'Fishy Works',
    note = 'Reprint of~\citet{Snow:2000}',
}
@collection{Snow:2000,
    editor = 'Jane Snow',
    title = 'Fishy Works',
}
```

LaTeX's bibliography engines (`natbib`, `biblatex`) handle
self-citations of both kinds. 

[Pandoc][] and [Quarto][] can use those engines but only for PDF
output. They come instead with their own engine, [Citeproc][],
which conveniently uses [citation styles files][CSLs] and covers
all output formats. 

However, Citeproc only handles `crossref` self-citations. It fails
to process citation commands in bibliographies. 

This filter enables Citeproc to process cite commands in the
bibliography. It ensures that the self-cited entries are displayed
in the document's bibliography.

Are self-citing bibliographies a good idea? It ensures consistency
by avoiding multiple copies of the same data, but creates
dependencies between entries. The [citation sytle language][CSLs]
doesn't seem to permit it. Be that as it may, many of us have
legacy self-citing bibliographies, so we may as well handle them.

Requirements
------------------------------------------------------------------

Pandoc 2.17+ or Quarto 1.4+

_Note_. Version 1 of this filter does not work with Pandoc 3.1.10+
and Quarto 1.4.530+. If switching from version 1 to current
version, make sure you do not call `-C` or `--citeproc` in Pandoc
or set `citeproc: false` in Quarto. See
[below](#how-the-filter-works) for details.

Usage
------------------------------------------------------------------

This filter remplaces Citeproc. 

The filter modifies the internal document representation; it can
be used with many publishing systems that are based on Pandoc.

### Plain pandoc

Pass the filter to pandoc via the `--lua-filter` (or `-L`) command
line option:

    pandoc --lua-filter recursive-citeproc.lua ...

Or via a defaults file:

``` yaml
filters:
- recursive-citeproc.lua
```

Copy the file in your Pandoc user data directory to make
it available to Pandoc anywhere. Run `pandoc -v` to see
where your Pandoc user data directory is.

__Do not use Citeproc__. Do not use the `--citeproc` or `-C`
option in combination with this filter. If applied before the
filter, it is redundant; if after, it generates a duplicate
bibliography.

### Quarto

Users of Quarto can install this filter as an extension with

    quarto install extension dialoa/recursive-citeproc.git

and use it by adding `recursive-citeproc` to the `filters` entry
in their YAML header. You should also deactivate Citeproc:

``` yaml
---
citeproc: false
filters:
- recursive-citeproc
---
```

If you use other filters and specify their order relative to
Quarto, it is safer to run this filter after Quarto's own:

``` yaml
---
citeproc: false
filters:
- ...
- quarto
- recursive-citeproc
---
```


### R Markdown

Use `pandoc_args` to invoke the filter. See 
the [R Markdown
Cookbook](https://bookdown.org/yihui/rmarkdown-cookbook/lua-filters.html)
for details.

``` yaml
---
output:
  word_document:
    pandoc_args: ['--lua-filter=recursive-citeproc.lua']
---
```

__Do not use Citeproc__. Before this filter, it is redundant;
after, it duplicates the bibliography.

Options
------------------------------------------------------------------

You can specify the filter's maximum recursive depth in the
document's metadata. Use 0 for infinte (default 10):

``` 
recursive-citeproc:
  max-depth: 5
```

A `max-depth` of 2, for instance, means that the filter inserts
references that are only cited by references cited in the
document's body, but not references that are only cited by
references that are themselves only cited by references cited in
the document. 

If the max depth is reached before all self-recursive citations
are processed, PDF output may generate an error.

Testing
------------------------------------------------------------------

To try the filter with Pandoc or Quarto, clone the directory.

### Pandoc

Generate Pandoc outputs with `make generate`. Change the output
format with `make generate FORMAT=docx`. Use `FORMAT=latex` for
latex outputs. You can list multiple formats, `make generate
FORMAT="docx pdf"`. The outputs will be in the `test` folder,
named `expected.<format>`. 

Requires [Pandoc][]. 

### Quarto

As above, replacing `generate` with `qgenerate`. 

Requires [Quarto][].

### Pandoc within Quarto

With [Quarto][] installed, you can also use the Pandoc engine
embedded in Quarto: add the argument `PANDOC="quarto pandoc"` to
the Pandoc commands above, e.g. `make generate FORMAT=docx
PANDOC="quarto pandoc"`.


How the filter works
------------------------------------------------------------------

### Version 2.0.0+

Version 2 is meant to replace Citeproc. It returns the document
appended with a `refs` Div containing Citeproc bibliography
output. 

The filter runs Citeproc on the document and checks whether the
generated bibliography contains citations. If not, it simply
returns the document with bibliography. 

If the bibliography contains citations, the filter recursively 
runs Citeproc on those citations, generated citations, and so on 
recursively until all needed citations are identified. They are
then added to the document's `nocite` metadata field. 

Citeproc is then run on the document, which typesets Cite elements
in the document body and adds a bibliography with all needed
entries to cover self-citations. However, Cite elements in the
bibliography may still contain LaTeX cite commands that aren't
typeset yet. To ensure these are typeset, we run Citeproc on the
bibliography itself, and update the document's bibliography with
the result. 

The last step of the process generates a duplicate bilbiography
which we discard. There is no way around it since Pandoc 3.1.10:
if we ran Citeproc on the bibliography with
`suppress-bibliography` the Cite commands couldn't be converted to
links. To ensure `link-references` adds links to citations even in
the bibliography, we must leave `suppress-bibliography` to false.

### Version 1.0.0+

Version 1 of this filter was supposed to be run *in combination
with and before* Citeproc. 

It added a Citeproc-generated bibliography to the document, which
could contain [Cite
elements](https://pandoc.org/lua-filters.html#type-cite) whose
`content` could contain a LaTeX citation commands, and exited with
the document's metadata key `suppress-bibliography` to `true`.
Citeproc running after this would:

1. convert any LaTeX citation in 
the `content` of Cite elements in the the bibliography. 
2. add Links to the the `content` of Cite elements, if
document's metadata key `link-references` was `true`, 

The filter's main task was to ensure that the Citeproc-generated
bibliography contained all entries cited in bibliography entries,
and entries cited in bibliography entries cited in other
bibliographies entries, and so on. That was done by generating a
the bibliography a first time, checking whether it added citations,
adding them to the metadata `nocite` key and trying again until
no new citations was added or the maximal depth was reached.

Since Pandoc 3.1.10, `suppress-bibliography` deactivates
`link-references`. The filter would still handle self-citing
bibliographies but `link-references` would have no effect:
citations would not be linked to bibliographies. To let Citeproc
link references, we would need to remove `suppress-bibliography`,
but we would then get a duplicate bibliography.

The solution in version 2 was to incorporate the last Citeproc
step within the filter; we run it witout `suppress-bibliography`
for the references to be linked if `link-references` is set and we
take out the duplicate bibliography it outputs. 

Credits
------------------------------------------------------------------

Based on an idea given by John MacFarlane on the pandoc-discuss
mailing list.

License
------------------------------------------------------------------

This pandoc Lua filter is published under the MIT license, see
file `LICENSE` for details.
