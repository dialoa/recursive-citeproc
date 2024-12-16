# Name of the filter file, *with* `.lua` file extension.
FILTER_FILE := $(wildcard *.lua)
# Name of the filter, *without* `.lua` file extension
FILTER_NAME = $(patsubst %.lua,%,$(FILTER_FILE))
# Source files
#	Optional: build the filter file from multiple sources.
#	*Do not comment out!* To deactivate it's safer to
#	define an empty SOURCE_MAIN variable with:
# 	SOURCE_MAIN = 
SOURCE_DIR = src

# 	Find source files	
SOURCE_FILES := $(wildcard $(SOURCE_DIR)/*.lua)
SOURCE_MODULES := $(SOURCE_FILES:$(SOURCE_DIR)/%.lua=%)
SOURCE_MODULES := $(SOURCE_MODULES:main=)
SOURCE_MAIN = main

# Pandoc example file
EXAMPLE_DIR := example
EXPECTED_DIR := expected
TEST_SRC := $(EXAMPLE_DIR)/input.md
TEST_DEFAULTS := _pandoc.yml
TEST_FILES := $(TEST_SRC) $(TEST_DEFAULTS)
QTEST_DEFAULTS := _quarto.yml _quarto-generate.yml _quarto-test.yml
QTEST_FILES := $(TEST_SRC) $(QTEST_DEFAULTS)

# Docs
# Source and defaults for docs version of Pandoc example output
DOCS_SRC = docs/manual.md
DOCS_DEFAULTS := $(TEST_DEFAULTS)

# Allow to use a different pandoc binary, e.g. when testing.
PANDOC ?= pandoc
QUARTO ?= quarto
# Allow to adjust the diff command if necessary
DIFF ?= diff
# Use a POSIX sed with ERE ('v' is specific to GNU sed)
SED := sed $(shell sed v </dev/null >/dev/null 2>&1 && echo " --posix") -E

# Pandoc formats for test outputs
# Use make generate FORMAT=pdf to try PDF, 
# not included in the test as PDF files aren't identical on each run
FORMAT ?= html

# Directory containing the Quarto extension
QUARTO_EXT_DIR = _extensions/$(FILTER_NAME)
# The extension's name. Used in the Quarto extension metadata
EXT_NAME = $(FILTER_NAME)
# Current version, i.e., the latest tag. Used to version the quarto
# extension.
VERSION = $(shell git tag --sort=-version:refname --merged | head -n1 | \
						 sed -e 's/^v//' | tr -d "\n")
ifeq "$(VERSION)" ""
VERSION = 0.0.0
endif

# GitHub repository; used to setup the filter.
REPO_PATH = $(shell git remote get-url origin | sed -e 's%.*github\.com[/:]%%')
REPO_NAME = $(shell git remote get-url origin | sed -e 's%.*/%%')
USER_NAME = $(shell git config user.name)

## Show available targets
# Comments preceding "simple" targets (those which do not use macro
# name or starts with underscore or dot) and introduced by two dashes
# are used as their description.
.PHONY: help
help:
	@tabs 22 ; $(SED) -ne \
	'/^## / h ; /^[^_.$$#][^ ]+:/ { G; s/^(.*):.*##(.*)/\1@\2/; P ; h ; }' \
	$(MAKEFILE_LIST) | tr @ '\t' 

#
# Build
# 
# automatically triggered on `test` and `generate`

## Build the filter file from sources (requires luacc)
# If SOURCE_DIR is not empty, combine source files with
# luacc and replace the filter file. 
# ifeq is safer than ifdef (easier for the user to make
# the variable empty than to make it undefined).
ifneq ($(SOURCE_DIR), )
$(FILTER_FILE): _check_luacc $(SOURCE_FILES)
	@if [ -f $(QUARTO_EXT_DIR)/$(FILTER_FILE) ]; then \
		luacc -o $(QUARTO_EXT_DIR)/$(FILTER_FILE) -i $(SOURCE_DIR) \
			$(SOURCE_DIR)/$(SOURCE_MAIN) $(SOURCE_MODULES); \
		if [ ! -L $(FILTER_FILE) ]; then \
		    ln -s $(QUARTO_EXT_DIR)/$(FILTER_FILE) $(FILTER_FILE); \
		fi \
	else \
		luacc -o $(FILTER_FILE) -i $(SOURCE_DIR) \
			$(SOURCE_DIR)/$(SOURCE_MAIN) $(SOURCE_MODULES); \
	fi

.PHONY: check_luacc
_check_luacc: 
	@if ! command -v luacc &> /dev/null ; then \
		echo "LuaCC is needed to build the filter. Available on LuaRocks:"; \
		echo " https://luarocks.org/modules/mihacooper/luacc"; \
		exit; \
	fi

endif

#
# Test
#

## Test that running the filter on the sample input yields expected outputs
# The automatic variable `$<` refers to the first dependency
# (i.e., the filter file).
# let `test` be a PHONY target so that it is run each time it's called.
.PHONY: test
test: $(FILTER_FILE) $(TEST_FILES)
	@for ext in $(FORMAT) ; do \
		$(PANDOC) --defaults $(TEST_DEFAULTS) --to $$ext | \
		$(DIFF) expected/expected.$$ext - ; \
	done

## Generate the expected output
# This target **must not** be a dependency of the `test` target, as that
# would cause it to be regenerated on each run, making the test
# pointless.
.PHONY: generate
generate: $(FILTER_FILE) $(TEST_FILES)
	@for ext in $(FORMAT) ; do \
		$(PANDOC) --defaults $(TEST_DEFAULTS) --to $$ext \
		--output $(EXPECTED_DIR)/expected.$$ext ; \
	done

# Benchmark
# used to compare pandoc.utils.references with manual collection
.PHONY: benchmark
benchmark: $(FILTER_FILE) $(TEST_FILES)
	@mv -f $(EXAMPLE_DIR)/references.bib $(EXAMPLE_DIR)/references.back.bib
	@$(PANDOC) lua .tools/benchmark.lua $(DEPTH) > $(EXAMPLE_DIR)/references.bib
	@for ext in $(FORMAT) ; do \
		$(PANDOC) --defaults $(TEST_DEFAULTS) --to $$ext \
		--output $(EXPECTED_DIR)/expected.$$ext --verbose ; \
	done
	@mv -f $(EXAMPLE_DIR)/references.back.bib $(EXAMPLE_DIR)/references.bib

#
# Quarto test
#

## Quarto version of test target
.PHONY: qtest
qtest: $(FILTER_FILE) $(TEST_SRC) $(QTEST_FILES)
	@for ext in $(FORMAT) ; do \
		$(QUARTO) render --profile=test --to $$ext ; \
		$(DIFF) $(EXPECTED_DIR)/$(EXAMPLE_DIR)/qexpected.$$ext \
				$(EXPECTED_DIR)/$(EXAMPLE_DIR)/qtest.$$ext ; \
		rm -f $(EXPECTED_DIR)/$(EXAMPLE_DIR)/qtest.$$ext ; \
	done

## Regenerate Quarto expected outputs
.PHONY: qgenerate
qgenerate: $(FILTER_FILE) $(TEST_SRC) $(QTEST_FILES)
	@for ext in $(FORMAT) ; do \
		$(QUARTO) render --profile=generate --to $$ext ; \
	done

#
# Website
#

## Generate website files in _site
.PHONY: website
website: _site/index.html _site/$(FILTER_FILE)

_site/index.html: $(DOCS_SRC) $(TEST_FILES) $(FILTER_FILE) .tools/docs.lua \
		_site/output.html _site/style.css
	@mkdir -p _site
	@cp .tools/anchorlinks.js _site
	$(PANDOC) \
	    --standalone \
	    --lua-filter=.tools/docs.lua \
	    --lua-filter=.tools/anchorlinks.lua \
		--lua-filter=$(FILTER_FILE) \
	    --metadata=sample-file:$(TEST_SRC) \
	    --metadata=result-file:_site/output.html \
	    --metadata=code-file:$(FILTER_FILE) \
	    --css=style.css \
	    --toc \
	    --output=$@ $<

_site/style.css:
	@mkdir -p _site
	curl \
	    --output $@ \
	    'https://cdn.jsdelivr.net/npm/water.css@2/out/water.min.css'

_site/output.html: $(FILTER_FILE) $(TEST_SRC) $(DOCS_DEFAULTS)
	@mkdir -p _site
	$(PANDOC) \
	    --defaults=$(DOCS_DEFAULTS) \
		--to=html \
	    --output=$@

_site/$(FILTER_FILE): $(FILTER_FILE)
	@mkdir -p _site
	(cd _site && ln -sf ../$< $<)

#
# Quarto extension
#

## Creates or updates the quarto extension
.PHONY: quarto-extension
quarto-extension: $(QUARTO_EXT_DIR)/_extension.yml \
		$(QUARTO_EXT_DIR)/$(FILTER_FILE)

$(QUARTO_EXT_DIR):
	mkdir -p $@

# This may change, so re-create the file every time
.PHONY: $(QUARTO_EXT_DIR)/_extension.yml
$(QUARTO_EXT_DIR)/_extension.yml: _extensions/$(FILTER_NAME)
	@printf 'Creating %s\n' $@
	@printf 'name: %s\n' "$(EXT_NAME)" > $@
	@printf 'author: %s\n' "$(USER_NAME)" >> $@
	@printf 'version: %s\n'  "$(VERSION)" >> $@
	@printf 'contributes:\n  filters:\n    - %s\n' $(FILTER_FILE) >> $@

# The filter file must be below the quarto _extensions folder: a
# symlink in the extension would not work due to the way in which
# quarto installs extensions.
$(QUARTO_EXT_DIR)/$(FILTER_FILE): $(FILTER_FILE) $(QUARTO_EXT_DIR)
	if [ ! -L $(FILTER_FILE) ]; then \
	    mv $(FILTER_FILE) $(QUARTO_EXT_DIR)/$(FILTER_FILE) && \
	    ln -s $(QUARTO_EXT_DIR)/$(FILTER_FILE) $(FILTER_FILE); \
	fi

#
# Release
#

## Sets a new release (uses VERSION macro if defined)
## Usage make release VERSION=x.y.z
.PHONY: release
release: quarto-extension generate
	git commit -am "Release $(FILTER_NAME) $(VERSION)"
	git tag v$(VERSION) -m "$(FILTER_NAME) $(VERSION)"
	@echo 'Do not forget to push the tag back to github with `git push --tags`'

#
# Helpers
#

## Clean regenerable files
.PHONY: clean
clean:
	rm -rf _site/*
	rm -rf $(EXPECTED_DIR)/*

