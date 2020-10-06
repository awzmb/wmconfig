# fix for aws completion in fedora linux
if [ "$(uname)" = "Linux" ]; then
  complete -C aws_completer aws
fi

