Recursive-citeproc
==================================================================

[![GitHub build status][CI badge]][CI workflow]

Self-citing BibTeX bibliographies in [Pandoc][] and [Quarto][].

[CI badge]: https://img.shields.io/github/actions/workflow/status/dialoa/recursive-citeproc/ci.yaml?branch=main
[CI workflow]: https://github.com/dialoa/recursive-citeproc/actions/workflows/ci.yaml

[BibTeX]: https://ctan.math.illinois.edu/biblio/bibtex/base/btxdoc.pdf
[Citeproc]: https://github.com/jgm/citeproc
[CSLs]: https://citationstyles.org/
[Pandoc]: https://pandoc.org
[Quarto]: https://quarto.org

Overview
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

[Pandoc][] and [Quarto][] can use those engines but for PDF output
only. They come instead with their own engine, [Citeproc][], which
conveniently uses [citation styles files][CSLs] and covers all
output formats. 

However, Citeproc only handles `crossref` self-citations. 
It fails to process citation commands in bibliographies. 

This filter enables Citeproc to process cite commands in 
the bibliography. It ensures that the self-cited entries
are displayed in the document's bibliography.

Are self-citing bibliographies a good idea? It ensures
consistency by avoiding multiple copies of the same
data, but creates dependencies between entries. The
[citation sytle language][CSLs] doesn't seem to 
permit it. Be that as it may, many of us have legacy
self-citing bibliographies, so we may as well
handle them.

Usage
------------------------------------------------------------------

The filter modifies the internal document representation; it can
be used with many publishing systems that are based on Pandoc.

When using several filters on a document, this filter must 
be placed:
* after any filter that adds citations to the document,
* before Citeproc or Quarto

The filter must be used in combination with Citeproc.

### Plain pandoc

Pass the filter to pandoc via the `--lua-filter` (or `-L`) command
line option, followed by Citeproc (`--citeproc` or `-C`):

    pandoc --lua-filter recursive-citeproc.lua -C ...

Or via a defaults file:

``` yaml
filters:
- recursive-citeproc.lua
- citeproc
```

### Quarto

Users of Quarto can install this filter as an extension with

    quarto install extension tarleb/recursive-citeproc.git

and use it by adding `recursive-citeproc` to the `filters` entry
in their YAML header, before `quarto`.

``` yaml
---
filters:
- recursive-citeproc
- quarto
---
```

You must explicitly specify that the filter comes before Quarto's own,
by default Quarto runs its own (incl. Citeproc) first.

### R Markdown

Use `pandoc_args` to invoke the filter, followed by Citeproc. See 
the [R Markdown
Cookbook](https://bookdown.org/yihui/rmarkdown-cookbook/lua-filters.html)
for details.

``` yaml
---
output:
  word_document:
    pandoc_args: ['--lua-filter=recursive-citeproc.lua', '--citeproc']
---
```

Options
------------------------------------------------------------------

You can specify the filter's maximum recursive depth in the
document's metadata. Use 0 for infinte (default 100):

``` 
recursive-citeproc:
  max-depth: 5
```

A `max-depth` of 2, for instance, means that the filter inserts
references that are only cited by references cited in the document's
body, but not references that are only cited by references that are
themselves only cited by references cited in the document. 

If the max depth is reached before all self-recursive citations are 
processed, PDF output may generate an error.

How the filter works
------------------------------------------------------------------

The filter adds a Citeproc-generated bibliography to the document, 
which may contain citation commands, and sets the metadata key
`suppress-bibliography` to `true`. When Citeproc itself is run
on the result, the bibliography's citation commands are converted 
to text.

The filter's main task is to ensure that its Citeproc-generated
bibliography contains all the document's citations, including
those that may only appear in the bibliography itself. To do 
that, it checks whether the result of generating a bibliography
with Citeproc adds new citations. If it does, the filter 
adds those new citations in the metadata `nocite` field
and tries to generate the bibliography again, and so on
until generating the bibliography doesn't produce any citation
that is not already present in the bibliography.

Credits
------------------------------------------------------------------

Based on an idea given by John MacFarlane on the pandoc-discuss
mailing list.

License
------------------------------------------------------------------

This pandoc Lua filter is published under the MIT license, see
file `LICENSE` for details.
