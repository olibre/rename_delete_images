#!/bin/bash -e

# This script keeps ORF files having same filename as other JPG/jpg/jpeg/... files
# The script removes the other ORF files = the ORF orphans

if (( $# ))
then
    if [[ -d "$1" ]]
    then
        echo "
Ready to rename all JPEG files in following directory and subdirectories? (y/n)
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
Ready to rename all JPEG files in current directory and subdirectories? (y/n)
Current directory: '
    pwd
fi


# TODO check TTY [[ -t 0 ]] [[ -t 1 ]]
read -n 1 -p '(renaming consists in prefixing current filename with date and time)' answer
if [[ $answer != [yY] ]]
then
    echo >&2 "Answer '$answer' is not [yY] => exit"
    exit
fi

find $1 -name '[0-9][0-9]*' -o -type f -exec jhead -ft -n%Y%m%d_%H%M%S_%f {} +
