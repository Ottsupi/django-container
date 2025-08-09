FROM python:3.12

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN apt update && apt upgrade -y
RUN apt install -y libpq-dev python3-dev

RUN pip install --upgrade pip

ENV APP_HOME /code
WORKDIR ${APP_HOME}

# This takes a while so install it earlier for cache
RUN pip install --no-cache-dir psycopg[c]==3.2.*

COPY ./requirements/ ./requirements/
RUN pip install --no-cache-dir -r ./requirements/requirements.dev.txt

CMD ["sleep", "infinity"]
