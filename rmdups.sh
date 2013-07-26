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

fifo=$(mktemp -u)_fifo 
fif2=$(mktemp -u)_fif2
dups=$(mktemp -u)_dups
dirs=$(mktemp -u)_dirs
menu=$(mktemp -u)_menu
numb=$(mktemp -u)_numb
list=$(mktemp -u)_list
trash=$(mktemp -d)_trash

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
  if(s<10000) return four(s) " "; s/=1024 
  if(s<10000) return four(s) "K"; s/=1024
  if(s<10000) return four(s) "M"; s/=1024
  if(s<10000) return four(s) "G"; s/=1024
  if(s<10000) return four(s) "T"; s/=1024
  if(s<10000) return four(s) "P"; s/=1024
  if(s<10000) return four(s) "E"; s/=1024
  if(s<10000) return four(s) "Z"; s/=1024
              return four(s) "Y";  }
function dirname (path)
      { if(sub(/\/[^\/]*$/, "", path)) return path; else return "."; }
BEGIN { RS=ORS="\0" }
!/^$/ { sz=substr($0,0,11); name=substr($0,13); dir=dirname(name); sizes[dir]+=sz; files[dir]++ }
END   { for(dir in sizes) print tgmkb(sizes[dir]) "  " f(files[dir]) dir }' |
LC_ALL=C sort -zrshk1 > $dirs &
pid=$!


tr '\0' '\n' <$fifo |
dialog --title "Collecting files having same size"  --no-shadow --no-lines --progressbox 999 999


tr '\0' '\n' <$fif2 |
dialog --title "Computing MD5 sum"                  --no-shadow --no-lines --progressbox 999 999


wait $pid
echo -e "
fifo=$fifo;\t dups=$dups;\t menu=$menu; \t list=$list
fif2=$fif2;\t dirs=$dirs;\t numb=$numb; \t trash=$trash
"


choosedir()
{
  DUPLICATES=$( grep -zac -v '^$' $dups) #total number of files concerned
  UNIQUES=$(    grep -zac    '^$' $dups) #number of files, if all redundant are removed
  DIRECTORIES=$(grep -zac     .   $dirs) #number of directories concerned
  cat > $menu <<EOF
--no-shadow 
--no-lines 
--hline "After selection of the directory, you will choose the redundant files you want to remove"

--menu  "There are $DUPLICATES duplicated files within $DIRECTORIES directories.
These duplicated files represent $UNIQUES unique files.
Choose directory to proceed redundant file removal:"

999
999
$DIRECTORIES
EOF
  
  tr '\n"' "_'" < $dirs |
  gawk 'BEGIN { RS="\0" } { print FNR " \"" $0 "\" " }' >> $menu

  dialog --file $menu 2> $numb
  return $?
}



selectfiles()
{
  sel=$( awk -v RS='\0' "NR == $(<$numb)" $dirs )
  dir="${sel:21}"
  echo "dir='$dir'"

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
  return $?
}


removefiles()
{
  dialog --infobox "Moving selected files to directory $trash" 7 45
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
      
      file=$(awk -F '\0' -v RS='\0\0' 'NR == '"$nr"' { print substr($'"$nf"',13) }' $dups)

      if [[ $count < 2 ]]
      then
        dialog --pause "Cannot find file '$file' neither its duplicates!\n(the removal processing will automatically continue after countdown or press OK to continue now)" 15 40 10 
        continue
      fi
      
      if [[ $count < 2 ]]
      then
        dialog --yesno "Removed all duplicates of '$file'.\nThis last file is unique.\nDo you want to keep this file?" 15 40
        case $? in
          1)         ;; #No or Cancel button pressed  (DIALOG_CANCEL)
          *) continue;;
        esac
        # 0) continue;; #   Yes or OK button pressed  (DIALOG_OK)
        # 2) continue;; #        Help button pressed  (DIALOG_HELP)
        # 4) continue;; #        Help button pressed  (DIALOG_HELP), or the --item-help option is set when the Help button is pressed (DIALOG_ITEM_HELP)
        # 3) continue;; #       Extra button pressed  (DIALOG_EXTRA)
        #-1) continue;; #       ESC   key    pressed  (DIALOG_ESC) or error occured inside dialog (DIALOG_ERROR)
      fi
      
      srce="${file%/*}"
      dest=$trash/"$srce"
      mkdir -p "$dest"
      mv -v "$file" "$dest"
      
    fi
  done < $numb

  # take these removed files off the list '$dups'
  while IFS= read -r -d '' line
  do
    if [[ -z $line ]]
    then
       echo -en '\0'
    else
      file=${line:12}
      if [[ -e $file ]]
      then
        echo -en "$line\0"
      fi
    fi
  done <$dups |                                          
  awk -F '\0' -v RS='\0\0' -v ORS='\0\0' 'NF > 1' >$list
  mv $list $dups 
  
}


while [[ -s $dups ]]
do
  choosedir
  case $? in
   -1) exit;; #       ESC   key    pressed  (DIALOG_ESC) or error occured inside dialog (DIALOG_ERROR)
    1) exit;; #No or Cancel button pressed  (DIALOG_CANCEL)
  esac
   #0)     ;; #   Yes or OK button pressed  (DIALOG_OK)
   #2)     ;; #        Help button pressed  (DIALOG_HELP)
   #4)     ;; #        Help button pressed  (DIALOG_HELP), or the --item-help option is set when the Help button is pressed (DIALOG_ITEM_HELP)
   #3)     ;; #       Extra button pressed  (DIALOG_EXTRA)
  
  selectfiles
  case $? in
   -1) continue;; #       ESC   key    pressed  (DIALOG_ESC) or error occured inside dialog (DIALOG_ERROR)
    1) continue;; #No or Cancel button pressed  (DIALOG_CANCEL)
  esac
   #0)         ;; #   Yes or OK button pressed  (DIALOG_OK)
   #2)         ;; #        Help button pressed  (DIALOG_HELP)
   #4)         ;; #        Help button pressed  (DIALOG_HELP), or the --item-help option is set when the Help button is pressed (DIALOG_ITEM_HELP)
   #3)         ;; #       Extra button pressed  (DIALOG_EXTRA)

  removefiles
done


dialog --no-shadow --no-lines --programbox "Moved below files to directory $trash
To remove them definityvely use this command:

    rm -r $trash


" 999 999 < <( cd $trash; du -cha; echo "

Moved above files to directory $trash
To remove them definityvely use this command:

    rm -r $trash" )



rm -f $fifqo $fif2 $dups $dirs $menu $numb

#TODO: remove empty directories
