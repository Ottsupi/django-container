import os

PORT = os.environ.get("GUNICORN_PORT", default="8080")
HOST = "0.0.0.0"
bind = f"{HOST}:{PORT}"

workers = 2
threads = 4
timeout = 0

# run with:
# gunicorn -c gunicorn.py config.wsgi:application
