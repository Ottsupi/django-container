FROM python:3.12

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

ARG DEV_CONTAINER_UID
ARG DEV_CONTAINER_GID

ENV USER_HOME="/home/dev"
ENV APP_HOME="/home/dev/code"

# Setup the dev environment
WORKDIR ${USER_HOME}

RUN addgroup --gid ${DEV_CONTAINER_GID} devgroup
RUN adduser --uid ${DEV_CONTAINER_UID} --gid ${DEV_CONTAINER_GID} --disabled-password --shell /bin/bash --home /home/dev dev
RUN mkdir -p .ssh && chmod 700 .ssh
COPY ./.devcontainer/bash_history.template .bash_history
RUN chmod 600 .bash_history
COPY ./.devcontainer/.bashrc .bashrc


# Setup the app
WORKDIR ${APP_HOME}

RUN apt update && apt upgrade -y
RUN apt install -y libpq-dev python3-dev

RUN pip install --upgrade pip
RUN pip install --no-cache-dir psycopg[c]==3.2.*
# ^This takes a while so install it earlier for cache

COPY ./requirements/ ./requirements/
RUN pip install --no-cache-dir -r ./requirements/requirements.dev.txt

RUN chown -R dev:devgroup ${USER_HOME}

USER dev

CMD ["sleep", "infinity"]
