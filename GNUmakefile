# GNUmakefile - pomermaid: the program and its tests.
#
# `make` builds pomermaid under both size models, build/O2/pomermaid and
# build/OC/pomermaid. `make test` builds each unit test,
# test/<Name>Test.Mod, under both, runs it and compares its output with
# test/<Name>Test.expected and its standard error with
# test/<Name>Test.errors (empty if there is no such file); then it runs
# the case tests, test/cases/, with each pomermaid (tools/runcases).
# None of it needs groff, ConTeXt or Mermaid's tools. `make render`
# draws the cases with groff, in build/render/cases.pdf, and with
# ConTeXt, if it is found, in build/render/cases-context.pdf, and as
# SVG, in build/render/svg/, if mutool or pdftocairo is found.
# `make install` installs the pomermaid built under $(MODEL), -OC by
# default, in $(BINDIR), the MetaPost macros, pomermaid.mp, in
# $(DATADIR), its manual page, pomermaid.1, in $(MANDIR)/man1, and its
# documentation in $(DOCDIR), under
# $(PREFIX), ~/.local by default, or $(DESTDIR)$(PREFIX) for a package;
# `make uninstall` removes them. `make clean` removes build/.
#
# src/PmMpMacros.Mod is made from mp/pomermaid.mp by tools/mp2mod, and
# kept in the repository, so a build needs no awk.
#
# The libraries pomermaid uses are found in $(POCLIBDIR),
# ~/.local/lib/poc by default, where their own makefiles install them.

POC ?= poc
PREFIX ?= $(HOME)/.local
POCLIBDIR ?= $(HOME)/.local/lib/poc
BINDIR ?= $(PREFIX)/bin
DOCDIR ?= $(PREFIX)/share/doc/pomermaid
DATADIR ?= $(PREFIX)/share/pomermaid
MANDIR ?= $(PREFIX)/share/man
MODEL ?= OC
BUILD := build
# -trap-heap-exhausted: a NEW that finds no memory stops pomermaid with
# "heap exhausted" (trap 11), not a NIL pointer met later.
POCFLAGS ?= -trap-heap-exhausted

# An installed library on POC_LIBRARY_PATH would be taken in place of the
# one in $(POCLIBDIR).
unexport POC_LIBRARY_PATH

MODELS := O2 OC
SRCS := $(wildcard src/*.Mod)
TESTS := $(patsubst test/%.Mod,%,$(wildcard test/*Test.Mod))
CASES := $(wildcard test/cases/*)

.PHONY: all test test-o2 test-oc check-groff render install uninstall clean FORCE
.SECONDEXPANSION:

all: $(MODELS:%=$(BUILD)/%/pomermaid)

# what poc -version says, rewritten only when it changes, so that what is
# built depends on the compiler
POC_STAMP := $(BUILD)/poc-version

$(POC_STAMP): FORCE
	@mkdir -p $(BUILD)
	@$(POC) -version > $@.new
	@if cmp -s $@.new $@; then rm -f $@.new; else mv $@.new $@; fi

$(BUILD)/%/pomermaid: $(SRCS) $(POC_STAMP)
	mkdir -p $(BUILD)/$*
	$(POC) -$* $(POCFLAGS) -library-path $(POCLIBDIR) -import-path src \
	  -output-dir $(BUILD)/$* -o $@ src/pomermaid.Mod

# the macros, copied into each drawing by -t mp
src/PmMpMacros.Mod: mp/pomermaid.mp tools/mp2mod
	tools/mp2mod mp/pomermaid.mp $@

test: test-o2 test-oc

test-o2: $(TESTS:%=$(BUILD)/O2/test/%.passed) $(BUILD)/O2/cases.passed
test-oc: $(TESTS:%=$(BUILD)/OC/test/%.passed) $(BUILD)/OC/cases.passed

# $* is <model>/test/<Test>. A test is built from the sources, in its own
# directory.
$(BUILD)/%.passed: $(SRCS) test/$$(notdir $$*).Mod test/$$(notdir $$*).expected \
  $$(wildcard test/$$(notdir $$*).errors) $(POC_STAMP)
	mkdir -p $(BUILD)/$(dir $*)
	$(POC) -$(firstword $(subst /, ,$*)) $(POCFLAGS) -library-path $(POCLIBDIR) \
	  -import-path src -import-path test -output-dir $(BUILD)/$(dir $*) \
	  -o $(BUILD)/$* test/$(notdir $*).Mod
	cd $(BUILD)/$(dir $*) && ./$(notdir $*) > $(notdir $*).out 2> $(notdir $*).err
	diff -u test/$(notdir $*).expected $(BUILD)/$*.out
	diff -u $(or $(wildcard test/$(notdir $*).errors),/dev/null) $(BUILD)/$*.err
	touch $@

$(BUILD)/%/cases.passed: $(BUILD)/%/pomermaid $(CASES) tools/runcases
	tools/runcases $(BUILD)/$*/pomermaid $(BUILD)/$*/cases
	touch $@

# PmMetrics' widths against groff's \w, in a few fonts and sizes.
# Needs groff, so make test does not run it.
check-groff:
	set -e; for f in "TR 10" "TI 9" "HB 12" "CR 10.5"; do \
	  POC=$(POC) POCLIBDIR=$(POCLIBDIR) tools/checkwidths $$f; done

# The cases drawn with groff, one to a page, in build/render/cases.pdf,
# for looking at. Needs groff, so make test does not run it.
render: $(BUILD)/OC/pomermaid
	tools/render $(BUILD)/OC/pomermaid $(BUILD)/render

install: $(BUILD)/$(MODEL)/pomermaid
	install -d $(DESTDIR)$(BINDIR) $(DESTDIR)$(DATADIR) $(DESTDIR)$(DOCDIR) \
	  $(DESTDIR)$(MANDIR)/man1
	install -m 644 docs/user/pomermaid.1 $(DESTDIR)$(MANDIR)/man1
	install -m 755 $(BUILD)/$(MODEL)/pomermaid $(DESTDIR)$(BINDIR)/pomermaid
	install -m 644 mp/pomermaid.mp $(DESTDIR)$(DATADIR)
	install -m 644 LICENSE docs/user/pomermaid.md docs/user/differences.md \
	  docs/examples/pomermaid.lua $(DESTDIR)$(DOCDIR)

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/pomermaid
	rm -f $(DESTDIR)$(DATADIR)/pomermaid.mp
	rm -f $(DESTDIR)$(MANDIR)/man1/pomermaid.1
	rm -f $(DESTDIR)$(DOCDIR)/LICENSE $(DESTDIR)$(DOCDIR)/pomermaid.md \
	  $(DESTDIR)$(DOCDIR)/differences.md $(DESTDIR)$(DOCDIR)/pomermaid.lua
	-rmdir $(DESTDIR)$(DATADIR) $(DESTDIR)$(DOCDIR)

clean:
	rm -rf $(BUILD)
