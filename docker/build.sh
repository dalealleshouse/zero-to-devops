#!/bin/bash

docker build --tag=dalealleshouse/html-frontend:1.0 html-frontend/
docker push dalealleshouse/html-frontend:1.0

docker build --tag=dalealleshouse/html-frontend:2.0 html-frontend-err/
docker push dalealleshouse/html-frontend:2.0

docker build --tag=dalealleshouse/java-consumer:1.0 java-consumer/ 
docker push dalealleshouse/java-consumer:1.0

docker build --tag=dalealleshouse/ruby-producer:1.0 ruby-producer/
docker push dalealleshouse/ruby-producer:1.0

docker build --tag=dalealleshouse/status-api:1.0 status-api/
docker push dalealleshouse/status-api:1.0
