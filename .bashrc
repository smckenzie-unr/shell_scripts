# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

#parse_git_branch() {
#    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
#}


# if [ "$color_prompt" = yes ]; then
#     PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\[\033[01;36m\]$(parse_git_branch)\[\033[00m\]\$ '
# else
#     PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
# fi


##### ─────────────────────────────────────────────
#####  Posh‑git style Bash prompt (branch‑only when clean)
##### ─────────────────────────────────────────────

# 1) Load git-prompt helper from Ubuntu (provides __git_ps1)
if [ -f /etc/bash_completion.d/git-prompt ]; then
    . /etc/bash_completion.d/git-prompt
fi

# 2) Disable built‑in __git_ps1 symbols; we print our own
unset GIT_PS1_SHOWDIRTYSTATE
unset GIT_PS1_SHOWUNTRACKEDFILES
unset GIT_PS1_SHOWSTASHSTATE
unset GIT_PS1_SHOWUPSTREAM
export GIT_PS1_STATESEPARATOR=""

# 3) Colors (wrapped with \[ \] so readline knows they’re non‑printing)
COL_RESET='\[\e[0m\]'
# If this soft yellow is too pale on your theme, use '\[\e[33m\]' instead.
COL_YELLOW='\[\e[38;5;229m\]'
COL_CYAN='\[\e[96m\]'
COL_RED='\[\e[91m\]'
COL_GREEN='\[\e[92m\]'

# 4) Build a posh-git-like status string:
#    [branch S +A ~B -C !D | +E ~F -G !H W]
#    - S: upstream relation (e.g. ≡, ↑2, ↓1, 2↕3)
#    - Left counts: index (staged)
#    - Right counts: worktree (unstaged/untracked)
#    - W: overall state (! for unstaged/untracked, ~ for staged-only, empty when clean)
git_posh_status() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0

  local head='' branch='' state='' working=''
  local ahead=0 behind=0 has_upstream=0
  local i_add=0 i_mod=0 i_del=0 i_conf=0
  local w_add=0 w_mod=0 w_del=0 w_conf=0
  local line tag xy x y status body

  while IFS= read -r line; do
    [ -z "$line" ] && continue
    case "$line" in
      '# branch.head '*)
        head="${line#\# branch.head }"
        ;;
      '# branch.upstream '*)
        has_upstream=1
        ;;
      '# branch.ab '*)
        ahead="${line#\# branch.ab +}"
        ahead="${ahead%% *}"
        behind="${line##* -}"
        ;;
      '? '*)
        w_add=$((w_add + 1))
        ;;
      '! '*)
        ;;
      'u '*)
        i_conf=$((i_conf + 1))
        w_conf=$((w_conf + 1))
        ;;
      '1 '*|'2 '*)
        tag="${line%% *}"
        body="${line#${tag} }"
        xy="${body%% *}"
        x="${xy:0:1}"
        y="${xy:1:1}"

        case "$x" in
          A) i_add=$((i_add + 1)) ;;
          D) i_del=$((i_del + 1)) ;;
          U) i_conf=$((i_conf + 1)) ;;
          .) ;;
          *) i_mod=$((i_mod + 1)) ;;
        esac

        case "$y" in
          A) w_add=$((w_add + 1)) ;;
          D) w_del=$((w_del + 1)) ;;
          U) w_conf=$((w_conf + 1)) ;;
          .) ;;
          *) w_mod=$((w_mod + 1)) ;;
        esac
        ;;
    esac
  done < <(git status --porcelain=2 --branch --untracked-files=normal 2>/dev/null)

  if [ "$head" = "(detached)" ] || [ -z "$head" ]; then
    branch=$(git rev-parse --short HEAD 2>/dev/null)
  else
    branch="$head"
  fi

  if [ "$has_upstream" -eq 1 ]; then
    if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
      state="${ahead}↕${behind}"
    elif [ "$ahead" -gt 0 ]; then
      state="↑${ahead}"
    elif [ "$behind" -gt 0 ]; then
      state="↓${behind}"
    else
      state='≡'
    fi
  fi

  if [ "$w_add" -gt 0 ] || [ "$w_mod" -gt 0 ] || [ "$w_del" -gt 0 ] || [ "$w_conf" -gt 0 ]; then
    working=' !'
  elif [ "$i_add" -gt 0 ] || [ "$i_mod" -gt 0 ] || [ "$i_del" -gt 0 ] || [ "$i_conf" -gt 0 ]; then
    working=' ~'
  fi

  # Keep clean repos minimal: show branch name and upstream relation if present.
  if [ "$i_add" -eq 0 ] && [ "$i_mod" -eq 0 ] && [ "$i_del" -eq 0 ] && [ "$i_conf" -eq 0 ] && \
     [ "$w_add" -eq 0 ] && [ "$w_mod" -eq 0 ] && [ "$w_del" -eq 0 ] && [ "$w_conf" -eq 0 ]; then
    status="${COL_YELLOW}[${COL_CYAN}${branch}"
    [ -n "$state" ] && status+=" ${COL_CYAN}${state}"
    status+="${COL_YELLOW}]"
    printf '%s' "$status"
    return 0
  fi

  status="${COL_YELLOW}[${COL_CYAN}${branch}"
  [ -n "$state" ] && status+=" ${COL_CYAN}${state}"
  status+=" ${COL_GREEN}+${i_add} ~${i_mod} -${i_del} !${i_conf}"
  status+=" ${COL_YELLOW}|${COL_RED} +${w_add} ~${w_mod} -${w_del} !${w_conf}${working}"
  status+="${COL_YELLOW}]"
  printf '%s' "$status"
}

# Print a colored git segment only when inside a git repo (no empty brackets)
git_prompt_segment() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
  git_posh_status
}


# 5) Your final PS1
#    - Green user@host, blue cwd (your existing look)
#    - Yellow [ cyan(branch) red(counts-if-any) yellow ] reset
#    - Counts come from $(git_counts_clean); empty when clean → branch only
#    - Space before final \$ prompt char
if [ "$color_prompt" = yes ]; then
  set_bash_prompt() {
    local gitseg
    gitseg=$(git_prompt_segment)
    if [ -n "$gitseg" ]; then
      PS1="${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] ${gitseg}${COL_RESET}\$ "
    else
      PS1="${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]${COL_RESET}\$ "
    fi
  }
  PROMPT_COMMAND=set_bash_prompt
else
  PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi

unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Start ssh-agent if not already running
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    eval "$(ssh-agent -s)"
fi

# Point SSH_AUTH_SOCK to the agent
export SSH_AUTH_SOCK=$(ls /tmp/ssh-*/agent.* 2>/dev/null | head -n 1)

export PATH="/home/scott.mckenzie/.local/bin:$PATH"
#export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
