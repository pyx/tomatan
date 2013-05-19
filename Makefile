# Program Name {{{1
PROGRAM = tomatan

# Dirs {{{1
PROJECT_DIR = $(realpath .)
DATA_DIR = $(PROJECT_DIR)/data
SRC_DIR = $(PROJECT_DIR)/src
VAPI_DIR = $(PROJECT_DIR)/vapi

# build output dir
BUILD_DIR ?= build
DEBUG_BUILD_DIR ?= $(BUILD_DIR)/debug
RELEASE_BUILD_DIR ?= $(BUILD_DIR)/release

DIST_DIR ?= $(PROJECT_DIR)/dist

# install dest.
prefix ?= /usr/local
exec_prefix ?= $(prefix)
bindir ?= $(exec_prefix)/bin

# Files {{{1
# sources, default to all vala and genie source in SRC_DIR
SRC = $(wildcard $(SRC_DIR)/*.vala) $(wildcard $(SRC_DIR)/*.gs)
# local vapi files
VAPI = $(wildcard $(VAPI_DIR)/*.vapi)
# data files
DATA = $(wildcard $(DATA_DIR)/*)

# build output files
DEBUG_BUILD_OUTPUT = $(DEBUG_BUILD_DIR)/$(PROGRAM)
RELEASE_BUILD_OUTPUT = $(RELEASE_BUILD_DIR)/$(PROGRAM)

# Toolchain {{{1
# vala compiler
VALAC ?= valac
# debugger, default to GUI one
DEBUGGER ?= nemiver

# Flags {{{1
# link with packages...
PKGS += --pkg gtk+-3.0 --pkg libnotify --pkg tomatan-logo

# vala specific flags
VALAFLAGS += --vapidir=$(VAPI_DIR) -X -I$(DATA_DIR)

# gdb specific flags, need this to pass command line arguments into program
ifeq ($(DEBUGGER),gdb)
  DFLAGS += --args
endif

# flags for debug build, keep intermediate c files
DEBUG_OPTS ?= -g --save-temps
# release build, with a little optimization
RELEASE_OPTS ?= -X -O2

# Targets {{{1
.PHONY: all clean debug debug-build dist dist-all-tag dist-dev dist-tag dist-tip install release release-build run uninstall

all: release-build

clean:
	rm -fr *~ *.c *.h *.tmp $(BUILD_DIR) $(DIST_DIR)

# make a debug build, then run inside debugger, passing in ARGS as command line
# arguments.
debug: debug-build
	$(DEBUGGER) $(DFLAGS) $(DEBUG_BUILD_OUTPUT) $(ARGS)
debug-build: $(DEBUG_BUILD_OUTPUT)

dist: dist-dev

dist-all-tag: $(DIST_DIR)
	for t in $(shell hg tags --quiet); do hg archive -r "$$t" "$(DIST_DIR)/$(PROGRAM)-$$t.tar.bz2"; done

dist-dev: $(DIST_DIR)
	hg archive -r. $(DIST_DIR)/$(PROGRAM)-$(shell hg log -r. --template '{node|short}\n').tar.bz2

dist-tag: $(DIST_DIR)
	# find out the latest tagged revision. there should be no revision with
	# more than one tag, otherwise there will be space in archive name.
	hg archive -r $(shell hg log -r. --template '{latesttag}\n') "$(DIST_DIR)/$(PROGRAM)-$(shell hg log -r. --template '{latesttag}\n').tar.bz2"

dist-tip: $(DIST_DIR)
	hg archive -r tip $(DIST_DIR)/$(PROGRAM)-tip.tar.bz2

install:
	install -d $(DESTDIR)$(bindir)
	install -m 0755 $(RELEASE_BUILD_OUTPUT) $(DESTDIR)$(bindir)

release: release-build
release-build: $(RELEASE_BUILD_OUTPUT)

# make a release build, then run it.
run: release-build
	$(RELEASE_BUILD_OUTPUT) $(ARGS)

uninstall:
	-rm $(DESTDIR)$(bindir)/$(PROGRAM)

# Rules {{{1
$(DIST_DIR):
	mkdir -p $(DIST_DIR)

$(DEBUG_BUILD_DIR):
	mkdir -p $(DEBUG_BUILD_DIR)

$(RELEASE_BUILD_DIR):
	mkdir -p $(RELEASE_BUILD_DIR)

$(DEBUG_BUILD_OUTPUT): $(DEBUG_BUILD_DIR) $(VAPI) $(SRC)
	$(VALAC) $(VALAFLAGS) $(DEBUG_OPTS) $(SRC) $(PKGS) -b $(SRC_DIR) -d $(DEBUG_BUILD_DIR) -o $(PROGRAM)

$(RELEASE_BUILD_OUTPUT): $(RELEASE_BUILD_DIR) $(VAPI) $(SRC)
	$(VALAC) $(VALAFLAGS) $(RELEASE_OPTS) $(SRC) $(PKGS) -b $(SRC_DIR) -d $(RELEASE_BUILD_DIR) -o $(PROGRAM)
