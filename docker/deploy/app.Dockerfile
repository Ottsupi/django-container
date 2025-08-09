FROM python:3.12

RUN apt update && apt upgrade -y
RUN apt install -y libpq-dev python3-dev

RUN pip install --upgrade pip

ENV APP_HOME /code
WORKDIR ${APP_HOME}

COPY ./requirements/ ./requirements/
RUN pip install --no-cache-dir -r ./requirements/requirements.txt

COPY ./src/ .

RUN ["chmod", "+x", "entrypoint.sh"]
