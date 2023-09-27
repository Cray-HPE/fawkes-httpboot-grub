#
# MIT License
#
# (C) Copyright 2023 Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#

ifeq ($(GIT_REPO_NAME),)
GIT_REPO_NAME := $(basename $(git rev-parse --show-toplevel))
endif

ifeq ($(VERSION),)
VERSION := $(shell git describe --tags | tr -s '-' '~' | sed 's/^v//')
endif

# FIXME: When does this switch to release or when it is omitted?
BUILD_METADATA ?= 1~development~$(shell git rev-parse --short HEAD)

SPEC_FILE ?= ${GIT_REPO_NAME}.spec
SOURCE_NAME ?= ${GIT_REPO_NAME}
BUILD_DIR ?= $(PWD)/dist/rpmbuild
SOURCE_PATH := ${BUILD_DIR}/SOURCES/${SOURCE_NAME}-${VERSION}.tar.bz2
VENDOR := vendor/git.savannah.gnu.org/git/grub

rpm: rpm_package_source rpm_build_source build_vendor rpm_build
build_vendor: setup_grub \
	      build_grub_x86_64 \
	      build_grub_arm64 \
	      build_grub_images_x86_64 \
	      build_grub_images_arm64 

.PHONY: setup_debian
setup_debian:
	sudo apt update
	sudo apt -y install \
		    autoconf \
		    automake \
		    autopoint \
		    autopoint \
		    bison \
		    build-essential \
		    flex \
		    gcc-aarch64-linux-gnu \
		    gcc-arm-linux-gnueabi \
		    gettext \
		    iasl \
		    lzop \
		    unifont

.PHONY: setup_grub
setup_grub:
	(cd ${VENDOR} && ./bootstrap)
	(cd ${VENDOR} && mkdir -p x86_64 arm64)
	cp grub-minimal.cfg ${VENDOR}/x86_64
	cp grub-minimal.cfg ${VENDOR}/arm64
	mkdir -p artifacts
	
.PHONY: build_grub_x86_64
build_grub_x86_64:
	(cd ${VENDOR}/x86_64 && \
		../configure \
		    --target=x86_64-linux-gnu \
		    --with-platform=efi \
		    --host=x86_64 \
	)
	$(MAKE) -C ${VENDOR}/x86_64

.PHONY: build_grub_arm64
build_grub_arm64:
	(cd ${VENDOR}/arm64 && \
		../configure \
		    --target=aarch64-linux-gnu \
		    --with-platform=efi \
		    --host=x86_64 \
	)
	$(MAKE) -C ${VENDOR}/arm64
	
.PHONY: build_grub_images_x86_64
build_grub_images_x86_64:
	(cd ${VENDOR}/x86_64 && \
		./grub-mkstandalone \
		    --locale-directory /boot/grub/locale/ \
		    -d grub-core \
	            -O x86_64-efi \
		    --modules="configfile echo efinet fat help http linux ls net normal part_gpt part_msdos" \
		    -o "bootx64.efi" \
		    "boot/grub/grub.cfg=grub-minimial.cfg" \
	)
	cp ${VENDOR}/x86_64/bootx64.efi artifacts/

.PHONY: build_grub_images_arm64
build_grub_images_arm64:
	(cd ${VENDOR}/arm64 && \
		./grub-mkstandalone \
		    --locale-directory /boot/grub/locale/ \
		    -d grub-core \
		    -O arm64-efi \
		    --modules="configfile echo efinet fat help http linux ls net normal part_gpt part_msdos" \
		    -o "bootaa64.efi" \
		    "boot/grub/grub.cfg=grub-minimial.cfg" \
        )
	cp ${VENDOR}/arm64/bootaa64.efi artifacts/

.PHONY: clean
clean:
	$(MAKE) clean -C ${VENDOR}/x86_64 || true
	$(MAKE) clean -C ${VENDOR}/arm64 || true
	(cd ${VENDOR} && \
		git clean -f -d -x \
	)

.PHONY: prepare
prepare:
	rm -rf $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)/SPECS $(BUILD_DIR)/SOURCES ${BUILD_DIR}/BUILD
	cp $(SPEC_FILE) $(BUILD_DIR)/SPECS/

.PHONY: rpm_package_source
rpm_package_source:
	tar --transform 'flags=r;s,^,/${GIT_REPO_NAME}-${VERSION}/,' --exclude .git --exclude dist -cvjf $(SOURCE_PATH) .

.PHONY: rpm_build_source
rpm_build_source:
	BUILD_METADATA=$(BUILD_METADATA) rpmbuild --nodeps -bs $(BUILD_DIR)/SPECS/$(SPEC_FILE) --define "_topdir $(BUILD_DIR)"

.PHONY: rpm_build
rpm_build:
	BUILD_METADATA=$(BUILD_METADATA) rpmbuild --nodeps -bb $(BUILD_DIR)/SPECS/$(SPEC_FILE) --define "_topdir $(BUILD_DIR)"

