# ProyectoDevsu despliegue CI/CD 

### INTRODUCCION

Este laboratorio consiste en el despliegue de una aplicacion (API) desde forma local hasta llevarlo a un ambiente orquestizado de kubernetes. Por lo cual este proyecto se divide en 3 etapas las cuales son: Construccion del dockerfile de la applicacion (API), construccion del pipeline en Jenkins y despliegue de la aplicacion en un entorno de kubernetes. Todos los codigos desarollados se encuentran en el presente repositorio de github (https://github.com/Moonlight15-fireandlight/demoproject.git).

## Construccion del dockerfile

Para este paso se tuvo que realizar el despliegue en la maquina local del api. Para esto se creo una virtual enviromente (venv) donde se instalo el django y las librerias necesarias. No se realizo ningun cambio al codigo de la aplicacion compartida. Una vez adecuado el codigo se deplega localmente para ver que este funcionando correctamente, para esto ejecutamos el scripts de preubas compartidos :

~~~
python manage.py test api.tests
~~~

La cual se obtiene un resultado correcto:

![Testcodepreubas](/images/Evidencia01.PNG)

Además se agrego dos usuarios de prueba a la api (PAUL y Jeffrey):

![Usuariosadd](/images/Evidencia02.PNG)

Para generar el archivo con las librerias necesarias se utilizo el siguiente comando:

~~~
pip freeze > requirements.txt
~~~

El archivo dockerfile generado es:

~~~
#FROM python:3.12.2-alpine

FROM python:3.12.2-slim-bullseye

ENV PYTHONDONTWRITEBYTECODE 1

ENV PYTHONUNBUFFERED 1

WORKDIR /app

ADD . /app

RUN pip install --upgrade pip

RUN pip --no-cache-dir install -r requirements.txt

EXPOSE 8000

CMD ["python", "manage.py", "runserver"]

~~~ 

Se utilizo la imagen **python:3.12.2-slim-bullseye**, ya que presento un mejor desempeño y tamaño que otras semejantes (**Alpine**). Se declararon dos variables de entorno pertenecientes a las caracteristicas propias de django. Como se observa se guardara todos los archivos desarollados en la carpeta **app** del contenedor. La instalacion de los requerimientos se utiliza con --no-cache-dir para reducir el tamaño, luego se expone por el puerto 8000 y finalmente se declara como comando de ejecucion, para la mayoria de proyecto django, **python manage.py runserver**. La imagen presenta un tamaño entre 150 y 160 MB.

Una vez generado la imagen se creo el contenedor y verificar los logs de este, se ejecuto el siguiente comando para su creacion:

~~~
docker run -d -p 8000:8000 --name devsuapi devsuapi:latest
~~~

Luego verificamos los logs de este y comprobar que no exista un error 

![dockerlogs](/images/Evidencia03.PNG)

Una vez comprobado que el contenedor y su imagen estan funcionando correctamente, se procede a la construccion del pipeline para su automatizacion.

## Construccion del pipeline

Se desplego una maquina virtual (EC2) donde se instalo Jenkins y docker. Las etapas (stages) del pipeline desplegado se crearon principalmente con el objetivo de construir la image y almacenar en un entorno o repositorio seguri o en este caso se utilizo el servicio ECR (AWS). A continuacion se presenta un diagrama que resume las acciones a realizar en Jenkins.

![DiagramaJenkins](/images/Evidencia04.png)

OBSERVACIONES:

- Se requiere crear un rol de IAM con los siguientes permisos: **AmazonEC2ContainerRegistryFullAccess** y **AmazonElasticContainerRegistryPublicFullAccess**, luego se asigna a la instancia donde corre el Jenkins. Esto permite que el servidor Jenkins pueda acceder o ejecutar acciones sobre el recurso de ECR (repositorio) de su cuenta.

-  Se requiere instalar los siguientes plugins: Docker, Docker pipelines y Kubernetes. 

STAGES:

- **Loggin into AWS ECR** : Para que Amazon reconozca los permisos necesarion para ejecutar las siguientes acciones.

- **Code Build (Checkout)** : Declara el repositorio de github donde se extraera el dockerfile.

- **Docker Build Image** : Construccion de la imagen (docker build) mediante el dockerfile extraido.

- **Docker Push to ECR** : Almacena la imagen en un repositorio privado de AWS.

A continuacion, se adjunta imagenes de la ejecucion del job junto con el log :

![JobsEjecucion](/images/Evidencia05.PNG)

Los logs se adjunta en un archivo txt para su observacion.(logsjenkins.txt)

## DESPLIEGUE EN KUBERNETES

En esta ultima etapa se realiza la creación del cluster en kubernetes y nuestra aplicacion es desplegada en este entorno orquestado. 
Para minimizar costos en cuanto a maquinas virtuales para el despliegue del cluster, se utilizó la herramienta minikube en lugar de un entorno controlado como EKS o un despliegue mediante KUBEADM (donse se requiere como minimo 2 instancias EC2 medium). A continuacion se muestra una pequeña arquitectura del cluster en el ambiente de AWS.

![Arquitecturaminikube](/images/Evidencia06.png)

### Pasos para la creacion del cluster en minikube

~~~
1. Instalar docker en ubuntu 20.0 LTS (https://docs.docker.com/engine/install/ubuntu/)

2. Instalar minikube (https://minikube.sigs.k8s.io/docs/start/)

- curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

- sudo install minikube-linux-amd64 /usr/local/bin/minikube

3. Instalar kubectl

- curl -LO https://dl.k8s.io/release/v1.28.7/bin/linux/amd64/kubectl

- curl -LO "https://dl.k8s.io/release/v1.28.7/bin/linux/amd64/kubectl.sha256"

- echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

- sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

- kubectl version --client

4. Iniciar el minikube utilizando como driver docker

- minikube start --driver=docker 

5. Revision de la creacion correcta del cluster

- minikube status
~~~

![minikubestatus](/images/Evidencia07.PNG)

### Despliegue de la aplicacion

- Creacion del secret para jalar la imagen del repositorio (ECR)

~~~

kubectl create secret docker-registry regcred --docker-server=public.ecr.aws/g0d0u9h2/demodevsuapi --docker-username=AWS --docker-password=<password> --namespace=applications

~~~

La variable password se obtiene mediante la ejecucion del siguiente comando: 

~~~
aws ecr get-login-password --region us-west-2
~~~

![Secrets](/images/Evidencia08.PNG)

### Creacion del deployment

Para el despliegue de la API se desarolla un deployment con 2 replicas cuya imagen presenta la URI de la imagen subida al repositorio. (revisar manifiesto deployment)

~~~
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demodevsuapi
  namespace: applications
spec:
  replicas: 2
  selector:
    matchLabels:
      app: demodevsuapi
  template:
    metadata:
      labels:
        app: demodevsuapi
    spec:
      containers:
        - name: app
          image: public.ecr.aws/g0d0u9h2/demodevsuapi:latest #Image from repository ECR 
          imagePullPolicy: Always
      imagePullSecrets:
        - name: regcred
~~~

![Deployment](/images/Evidencia09.PNG)

### Despliegue mediante un servicio (nodeport)

Para exponer la aplicacion al usuario se utilizo un servicio tipo nodeport por el puerto 8000

~~~
apiVersion: v1
kind: Service
metadata:
  name: api-service
  namespace: applications
spec:
  type: NodePort
  ports:
  - port: 8000
  selector:
    app: demodevsuapi
~~~

![Sevice](/images/Evidencia10.PNG)

### Comprobar el correcto acceso al servicio

Para realizar el ingreso al cluster a la aplicacion se debe campbiar la direccion ip del resultado anterior por la ip publica del cluster, lo cual resulta a la siguiente direccion:

> https://35.165.95.231:32186/api/users/

### Observaciones:

- Se propuso instalar el ingress controller de NGINX, pero actualmente no poseo un dominio para adecuarlo como host ademas del costo adicional que resultaria comprarlo y asociarlo al AWS mediante el servicio de ROUTE 53 u otros. Ademas, el cluster de minikube es una herramienta nueva que he aprendio a manejar a partir de este laboratorio asi que me tomo algo de tiempo identificar sus diferencias . Muchas gracias

