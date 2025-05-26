#!/usr/bin/env bash

IMAGE_NAME="lcwllmr/pyjlab:latest"
VOLUME_NAME="lcwllmr-pyjlab-workspace"
CONTAINER_NAME="lcwllmr-pyjlab"
BACKUP_OUTPATH="/out//pyjlab-$(date +%Y%m%d-%H%M%S).tar.gz"

set -e

usage() {
    echo "Usage: pyjlab [refresh|start|stop|backup]"
    echo
    echo "If no sub-command is provided, the script will do all necessary initialization, launch the JupyterLab container and point the default web browser to it."
    echo
    echo "Optional sub-commands:"
    echo "  pyjlab refresh -> delete image and container, and pull latest image from Docker Hub"
    echo "  pyjlab stop -> stop the container"
    echo "  pyjlab backup -> backup all notebooks as tar.gz archive in current working directory on host"
    echo "  pyjlab help -> show this overview message"
}

init() {
    # check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo "Docker is not installed. Please install Docker and try again."
        exit 1
    fi

    # check if the volume exists
    if ! docker volume inspect "$VOLUME_NAME" >/dev/null 2>&1; then
        echo "Creating workspace volume..."
        docker volume create "$VOLUME_NAME"
    fi

    # check if the image is already pulled
    if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
        echo "Pulling latest image from Docker Hub..."
        docker pull "$IMAGE_NAME"
    fi
}

run() {
    # check if the container exists
    if docker container inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
        # check if the container is already running
        if [ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER_NAME")" = "true" ]; then
            echo "Container is already running."
        else
            echo "Container exists but is not running. Starting it..."
            docker start "$CONTAINER_NAME"
            sleep 1
        fi
    else
        echo "Launching a fresh container..."
        docker run -d \
            --name "$CONTAINER_NAME" \
            -p 8888:8888 \
            -v "$VOLUME_NAME":/workspace \
            "$IMAGE_NAME"
        sleep 1
    fi

    echo "JupyterLab is live at   http://localhost:8888/doc"

    echo "Opening in browser..."
    xdg-open http://localhost:8888/doc 1>/dev/null 2>&1
}

stop() {
    if docker container inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
        if [ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER_NAME")" = "true" ]; then
            docker stop "$CONTAINER_NAME"
        fi
    fi
}

clean() {
    # stop and remove container if necessary
    if docker container inspect "$CONTAINER_NAME" >/dev/null 2>&1; then
        if [ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER_NAME")" = "true" ]; then
            docker stop "$CONTAINER_NAME"
        fi
        docker rm "$CONTAINER_NAME"
    fi

    # delete image
    if docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
        docker rmi "$IMAGE_NAME"
    fi
}

backup() {
    docker run --rm \
      -v "$VOLUME_NAME":/workspace \
      -v "$PWD":/out busybox sh -c \
      "cd /workspace && find . -not -path '*/.*' -type f -name '*.ipynb' | tar -czf ${BACKUP_OUTPATH} -T -"
}

CMD=$1
case "$CMD" in
  "")
    init
    run
    ;;
  "refresh")
    clean
    init
    ;;
  "stop")
    stop
    ;;
  "backup")
    backup
    ;;
  "help")
    usage
    ;;
  *)
    echo "Sub-command $1 not valid."
    usage
    ;;
esac
