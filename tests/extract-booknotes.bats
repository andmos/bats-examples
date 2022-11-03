#!/usr/bin/env bats

function setup(){
    source ./extract-booknotes.sh
}

function teardown(){
  echo $result
}

@test "extract_author no argument" {
    run get_author 

    [ "${status}" -eq 1 ]
    [ "${lines[0]}" == "Missing argument file" ]
}

@test "extract_author with 'Above The Clouds' file as argument" {
    run get_author BookNotes/Above.The.Clouds.md

    [ "${status}" -eq 0 ]
    [ "${lines[0]}" == "Kilian Jornet" ]
}

@test "extract_title no argument" {
    run get_title

    [ "${status}" -eq 1 ]
    [ "${lines[0]}" == "Missing argument file" ]
}

@test "extract_title with 'Above The Clouds' file as argument" {
    run get_title BookNotes/Above.The.Clouds.md

    [ "${status}" -eq 0 ]
    [ "${lines[0]}" == "Above the Clouds: How I Carved My Own Path to the Top of the World" ]
}

@test "_validate_input_file with no argument" {
    run _validate_input_file

    [ "${status}" -eq 1 ]
    [ "${lines[0]}" == "Missing argument file" ]
}

@test "_validate_input_file with 'extract-booknotes.sh' file as argument" {
    run _validate_input_file extract-booknotes.sh
    
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" == "extract-booknotes.sh" ]
}
