from django.urls import path
from .views import *
from rest_framework import routers

router = routers.DefaultRouter()
router.register('users', UserViewSet, 'users')

#urlpatterns = [
#    path('home/', views.home, name='home'),
#    path('room/', views.room, name='room')
#]

urlpatterns = router.urls