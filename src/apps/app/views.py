import logging

from django.http import HttpResponse
from django.shortcuts import render

logger = logging.getLogger(__name__)


def index(request):
    logger.debug("Accessed Hello world! view")
    return HttpResponse("Hello world!")
