#!/bin/bash

export LANG=C # Use default settings (locale) for command 'sort'

echo 'Extracting patterns from filenames...'

skip_because_no_orf=0
skip_because_no_jpg=0
skip_because_too_many_jpg=0
already_same_name=0
changed_filenames=0

while read id
do
    orf=$( find "$@" -type f -iname "*$id*.ORF"  -printf "%f\n" | sort -u )
    jpg=$( find "$@" -type f -iname "*$id*.JP*G" -printf "%f\n" | sort -u )
    count_orf=$( wc -l <<< "$orf" )
    count_jpg=$( wc -l <<< "$jpg" )

    if [[ ${count_orf} -eq 0 ]]
    then
        echo >&2 "
ERROR: Identifier '$id' has been extracted from ORF files. But cannot find any ORF filename containing this identifier.
"
        let skip_because_no_orf++
        continue
    elif [[ ${count_jpg} -eq 0 ]]
    then
        echo >&2 "
All filenames containing identifier '$id' are ORF files => Skip (cannot rename)
"
        let skip_because_no_jpg++
        continue
    elif [[ ${count_jpg} -gt 1 ]]
    then
        echo >&2 "
Several different JPEG filenames containing identifier '$id' => Skip (cannot select one filename).
JPEG filenames are: $jpg
"
        let skip_because_too_many_jpg++
        continue
    else
        filename=${jpg%.*}
        if [[ ${orf%.*} == $filename ]]
        then
            let already_same_name++
        else
            find "$@" -type f -iname "*$id*.ORF" -execdir mv -v {} "$filename.ORF" ';'
            let changed_filenames++
        fi
    fi
done < <(find "$@" -type f  -iname '*.ORF' -printf "%f\n" | # Print filenames
         grep -o 'P[^._-]*'                               | # Extract identifier
         sort -u                                          ) # Unique identifiers


echo "Summary:
  skip_because_no_orf       = $skip_because_no_orf
  skip_because_no_jpg       = $skip_because_no_jpg
  skip_because_too_many_jpg = $skip_because_too_many_jpg
  already_same_name         = $already_same_name
  changed_filenames         = $changed_filenames
"

