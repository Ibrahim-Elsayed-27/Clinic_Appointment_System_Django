#!/bin/sh
set -e

echo "Waiting for postgres..."
python manage.py migrate
python manage.py create_groups
python manage.py seed_data
python manage.py collectstatic --noinput
exec gunicorn clinic_appointment.wsgi:application --bind 0.0.0.0:8000 --workers 3