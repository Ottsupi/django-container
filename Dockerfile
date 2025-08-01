FROM python:3.12

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN apt update && apt upgrade
RUN apt install -y libpq-dev python3-dev

RUN pip install --upgrade pip

ENV APP_HOME /develop
WORKDIR ${APP_HOME}

COPY ./src/requirements.txt ./src/requirements.txt
COPY ./src/requirements.dev.txt ./src/requirements.dev.txt
RUN pip install --no-cache-dir -r ./src/requirements.dev.txt

CMD ["sleep", "infinity"]
