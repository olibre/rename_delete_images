#!/bin/bash -e

# This script keeps ORF files having same filename as other JPG/jpg/jpeg/... files
# The script removes the other ORF files = the ORF orphans

dir_orf=${1?:Missing 1st parameter = Directory to find files ORF}
dir_jpg=${2?:Missing 2nd parameter = Directory to find files JPG/jpg/jpeg/...}

export LANG=C # Use default settings (locale) for command 'sort'

echo 'Extracting filenames...'

orf_files=$( find "$dir_orf" -type f  -name '*.ORF' )
jpg_files=$( find "$dir_jpg" -type f -iregex '.*[.]JPE?G' )

orf_names=$( sed 's|.*/\([^.]*\)[.][^.]\+$|\1|' <<< "$orf_files" )
jpg_names=$( sed 's|.*/\([^.]*\)[.][^.]\+$|\1|' <<< "$jpg_files" )

orf_uniqs=$( sort -u <<< "$orf_names" )
jpg_uniqs=$( sort -u <<< "$jpg_names" )

orphans=$(  while read orf
            do
                if ! fgrep -sq "$orf" <<< "$jpg_uniqs"
                then
                    echo "$orf"
                fi
            done <<< "$orf_uniqs"
        )

[[ -z $orf_files ]] && count_orf=0 || count_orf=$( wc -l <<< "$orf_files" )
[[ -z $jpg_files ]] && count_jpg=0 || count_jpg=$( wc -l <<< "$jpg_files" )
[[ -z $orphans   ]] && count=0     || count=$(     wc -l <<< "$orphans"   )

echo -e "
Found:
\t$count_orf files '*.ORF'
\t$count_jpg files '*.JPG' '*.JPEG' (case insesitive)
\t$count orphans '*.ORF'
"

if [[ $count -eq 0 ]]
then
    echo >&2 'No ORF orphans found => exit'
    exit
fi



echo 'Checking filenames...'

find_pattern()
{
    id="$1"
    if [[ $dir_orf == $dir_jpg ]]
    then
        find "$dir_orf" -type f -name "*$id*"
    else
        find "$dir_orf" "$dir_jpg" -type f -name "*$id*"
    fi | wc -l
}

# Basic check
error=0
while read orph
do
    count=$( find_pattern "$orph" )
    if [[ $count -ne 1 ]]
    then
        echo >&2 "ERROR: Pattern '$orph' has been determined as identifing an orphan ORF files. But there are '$count' filenames containing the pattern (should be 1)"
        set +e
        let error++
        set -e
    fi
done <<< "$orphans"

if (( $error ))
then
    echo >&2 "Found '$error' error(s) => exit"
    exit
fi

orphan_files=
while read orph
do
    filename=$( fgrep "/$orph".ORF <<< "$orf_files" )
    if [[ -f "$filename" ]]
    then
        if [[ -z $orphan_files ]]
        then    # First insertion
            orphan_files="$filename"
        else    # Append
            orphan_files="$orphan_files
$filename"
        fi
    else
        echo >&2 "ERROR: Name '$orph' has been determined as unique ORF files. But cannot find file in directory '$dir_orf'."
        set +e
        let error++
        set -e
    fi
done <<< "$orphans"

if (( $error ))
then
    echo >&2 "Found '$error' error(s) => exit"
    exit
fi

# TODO check TTY [[ -t 0 ]] [[ -t 1 ]]
count=$( wc -l <<< "$orphan_files" )
read -n 1 -p "
Ready to delete '$count' ORF orphans? (y/n)" answer
if [[ $answer != [yY] ]]
then
    echo >&2 "Answer '$answer' is not [yY] => exit"
    exit
fi

while read orph
do
    if ! rm -v "$orph"
    then
        echo >&2 "ERROR while removing '$orph' => exit"
        exit
    fi
done <<< "$orphan_files"
