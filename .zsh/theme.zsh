# zsh theme

# colors
black="%F{0}"
red="%F{1}"
green="%F{2}"
yellow="%F{3}"
blue="%F{4}"
magenta="%F{5}"
cyan="%F{6}"
white="%F{7}"


# k8s and aws profile information
function k8s_info {
  if [ -f ~/.kube/config ]; then
    k8s_context=$(cat ~/.kube/config | grep "current-context:" | sed "s/current-context: //")
    if [ ! -z $k8s_context ]; then
      echo " %F{135}<$k8s_context>"
    fi
  fi
}

function aws_info {
  if [ ! -z $AWS_PROFILE ]; then
    echo " %F{111}<aws: $AWS_PROFILE>"
  fi
}

setopt prompt_subst

# load vcs module
autoload -U add-zsh-hook
autoload -Uz vcs_info

# enable vcs systems you use
zstyle ':vcs_info:*' enable git svn

# check-for-changes can be really slow.
# disable if you work with large repositories
zstyle ':vcs_info:*:prompt:*' check-for-changes true

# set formats
# %b - branchname
# %u - unstagedstr (see below)
# %c - stagedstr (see below)
# %a - action (e.g. rebase-i)
# %R - repository path
# %S - path in the repository
reset_color="%f"
FMT_BRANCH="<%{$blue%}%b%u%c${reset_color}>"
FMT_ACTION="<%{$green%}%a${reset_color}>"
FMT_UNSTAGED="%{$blue%} "
FMT_STAGED="%{$blue%} "

# vcs style settings
zstyle ':vcs_info:*:prompt:*' unstagedstr   "${FMT_UNSTAGED}"
zstyle ':vcs_info:*:prompt:*' stagedstr     "${FMT_STAGED}"
zstyle ':vcs_info:*:prompt:*' actionformats "${FMT_BRANCH}${FMT_ACTION}"
zstyle ':vcs_info:*:prompt:*' formats       "${FMT_BRANCH}"
zstyle ':vcs_info:*:prompt:*' nvcsformats   ""

# extend vcs_info to check for untracked files or updated submodules
function precmd {
    if git ls-files --other --exclude-standard 2> /dev/null | grep -q "."; then
        PR_GIT_UPDATE=1
        FMT_BRANCH="<%{$cyan%}%b%u%c%{$red%}:${reset_color}>"
    else
        FMT_BRANCH="<%{$cyan%}%b%u%c${reset_color}>"
    fi
    zstyle ':vcs_info:*:prompt:*' formats " ${FMT_BRANCH}"

    vcs_info 'prompt'
}
add-zsh-hook precmd precmd

# use red color if in su prompt
if [ $UID -eq 0 ]; then CARETCOLOR="${red}"; else CARETCOLOR="${blue}"; fi

# build prompt
function left_prompt {
	#echo -n "%F{6}%n%f" # User
	#echo -n "%F{8}@%f" # at
	echo -n "%F{12}%m%f" # Host
	echo -n " %F{8}::%f" # in
	echo -n " %{$cyan%}%~" # Dir
	#echo -n "\n"
	echo -n " %{$blue%}»${reset_color} " # $ or #
}

function right_prompt {
	echo -n "$vcs_info_msg_0_" # Git branch
	echo -n "$(k8s_info)$(aws_info)%{$reset_color%}" # Git branch
}

PROMPT='$(left_prompt)'
RPROMPT='$(right_prompt)'
