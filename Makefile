# Define variables
CD_SRC = cd src &&
MANAGE = $(CD_SRC) python manage.py

run:
	$(MANAGE) runserver_plus

migrations:
	$(MANAGE) makemigrations

migrate:
	$(MANAGE) migrate

superuser:
	$(MANAGE) createsuperuser

shell:
	$(MANAGE) shell_plus

urls:
	$(MANAGE) show_urls
