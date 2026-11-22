# GNUmakefile - pomermaid: the program and its tests.
#
# `make` builds pomermaid under both size models, build/O2/pomermaid and
# build/OC/pomermaid. `make test` builds each unit test,
# test/<Name>Test.Mod, under both, runs it and compares its output with
# test/<Name>Test.expected and its standard error with
# test/<Name>Test.errors (empty if there is no such file); then it runs
# the case tests, test/cases/, with each pomermaid (tools/runcases).
# None of it needs groff, ConTeXt or Mermaid's tools.
# `make install` installs the pomermaid built under $(MODEL), -OC by
# default, in $(BINDIR), and its documentation in $(DOCDIR), under
# $(PREFIX), ~/.local by default, or $(DESTDIR)$(PREFIX) for a package;
# `make uninstall` removes them. `make clean` removes build/.
#
# The libraries pomermaid uses are found in $(POCLIBDIR),
# ~/.local/lib/poc by default, where their own makefiles install them.

POC ?= poc
PREFIX ?= $(HOME)/.local
POCLIBDIR ?= $(HOME)/.local/lib/poc
BINDIR ?= $(PREFIX)/bin
DOCDIR ?= $(PREFIX)/share/doc/pomermaid
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

.PHONY: all test test-o2 test-oc install uninstall clean FORCE
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

install: $(BUILD)/$(MODEL)/pomermaid
	install -d $(DESTDIR)$(BINDIR) $(DESTDIR)$(DOCDIR)
	install -m 755 $(BUILD)/$(MODEL)/pomermaid $(DESTDIR)$(BINDIR)/pomermaid
	install -m 644 LICENSE $(DESTDIR)$(DOCDIR)

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/pomermaid
	rm -f $(DESTDIR)$(DOCDIR)/LICENSE
	-rmdir $(DESTDIR)$(DOCDIR)

clean:
	rm -rf $(BUILD)
