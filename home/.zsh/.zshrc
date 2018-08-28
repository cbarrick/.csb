#!/bin/zsh


# Shell Options
#--------------------
# zshoptions(1)  /  http://zsh.sourceforge.net/Doc/Release/Options.html

# Changing Directories
setopt auto_cd # If command is a directory path, cd to it.
setopt auto_pushd # cd is really pushd.
setopt chase_links # Resolve symbolic links to their true location.
setopt pushd_ignore_dups # Don't put duplicates on the directory stack.
setopt pushd_minus # Make `cd -1` go to the previous directory, etc.
setopt pushd_to_home # pushd with no arguments goes home, like cd.

# Completion
setopt auto_param_keys # Intelligently add a space after variable completion.
setopt auto_param_slash # Intelligently add a slash after directory completion.
setopt auto_remove_slash # Remove trailing slash if next char is a word delim.
setopt complete_aliases # Treat aliases as distinct commands.
setopt complete_in_word # Completions happen at the cursor's location.
setopt glob_complete # Tab completion expands globs.
setopt hash_list_all # Ensure the command path is hashed before completion.
setopt menu_complete # Expand first match and use the interactive menu.

# Expansion and Globbing
setopt glob # Enable globbing (i.e. the use of the '*' operator).
setopt extended_glob # Use additional glob operators ('#', '~', and '^').
# setopt glob_dots # Do not require a leading '.' to be matched explicitly.
setopt mark_dirs # Mark directories resulting from globs with trailing slashes.
setopt nomatch # If a glob fails, the command isn't executed.

# History
setopt hist_ignore_all_dups # Ignore all duplicates when writing history.
setopt hist_ignore_space # Ignore commands that begin with spaces.
setopt inc_append_history # Write commands to history file as soon as possible.

# Input/Output
setopt append_create # Allow '>>' to create a file.
setopt no_clobber # Prevent `>` from clobbering files. Use `>!` to clobber.
setopt correct # Offer to correct the spelling of commands.
setopt interactive_comments # Allow comments in interactive shells.
setopt short_loops # Enable short loop syntax: `for <var> in <seq>; <command>`.

# Job Control
setopt auto_continue # When suspended jobs are disowned, resume them in the bg.
setopt auto_resume # Single-word simple commands are candidates for resumption.
setopt bg_nice # Run background jobs at lower priority.
setopt check_jobs # Warn about suspended jobs on exit.
setopt check_running_jobs # Warn about background jobs on exit.

# Scripts and Functions
setopt local_loops # Do not allow `break` etc. to propogate outside function scope.

# ZLE
setopt no_beep # The shell shouldn't beep on ZLE errors (most beeps).
setopt zle # Use ZLE. This is default, but I like to be explicit.


# History
#--------------------
HISTSIZE=2000
SAVEHIST=${HISTSIZE}
HISTFILE=${ZDOTDIR}/.history
export HISTSIZE SAVEHIST HISTFILE


# Keyboard
#--------------------
autoload -Uz zkbd
[[ ! -f ${ZDOTDIR}/zkbd/${TERM} ]] && zkbd
source ${ZDOTDIR}/zkbd/${TERM}

bindkey -e
[[ -n ${key[Home]}       ]] && bindkey ${key[Home]}       beginning-of-line
[[ -n ${key[End]}        ]] && bindkey ${key[End]}        end-of-line
[[ -n ${key[Insert]}     ]] && bindkey ${key[Insert]}     overwrite-mode
[[ -n ${key[Delete]}     ]] && bindkey ${key[Delete]}     delete-char
[[ -n ${key[Up]}         ]] && bindkey ${key[Up]}         up-line-or-search
[[ -n ${key[Down]}       ]] && bindkey ${key[Down]}       down-line-or-search
[[ -n ${key[Left]}       ]] && bindkey ${key[Left]}       backward-char
[[ -n ${key[Right]}      ]] && bindkey ${key[Right]}      forward-char
[[ -n ${key[Ctrl-Left]}  ]] && bindkey ${key[Ctrl-Left]}  backward-word
[[ -n ${key[Ctrl-Right]} ]] && bindkey ${key[Ctrl-Right]} forward-word
[[ -n ${key[Alt-Left]}   ]] && bindkey ${key[Alt-Left]}   backward-word
[[ -n ${key[Alt-Right]}  ]] && bindkey ${key[Alt-Right]}  forward-word


# Prompt
#--------------------
autoload -Uz promptinit
promptinit
prompt cbarrick


# Completion
#--------------------
autoload -Uz compinit
compinit -u

zstyle ':completion:*' use-cache true # Cache completion to `${ZDOTDIR}/.zcompcache`.
zstyle ':completion:*' menu 'select' # Make the menu interactive with arrow keys.

# TODO: Setup 'Tab' key combos in zkbd.
bindkey '^I' menu-expand-or-complete
bindkey '^[[Z' reverse-menu-complete


# Command checking
#--------------------
function exists {
	type $1 &> /dev/null
}


# Core utils
#--------------------
alias sed="sed -r"
alias mkdir="mkdir -p"
alias grep="grep --extended-regexp --color"
alias ls="ls --human-readable --classify --group-directories-first --color=auto"
alias l="ls --format=long"
alias la="l --almost-all"
alias df="df -h --total"
alias du="du -h --total"
alias pacman="sudo pacman"
alias systemctl="sudo systemctl"

# Use hub instead of git when avaliable
exists hub && alias git=hub

# Editors in order of preference, least to most
exists nano && EDITOR="nano"
exists vim  && EDITOR="vim"
exists atom && EDITOR="atom -w"
export EDITOR VISUAL="$EDITOR"

PAGER="less"
LESS="-MSR"
export PAGER LESS


# Rationalize Dots
#--------------------
# Automatically expands '...' to '../..'

function rationalize-dot {
	if [[ ${LBUFFER} = *.. ]]
	then
		LBUFFER=${LBUFFER[1,-1]}
		LBUFFER+=/..
	else
		LBUFFER+=.
	fi
}
zle -N rationalize-dot
bindkey . rationalize-dot


# Word Characters
#--------------------
# Where do words break when using `backward-word` (alt-left) etc.
# This removes the '/' from the default.
WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'
export WORDCHARS


# Window Title
#--------------------

# Get the cwd as a "file:" URL, including the hostname.
# This is needed for advanced features of iTerm2 and Terminal.app.
# cwurl = Current Working URL
function cwurl {
	# Percent-encode the cwd
	# LANG=C to process text byte-by-byte.
	local pct_encoded_cwd=''
	{
		local i ch hexch LANG=C
		for ((i = 1; i <= ${#PWD}; ++i))
		do
			ch="${PWD}[i]"
			if [[ "${ch}" =~ [/._~A-Za-z0-9-] ]]
			then
				pct_encoded_cwd+="${ch}"
			else
				hexch=$(printf "%02X" "'${ch}")
				pct_encoded_cwd+="%%${hexch}"
			fi
		done
	}

	echo "file://${HOST}${pct_encoded_cwd}"
}

# Sets the title to whatever is passed as $1
function set-term-title {
	# OSC 0, 1, and 2 are the portable escape codes for setting window titles.
	printf "\e]0;${1}\a"  # Both tab and window
	printf "\e]1;${1}\a"  # Tab title
	printf "\e]2;${1}\a"  # Window title

	# When using tmux -CC integration with iTerm2,
	# tabs and windows must be named through tmux.
	if [[ -n ${TMUX} ]]
	then
		tmux rename-window ${1}
	fi
}

# Notify Terminals on macOS of PWD.
function set-apple-title {
	# OSC 6 and 7 are used on macOS to advertise user, host, and pwd.
	# These codes may foobar other terminals on Linux, like gnome-terminal.
	printf "\e]6;\a"          # Current document as a URL (Terminal.app)
	printf "\e]7;$(cwurl)\a"  # CWD as a URL (Terminal.app and iTerm2)
}

# At the prompt, we set the title to "$HOST : $PWD".
# We call `print -P` to use prompt expansion instead of variable expansion.
function precmd-title {
	set-term-title "$(print -P %m : %~)"
	if [[ ${TERM_PROGRAM} == 'Apple_Terminal' || ${TERM_PROGRAM} == 'iTerm.app' ]]
	then
		set-apple-title
	fi
}

# When running a command, set the title to "$HOST : $COMMAND"
# The command is passed as $1 to the preexec hook.
function preexec-title {
	set-term-title "$(print -P %M : $1)"
}

# Setup the hooks
autoload add-zsh-hook
add-zsh-hook precmd precmd-title
add-zsh-hook preexec preexec-title


# iTerm2
#--------------------
if [[ ${TERM_PROGRAM} == 'iTerm.app' ]]
then
	source ${ZDOTDIR}/iterm2.zsh
fi


# Go
#--------------------
export GOPATH=${HOME}/.go
path=(${GOPATH}/bin ${path})
cdpath=(${GOPATH}/src ${GOPATH}/src/github.com/cbarrick ${cdpath})


# Python
#--------------------
source ~/.conda/etc/profile.d/conda.sh
exists conda && conda activate

export IPYTHONDIR="${HOME}/.ipython"
alias ipy="ipython --no-confirm-exit --no-term-title --classic"
alias ipylab="ipy --pylab"
