FROM python:3.12

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

ENV APP_HOME="/home/dev/code"
WORKDIR ${APP_HOME}

RUN groupadd --gid 1000 devgroup
RUN useradd --uid 1000 --gid 1000 --create-home dev

RUN apt update && apt upgrade -y
RUN apt install -y libpq-dev python3-dev

RUN pip install --upgrade pip
RUN pip install --no-cache-dir psycopg[c]==3.2.*
# ^This takes a while so install it earlier for cache

COPY ./requirements/ ./requirements/
RUN pip install --no-cache-dir -r ./requirements/requirements.dev.txt

RUN chown -R dev:devgroup ${APP_HOME}/..

USER dev

CMD ["sleep", "infinity"]
