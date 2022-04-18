#!/bin/env bash

set -e

if [ "$EUID" -ne 0 ]; then 
    echo "Please run this command as root!"
    exit 1
fi

insmod ../../kernel-module/memutil.ko event_name1="$1" event_name2="$2" event_name3="$3"
