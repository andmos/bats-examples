#!/usr/bin/env bash

function get_author(){
    local FILE="$1"
    if [[ -z $FILE ]]; then 
        echo "Missing argument file"
        exit 1
    fi
    local AUTHOR=$(grep -oP '(?<=Author:\s)(\w+).*' "$FILE")
    echo "$AUTHOR"
}

function get_title(){
    local FILE="$1"
    if [[ -z $FILE ]]; then 
        echo "Missing argument file"
        exit 1
    fi
    local TITLE=$(grep -oP '(?<=Full Title:\s)(\w+).*' "$FILE")
    echo "$TITLE"
}