# Usa la imagen de AWS Lambda Python 3.9 como base
FROM public.ecr.aws/lambda/python:3.9

# Copia el contenido de tu función Lambda al directorio de trabajo (/var/task)
COPY . /var/task

# Instala los requisitos de la función Lambda
RUN pip install -r /var/task/requirements.txt

# Configura el punto de entrada para la función Lambda
CMD ["main.lambda_handler"]
