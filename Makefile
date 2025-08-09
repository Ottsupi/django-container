# Define variables
CD_SRC = cd src &&
MANAGE = $(CD_SRC) python manage.py

.PHONY: run migrations migrate superuser static app shell urls

run:
	$(MANAGE) runserver_plus 0.0.0.0:8000

migrations:
	$(MANAGE) makemigrations

migrate:
	$(MANAGE) migrate

superuser:
	$(MANAGE) createsuperuser

static:
	$(MANAGE) collectstatic

app:
	@read -p "What is the name of the app? " app_name; \
	mkdir src/apps/$$app_name && \
	$(MANAGE) startapp $$app_name apps/$$app_name && \
	echo "Don't forget to update the app name in 'apps.py'!"

shell:
	$(MANAGE) shell_plus

urls:
	$(MANAGE) show_urls
