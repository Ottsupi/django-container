import logging

from django.http import HttpRequest, HttpResponse
from django.shortcuts import render

logger = logging.getLogger(__name__)


def index(request: HttpRequest):
    logger.debug("Accessed Hello world! view")

    message = "Hello World!"
    if request.user.is_authenticated:
        message = f"Hello {request.user.username}!"

    context = {
        "message": message,
    }

    return render(request, "apps/app/home.html", context)


def health_check():
    return HttpResponse(status=200)
