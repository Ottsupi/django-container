FROM python:3.12

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN pip install --upgrade pip

ENV APP_HOME /develop
WORKDIR ${APP_HOME}

CMD ["sleep", "infinity"]