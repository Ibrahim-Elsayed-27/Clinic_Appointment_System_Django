from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.contrib.auth.models import Group
from django.utils import timezone

from accounts.forms import StaffRegistrationForm, PatientRegistrationForm
from appointments.models import Appointment
from medical_records.models import ConsultationRecord
from scheduling.models import DoctorSchedule, Slot

from datetime import time, timedelta, datetime

User = get_user_model()


class Command(BaseCommand):
    help = "Seed database with initial users, schedules, appointments, and consultation records"

    def handle(self, *args, **kwargs):
        self.stdout.write(self.style.WARNING("Seeding database..."))

        # Clear existing data
        User.objects.all().delete()

        users = [
            # Admin
            {
                "username": "admin",
                "email": "admin@mediflow.com",
                "password": "Maher123!",
                "role": "A",
                "first_name": "Admin",
                "last_name": "User",
            },

            # Doctors
            {
                "username": "dr_mustafa",
                "email": "mustafa@mediflow.com",
                "first_name": "Mustafa",
                "last_name": "Tarek",
                "password": "Doctor123!",
                "role": "D",
            },
            {
                "username": "dr_yasser",
                "email": "yasser@mediflow.com",
                "first_name": "Ahmed",
                "last_name": "Yasser",
                "password": "Doctor123!",
                "role": "D",
            },

            # Receptionist
            {
                "username": "rec_yassin",
                "email": "yassin@mediflow.com",
                "first_name": "Yassin",
                "last_name": "Ibrahim",
                "password": "Reception123!",
                "role": "R",
            },

            # Patients
            {
                "username": "pat_bassant",
                "email": "bassant@mediflow.com",
                "first_name": "Bassant",
                "last_name": "Mohamed",
                "password": "Patient123!",
                "role": "P",
            },
            {
                "username": "pat_ibrahim",
                "email": "ibrahim@mediflow.com",
                "first_name": "Ibrahim",
                "last_name": "Ali",
                "password": "Patient123!",
                "role": "P",
            },
        ]

        created_users = {}

        # ---------- Create Users ----------
        for user_data in users:
            password = user_data.pop("password")

            if user_data.get("role") == "A":
                user = User.objects.create_superuser(
                    username=user_data["username"],
                    email=user_data["email"],
                    password=password,
                    first_name=user_data["first_name"],
                    last_name=user_data["last_name"],
                    role="A",
                )

                group, _ = Group.objects.get_or_create(name="Admin")
                user.groups.add(group)
                user.save()

                created_users[user.username] = user
                self.stdout.write(self.style.SUCCESS(f"Created admin: {user.username}"))
                continue

            form_data = {
                "username": user_data.get("username"),
                "first_name": user_data.get("first_name"),
                "last_name": user_data.get("last_name"),
                "email": user_data.get("email"),
                "role": user_data.get("role"),
                "password1": password,
                "password2": password,
            }

            if user_data.get("role") == "P":
                form = PatientRegistrationForm(form_data)
            else:
                form = StaffRegistrationForm(form_data)

            if form.is_valid():
                user = form.save()
                created_users[user.username] = user
                self.stdout.write(self.style.SUCCESS(f"Created user: {user.username}"))
            else:
                self.stdout.write(
                    self.style.ERROR(f"Failed to create {user_data.get('username')}: {form.errors}")
                )

        today = timezone.localdate()
        weekday = today.weekday()

        doctor_usernames = ["dr_mustafa", "dr_yasser"]

        # ---------- Helper to create slot ----------
        def create_slot(schedule, date, start_hour, start_minute, reserved=False):
            start = time(start_hour, start_minute)
            end_dt = datetime.combine(date, start) + timedelta(minutes=30)
            end = end_dt.time()

            return Slot.objects.create(
                doctor_schedule=schedule,
                date=date,
                start_time=start,
                end_time=end,
                is_available=not reserved,
            )

        appointments = []

        # ---------- Standard demo appointments ----------
        for idx, doc_username in enumerate(doctor_usernames):

            doctor = created_users.get(doc_username)
            patient = created_users.get("pat_bassant")

            schedule = DoctorSchedule.objects.create(
                doctor=doctor,
                day_of_week=weekday,
                start_time=time(9, 0),
                end_time=time(11, 0),
            )

            slot1 = create_slot(schedule, today, 9, 0, reserved=True)
            slot2 = create_slot(schedule, today, 9, 30, reserved=True)

            appt_completed = Appointment.objects.create(
                patient=patient,
                doctor=doctor,
                slot=slot1,
                status="COMPLETED",
            )

            ConsultationRecord.objects.create(
                appointment=appt_completed,
                diagnosis="Test diagnosis for seeded data.",
                notes="Seeded consultation notes.",
                prescription="Seeded prescription details.",
                requested_tests="Blood test, X-ray.",
            )

            appt_confirmed = Appointment.objects.create(
                patient=patient,
                doctor=doctor,
                slot=slot2,
                status="CONFIRMED",
            )

            appointments.extend([appt_completed, appt_confirmed])

        # ---------- Historical appointments for pat_ibrahim ----------
        history_patient = created_users.get("pat_ibrahim")
        past_date = today - timedelta(days=5)

        for doc_username in doctor_usernames:

            doctor = created_users.get(doc_username)

            schedule = DoctorSchedule.objects.create(
                doctor=doctor,
                day_of_week=past_date.weekday(),
                start_time=time(10, 0),
                end_time=time(12, 0),
            )

            slot = Slot.objects.create(
                doctor_schedule=schedule,
                date=past_date,
                start_time=time(10, 0),
                end_time=time(10, 30),
                is_available=False,
            )

            past_appt = Appointment.objects.create(
                patient=history_patient,
                doctor=doctor,
                slot=slot,
                status="COMPLETED",
            )

            ConsultationRecord.objects.create(
                appointment=past_appt,
                diagnosis="Previous consultation diagnosis",
                notes="Routine medical check.",
                prescription="Pain reliever",
                requested_tests="None",
            )

            appointments.append(past_appt)

        # ---------- Today's completed appointment WITHOUT consultation ----------
        doctor_today = created_users.get("dr_mustafa")

        schedule_today = DoctorSchedule.objects.create(
            doctor=doctor_today,
            day_of_week=weekday,
            start_time=time(12, 0),
            end_time=time(13, 0),
        )

        slot_today = Slot.objects.create(
            doctor_schedule=schedule_today,
            date=today,
            start_time=time(12, 0),
            end_time=time(12, 30),
            is_available=False,
        )

        appt_today = Appointment.objects.create(
            patient=history_patient,
            doctor=doctor_today,
            slot=slot_today,
            status="COMPLETED",
        )

        appointments.append(appt_today)

        self.stdout.write(
            self.style.SUCCESS(
                "Created past consultations for pat_ibrahim with both doctors "
                "and a completed appointment today WITHOUT consultation record."
            )
        )

        self.stdout.write(
            self.style.SUCCESS(f"Created {len(appointments)} appointments in total.")
        )

        self.stdout.write(self.style.SUCCESS("Seeding completed!"))