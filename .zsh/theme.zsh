# zsh theme

# k8s and aws profile information
function k8s_info {
  if [ -f ~/.kube/config ]; then
    k8s_context=$(cat ~/.kube/config | grep "current-context:" | sed "s/current-context: //")
    if [ ! -z $k8s_context ]; then
      echo " %F{135}(k8s: $k8s_context)"
    fi
  fi
}

function aws_info {
  if [ ! -z $AWS_PROFILE ]; then
    echo " %F{111}(aws: $AWS_PROFILE)"
  fi
}

setopt prompt_subst

autoload -U add-zsh-hook
autoload -Uz vcs_info

# colors
c_red="%F{red}"
c_green="%F{green}"
c_cyan="%F{cyan}"
c_blue="%F{blue}"
c_yellow="%F{yellow}"
c_magenta="%F{magenta}"
c_background="%F{0}"

# enable VCS systems you use
zstyle ':vcs_info:*' enable git svn

# check-for-changes can be really slow.
# you should disable it, if you work with large repositories
zstyle ':vcs_info:*:prompt:*' check-for-changes true

# set formats
# %b - branchname
# %u - unstagedstr (see below)
# %c - stagedstr (see below)
# %a - action (e.g. rebase-i)
# %R - repository path
# %S - path in the repository
RESET_COLOR="%f"
FMT_BRANCH="(%{$c_cyan%}%b%u%c${RESET_COLOR})"
FMT_ACTION="(%{$c_green%}%a${RESET_COLOR})"
FMT_UNSTAGED="%{$c_yellow%}:"
FMT_STAGED="%{$c_green%}:"

zstyle ':vcs_info:*:prompt:*' unstagedstr   "${FMT_UNSTAGED}"
zstyle ':vcs_info:*:prompt:*' stagedstr     "${FMT_STAGED}"
zstyle ':vcs_info:*:prompt:*' actionformats "${FMT_BRANCH}${FMT_ACTION}"
zstyle ':vcs_info:*:prompt:*' formats       "${FMT_BRANCH}"
zstyle ':vcs_info:*:prompt:*' nvcsformats   ""

function precmd {
    # check for untracked files or updated submodules, since vcs_info doesn't
    if git ls-files --other --exclude-standard 2> /dev/null | grep -q "."; then
        PR_GIT_UPDATE=1
        FMT_BRANCH="(%{$c_cyan%}%b%u%c%{$c_red%}:${RESET_COLOR})"
    else
        FMT_BRANCH="(%{$c_cyan%}%b%u%c${RESET_COLOR})"
    fi
    zstyle ':vcs_info:*:prompt:*' formats " ${FMT_BRANCH}"

    vcs_info 'prompt'
}
add-zsh-hook precmd precmd

pr_24h_clock=' %*'

PS1='%m %{${fg_bold[blue]}%}:: %{$RESET_COLOR%}%{${fg[c_green]}%}%3~ %{${fg_bold[$CARETCOLOR]}%}»%{${RESET_COLOR}%}
%{$c_blue%}%n${RESET_COLOR}@%{$c_blue%}%m${RESET_COLOR} %{$c_blue%}%~${RESET_COLOR}$vcs_info_msg_0_$(k8s_info)$(aws_info)${RESET_COLOR} %{$c_green%}»${RESET_COLOR} '
