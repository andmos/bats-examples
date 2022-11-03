#!/usr/bin/env bash

function get_author(){
    FILE=$(_validate_input_file "$1")
    if [ $? -eq 1 ]; then 
        echo "$FILE"
        exit 1
    fi
    local AUTHOR
    AUTHOR=$(grep -oP '(?<=Author:\s)(\w+).*' "$FILE")
    echo "$AUTHOR"
}

function get_title(){
    FILE=$(_validate_input_file "$1")
    if [ $? -eq 1 ]; then 
        echo "$FILE"
        exit 1
    fi
    local TITLE
    TITLE=$(grep -oP '(?<=Full Title:\s)(\w+).*' "$FILE")
    echo "$TITLE"
}

function _validate_input_file(){
    local FILE="$1"
    if [[ -z $FILE ]]; then 
        echo "Missing argument file"
        return 1
    fi
    echo "$FILE"
}
