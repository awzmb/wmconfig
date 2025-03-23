#ggcloud() {
  #podman run --rm \
    #-v $HOME/.config/gcloud:/root/.config/gcloud \
    #-it gcr.io/google.com/cloudsdktool/google-cloud-cli:latest \
    #gcloud "$@"
#}

#complete -o nospace -C ggcloud gcloud
#compdef gcloud ggcloud
