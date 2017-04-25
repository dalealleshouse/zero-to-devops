#!/bin/bash

IP=$1

> ~/.minikube/docker.temp
echo export DOCKER_TLS_VERIFY=1 >> ~/.minikube/docker.temp
echo export DOCKER_HOST=tcp://$IP:2376 >> ~/.minikube/docker.temp
echo export DOCKER_CERT_PATH=/mnt/c/Users/dalea/.minikube/certs >> ~/.minikube/docker.temp
echo export DOCKER_API_VERSION=1.23 >> ~/.minikube/docker.temp
