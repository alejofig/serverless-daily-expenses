Prerrequisitos:
1. Tener un dominio en Route53 
2. Tener Docker.
3. Tener AWS CLI configurado.
4. Crear unas credenciales en la consola de gcp para enviar los datos a sheets.
5. Crear un repositorio en ECR y copiar los comandos de envío en build-image.sh
6. Activar el modelo de Bedrock titan-text-express-v1 desde la consola de aws
7. Subir la imagen a ECR
8. Crear hoja de calculo y compartirla con el client_email
9. Cambiar las variables de entorno de la hoja de calculo y la hoja de trabajo en main.tf