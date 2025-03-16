# Define the directory containing the containerfiles
CONTAINERFILES_DIR := .

# Find all containerfiles in the directory
CONTAINERFILES := $(wildcard $(CONTAINERFILES_DIR)/*.containerfile)

# Extract the names before .containerfile
IMAGES := $(patsubst %.containerfile,%,$(notdir $(CONTAINERFILES)))

# Default target to build all images
all: $(IMAGES)

# Rule to build each image
$(IMAGES):
	podman buildx build --tag $@ -f $(CONTAINERFILES_DIR)/$@.containerfile

.PHONY: all $(IMAGES)
