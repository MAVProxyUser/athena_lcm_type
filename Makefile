.DEFAULT_GOAL := build

.PHONY: build test

.PHONY: no_targets list

SHELL = /usr/bin/env bash

#############
# Variables # 
#############
# Git
CI_BUILD_CONCURRECY ?= 40
CI_COMMIT_SHORT_SHA ?= no_sha
CI_COMMIT_REF_NAME ?= master
CI_PROJECT_DIR ?= $(shell pwd)
GIT_CLONE_COMMAND ?= git clone --recurse-submodules -j$(CI_BUILD_CONCURRECY)

# Athena athena_lcm_type build variables
CYBERDOG_PATH ?= /opt/ros2/cyberdog
CROSS_ROOT_PATH ?= /mnt/sdcard
CROSS_HOME_PATH ?= $(CROSS_ROOT_PATH)/home
CROSS_SETUP_BASH_FILE ?= $(CROSS_ROOT_PATH)/opt/ros2/foxy/local_setup.bash
CROSS_CYBERDOG_PATH ?= $(CROSS_ROOT_PATH)$(CYBERDOG_PATH)
CROSS_BUILD_FLAG ?= --cmake-force-configure --cmake-args -DCMAKE_TOOLCHAIN_FILE=/home/builder/toolchainfile.cmake --merge-install --event-handlers console_cohesion+ --install-base $(INSTALL_BASE) --parallel-workers $(CI_BUILD_CONCURRECY) --packages-up-to $(PACKAGE_NAME)
CROSS_TEST_FLAG ?= --merge-install --event-handlers console_cohesion+ --return-code-on-test-failure --install-base $(INSTALL_BASE) --parallel-workers $(CI_BUILD_CONCURRECY) --packages-up-to $(PACKAGE_NAME)

REPO_NAME := $(lastword $(subst /, ,$(CI_PROJECT_DIR)))
PACKAGE_NAME ?= lcm_translate_msgs
ATHENA_REPOS_NAME ?= src
INSTALL_BASE ?= $(CROSS_HOME_PATH)/$(REPO_NAME)/athena_ros2_deb/src$(CYBERDOG_PATH)
CLEAN_FILES ?= $(ATHENA_REPOS_NAME) athena_ros2_deb/src$(CYBERDOG_PATH)/*
BUILD_FILE_NAME ?= $(PACKAGE_NAME)_athena_ros2_deb_src-$(CI_COMMIT_SHORT_SHA).tar

#################
# BUILD TARGET  #
#################
build: touch-files build-files upload-files

touch-files:
	cp -arp $(CI_PROJECT_DIR) $(CROSS_HOME_PATH)
	mkdir -p $(CROSS_HOME_PATH)/build
	cd $(CROSS_HOME_PATH) && \
		rm -rf $(CLEAN_FILES)

build-files:
	cd $(CROSS_HOME_PATH) && \
		source $(CROSS_SETUP_BASH_FILE) && \
		colcon build $(CROSS_BUILD_FLAG)

upload-files:
	cd $(CROSS_HOME_PATH)/$(REPO_NAME) && \
		tar cf $(BUILD_FILE_NAME) athena_ros2_deb/src && \
		$(FDS_COMMAND_UPLOAD) $(BUILD_FILE_NAME) $(FDS_URL_PREFIX)/$(REPO_NAME)/$(CI_COMMIT_REF_NAME)/$(BUILD_FILE_NAME)

#################                                                      
# TEST TARGET   #
#################
test: touch-files build-files
	cd $(CROSS_HOME_PATH) && \
		colcon test $(CROSS_TEST_FLAG)


################
# Minor Targets#
################
no_targets:
list:
	@sh -c "$(MAKE) -p no_targets | awk -F':' '/^[a-zA-Z0-9][^\$$#\/\\t=]*:([^=]|$$)/ {split(\$$1,A,/ /);for(i in A)print A[i]}' | grep -v '__\$$' \
		| grep -v 'make'| grep -v 'list'| grep -v 'no_targets' |grep -v 'Makefile' | sort | uniq"
