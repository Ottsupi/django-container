import logging

from django.http import HttpResponse
from django.shortcuts import render

logger = logging.getLogger(__name__)


def index(request):
    logger.debug("Accessed Hello world! view")

    message = "Hello world!"
    context = {
        "message": message,
    }

    return render(request, "app/home.html", context)


def health_check(request):
    return HttpResponse(status=200)
