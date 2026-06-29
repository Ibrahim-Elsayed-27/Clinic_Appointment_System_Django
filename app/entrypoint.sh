#!/bin/sh
set -e

echo "Waiting for postgres..."
python manage.py migrate
python manage.py create_groups
exec gunicorn clinic_appointment.wsgi:application --bind 0.0.0.0:8000 --workers 3