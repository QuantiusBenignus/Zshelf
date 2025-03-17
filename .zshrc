# ~/.zshrc
#My sample .zshrc optimized for speed (< 6.5 ms startup time and some unique functionality)
#Aside from the next line, settings related to Zshelf are all at the end of this file in case the rest of the .zshrc is of no interest.  
export ZDOTDIR="${ZDOTDIR:-$HOME}" #Needed for Zshelf setup.

timbit=$(date "+%s%4N")
#zmodload zsh/zprof

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e
bindkey ';5A' history-beginning-search-backward
bindkey ';5B' history-beginning-search-forward

setopt EXTENDED_HISTORY HISTIGNOREALLDUPS HISTIGNORESPACE SHARE_HISTORY HIST_VERIFY
#setopt TRANSIENT_RPROMPT

#See below for my compinit setup.
ZSH_DISABLE_COMPFIX=true

export HISTFILE="$ZDOTDIR/.zsh_history"
export HISTSIZE=10000
export SAVEHIST=10000

#The next is an aggressive reduction in the elements of fpath, where entries have been removed as not needed.
#Trim you fpath only if you are sure that you are not using functions from the directories removed from the fpath array.  
#fpath=(
#$ZDOTDIR/.zfunc /usr/share/zsh/vendor-completions
#/usr/share/zsh/functions/Chpwd 
#/usr/share/zsh/functions/Completion /usr/share/zsh/functions/Completion/Base 
#/usr/share/zsh/functions/Completion/Debian /usr/share/zsh/functions/Completion/Linux 
#/usr/share/zsh/functions/Completion/Unix /usr/share/zsh/functions/Completion/X 
#/usr/share/zsh/functions/Completion/Zsh /usr/share/zsh/functions/Exceptions 
#/usr/share/zsh/functions/MIME /usr/share/zsh/functions/Math /usr/share/zsh/functions/Misc 
#/usr/share/zsh/functions/TCP 
#/usr/share/zsh/functions/Zle)

autoload -Uz compinit 

#Zsh command line PROMPT and RPROMPT vars:
GITL=2
GSCHAR="📂" 
GITBRAN=""
HEXLINK=" "

function preexec() {
#time ref
  timbit=$(date +%s%4N)
}

#Check only on cd:🚧✅🛑
function chpwd() {
  git rev-parse --git-dir > /dev/null 2>&1
  if (( GITL=$? )); then
     GSCHAR="📂"; GITBRAN=""        
  else
     [[ $PWD == *.git* ]] && { GITL=1; GSCHAR="🩻"; } 
  fi
  print -Pn "\e]0;%n@%m: %~/${GSCHAR}\a"
}

function precmd() {
  if ! (( $GITL )); then
      local branch=$(git branch --show-current 2>/dev/null)
      # If no branch is found, a detached HEAD state    
      GITBRAN=${branch:="HEAD detached"} # at $(git rev-parse --short HEAD)"
      [[ -z $(git status --porcelain 2>/dev/null) ]] && GSCHAR="✅" || GSCHAR="🚧"
  fi
  local elapsed=$(($(date +%s%4N) - $timbit - 6.5 ))
  if (( elapsed >= 10000 )); then
      elapsed=$(printf "%.2fs\n" "$((elapsed / 10000.0))")
  else
      elapsed=${$(printf "%.1fms\n" "$((elapsed / 10.))")#-}
  fi
# Random RPROMPT link emoji to codepoint URL OR to the LLM prompt file $TPROMPTF if not empty (when flashing ).   
# You can CTRL-click on it to edit the LLM prompt (when flashing) 
  local hexcode=$(( $RANDOM %2 ? $((RANDOM % 1259 + 127744)) : $((RANDOM % 244 + 129291)) ))
  hexcode=$(printf %X "$hexcode")  
  local prchar='❯'  
  if [[ -s $TPROMPTF ]]; then 
      prchar='⏺'
      HEXLINK="$(printf "\e]8;;file:$TPROMPTF\e\\$(printf "\U$hexcode")\e]8;;\e\\")"
  else
      HEXLINK="$(printf "\e]8;;https://codepoints.net/U+$hexcode\e\\$(printf "\U$hexcode")\e]8;;\e\\")"
  fi    
#In the RPROMPT next, the random colors are chosen between 20 and 231 to cheaply avoid 0, 16..19 and 232..236, which merge with (my) background.
#Used: for i in {0..255}; do printf "\033[38;5;%dm$i " $i; done to see the low contrast colors.    
  local furi="$(printf "\e]8;;file:$PWD\e\\$GSCHAR\e]8;;\e\\")"
  export PROMPT="%B%1~%b%(?.%F{green}.%F{red}%?)❯%f%S${GITBRAN}%s❯" 
  export RPROMPT="%F{45}%-2~%(4~./…./)%{$furi%2G%} %(1j.⚙️ %j.) %F{$((RANDOM % 212 + 20))}%S$elapsed%s %{$HEXLINK%G%} %*%f"
}

## minimal completion-style
zstyle ':completion:*:approximate:*' max-errors 1 numeric
zstyle ':completion:*' menu select=none
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path $ZDOTDIR/.compcache
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-suffixes true
zstyle ':completion:*' completer _complete _files
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' max-errors 1
zstyle ':completion:*' verbose false
zstyle ':completion:*' expand true
zstyle ':completion:*' file-sort name
zstyle ':completion:*' directory-sort false
zstyle ':completion:*:*:*:*:*' verbose false

# Set personal aliases:
alias ls='ls --color=auto --hyperlink=auto'
alias la='ls -lahFtr --group-directories-first'
alias sorf="find . -type f -printf '%s %p\n'| sort -hr | head -30"
alias dud="du -d 1 -h --exclude={/proc,/sys,/dev,/run} | sort -h"
alias ipkgs='dpkg-query -W --showformat='${Installed-Size}\t${Package}\n' | sort -nr | less'
alias hrep='() { fc -Dlim "*$@*" 1 }'

#Extra aliases
alias elias='source $ZDOTDIR/.ezshalias'

if [[ $(date +%s) -gt (( $(stat -c %Y $ZDOTDIR/.zcompdump.zwc ) + 36000 )) ]]; then 
   print "Updating completions:\n"
   compinit
   zcompile $ZDOTDIR/.zcompdump
else
   compinit -C
fi

#This block is for the LLM functions:
fpath=($ZDOTDIR/.zfunc $fpath)
#Those are the LLM manipulation functions
autoload -Uz qlm _qlm reqlm promf
autoload -Uz gem gem2 qwen qwec mist deeq
#Register the LLM name completion (must be after compinit)
compdef _qlm qlm


#zprof
