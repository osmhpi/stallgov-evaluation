#!/bin/env bash

set -e

if [ "$EUID" -ne 0 ]; then 
    echo "Please run this command as root!"
    exit 1
fi

rmmod ../../kernel-module/memutil.ko
