#!/bin/bash

set -e

readonly BUJO_WEEK_START="${BUJO_WEEK_START:=1}"
readonly BUJO_ROOT="${BUJO_ROOT:=$HOME/.bujo}"
readonly BUJO_EDITOR="${BUJO_EDITOR:=$EDITOR}"
readonly BUJO_FILENAME="${BUJO_FILENAME:=%y%m%w}"
readonly BUJO_TIMESTAMP_FORMAT="${BUJO_TIMESTAMP_FORMAT:=%y-%m-%d@%H:%M}"
readonly BUJO_FILE_EXT="${BUJO_FILE_EXT:=.md}"
BUJO_INCLUDE_TIMESTAMP="${BUJO_INCLUDE_TIMESTAMP:=false}"
OPEN_EDITOR=false
declare -A centuryCodes=( [17]=4 [18]=2 [19]=0 [20]=6 [21]=4 [22]=2 [23]=0 )
declare -A monthCodes=( [1]=0 [2]=3 [3]=3 [4]=6 [5]=1 [6]=4 [7]=6 [8]=2 [9]=5 [10]=0 [11]=3 [12]=5 )
declare -A monthDays=( [1]=31 [2]=28 [3]=31 [4]=30 [5]=31 [6]=30 [7]=31 [8]=31 [9]=30 [10]=31 [11]=30 [12]=31 )
declare -A weekdays=( [0]="Sunday" [1]="Monday" [2]="Tuesday" [3]="Wednesday" [4]="Thursday" [5]="Friday" [6]="Saturday" )

quickhelp() { 
  echo "bujo [opts] [note input can have spaces without quotes]"
  echo ""
  echo "A command line utility for rappid note logging"
  echo ""
  echo "Parameters:"
  echo "  -l|--list               List (tree) entries and exit"
  echo "  -g|--grep [args]        Run \`grep\` against \$BUJO_ROOT"
  echo "  -t|--task|--todo        Mark entry as a todo"
  echo "  -c|--collection <name>  Specify collection (filename). Accepts subpaths, i.e. docs/collections"
  echo "                          Append trailing slash to denote directory."
  echo "  -o|--open               Open editor instead of exiting"
  echo "  -T                      Include timestamp"
  echo "  -T0                     Do not include timestamp (default unless configured)"
  echo "  -h|                     Print short help."
  echo "  --help                  Print full help."
  echo "  -H|--heading <title>    Specify custom title (collection name if ommitted)" 
  #echo "  -d|--debug              Print debug messages"
}

fullhelp() { 
  quickhelp
  echo ""
  echo "Configuration:"
  echo "  \$BUJO_ROOT                   Base path to use, defaults to ~/.bujo"
  echo "  \$BUJO_WEEK_START             Day to use as first day of week (from 0 to 6, 0 being Sunday, 6 being Saturday). Defaults to 1 (Monday)"
  echo "  \$BUJO_EDITOR                 Editor to use, defaults to \$EDITOR"
  echo "  \$BUJO_FILENAME               Filename format to use when not specifying collection"
  echo "  \$BUJO_FILE_EXT               File extension to use for notes. Default is .md"
  echo "  \$BUJO_INCLUDE_TIMESTAMP      Whether to log a timestamp before each action. Is overwritten by parameters"
  echo ""
  echo "Pattern Substitutions:"
  echo "  %y - Year"
  echo "  %m - Month"
  echo "  %d - Day"
  echo "  %w - Week of month (based off \$BUJO_WEEK_START)"
  echo "  %H - Hour"
  echo "  %M - Minute"
  echo ""
  echo "Entries can be written naturally with no need for quoting, i.e."
  echo "  bujo Today I tried bujo cli"
  echo "Creates the entry \`Today I tried bujo cli\` in the default file "
  echo ""
  echo "Because of this, you need to quote any positional argument containing spaces, i.e."
  echo "  bujo -c "examples/spaces in args" -H \"Your custom header\" With a note entry"
  echo "Creates a file under the \`examples\` folder in \$BUJO_ROOT named \`spaces in args\` with the title set"
  echo "to \`Your custom header\` and the entry \`With a note entry\`"
  echo ""
  echo "Source code available on github - https://github.com/b0dee/bujo"
  exit 0
}
# Exits program after printing message
fatal() {
  if [[ -z $1 ]]; then message="fatal() expects a message to print"; else message=$1; fi
  debug "fatal() ------"
  echo "$message"
  exit 1
}

# Args: message
debug() { 
  if [[ -z $1 ]]; then fatal "debug() expects a message to print"; fi
  if [[ -z ${DEBUG} ]]; then return; fi
  echo "[DEBUG] $1"

}


# Args: year
isLeap() { 
  if [[ -z $1 ]]; then fatal "isleap() expects integer year as a parameter"; fi

  if [[ $(expr $1 % 400) -eq 0 || $(expr $1 % 100) -eq 0 && $(expr $1 % 4) -eq 0 ]]; then echo 1;
  else echo 0; fi
}

# Args: year, month, day
# 0 = Sunday to 6 = Saturday
getWeekDay() {
  if [[ -z $1 || -z $2 || -z $3 ]]; then fatal "getWeekDay expects year,month,day arguments to be provided"; fi
  local year=$1
  local month=$2
  local day=$3
  local year_c=$(expr $year / 100)
  local year_s=$(expr $year % 100)
  local leap=$(isLeap $year)
  yearCode=$(expr $(expr $year_s + $(expr $year_s / 4)) % 7)
  monthCode=${monthCodes[$month]}
  echo $(expr $(expr $yearCode + $monthCode + ${centuryCodes[${year_c}]} + $day - $leap) % 7)
}

# Args: year,month,day
getWeekOfMonth() { 
  if [[ -z $1 || -z $2 || -z $3 ]]; then fatal "getWeekOfMonth expects year,month,day arguments to be provided"; fi
  local year=$1
  local month=$2
  local day=$3
  firstDayOfMonth=$(getWeekDay $year $month 1)

  if [[ $BUJO_WEEK_START -gt $firstDayOfMonth ]]; then
    firstWeekStartOfMonth=$(expr $BUJO_WEEK_START - $firstDayOfMonth)
  else
    firstWeekStartOfMonth=$(expr $(expr 7 % $firstDayOfMonth) + $BUJO_WEEK_START)
  fi

  if [[ $firstWeekStartOfMonth -lt $day ]]; then
    echo $(expr $(expr $(expr $day - $firstWeekStartOfMonth) / 7) + 1)
  else
    if [[ $month -eq 1 ]]; then
      year=$(expr $year - 1)
      month=12
    fi

    local leap=$(isLeap $year)

    if [[ $leap -eq 1 && $month -eq 2 ]]; then
      local daysInMonth=29
    else
      local daysInMonth=${monthDays[$(expr $month - 1)]}
      echo $(getWeekOfMonth $year $(expr $month - 1) $(expr $day + $daysInMonth))
    fi
  fi
  
}

INPUT_STRING=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -l|--list)
      tree "${BUJO_ROOT}/$2"
      exit 0
      ;;
    -t|--task|--todo)
      readonly TASK=true
      shift # past argument
      ;;
    -c|--collection)
      if [[ -z ${2} ]]; then fatal "Error: collection parameter requires argument"; fi
      readonly COLLECTION="$2"
      shift # past argument
      shift # past value
      ;;
    -H|--header|--heading)
      if [[ -z $2 ]]; then fatal "Error: header parameter requires argument"; fi
      readonly HEADING="$2"
      shift # past argument
      shift # past value
      ;;
    -o|--open)
      OPEN_EDITOR=true
      shift # past argument
      ;;
    -T0)
      BUJO_INCLUDE_TIMESTAMP=false
      shift # past argument
      ;;
    -T)
      BUJO_INCLUDE_TIMESTAMP=true
      shift # past argument
      ;;
    -h)
      quickhelp
      exit 0
      ;;
    --help)
      fullhelp
      ;;
    -d|--debug)
      DEBUG=true
      shift # past argument
      ;;
    *)
      INPUT_STRING+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

if ! [[ -z ${COLLECTION} ]];      then debug "Collection  : ${COLLECTION}"; fi
if ! [[ -z ${HEADING} ]];         then debug "Heading     : ${HEADING}"; fi
if ! [[ -z ${TASK} ]];            then debug "Task        : ${TASK}"; fi
if ! [[ -z ${INPUT_STRING[@]} ]]; then debug "Input String: ${INPUT_STRING[@]}"; fi
if ! [[ -z ${LIST} ]];            then debug "List        : ${LIST}"; fi
if ! [[ -z ${BUJO_INCLUDE_TIMESTAMP} ]];            then debug "BujoIncludeTimestamp        : ${BUJO_INCLUDE_TIMESTAMP}"; fi
if ! [[ -z ${OPEN_EDITOR} ]];            then debug "OpenEditor        : ${OPEN_EDITOR}"; fi
if ! [[ -z ${HELP} ]];            then debug "Help        : ${HELP}"; fi

stringfmt() {
  if [[ -z $1 ]]; then fatal "stringfmt() expects input string to format"; fi
  local year=$(date +%Y)
  local month=$(date +%m)
  local day=$(date +%d)
  local week=$(getWeekOfMonth $year $month $day)
  if [[ $week -gt 4 ]]; then month=$(expr ${month} - 1); fi
  local hr=$(date +%H)
  local min=$(date +%M)
  out=${1/"%y"/$year}
  out=${out/"%m"/$month}
  out=${out/"%d"/$day}
  out=${out/"%w"/$week}
  out=${out/"%H"/$hr}
  out=${out/"%M"/$min}
  echo $out
}

main() { 
  local content="${INPUT_STRING[@]}"
  local filepath="${BUJO_ROOT/"~"/"$HOME"}/"
  if ! [[ -z ${COLLECTION} ]]; then 
    local dirregex="/$"
    local collection=$COLLECTION
    if [[ ${COLLECTION} =~ $dirregex ]]; then
      collection="$COLLECTION/$BUJO_FILENAME"
    fi
    # TODO - If collection ends in '/' it should treat collection provided as a folder and append default filename 
    filepath+=$(stringfmt "${collection/$BUJO_FILE_EXT/""}${BUJO_FILE_EXT}";) 
  else
    filepath+=$(stringfmt "${BUJO_FILENAME}${BUJO_FILE_EXT}")
  fi
  mkdir -p $(dirname "$filepath")

  if ! [[ -f "${filepath}" ]]; then
    if ! [[ -z ${HEADING} ]]; then 
      printf "%s\n\n" "# $(stringfmt "${HEADING}" | sed -r "s/( *[a-z])([a-z]+)( |$)/\U\1\L\2\3/g")" >> "${filepath}"
    else
      printf "%s\n\n" "# $(basename -s ${BUJO_FILE_EXT} "${filepath}" | sed -r "s/( *[a-z])([a-z]+)( |$)/\U\1\L\2\3/g")" >> "${filepath}"
    fi
  fi

  if ! [[ -z ${TASK} ]]; then 
    if [[ -z ${content} ]]; then fatal "Cannot create task/todo without input string"; fi
    content="- [ ] ${content}"

  else
    local taskregex="^ *[-*+]"
    if [[ "$(tail -n 1 "${filepath}")" =~ $taskregex ]]; then
      content="\n${content}"
    fi
    content="${content}\n"
  fi

  if ${BUJO_INCLUDE_TIMESTAMP}; then
    content="$(stringfmt "${BUJO_TIMESTAMP_FORMAT}")\n${content}"
  fi

  if [[ -z ${INPUT_STRING} ]]; then
    if [ -p "/dev/stdin" ]; then
      printf "%b\n\`\`\`text\n" "${content}" >> "${filepath}"
      (cat; printf "\n") >> "${filepath}"
      printf "\`\`\`\n" >> "${filepath}"
    else
      eval "${BUJO_EDITOR}" "'${filepath}'"
      exit 0
    fi
  else
    printf "%b\n" "${content}" >> "${filepath}"
  fi

  if $OPEN_EDITOR; then
    eval "${BUJO_EDITOR}" "'${filepath}'"
  fi

}

main ${*}

# TODO: 


