NAME := selenium-rocker
VERSION := $(or $(VERSION),$(VERSION),3.9.1-actinium)
NAMESPACE := $(or $(NAMESPACE),$(NAMESPACE),$(NAME))
AUTHORS := $(or $(AUTHORS),$(AUTHORS),SeleniumHQ)
PLATFORM := $(shell uname -s)
BUILD_ARGS := $(BUILD_ARGS)
MAJOR := $(word 1,$(subst ., ,$(VERSION)))
MINOR := $(word 2,$(subst ., ,$(VERSION)))
MAJOR_MINOR_PATCH := $(word 1,$(subst -, ,$(VERSION)))

all: chrome standalone_chrome

generate_all:	\
	generate_nodebase \
	generate_chrome \
	generate_standalone_chrome 

build: all

base:
	cd ./Base && docker build $(BUILD_ARGS) -t $(NAME)/base:$(VERSION) .

# create Dockerfile from Dockerfile.txt using script generate.sh
generate_nodebase:
	cd ./NodeBase && ./generate.sh $(VERSION) $(NAMESPACE) $(AUTHORS)

nodebase: base generate_nodebase
	cd ./NodeBase && docker build $(BUILD_ARGS) -t $(NAME)/node-base:$(VERSION) .

# create Dockerfile from Dockerfile.txt using script generate.sh	
generate_chrome:
	cd ./NodeChrome && ./generate.sh $(VERSION) $(NAMESPACE) $(AUTHORS)

chrome: nodebase generate_chrome
	cd ./NodeChrome && docker build $(BUILD_ARGS) -t $(NAME)/node-chrome:$(VERSION) .

# create Dockerfile from Dockerfile.txt using script generate.sh	
generate_standalone_chrome:
	cd ./Standalone && ./generate.sh StandaloneChrome node-chrome Chrome $(VERSION) $(NAMESPACE) $(AUTHORS)

standalone_chrome: chrome generate_standalone_chrome
	cd ./StandaloneChrome && docker build $(BUILD_ARGS) -t $(NAME)/standalone-chrome:$(VERSION) .
	
.PHONY: \
	all \
	base \
	build \
	chrome \
	generate_all \
	generate_nodebase \
	generate_chrome \
	generate_standalone_chrome \
	nodebase \
	standalone_chrome \