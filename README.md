# SRE DevOps Challenge
The goal of this technical exercise is to transform the attached docker compose file into a
K8S infrastructure. The project is a simple NextJS app that tracks user visits in a RedisDB. 
Our developers have created the following docker-compose.yml file:

```yaml
version: '2'
services: 
  app:
    build:
      context: .
      target: dev
    ports:
      - '3000:3000'
    volumes:
      - './app:/app/app'
      - './public:/app/public'
    links:
      - db
    environment:
      - REDIS_HOST=db
      - REDIS_PORT=6379
  db:
    image: 'redis'
```

The have been very keen to provide a multistage dockerfile with `runner` target that generates our prod build.

This app uses needs the following env vars to configure redis connection:

- REDIS_HOST: Host of the redis instance
- REDIS_PORT: Port of the redis instance
- REDIS_USERNAME: Redis instance username
- REDIS_PASSWORD: Redis instance password

## Exercise 1 - Pipelines

We need to generate the pipelines that build and publish the project image. Please provide scripts, github action or gitlab pipelines that build the image and publish it to the registry (feel free to use any public docker image registry of your choice).

## Exercise 2 - Kubernetes

We want to deploy this project to our K8S cluster. Please provide scripts, kubernetes manifest or helm charts that create the needed infrastructure. We use GKE but in this case feel free to use any locally hosted cluster (minikube, kind, etc..).
Write it as this was a real world production project, so keep into account things like High Avaliability, Autoscalling, Security, etc...

## Exercise 3 - Docs

Last but not least, please write a meaninful documentation of your design choices and how a developer can deploy the project.


## Documentation exercise 1 - Pipelines
- Use Github Actions
- Use act to run Github Actions locally: (install it: https://github.com/nektos/act) # linux/arm64 for M chips
  - act --list --container-architecture linux/amd64
  - act -j test --container-architecture linux/amd64
  - act -j build -s DOCKERHUB_USERNAME -s DOCKERHUB_TOKEN -s GITHUB_TOKEN --container-architecture linux/amd64