_ggcloud() {
  # Use the vendor completion function
  _python_argcomplete "$@"
}

compdef _ggcloud ggcloud

#alias ggcloud="docker run --rm -ti -v $HOME/.config/gcloud:/root/.config/gcloud gcr.io/google.com/cloudsdktool/google-cloud-cli:stable gcloud"
#complete -o nospace -C ggcloud gcloud
