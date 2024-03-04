#FROM python:3.12.2-alpine
#FROM python:3.9-slim-buster
FROM python:3.12.2-slim-bullseye

ENV PYTHONDONTWRITEBYTECODE 1

ENV PYTHONUNBUFFERED 1

WORKDIR /app

ADD . /app

RUN pip install --upgrade pip

RUN pip --no-cache-dir install -r requirements.txt

EXPOSE 8000

CMD ["python", "manage.py", "runserver"]

#CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]


