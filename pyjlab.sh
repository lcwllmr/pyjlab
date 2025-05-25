#!/usr/bin/env bash

IMAGE_NAME="lcwllmr/pyjlab:latest"
VOLUME_NAME="lcwllmr-pyjlab-workspace"
CONTAINER_NAME="lcwllmr-pyjlab"

# check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker and try again."
    exit 1
fi

# check if the volume exists
if ! docker volume inspect "$VOLUME_NAME" >/dev/null 2>&1; then
    echo "Workspace volume does not yet exist. Creating it..."
    docker volume create "$VOLUME_NAME"
fi

# check if the image is already pulled
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    echo "Docker image not found locally. Pulling from Docker Hub..."
    docker pull "$IMAGE_NAME"
fi

# check if the container has already been created
if ! docker container inspect "$CONTAINER_NAME" > /dev/null 2>&1; then
    echo "Container not found. Creating it "
fi


# check if the container exists
if docker container inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
    # check if the container is already running
    if [ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER_NAME")" = "true" ]; then
        echo "Container '$CONTAINER_NAME' is already running."
    else
        echo "Container '$CONTAINER_NAME' exists but is not running. Starting it..."
        docker start "$CONTAINER_NAME"
    fi
else
    echo "Container '$CONTAINER_NAME' does not exist. Creating and starting it..."
    docker run -d \
        --name "$CONTAINER_NAME" \
        -p 8888:8888 \
        -v "$VOLUME_NAME":/workspace \
        "$IMAGE_NAME"
fi

echo "JupyterLab is live at   http://localhost:8888/doc"

echo "Opening in browser..."
xdg-open http://localhost:8888/doc 1>/dev/null 2>&1
