FROM mcr.microsoft.com/devcontainers/universal:2-focal

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y postgresql-client \
    && rm -rf /var/lib/apt/lists/*
