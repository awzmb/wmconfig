# fix for aws completion in fedora linux
if [ "$(uname)" = "Linux" ]; then
  complete -C aws_completer aws
fi

# set xdg runtime dir for podman to work
# in fedora linux
if [ "$(uname)" = "Linux" ]; then
  export XDG_RUNTIME_DIR=/run/user/$(id -u)
fi

