#!/bin/bash

docker build --tag=html-frontend:1.0 html-frontend/
docker build --tag=html-frontend:2.0 html-frontend-err/
docker build --tag=java-consumer:1.0 java-consumer/ 
docker build --tag=ruby-producer:1.0 ruby-producer/
docker build --tag=status-api:1.0 status-api/
docker pull rabbitmq:3.6.6-management
