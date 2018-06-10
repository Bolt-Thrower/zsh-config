# Promt ########################################################################

# http://www.utf8icons.com/
# http://apps.timwhitlock.info/emoji/tables/unicode

autoload +X -U colors && colors

################
### PROMPT SETUP
################

setopt NOTIFY # Report the status of background jobs immediately, rather than waiting until just before printing a prompt.
setopt INTERACTIVE_COMMENTS # Allowes to use #-sign as comment within commandline
setopt PROMPT_SUBST # substitude variables within prompt string
# setopt SINGLE_LINE_ZLE # single line command history

_prompt_cmd_id=0
function _prompt_cmd_id_increment { ((_prompt_cmd_id++)) }
precmd_functions=(_prompt_cmd_id_increment $precmd_functions) # increment before prompt

_prompt_exec_id=0
function _prompt_exec_id_increment { ((_prompt_exec_id++)) }
preexec_functions=(_prompt_exec_id_increment $preexec_functions) # increment before execute command

###### Command Line ############################################################

function _prompt_info {

  # --- prompt indicator
  local prompt_info="${fg_bold[grey]}#${reset_color} "

  # --- username
  if [ $EUID = 0 ]; then # highlight root user
    prompt_info+="${fg_bold[red]}${USER}${reset_color}" 
  else
    prompt_info+="${fg[cyan]}${USER}${reset_color}"
  fi
  
  # --- hostname
  prompt_info+="${fg_bold[grey]}@${reset_color}${fg[blue]}${HOST:-HOSTNAME}${reset_color}"

  # --- directory
  # shorten $PWD: replace $HOME wit '~' and parent folders with first character only
  local current_dir=${${PWD/#$HOME/'~'}//(#m)[^\/]##\//${MATCH[1]}/} 
  prompt_info+=" ${fg_bold[grey]}in${reset_color} ${fg[yellow]}$current_dir${reset_color}"

  # --- git branch
  local current_branch_status_line="$(git status --short --branch --porcelain 2>/dev/null | head -1)"
  if [ -n "$current_branch_status_line" ]; then
    if [[ "$current_branch_status_line" == *"(no branch)"* ]]; then
        prompt_info+=" ${fg_bold[grey]}at${reset_color} ${fg[green]}detached HEAD${reset_color}"
    else
        local branch_name="${${current_branch_status_line#*' '}%%'...'*}"
        prompt_info+=" ${fg_bold[grey]}on${reset_color} ${fg[green]}${branch_name}$current_branch${reset_color}"
    fi

    if [ -n "$(git status --short --porcelain 2>/dev/null)" ]; then
      prompt_info+="${fg_bold[magenta]}*${reset_color}"
    fi
    
    prompt_info+=' '
    if [[ "$current_branch_status_line" == *"ahead"* ]]; then
      prompt_info+="${fg_bold[magenta]}⇡${reset_color}"
    fi
    
    if [[ "$current_branch_status_line" == *"behind"* ]]; then
      prompt_info+="${fg_bold[magenta]}⇣${reset_color}"
    fi
  fi

  echo -e "$prompt_info"
}

### prompt
precmd_functions=($precmd_functions _prompt_info)
PS1='‣ '
PS2='• '

# right prompt
# RPROMPT='[%D{%H:%M:%S}]' # date

###### EXIT CODE ###############################################################
# print exit code on error
_prompt_exit_code_exec_id=0
function _prompt_exit_code {
  local exit_code=$status
  if [ $exit_code != 0 ] && [ $_prompt_exec_id != $_prompt_exit_code_exec_id ]; then
    echo "${fg_bold[red]}✖ ${exit_code}${reset_color}"
  fi
  _prompt_exit_code_exec_id=$_prompt_exec_id
}
# run before prompt
precmd_functions=(_prompt_exit_code $precmd_functions)


function _promp_int_trap {
  
  local FULLBUFFER="${PREBUFFER}${BUFFER}"
  if [ -n "$FULLBUFFER" ]; then
    echo -n "\n${fg_bold[yellow]}•${reset_color}"
    # •
  
    # TODO 
    
    # tput cuu 1
    # print -z - "$FULLBUFFER"
    # zle reset-prompt
    # zle -R
    
    # echo -en "${fg_bold[grey]}"
    # print -rn - ${FULLBUFFER}
    # echo -en "${reset_color}"
    
    
    # tput cuu 1
    # print -z - "$FULLBUFFER"
    # zle reset-prompt
    # zle -R

  fi
  
  
}
trap '_promp_int_trap; return 130' INT


###### REZIZE TERMINAL WINDOW ##################################################
# Ensure that the prompt is redrawn when the terminal size changes.
function TRAPWINCH {
  zle && { zle reset-prompt; zle -R }
}


# clear screen for mutiline prompt
function _clear_screen_widget { 
  tput clear
  local precmd
  for precmd in $precmd_functions; do
      $precmd
  done
  zle reset-prompt
}
zle -N _clear_screen_widget
bindkey "^L" _clear_screen_widget

################
### PROMPT UTILS
################

# Edit the current command line in $EDITOR
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey "^X^E" edit-command-line

# print one line annotation with comment 
function annotation {
  local comment=$1
  echo
  echo "${bg[grey]}${fg_bold[default]}\e[2K  ⇛ ${comment}${reset_color}"
  echo
}

 # make it possible to undo abort cmd line
function zle-line-init {
  if [[ -n $ZLE_LINE_ABORTED ]]; then
    local buffer_save="$BUFFER"
    local cursor_save="$CURSOR"
    BUFFER="$ZLE_LINE_ABORTED" 
    CURSOR="${#BUFFER}" 
    zle split-undo
    BUFFER="$buffer_save" CURSOR="$cursor_save" 
  fi
}
zle -N zle-line-init
