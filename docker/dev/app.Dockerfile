FROM python:3.14

ARG DEV_CONTAINER_UID
ARG DEV_CONTAINER_GID

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    USER_HOME="/home/dev" \
    APP_HOME="/home/dev/code"

# Setup system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    pkg-config \
    python3-dev \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip && \
    pip install --no-cache-dir psycopg[c]==3.3.*
# ^This takes a while so install it earlier for cache


# Setup the dev environment
RUN groupadd --gid ${DEV_CONTAINER_GID} devgroup && \
    useradd --uid ${DEV_CONTAINER_UID} --gid ${DEV_CONTAINER_GID} --create-home --shell /bin/bash dev
RUN curl -sS https://starship.rs/install.sh | sh -s -- -y

USER dev
WORKDIR ${USER_HOME}
RUN mkdir -p .ssh && chmod 700 .ssh && \
    touch .bash_history && chmod 600 .bash_history
COPY ./.devcontainer/.bashrc .bashrc
RUN mkdir -p .config
COPY ./.devcontainer/starship.toml .config/starship.toml


WORKDIR ${APP_HOME}
CMD ["sleep", "infinity"]
