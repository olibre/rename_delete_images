#!/bin/bash

# Copyright 2013 oLibre@Lmap.org
#
# Fair license - http://en.wikipedia.org/wiki/Fair_License
#   Usage of the works is permitted provided that
#   this instrument is retained with the works,
#   so that any entity that uses the works
#   is notified of this instrument.
#   DISCLAIMER: THE WORKS ARE WITHOUT WARRANTY.
#
# License Équitable - http://french.stackexchange.com/questions/7034
#   Toute utilisation des œuvres est permise à condition
#   que cette mention légale soit conservée avec les œuvres,
#   afin que tout autre utilisateur des œuvres
#   soit informé de cette mention légale.
#   AVERTISSEMENT : LES ŒUVRES N'ONT PAS DE GARANTIE.

#set -e   #debug (exit as soon an error occurs)

usage()
{
  echo >&2 "
Invalid option: -$1

Usage:  ${0##*/}  [-b BASE_DIR]  [-j JUNK_DIR]  [PATHS...]

BASE_DIR is the temporary directory where all the working files are created.
At the end, the command '${0##*/}' removes all temporary files
and also removes the BASE_DIR main directory except if it contains JUNK_DIR.

JUNK_DIR is the directory where to 'junk' (throw) the duplicated files
To be safer the command '${0##*/}' does not deleted this JUNK_DIR.
Finally, the user deletes itself the JUNK_DIR.

PATHS are one or more directories where to search for duplicated files.
By default, search in the current working directory.
"
  exit 1
}



unset base
unset junk

# command line options
while getopts "b:j:" opt; do
  case $opt in
    b)   base=$OPTARG; mkdir -p "$base";;
    j)   junk=$OPTARG;;
    \?)  usage;;
    :)   usage;;
  esac
done

shift $(($OPTIND - 1))
# Remaining arguments are "$@"


[[ -z $base ]] && base=$(mktemp -d)
[[ -z $junk ]] && junk="${base}"/junk
                  fifo="${base}"/fifo
                  fif2="${base}"/fif2
                  dups="${base}"/dups
                  dirs="${base}"/dirs
                  menu="${base}"/menu
                  numb="${base}"/numb
                  list="${base}"/list

rm -f  "$fifo" "$fif2"
mkfifo "$fifo" "$fif2"

# real path
shopt -sq expand_aliases
if type realpath &>/dev/null
then
  alias rp='realpath'
elif type readlink &>/dev/null
then
  alias rp='readlink -fn'
elif type perl &>/dev/null
then
  alias rp='perl -e '\''use Cwd "abs_path"; print abs_path("$ARGV[1]");'\'
else
  alias rp='echo'
fi

#find in the PATHS given as parameter ($@) or in current directory (.) by default
find_except_junk()
{
  [[ -d $junk ]] && j=$( rp "$junk" )
  for dir in "$@"
  do
    if [[ -e $dir ]]
    then
#      echo "$dir"
      d=$( rp "$dir" )
      if [[ -d $junk ]]
      then        #ignore file in $junk (JUNK_DIR)
        find -L -O3 "$d" -path "$j" -prune -o -xtype f -readable -printf '%11s %p\0'
      else
        find -L -O3 "$d"                      -xtype f -readable -printf '%11s %p\0'   #print size and filename
      fi
    fi
  done
}

if [[ $# < 2 ]]
then
  ROOTDIR=$( rp "${1:-.}" )
else
  ROOTDIR=""
fi

find_except_junk "${@:-.}" |
tee "$fifo" |                         #fifo for dialog progressbox
grep -vzZ '^          0 ' |           #ignore empty files
LC_ALL=C sort -z |                    #sort by size
uniq -Dzw11 |                         #keep files having same size
while IFS= read -r -d '' line
do                                    #for each file compute md5sum
  set -e                              #exit as soon an error occurs
  FIRSTLOOP=1
  size=${line:0:11}                   #extract size
  file=$( rp "${line:12}" )           #extract path and filename
  if [[ -n $ROOTDIR ]]
  then
    file=${file#$ROOTDIR/}            #shorter path if subdir of ROOTDIR
    if (( $FIRSTLOOP ))
    then
      FIRSTLOOP=0
      cd "$ROOTDIR"
    fi
  fi
  out=$size'\t'$(md5sum "$file")      #out = size, MD5-sum and filename
  [[ $file != */* ]] &&               #if missing directory
    out=${out:0:47}'./'${out:47}      #             => add 'current dir'
  echo -ne "$out\0"                   #null terminated instead of '\n'
done |
tee "$fif2" |                         #fifo for dialog progressbox
LC_ALL=C sort -z | uniq -z |          #remove symbolic links (same name)
uniq -zw46 --all-repeated=separate |  #keep the duplicates (same md5sum)
awk '{ print substr($0,0,12) substr($0,47) }' RS='\0' ORS='\0' >| "$dups" &  #remove MD5 sum
# run processing in background
#TODO: really check if file content are same (ex: using command cmp)

pid=$!                                #keep track of pid to wait for it

tr '\0' '\n' <"$fifo" |
dialog --title "Collecting files having same size..."  --no-shadow --no-lines --progressbox 999 999

tr '\0' '\n' <"$fif2" |
dialog --title "Computing MD5 sum for files having same size..." --no-shadow --no-lines --progressbox 999 999

wait $pid
#TODO check disk full




#TODO: Propose 'hard link' instead of 'remove'

choosedir()
{
  gawk '
  function four(s) {
    if(s<  10) return "   " int(s)
    if(s< 100) return "  "  int(s)
    if(s<1000) return " "   int(s)
               return       int(s)  }
  function f(n) {
    if(n==1)   return     "   1 file     "
    else       return four(n) " files    " }
  function tgmkb4 (s) {
    if(s<10000) return four(s) " "; s/=1024
    if(s<10000) return four(s) "K"; s/=1024
    if(s<10000) return four(s) "M"; s/=1024
    if(s<10000) return four(s) "G"; s/=1024
    if(s<10000) return four(s) "T"; s/=1024
    if(s<10000) return four(s) "P"; s/=1024
    if(s<10000) return four(s) "E"; s/=1024
    if(s<10000) return four(s) "Z"; s/=1024
                return four(s) "Y";  }
  function tgmkb (s) {
    if(s<10000) return s " bytes";   s/=1024
    if(s<10000) return int(s) " KB"; s/=1024
    if(s<10000) return int(s) " MB"; s/=1024
    if(s<10000) return int(s) " GB"; s/=1024
    if(s<10000) return int(s) " TB"; s/=1024
    if(s<10000) return int(s) " PB"; s/=1024
    if(s<10000) return int(s) " EB"; s/=1024
    if(s<10000) return int(s) " ZB"; s/=1024
                return int(s) " YB";  }
  function dirname (path)
        { if(sub(/\/[^\/]*$/, "", path)) return path; else return "."; }
  BEGIN { RS="\0" }
   /^$/ { uniques++ }
  !/^$/ { sz=substr($0,0,11); name=substr($0,13); dir=dirname(name);
          sizes[dir]+=sz; totsizes+=sz; files[dir]++; totfiles++;
          if (u!=uniques) { u=uniques; totuniq+=sz } }
  END   { print "--no-shadow --no-lines" > "'"$menu"'"
          print "--hline \"After selection of the directory, you will choose the redundant files you want to remove\"" >> "'"$menu"'"
          print "--menu \"There are " totfiles " duplicated files (" tgmkb(totsizes) ") within " length(sizes) " directories." >> "'"$menu"'"
          print "These duplicated files represent " uniques " unique files (" tgmkb(totuniq) ")." >> "'"$menu"'"
          print "This tool can remove the " totfiles - uniques " redundant files representing " tgmkb(totsizes - totuniq) "." >> "'"$menu"'"
          print "Choose directory to proceed redundant file removal:\" 999 999 999" >> "'"$menu"'"
          ORS="\0"
          for(dir in sizes) print tgmkb4(sizes[dir]) "  " f(files[dir]) dir }' "$dups" |
  LC_ALL=C sort -zrshk1 |
  tee "$dirs" |
  tr '\n"' "_'" |
  gawk 'BEGIN { RS="\0"; }  { print FNR " \"" $0 "\" " }' >> "$menu"

  dialog --file $menu 2> "$numb"

  return $?
}



selectfiles()
{
  sel=$( awk -v RS='\0' "NR == $(<$numb)" "$dirs" )
  dir="${sel:21}"

  cat >"$list" <<EOF
--no-shadow
--no-lines
--separate-output

--checklist "Selected duplicated files from directory $dir
Selection can be changed:"

999
999
999

EOF

  awk -F '\0' -v RS='\0\0' -v dir="$dir/" '
    $0 ~ dir {
      txt = file = ""
      for (i=1; i<=NF; i++)
      {
        if ($i == "")           #this can occur sometimes at EOF
        {
          if (file) print txt
          exit
        }
        path = substr ($i, 13)
        if (file == "")         #if file not yet set
        {
          p = index (path, dir)
          if (p == 1)
          {
            file = substr ($i, 13 + length(dir))
            if (file !~ "/")    #if file located in dir
            {
              print NR "." i "\t" "\"" file " duplicates:" "\"" "\t" "ON"
              continue
            }
            file = ""
          }
        }
        dupf = path
        sub(/.*\//, "", dupf)                       #basename
        if(! sub(/\/[^\/]*$/, "", path)) path="."   # dirname
        txt = txt "\n" NR "." i  "\t" "\"" dupf " in " path "\"" "\t" "0"
      }
      if (file)
        print txt "\n" "\" \""  "\t" "---" "\t\t\t" "0" "\n"
    }' "$dups" >>"$list"
  #TODO | tr '"' "'"

  dialog --file "$list" 2> "$numb"
  return $?
}


removefiles()
{
  dialog --infobox "Moving selected files to directory $junk ..." 3 100 #7 45
  while read line
  do
    nr=${line%%.*}
    nf=${line##*.}

    echo >&2 -ne "$nr.$nf\t"

    if [[ $nr != [0-9]* || $nf != [0-9]* ]]
    then
      echo >&2 "Not numbers => continue"
      continue
    fi

    # Security checks

    file=$(  awk -F '\0' -v RS='\0\0' 'NR == '"$nr"' { print substr($'"$nf"',13) }' $dups)
    echo >&2 -n "$file"

    if [[ ! -f "$file" ]]
    then
      echo >&2 " does not exist => next file"
      dialog --pause "Cannot find file '$file' => Cannot remove it
(the removal processing will automatically continue
after countdown or press OK to continue now)" 15 40 10
      continue
    fi

    filerp=$( rp "$file" )
    echo >&2 " ($filerp)"

    count=0
    while read f
    do
      #echo >&2 -ne "#$count\treading file '$f'\t"
      if [[ -f $f && ! -L $f ]]
      then
        frp=$( rp "$f" )
        [[ "$filerp" != "$frp" ]] && cmp -s "$filerp" "$frp" && let count++
      fi
    done < <(awk -F '\0' -v RS='\0\0' 'NR == '"$nr"' { for(i=1;i<=NF;i++) if($i) print substr ($i, 13) }'     $dups)

    if (( ! $count ))
    then
      echo >&2 "Unique file (no other duplicates) => ask confirmation"
      dialog --yesno "Removed all duplicates of '$file'.\nThis last file is unique.\nDo you want to keep this file?" 15 40
      case $? in
        1)         ;; #No or Cancel button pressed  (DIALOG_CANCEL)
        *) continue;;
      esac
    fi

    srce="${file%/*}"
    dest=$junk/"$srce"
    mkdir >&2 -vp        "$dest"
    mv    >&2 -v "$file" "$dest"

    # Remove empty directory
    rmdir >&2 -vp --ignore-fail-on-non-empty "$srce"

  done < "$numb"


  # take these removed files off the list '$dups'
  while IFS= read -r -d '' line
  do
    #echo >&2 -n "Processing '$line' "
    if [[ -z $line ]]
    then
       echo -en '\0'
    else
      file=${line:12}
      if [[ -e $file ]]
      then
        #echo >&2 "file '$file' exists => print line"
        echo -en "$line\0"
      #else
      #  echo >&2 "file '$file' does not exist => do not print line"
      fi
    fi
  done < "$dups" |
  awk -F '\0' -v RS='\0\0' -v ORS='\0\0' 'NF > 1' > "$numb"
  mv "$numb" "$dups"

}




if [[ ! -s "$dups" ]]
then
  cat <<EOF >"$menu"
  --infobox
  "No duplicated file found in $( (( $# > 1 )) && echo directories: || echo directory: )
EOF
  for dir in "${@:-.}"
  do
    echo -ne ' \t'
    if [[ -e $dir ]]
    then
      d=$( rp "$dir" )
      ls -ldgG "$dir" |
      if [[ "$d" != "$dir" ]]
      then
        sed 's|$|\t'"($d)|"
      fi
    else
      echo "$dir (does not exist)"
    fi
  done >>"$menu"
  echo '"'  $(($#+5))  100 >>"$menu"
  dialog --file "$menu"
else

  while [[ -s "$dups" ]]
  do
    choosedir
    case $? in
     -1) break;; #       ESC   key    pressed  (DIALOG_ESC) or error occured inside dialog (DIALOG_ERROR)
      1) break;; #No or Cancel button pressed  (DIALOG_CANCEL)
    esac

    selectfiles
    case $? in
     -1) continue;; #       ESC   key    pressed  (DIALOG_ESC) or error occured inside dialog (DIALOG_ERROR)
      1) continue;; #No or Cancel button pressed  (DIALOG_CANCEL)
    esac

    removefiles
  done

  [[ -d $junk ]] && dialog --no-shadow --no-lines --programbox "Moved below files to directory $junk
To remove them definityvely use command 'rm -r $junk'
" 999 999 < <( cd $junk; du -cha; echo "

Moved above files to directory $junk
To remove them definityvely use this command:

    rm -r $junk" )

fi

# try to remove temporary working directory
rmdir --ignore-fail-on-non-empty "$base"
