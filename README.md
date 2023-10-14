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
- Use act to run Github Actions locally: (install it: https://github.com/nektos/act) # linux/arm64 for better performance with M chips - uncompatibilities may arise
- act --list --container-architecture linux/amd64
- act -W .github/workflows/ci-check.yaml --container-architecture linux/amd64
- act -j unit-tests --container-architecture linux/amd64
- act -j build-test -s SNYK_TOKEN --container-architecture linux/amd64
- act -j build -s DOCKERHUB_USERNAME -s DOCKERHUB_TOKEN -s GITHUB_TOKEN --container-architecture linux/amd64

## Documentation exercise 2 - Kubernetes
- Using Kubernetes builtin on top of Docker Desktop (k3s, minikube or kind are other possibilities)
- Developers need to install kubectl and helm
- Helm wrapper has been created using `helm init` and removing to have only the minimum required configuration.
We only use helm to set a strict separation of config from code, so we can build once and deploy many - https://12factor.net/
- We deploy new versions using rolling updates (allow Deployments' update to take place with zero downtime by incrementally updating Pods instances with new ones).
- For pod security we [restrict escalation and root privileges](https://learn.microsoft.com/en-us/azure/aks/developer-best-practices-pod-security)
- For high availability we use initially affinities on pods: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#more-practical-use-cases
Allocating replicas among different nodes with soft antiAffinity on lower environments.
```yaml
  preferredDuringSchedulingIgnoredDuringExecution:
  ...
    topologyKey: "kubernetes.io/hostname"
```
and among different [region](https://kubernetes.io/docs/reference/labels-annotations-taints/#topologykubernetesioregion), zones and nodes with hard antiAffinity on higher environments.
```yaml
  requiredDuringSchedulingIgnoredDuringExecution:
  ...
    topologyKey: "kubernetes.io/hostname"
    topologyKey: "topology.kubernetes.io/region"
    topologyKey: "topology.kubernetes.io/zone"
```
 At scale, however, I would analyze each application/component use case and evaluate the use of topology-spread-constraint to a more granular control of the availability: https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/

- For scalability we use horizontal pod autoscaler with metrics server: https://github.com/kubernetes-sigs/metrics-server

- Deploy to dev:
```bash
helm template ./ops/charts -f ./ops/charts/env/dev/values.yaml --set imageTag=`(git rev-parse HEAD)`
```