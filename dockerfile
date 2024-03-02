FROM 3.12-alpine

WORKDIR /app

COPY . /app

RUN pip install --upgrade pip

RUN pip --no-cache-dir install -r requirements.txt

EXPOSE 8000

CMD [python, manage.py, runserver]


