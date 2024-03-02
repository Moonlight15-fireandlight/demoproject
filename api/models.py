from django.db import models

# Create your models here.

class User(models.Model):
    dni = models.CharField(max_length=13, unique=True)
    name = models.CharField(max_length=30)

    def __str__(self):
        return self.name
    