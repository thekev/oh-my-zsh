# vim:ft=zsh ts=2 sw=2 sts=2
#
# agnoster's Theme - https://gist.github.com/3712874
# A Powerline-inspired theme for ZSH
#
# # README
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://gist.github.com/1595572).
#
# In addition, I recommend the
# [Solarized theme](https://github.com/altercation/solarized/) and, if you're
# using it on Mac OS X, [iTerm 2](http://www.iterm2.com/) over Terminal.app -
# it has significantly better color fidelity.
#
# # Goals
#
# The aim of this theme is to only show you *relevant* information. Like most
# prompts, it will only show git information when in a git working directory.
# However, it goes a step further: everything from the current user and
# hostname to whether the last call exited with an error to whether background
# jobs are running in this shell will all be displayed automatically when
# appropriate.

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'
SEGMENT_SEPARATOR='⮀'
RCURRENT_BG='NONE'
RSEGMENT_SEPARATOR='⮂'

# Begin a segment
# Takes four to five arguments: background and foreground for 16-color 
# term, followed by numeric 256-color term colors. Any can be omitted
# rendering default background/foreground.
# fifth option is a string to echo
prompt_segment() {
  local bg fg lbg lfg hbg hfg newbg
  [[ -n $1 ]] && lbg="%K{$1}" || lbg="%k"
  [[ -n $2 ]] && lfg="%F{$2}" || lfg="%f"
  [[ -n $3 ]] && hbg="%K{$3}" || hbg="%k"
  [[ -n $4 ]] && hfg="%F{$4}" || hfg="%f"
  if [[ "$TERM" == "xterm-256color" ]]; then
    bg=$hbg; fg=$hfg; newbg=$3
  else
    bg=$lbg; fg=$lfg; newbg=$1
  fi

  if [[ $CURRENT_BG != 'NONE' && $newbg != $CURRENT_BG ]]; then
    echo -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
  else
    echo -n "%{$bg%}%{$fg%} "
  fi
  CURRENT_BG=$newbg
  [[ -n $5 ]] && echo -n $5
}

#TODO make the above and this into one function, somehow... messy messy
#--the only diff is RCURRENT_BG and RSEGMENT_SEPARATOR
# Begin a right-segment
# Takes four to five arguments: background and foreground for 16-color 
# term, followed by numeric 256-color term colors. Any can be omitted
# rendering default background/foreground.
# fifth option is a string to echo
rprompt_segment() {
  local bg fg lbg lfg hbg hfg newbg
  [[ -n $1 ]] && lbg="%K{$1}" || lbg="%k"
  [[ -n $2 ]] && lfg="%F{$2}" || lfg="%f"
  [[ -n $3 ]] && hbg="%K{$3}" || hbg="%k"
  [[ -n $4 ]] && hfg="%F{$4}" || hfg="%f"
  if [[ "$TERM" == "xterm-256color" ]]; then
    bg=$hbg; fg=$hfg; newbg=$3
  else
    bg=$lbg; fg=$lfg; newbg=$1
  fi

  if [[ $RCURRENT_BG != 'NONE' && $newbg != $RCURRENT_BG ]]; then
    echo -n " %{$bg%F{$RCURRENT_BG}%}$RSEGMENT_SEPARATOR%{$fg%} "
  else
    echo -n "%{$bg%}%{$fg%} "
  fi
  RCURRENT_BG=$newbg
  [[ -n $5 ]] && echo -n $5
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}"
  CURRENT_BG=''
}

# End the rprompt, closing any open segments
rprompt_end() {
  if [[ -n $RCURRENT_BG ]]; then
    echo -n " %{%k%F{$RCURRENT_BG}%}$RSEGMENT_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}"
  RCURRENT_BG=''
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
prompt_context() {
  local user=`whoami`

  if [[ "$user" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment blue white 21 250 "%(!.%{%F{yellow}%}.)$user@%m"
  fi
}

# Git: branch/detached head, dirty status
prompt_git() {
  local ref dirty
  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    dirty=$(parse_git_dirty)
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git show-ref --head -s --abbrev |head -n1 2> /dev/null)"
    if [[ -n $dirty ]]; then
      prompt_segment yellow black 178 black
    else
      prompt_segment green black 22 255
    fi

    setopt promptsubst
    autoload -Uz vcs_info

    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*' get-revision true
    zstyle ':vcs_info:*' check-for-changes true
    zstyle ':vcs_info:*' stagedstr '✚'
    zstyle ':vcs_info:git:*' unstagedstr '●'
    zstyle ':vcs_info:*' formats ' %u%c'
    zstyle ':vcs_info:*' actionformats '%u%c'
    vcs_info
    echo -n "${ref/refs\/heads\//⭠ }${vcs_info_msg_0_}"
  fi
}

prompt_hg() {
	local rev status
	if $(hg id >/dev/null 2>&1); then
		if $(hg prompt >/dev/null 2>&1); then
			if [[ $(hg prompt "{status|unknown}") = "?" ]]; then
				# if files are not added
				prompt_segment red white
				st='±'
			elif [[ -n $(hg prompt "{status|modified}") ]]; then
				# if any modification
				prompt_segment yellow black
				st='±'
			else
				# if working copy is clean
				prompt_segment green black
			fi
			echo -n $(hg prompt "⭠ {rev}@{branch}") $st
		else
			st=""
			rev=$(hg id -n 2>/dev/null | sed 's/[^-0-9]//g')
			branch=$(hg id -b 2>/dev/null)
			if `hg st | grep -Eq "^\?"`; then
				prompt_segment red black
				st='±'
			elif `hg st | grep -Eq "^(M|A)"`; then
				prompt_segment yellow black
				st='±'
			else
				prompt_segment green black
			fi
			echo -n "⭠ $rev@$branch" $st
		fi
	fi
}

# Dir: current working directory
prompt_dir() {
  prompt_segment 8 15 237 195 '%~'
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  local symbols
  symbols=()
  [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}■$RETVAL"
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}Ω"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}‼"

  [[ -n "$symbols" ]] && prompt_segment blue default 234 195 "$symbols"
}

# right prompt
# !###, duh
build_rprompt() {
  local str
  #prepend right to left
  str="$(rprompt_segment 8 14 235 248 '!%! ')"
  str="$(rprompt_segment 8 14 233 244 '%* ')${str}"
  str="$(rprompt_end)${str}"
  echo $str > /tmp/str
  echo -n "$str%{%f%}"
}

## Main prompt
build_prompt() {
  RETVAL=$?
  prompt_status
  prompt_context
  prompt_dir
  prompt_git
  prompt_hg
  prompt_end
}

PROMPT='%{%f%b%k%}$(build_prompt) '
RPROMPT='%{%f%b%k%}$(build_rprompt)'
