#!/bin/bash -e

if (( $# ))
then
    if [[ -d "$1" ]]
    then
        echo "
This script will rename JPEG files in following directory and subdirectories:
'$1'
"
    else
        echo 2>&1 "
First argument is not a directory: '$1'
=> exit
"
        exit
    fi
else
    echo -n '
This script will rename JPEG files in current directory and subdirectories.
Current directory: '
    pwd
fi

echo "The renaming consists in prefixing current filename with date and time."


# TODO check TTY [[ -t 0 ]] [[ -t 1 ]]
read -n 1 -p 'Ready to continue? (y/n) ' answer
if [[ $answer != [yY] ]]
then
    echo >&2 "
Answer '$answer' is not 'y' or 'Y' => exit"
    exit
fi

echo

find "$@" -name '[0-9][0-9]*' -o -type f -exec jhead -ft -n%Y%m%d_%H%M%S_%f {} +
