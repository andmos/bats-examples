# TDD for shell scripts with bats

Let's begin simple: We want to extract the author from a markdown file containing book notes, but want the job to exit if no argument is given:

```sh
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
```

When run against an empty file, this test will fail:

```sh
#!/usr/bin/env bash

function get_author(){

}
```

```sh
$ bats tests/extract-booknotes.bats 
extract-booknotes.bats
 ✗ extract_author no argument
   (from function `setup' in test file tests/extract-booknotes.bats, line 4)
     `source ./extract-booknotes.sh ' failed with status 2
   ./extract-booknotes.sh: line 9: syntax error near unexpected token `}'
   

1 test, 1 failure
```

And if we fill in the code:

```sh
#!/usr/bin/env bash

function get_author(){
    local FILE="$1"
    if [[ -z $FILE ]]; then 
        echo "Missing argument file"
        exit 1
    fi
}
```

And run the testa again:

```sh
$ bats tests/extract-booknotes.bats 
extract-booknotes.bats
 ✓ extract_author no argument

1 test, 0 failures
```

We get some green tests.

Cool. Now for the functionality. We want to extract the author(s) from the markdown notes file:

```md
### Metadata

- Author: Kilian Jornet
- Full Title: Above the Clouds: How I Carved My Own Path to the Top of the World
- Category: #books
```

Again, let's start with the test:

```sh
@test "extract_author with 'Above The Clouds' file as argument" {
    run get_author BookNotes/Above.The.Clouds.md
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" == "Kilian Jornet" ]
}
```

And that test will fail since we don't have updated our code:

```sh
$ bats tests/extract-booknotes.bats 
extract-booknotes.bats
 ✓ extract_author no argument
 ✗ extract_author with 'Above The Clouds' file as argument
   (in test file tests/extract-booknotes.bats, line 20)
     `[ "${lines[0]}" == "Kilian Jornet" ]' failed
   

2 tests, 1 failure
```

Cool. Now let's do some regex-matching, an operation that's good to have tests for:

```sh
function get_author(){
    local FILE="$1"
    if [[ -z $FILE ]]; then 
        echo "Missing argument file"
        exit 1
    fi
    local AUTHOR=$(grep -oP '(?<=Author:\s)(\w+).*' "$FILE") # <---This one right here. I'm not comfortable with regex spread around, so a test for this is quite nice.
    echo "$AUTHOR"
}

```

With this pice of code in place, the test should be green:

```sh
$ bats tests/extract-booknotes.bats 
extract-booknotes.bats
 ✓ extract_author no argument
 ✓ extract_author with 'Above The Clouds' file as argument

2 tests, 0 failures
```

And indeed it is.

Don't believe the tests? Let' try the method ourself:

```sh
$ source extract-booknotes.sh
$ get_author BookNotes/BookNotes/Above.The.Clouds.md 
Kilian Jornet
```

Don't you know it, it works! Tests don't lie. 

How about the title? We have the author, but not the title? That's kind of backwards.
Let's begin by specifying how the function should look, again from our tests:

```sh
@test "extract_title no argument" {
    run get_title
    [ "${status}" -eq 1 ]
    [ "${lines[0]}" == "Missing argument file" ]
}
```

Same as before, no file should give output and exitcode 1. No code written yet, no green test. You know the drill.

With that in place we can focus on extracting the title from the file. As always, the test first:

```sh
@test "extract_title with 'Above The Clouds' file as argument" {
    run get_title BookNotes/Above.The.Clouds.md
    [ "${status}" -eq 0 ]
    [ "${lines[0]}" == "Above the Clouds: How I Carved My Own Path to the Top of the World" ]
}
```

How do you think running this test will go? That's a no. We don't have any code yet.

Let's break out that regex to match the title from the markdown:

```sh
function get_title(){
    local FILE="$1"
    if [[ -z $FILE ]]; then 
        echo "Missing argument file"
        exit 1
    fi
    local TITLE=$(grep -oP '(?<=Full Title:\s)(\w+).*' "$FILE")
    echo "$TITLE"
}
```

With this line in place, the tests go green:

```sh
$ bats tests/extract-booknotes.bats 
extract-booknotes.bats
 ✓ extract_author no argument
 ✓ extract_author with 'Above The Clouds' file as argument
 ✓ extract_title no argument
 ✓ extract_title with 'Above The Clouds' file as argument

4 tests, 0 failures
```

NICE. But wait. What about refactoring? Isn't that a part of TDD?

Yes indeed. The observant reader may have seen that the two functions have something in common: both take in a file for parsing, and both do the parsing based on REGEX expressions.
