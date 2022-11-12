#!/usr/bin/env bats

@test "GET: /people first person entity is Luke Skywalker" { # The first line contains the test-annotation and a name / explanation of the function to be tested.
    #Arrange
    local EXPECTED_PERSON="Luke Skywalker"
    local ACTUAL_PERSON
    #Act
    ACTUAL_PERSON="$(curl -s https://swapi.dev/api/people/1/ |jq '.name' --raw-output)" # Here we do our call to the Star Wars API with Curl and parse the JSON with jq
    # Assert
    [ "${ACTUAL_PERSON}" == "${EXPECTED_PERSON}" ] # The assert is a normal Bash test, where we check the actual person against what we expect.
}