_bujo() { 
  bujo_root="${BUJO_ROOT:=$HOME/.bujo}"
  bujo_root="${bujo_root/"~"/$HOME}"
  file_ext="${BUJO_FILE_EXT:=.md}"
  local cur=${COMP_WORDS[COMP_CWORD]}
  if [[ $COMP_CWORD -ge 2 && ${COMP_WORDS[$(expr $COMP_CWORD - 1)]} == "-c" || ${COMP_WORDS[$(expr $COMP_CWORD - 1)]} == "--collection" ]]; then
      COMPREPLY=( $(compgen -W "$(find $bujo_root -type f | sed -E "s~${bujo_root}\/(.*)${file_ext}~\1~")")) 
      return 
    # List collections
    #
    #
    #
  else
    COMPREPLY=( $(compgen -W "-l --list -g --grep -t --task --todo -c --collection -o --open -T -T0 -h --help -H --heading") )
    return
  fi
    #local prev=${COMP_WORDS[$(expr $COMP_CWORD -1)]}
  # if [ $COMP_CWORD -gt 0 ]; then
  #   if [ $prev -eq "-c" || $prev -eq "--collection" ]; then
  #     # List colletions
  #   fi
  # fi
} && complete -o nospace -F _bujo bujo
