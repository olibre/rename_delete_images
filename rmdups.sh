#!/bin/bash

#Copyleft 2013 oLibre@Lmap.org 
#Double licence:  Fair licence + CC-SA http://creativecommons.org/licenses/sa/1.0/
#   Usage of the works is permitted provided that 
#   this instrument is retained with the works, 
#   so that any entity that uses the works 
#   is notified of this instrument.
#   DISCLAIMER: THE WORKS ARE WITHOUT WARRANTY.

 

{ type whiptail &>/dev/null && DIALOG=whiptail ||
{ type dialog   &>/dev/null && DIALOG=dialog   ||
{ type yad      &>/dev/null && DIALOG=yad      ||
{ type zenity   &>/dev/null && DIALOG=zenity   ||
{ type xdialog  &>/dev/null && DIALOG=xdialog  ||
{ type gdialog  &>/dev/null && DIALOG=gdialog  ||
{ type cdialog  &>/dev/null && DIALOG=cdialog  ||
{ echo >&2 "Please install 'yad' or 'zenity'" && exit 1 ; } } } } } } } }

fifo=$(mktemp -u) 
fif2=$(mktemp -u)
dups=$(mktemp -u)
dirs=$(mktemp -u)
menu=$(mktemp -u)
numb=$(mktemp -u)
list=$(mktemp -u)

mkfifo $fifo $fif2


# run processing in background
find . -type f -printf '%11s %P\0' |  #print size and filename
tee $fifo |                           #write in fifo for dialog progressbox
grep -vzZ '^          0 ' |           #ignore empty files
LC_ALL=C sort -z |                    #sort by size
uniq -Dzw11 |                         #keep files having same size
while IFS= read -r -d '' line
do                                    #for each file compute md5sum
  out=${line:0:11}'\t'$(md5sum "${line:12}")
  [[ ${line:12} != */* ]] && out=${out:0:47}'./'${out:48}
  echo -ne "$out\0"
                                      #file size + md5sim + file name + null terminated instead of '\n'
done |                                #keep the duplicates (same md5sum)
tee $fif2 |
uniq -zw46 --all-repeated=separate | 
awk -v RS='\0' -v ORS='\0' '{ print substr($0,0,12) substr($0,47) }' |         #remove MD5 sum
tee $dups  |
#xargs -d '\n' du -sb 2<&- |          #retrieve size of each file
gawk '
function four(s) {
  if(s<  10) return "   " int(s)
  if(s< 100) return "  "  int(s)
  if(s<1000) return " "   int(s)
             return       int(s)  }
function f(n) {
  if(n==1)   return     "   1 file     "
  else       return four(n) " files    " }
             
function tgmkb (s) { 
  if(s<10000) return four(s) " "; size/=1024 
  if(s<10000) return four(s) "K"; size/=1024
  if(s<10000) return four(s) "M"; size/=1024
  if(s<10000) return four(s) "G"; size/=1024
              return four(s) "T"; }
function dirname (path)
      { if(sub(/\/[^\/]*$/, "", path)) return path; else return "."; }
BEGIN { RS=ORS="\0" }
!/^$/ { sz=substr($0,0,11); name=substr($0,13); dir=dirname(name); sizes[dir]+=sz; files[dir]++ }
END   { for(dir in sizes) print tgmkb(sizes[dir]) "  " f(files[dir]) dir }' |
LC_ALL=C sort -zrshk1 > $dirs &
pid=$!


tr '\0' '\n' <$fifo |
dialog --title "Collecting files having same size..."    --no-shadow --no-lines --progressbox $(tput lines) $(tput cols)


tr '\0' '\n' <$fif2 |
dialog --title "Computing MD5 sum" --no-shadow --no-lines --progressbox $(tput lines) $(tput cols)


wait $pid
DUPLICATES=$( grep -zac -v '^$' $dups) #total number of files concerned
UNIQUES=$(    grep -zac    '^$' $dups) #number of files, if all redundant are removed
DIRECTORIES=$(grep -zac     .   $dirs) #number of directories concerned
cat > $menu <<EOF
--no-shadow 
--no-lines 
--hline "After selection of the directory, you will choose the redundant files you want to remove"

--menu  "There are $DUPLICATES duplicated files within $DIRECTORIES directories.\nThese duplicated files represent $UNIQUES unique files.\nChoose directory to proceed redundant file removal:"

999
999
$DIRECTORIES
EOF
tr '\n"' "_'" < $dirs |
gawk 'BEGIN { RS="\0" } { print FNR " \"" $0 "\" " }' >> $menu

dialog --file $menu 2> $numb
[[ $? -eq 1 ]] && exit




sel=$( awk -v RS='\0' "NR == $(<$numb)" $dirs )
dir="${sel:21}"



cat >"$list" <<EOF
--no-shadow
--no-lines
--separate-output

--checklist "Selected duplicated files from directory $dir\nSelection can be changed:"

999
999
999

EOF



echo -e "
fifo=$fifo;\t dups=$dups;\t menu=$menu; \t list=$list
fif2=$fif2;\t dirs=$dirs;\t numb=$numb; \t dir=$dir
"

awk -F '\0' -v RS='\0\0' -v dir="$dir/" '
  $0 ~ dir {
    txt = file = ""
    for (i=1; i<=NF; i++)
    {
      if ($i == "") 
      {
        if (file) print txt
        exit
      }
      path = substr ($i, 13)
      if (file == "")
      {
        p = index (path, dir)
        if (p == 1)
        {
          file = substr ($i, 13 + length(dir))
          if (file !~ "/")
          {
            print NR "." i "\t" "\"" file " duplicates:" "\"" "\t" "ON"
            continue
          }
          file = ""
        }
      }
      txt = txt "\n" NR "." i  "\t" "\"" path "\"" "\t" 0
    }
    if (file)
      print txt "\n" "\" \""  "\t" "---" "\t\t\t" "0" "\n"
  }' $dups >>"$list"
#TODO | tr '"' "'" 

dialog --file $list 2> $numb
[[ $? -eq 1 ]] && exit




trash=$(mktemp -d)
echo "Moving selected duplicated files to directory: $trash"
while read line
do
  nr=${line%%.*}
  nf=${line##*.}
  if [[ $nr = [0-9]* && $nf = [0-9]* ]]
  then
    count=0
    while read file
    do
      [[ -f $file && ! -L $file ]] && let count++
    done < <(awk -F '\0' -v RS='\0\0' 'NR == '"$nr"' { for(i=1;i<=NF;i++) if($i) print substr ($i, 13) }' $dups)
    
    if [[ $count < 2 ]]
    then
      echo "Are you sure? (TODO)"
    else
      file=$(awk -F '\0' -v RS='\0\0' 'NR == '"$nr"' { print substr($'"$nf"',13) }' $dups)
      srce="${file%/*}"
      dest=$trash/"$srce"
      mkdir -p "$dest"
      mv -v "$file" "$dest"
    fi
  fi
done < $numb

#rm -f $fifo $fif2 $dups $dirs $menu $numb
