export DOCKER_DEFAULT_PLATFORM=linux/amd64
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin ${mi_numero_aws}.dkr.ecr.us-west-2.amazonaws.com
docker build -t mi_imagen .
docker tag mi_imagen:latest ${mi_numero_aws}.dkr.ecr.us-west-2.amazonaws.com/mi_imagen:latest
docker push ${mi_numero_aws}.dkr.ecr.us-west-2.amazonaws.com/mi_imagen:latest