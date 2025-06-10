#!/bin/bash
function help (){
echo 'hex written by Tagd 2025
https://github.com/tagd-tagd/hex_game
variant of 2048 game by Gabriele Cirulli
./hex.sh [huc]
-h help
-u disable undo (minimize write to disk)
-c disable colors

KEYS
arrow keys
r - redraw screen
u - undo
s - save game
l - load saved game
q - quit (for restore game press 'u' after start)'
exit
}

trap 'exit' INT HUP TERM
trap 'stty echo;tput cnorm' EXIT
# stop terminal echo
stty -echo
#hide cursor
tput civis

declare -ia T R180 R270 R90=(12 8 4 0 13 9 5 1 14 10 6 2 15 11 7 3)
declare -ia M
declare -r FILENAME=$(readlink -e $0)
declare KEYCODE
declare -i PRM_UNDO=1 PRM_COLOR=1

#Color  Foreground  Background
declare fgBLK='\033[30m' bgBLK='\033[40m'
declare fgRED='\033[31m' bgRED='\033[41m'
declare fgGRN='\033[32m' bgGRN='\033[42m'
declare fgORA='\033[33m' bgORA='\033[43m'
declare fgBLU='\033[34m' bgBLU='\033[44m'
declare fgMGN='\033[35m' bgMGN='\033[45m'
declare fgCYN='\033[36m' bgCYN='\033[46m'
declare fgGRA='\033[37m' bgGRA='\033[47m'
declare fgWHA='\033[37m' bgWHA='\033[47m'
declare fgDEF='\033[39m' bgDEF='\033[49m'
declare clRST='\e[0m'
#value colors
declare -a COLOR=("$fgDEF$bgDEF" "$fgWHA$bgRED" "$fgWHA$bgGRN" "$fgWHA$bgORA") 
          COLOR+=("$fgWHA$bgBLU" "$fgWHA$bgMGN" "$fgWHA$bgCYN" "$fgBLK$bgRED")
          COLOR+=("$fgBLK$bgGRN" "$fgBLK$bgORA" "$fgBLK$bgBLU" "$fgBLK$bgMGN") 
          COLOR+=("$fgBLK$bgCYN" "$fgRED$bgBLU" "$fgRED$bgGRN" "$fgRED$bgORA") 

#                     |       |       |
declare -i i j k l m n n0 n1

function get_param (){
  (($#)) || return
  [[ "$@" =~ [h] ]] && help
  [[ "$@" =~ [u] ]] && PRM_UNDO=0 
  [[ "$@" =~ [c] ]] && PRM_COLOR=0 
}

function get_keycode(){
  local -i i
  local -x IFS=''
  local  K1 K2 K=''
  read -rsn1 -d $'\0' K1;read -d $'\0' -rsn7 -t 0.001 K2
  [[ "$K1" != $'\x1b' ]] && K2=''
  K1+="${K2}"
  i=${#K1}
  while ((i--));do
    printf -v K2 "%02X" \"${K1:$i:1}\"
    K="${K2}${K}"
  done
  printf -v KEYCODE "%s" "$K"
}

function save {
  local -i i
  local -l y=y
  local FNAME

  if [[ -z "$1" ]];then
   clear
   ls -1 "${FILENAME}.sav"[0-9] 2>/dev/null
   echo
    read -e -n1 -p "Input fileNUM [0]-9 for SAVE):" i
    ((i<0)) && i=0
    ((i>9)) && i=9
    FNAME="${FILENAME}.sav$i"
    if [[ -f "$FNAME" ]];then
      read -e  -n1 -p "OVERWRITE $FNAME ? [Y]n" y
      if [[ "$y" =~ [nNтТ] ]];then
        echo -e "\n\nSave canceled"
        sleep 3
        return
      fi
    fi

  else #autosave
    ((PRM_UNDO)) || return
    FNAME="$FILENAME.sav$1"
  fi
  echo "${M[@]}" >"$FNAME"
}

function load {
  local -i i
  local -l y=y
  local FNAME
  clear
  if [[ -n "$1" ]];then
    FNAME="$FILENAME.sav$1"
  else
    ls -1 "$FILENAME.sav"[0-9] 2>/dev/null
    if (($?));then
      echo "No saved games"
      sleep 3
      return
    fi
    read -e -n1 -p "INPUT fileNUM [0]-9 for load):"
    i=$REPLY
    FNAME="$FILENAME.sav$i"
  fi
  if [[ -f "$FNAME" ]];then
    read -a M <"$FNAME"
  else 
    echo "File $FNAME not found."
    sleep 3
    return
  fi
}

function initm {
  local -i i 
  clear
  i=16
  while ((i--));do
    R180[$i]=15-$i
    R270[$i]=15-${R90[$i]}
    M[$i]=0
  done
  M[16]=0 # score
  add
  add
  show
}

function check_empty_cells {
  local -i i=16 l=16
  while ((i--));do
    ((${M[i]} && l--))
  done 
  echo $l
}

function add {
  local -i n e r=1
  e=$(check_empty_cells)
  if [[ $e -eq 0 ]];then
    echo -e '\nGame over'
    exit
  fi
#default new value=1, but
  (($SRANDOM % 16)) || r=2
  ((M[16]++)) #score +1
# random cell
  ((e=SRANDOM % e))
  for ((n=0;n<16;n++));do
    if [[ ${M[$n]} -eq 0 ]];then
      if [[ $e -eq 0 ]];then
        M[$n]=r
        return
      fi
      (( e-=1 ))
    fi
  done #n
}
function show(){
  local S=''
  local D
  local -i i j

  tput cup 0 0
  for i in {0..15};do
    printf -v D "%2X" ${M[$i]}
    [[ "$D" == " 0" ]] && D=" ."
    if ((PRM_COLOR));then
      S+="${COLOR[${M[$i]}]}${D}${clRST}"
    else
      S+="$D"
    fi
    (((i%4)==3)) && S+="\n"
  done
  printf "$S"
  printf "\nHex:%04X" ${M[16]}
}


function sumrot {
  save u
  #sum
  case $1 in
    l)T=(${R90[@]});;
    r)T=(${R270[@]});;
    d)T=(${R180[@]});;
    u)T=(${!R90[@]});;
    *)return
  esac
  for ((n=0;n<12;n++));do
    if ((n0=T[n],n1=T[n+4],M[n0]>0));then 
      ((M[n0]==M[n1])) && ((M[n0]++,M[n1]=0))
    fi
  done

  #slide
  for ((n=0;n<12;n++));do
    n0=${T[$n]}
    if [[ ${M[$n0]} -eq 0 ]];then
      for ((m=n+4;m<16;m+=4));do
        n1=${T[$m]}
        if [[ ${M[$n1]} -ne 0 ]];then
          M[$n0]=${M[$n1]}
          M[$n1]=0
          break
        fi
      done #m
    fi
  done #n
}

function next {
  show
  add
  sleep .3
  show
}
function quit(){
  clear
  save u
  exit
}

get_param "$@"
initm
#show

escape_char=$(printf "\u1b")
while : ;do
  get_keycode
  case "$KEYCODE" in
    '1B5B41') sumrot u;next ;;    # UP
    '1B5B44') sumrot l;next ;;    # LEFT
    '1B5B42') sumrot d;next ;;    # DOWN 
    '1B5B43') sumrot r;next ;;    # RIGHT
    '72'|'52'|'41A'|'43A')        clear;show;; # rR Кк restore screen
    '75'|'55'|'413'|'433') load u;clear;show;; # uU Гг undo
    '73'|'53'|'42B'|'44B') save;  clear;show;; # sS Ыы save
    '6C'|'4C'|'414'|'434') load;  clear;show;; # lL Дд load
    '71'|'51'|'419'|'439') quit;;              # qQ Йй quit
    *) continue ;;
  esac
done
