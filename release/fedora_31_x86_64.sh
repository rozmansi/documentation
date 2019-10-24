#!/bin/sh

ARCH=x86_64
OS_VERSION=31
MOCK_CONFIG=fedora-${OS_VERSION}-${ARCH}

export MOCK_CONFIG ARCH
(
    sh release/build_packages.sh
)