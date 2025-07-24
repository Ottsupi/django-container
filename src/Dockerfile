FROM python:3.12

RUN pip install --upgrade pip

ENV APP_HOME /code
WORKDIR ${APP_HOME}

COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN ["chmod", "+x", "entrypoint.sh"]
