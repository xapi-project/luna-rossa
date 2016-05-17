#
# This header creates a _tags file suitable for coverage analysis
# with bisect_ppx.
# 
# make coverage 
# prepares for building with coverage analysis
#
# make uncover
# reverses the setup from "make coverage"
#

# the default target when Make is called with no argument
default: build

coverage: _tags _tags.coverage 
	test ! -f _tags.orig && mv _tags _tags.orig || true
	cat _tags.coverage _tags.orig > _tags

uncover: _tags.orig
	mv _tags.orig _tags

.PHONY: default coverage uncover
	
# OASIS_START
# DO NOT EDIT (digest: a3c674b4239234cbbe53afe090018954)

SETUP = ocaml setup.ml

build: setup.data
	$(SETUP) -build $(BUILDFLAGS)

doc: setup.data build
	$(SETUP) -doc $(DOCFLAGS)

test: setup.data build
	$(SETUP) -test $(TESTFLAGS)

all:
	$(SETUP) -all $(ALLFLAGS)

install: setup.data
	$(SETUP) -install $(INSTALLFLAGS)

uninstall: setup.data
	$(SETUP) -uninstall $(UNINSTALLFLAGS)

reinstall: setup.data
	$(SETUP) -reinstall $(REINSTALLFLAGS)

clean:
	$(SETUP) -clean $(CLEANFLAGS)

distclean:
	$(SETUP) -distclean $(DISTCLEANFLAGS)

setup.data:
	$(SETUP) -configure $(CONFIGUREFLAGS)

configure:
	$(SETUP) -configure $(CONFIGUREFLAGS)

.PHONY: build doc test all install uninstall reinstall clean distclean configure

# OASIS_STOP
