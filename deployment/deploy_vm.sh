#!/bin/bash

# echo yes | mix phx.gen.release --docker
docker buildx build . -t registry.devtoolbelt.xyz/icky_venus:latest --platform linux/amd64 --push && \
scp deployment/docker-compose.yaml root@digital-ocean:/root/icky_venus && \
scp deployment/.env root@digital-ocean:/root/icky_venus && \
scp -r data/ root@digital-ocean:/root/icky_venus/ && \
ssh digital-ocean << EOF
docker-compose -f icky_venus/docker-compose.yaml -p icky_venus down && \
docker-compose -f icky_venus/docker-compose.yaml -p icky_venus up -d
EOF
