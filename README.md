# TDD for shell scripts with bats

## Testing, testing

> "Testing shows the presence, not the absence of bugs." - [Edsger W. Dijkstra](http://homepages.cs.ncl.ac.uk/brian.randell/NATO/nato1969.PDF)

(Some intro on how it's more common than not to have tests in our project)

[Dave Farley wrote a blog post some years ago](https://www.davefarley.net/?p=278) about how we should use techniques from classical science and engineering and apply them to software development to make the field "a real engineering field, not just a pretend-to-be", and to archive this, testing is essential. To be frank, in how many other engineering fields is testing of the things created optional?

Used correctly, automated testing is a great way to implement the essence of science, to falsify the hypothesis about the code.

Every programming language or ecosystem that's worth taking seriously has a testing library, or sometimes whole frameworks created for them. For C# and dotnet [xunit](https://github.com/xunit/xunit) has become somewhat of a standard, in Java and JVM land [JUnit](https://junit.org/junit5/) has been around for a long time, and for JavaScript, both frontend and backend, testing with [Jest](https://jestjs.io/) has seen a lot of traction.

Writing our unit, integration or integrated tests in the same language as the production code and keeping the tests close is the de facto standard.

But aren't we forgetting something? Our systems do not stop at the application code level. To be able to build and deploy our code, chances are we have some build scripts and deployment pipelines, or some good old "glue scripts" keeping it all together. To do most of this heavy lifting most of us still depend on the good old shell scripts, most notably written in the old work-horse Bourne Again Shell, or Bash.

If anything, chances are slim that Bash is going away anytime soon, and scripts written for the shell deserves tests of it's own.
The shell is also often forgotten as an environment to test systems from in of itself. There are lots of CLI's that can be used to test different aspect of our systems, and there is no rule proclaiming that integration or load tests need to be written or hosted by the same codebase as our application.

It's time to introduce shell testing with `bats`.

## Shell testing with Bats

To show how writing tests with `bats` work, let's write some black-box test verifying a REST-API with `curl`.
Our "system under test", or "SUT", is the [The Star Wars API](https://swapi.dev/). This will show how `bats` work, and show one of it's use cases.

We begin with a test to make sure Luke Skywalker is the first entity of the `/people` endpoint.
As we will see, tests are set up like most other testing frameworks, here following the "arrange act assert" pattern.

```sh
#!/usr/bin/env bats

@test "GET: /people first person entity is Luke Skywalker" { # The first line contains the test-annotation and a name / explanation of the function to be tested.
    #Arrange
    local EXPECTED_PERSON="Luke Skywalker"
    local ACTUAL_PERSON
    #Act
    ACTUAL_PERSON="$(curl -s https://swapi.dev/api/people/1/ |jq '.name' --raw-output)" # Here we do our call to the Star Wars API with curl and parse the JSON with jq
    # Assert
    [ "${ACTUAL_PERSON}" == "${EXPECTED_PERSON}" ] # The assert is a normal Bash test, where we check the actual person against what we expect.
}
```

To run the test, use the `bats` command:

```sh
$ bats tests/star-wars-api.bats 
star-wars-api.bats
 ✓ GET: /people first person entity is Luke Skywalker

1 tests, 0 failures
```

We can expand on this and check if the `/planets` endpoint contains Naboo:

```sh
@test "GET: /planets contains 'Naboo'" {
    local EXPECTED_PLANET="Naboo"
    local ACTUAL_PLANET 

    ACTUAL_PLANET="$(curl -s https://swapi.dev/api/planets/ | EXPECTED_PLANET="$EXPECTED_PLANET" jq '.results[] | select(.name == env.EXPECTED_PLANET).name' --raw-output)"

    [ "${ACTUAL_PLANET}" == "${EXPECTED_PLANET}" ]
}
```

The two tests are now run together:

```sh
$ bats tests/star-wars-api.bats 
star-wars-api.bats
 ✓ GET: /people first person entity is Luke Skywalker
 ✓ GET: /planets contains 'Naboo'

2 tests, 0 failures
```

Great. Those examples show the overview of `bats`. Next, let's spice it up with some Test Driver Development (TDD) on some actual shell scripts.

## Using TDD in our shell scripts for fun and profit

Let's begin simple: We want a function to extract the author from a markdown file containing book notes, but want the job to exit if no argument (I.e. a file) is given. This being TDD, we want a failing test explaining the logic we want before we actually write som code.

In this example, we will see the keyword `run`, which is used to run a function, as well as the `$status` and `$lines` variables provided by `bats`.

```sh
#!/usr/bin/env bats

function setup(){
    source ./extract-booknotes.sh # The setup method sources in the script we want to test.
}

function teardown(){
  echo $result # The teardown method returns the "$result" variable from bats itself. This helps with debugging failing tests.
}

@test "extract_author no argument" { # The first line contains the test-annotation and a name / explanation of the function to be tested.
    run get_author  # The `run` keyword comes from bats and is for triggering functions or script.

    [ "${status}" -eq 1 ] # The $status variable contains the return code from the functions or scripts being tested, 
    [ "${lines[0]}" == "Missing argument file" ] # While the $lines variable is an array of strings from the functions or script we want to test.
}
```

When run against an empty file, this test will (not surprisingly) fail:

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

Cool. Now for the functionality. We want to extract the author from the markdown notes file:

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
    local AUTHOR
    AUTHOR=$(grep -oP '(?<=Author:\s)(\w+).*' "$FILE") # <--- This one right here. I'm not comfortable with regex spread around, so a test for this is quite nice.
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

Same as before, no file should give output and exit code 1. No code written yet, no green test. You know the drill.

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
    local TITLE
    TITLE=$(grep -oP '(?<=Full Title:\s)(\w+).*' "$FILE")
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

Yes indeed. The observant reader may have seen that the two functions have something in common: both take in an argument of a file name for parsing, and both do the parsing based on regex expressions. If noe argument is given, return an exit code and a message saying "Missing Argument file". 

Let's begin by extracting the input validation from the `get_author` and `get_title` functions and call it `_file_exists`. This function will be more generalized and standalone. As always, the functions behavior is first described with tests, which makes for great documentation of the function.

```sh

# The behavior should be the same for no arguments, exitcode 1 and 'Missing Argument file' as output:
@test "_file_exists with no argument" {
    run _file_exists

    [ "${status}" -eq 1 ]
    [ "${lines[0]}" == "Missing argument file" ]
}

# Since the function validating the input file now can be extracted from the book notes parser, it can check the script itself:
@test "_file_exists with 'extract-booknotes.sh' file as argument" {
    run _file_exists extract-booknotes.sh

    [ "${status}" -eq 0 ]
    [ "${lines[0]}" == "extract-booknotes.sh" ]
}
```

Then we can extract the input check directly from the functions:

```sh
function _file_exists(){
    local FILE="$1"
    if [[ -z $FILE ]]; then 
        echo "Missing argument file"
        return 1
    fi
    echo "$FILE"
}
```

Now here we could also extend the `_file_exists` code with a branch handling an argument of the name of a non-existing file, but to stay strictly in line with TDD we should only add enough production code for the tests to to pass, which we have done with the extracted snippet.

The refactored `get_author` function now looks like this:

```sh
function get_author(){
    FILE=$(_file_exists "$1") # <--- Here we run the input through the validation function
    if [ $? -eq 1 ]; then  # <--- And then check the return code from the function
        echo "$FILE" # <--- Before we return the output from the validation if it fails
        exit 1 # <--- Then, exit.
    fi
    local AUTHOR
    AUTHOR=$(grep -oP '(?<=Author:\s)(\w+).*' "$FILE")
    echo "$AUTHOR"
}
```

How about the tests?

```sh
$ bats tests/extract-booknotes.bats 
extract-booknotes.bats
 ✓ extract_author no argument
 ✓ extract_author with 'Above The Clouds' file as argument
 ✓ extract_title no argument
 ✓ extract_title with 'Above The Clouds' file as argument
 ✓ _file_exists with no argument
 ✓ _file_exists with 'extract-booknotes.sh' file as argument

6 tests, 0 failures
```

Did the code get any better or clearer? More dynamic and a better abstraction, but shorter? Absolutely not, but the tests are green so the refactoring could be made safer with guardrails.
