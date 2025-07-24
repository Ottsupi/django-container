import os

PORT = os.environ.get('SERVER_ PORT', default='8080')
HOST = '0.0.0.0'
bind = f'{HOST}:{PORT}'

workers = 2
threads = 4
timeout = 0

# run with:
# gunicorn -c gunicorn.py core.wsgi:application
