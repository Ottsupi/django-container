#!/bin/sh

# Apply database migrations
echo "[1/2] ${ENVIRONMENT} - Applying database migrations..."
python manage.py migrate --noinput

# Start Gunicorn
echo "[2/3] ${ENVIRONMENT} - Collecting static files..."
python manage.py collectstatic --noinput

# Start Gunicorn
echo "[3/3] ${ENVIRONMENT} - Starting Gunicorn..."
exec gunicorn -c gunicorn.py core.wsgi:application
