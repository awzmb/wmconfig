# Get all subdirectories with a Containerfile
DIRS := $(wildcard */Dockerfile)

# Extract the names of the directories
IMAGES := $(patsubst %/Dockerfile,%,$(DIRS))

# Default target to build all images
all: $(IMAGES)

# Rule to build each image
$(IMAGES):
	podman buildx build --build-arg "USERNAME=$$(whoami)" --build-arg "USER_ID=$$(id -u)" --build-arg "GROUP_ID=$$(id -g)" --tag $@ -f $@/Dockerfile $@

.PHONY: all $(IMAGES)

update:
	podman run --rm -it --user $(id -u):$(id -g) --volume "${PWD}":/workspace:Z --workdir /workspace ghcr.io/updatecli/updatecli:latest apply
