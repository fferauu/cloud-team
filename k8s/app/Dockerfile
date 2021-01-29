FROM python:3.9

RUN useradd appuser
USER appuser

WORKDIR /usr/src/app
COPY --chown=appuser:appuser ./my_logging_server.py .

CMD ["python", "./my_logging_server.py"]
