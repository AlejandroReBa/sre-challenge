# SRE DevOps Challenge - Solution Proposal

## Environment Setup
- Mac M2
- [Iterm2](https://iterm2.com/), ZSH and [ohmyzsh](https://ohmyz.sh/)
- [Visual Studio Code](https://code.visualstudio.com/)


## Tools
- [Github](https://github.com/)
- [Github Actions](https://github.com/features/actions)
- [Docker Hub Registry](https://hub.docker.com/)
- [Snyk](https://snyk.io/)
- [Act](https://github.com/nektos/act)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Docker, Kubernetes)
- [Kubectl](https://kubernetes.io/es/docs/reference/kubectl/)
- [Helm](https://helm.sh/)

## Accounts
To run this project is required
- Github
- Dockerhub registry
- Snyk

## Exercise 1 - Pipelines
- CI pipelines have been implemented using Github Actions

- To develop and test the workflow before pushing changes I used [act](https://github.com/nektos/act) to run Github Actions locally: 
```bash
# https://github.com/nektos/act
brew install act
```

### CI Environment Variables&Secrets
They are exposed as environment variables on local, while stored as secrets on Github
```bash
- $GITHUB_TOKEN
- $DOCKERHUB_USERNAME
- $DOCKERHUB_TOKEN
- $SNYK_TOKEN
```

### Most used act commands
```bash
act --list
act -W .github/workflows/ci-check.yaml --container-architecture linux/amd64 -s SNYK_TOKEN
act -j build --container-architecture linux/amd64  -s DOCKERHUB_USERNAME -s DOCKERHUB_TOKEN -s GITHUB_TOKEN
```

### CI structure
I delivered two workflows:   
1. [ci-check](.github/workflows/ci-check.yaml) - verify the status of the changes: unit-tests, build-test and vulnerability test of the Docker image. Triggered on push to any branch (but the trunk branch) and PR against the trunk branch.
2. [ci-build](.github/workflows/ci-build.yaml) - build and publish the image to Docker Hub. Triggered on push to the trunk branch.


## Exercise 2 - Kubernetes
- The migration from docker-compose to Kubernetes has been implemented using Docker Desktop.
```bash
brew install --cask docker
brew install kubernetes-cli
brew install helm
```
- We only use helm to set a strict separation of config from code, so we can build once and deploy many - https://12factor.net/


### High Availability

#### Rolling updates
- I deploy new versions using rolling updates (allow Deployments' update to take place with zero downtime by incrementally updating Pods instances with new ones).

#### Affinities
- I set [affinities](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#more-practical-use-cases) on pods: 
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
 - At scale, however, I would analyze each application/component use case and evaluate the use of [topology-spread-constraint](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/) to a more granular control of the availability.

#### Redis - Applicable to databases, event messages/broker queues or similar
- For redis on development environment we use a deployment single-node, but for production we have several choices
  - My recommendation for DDBB is to use a SaaS/DBaaS approach. For Redis, in example, we have the [DBaaS Enterprise Cloud Service](https://redis.com/redis-enterprise/advantages/) so Ops/SRE don't need to guarantee the performance, high availability, geodistribution, disaster recovery, security, etc. There are also alternatives on top of Redis (API compliance) as [Dragonfly](https://www.dragonflydb.io/)
  - Previous to have a builtin Redis on Kubernetes on production, we need to analyze the use case to decide whether Redis Sentinel or Redis Cluster is the best choice, and also compare helm charts possibilities as the one from [bitnami](https://github.com/bitnami/charts/tree/main/bitnami/redis-cluster). For this exercise I have used this helm chart (redis-cluster-9.0.12) as reference 
  ```bash
  helm template oci://registry-1.docker.io/bitnamicharts/redis-cluster
  ```
  so I set a statefulset cluster with many nodes.

#### Backup and disaster recovery
- Even when we are deployed in multiple zones or regions, there are many incidences that can affect our applications and data.
For this application, componentes are backed on github as we didn't apply manual configurations, but the data stored on persistent volumes is different.   
 The PV (persistent volume) disk attached to pods can be backed up using several tools, as [Velero](https://velero.io/) which provides support for **Disaster Recovery**, Data Migration and Data Protection.

### Scalability - autoscalling

#### Infrastructure
For Cloud Vendors Offering, like Google Kubernetes Engine, I would enable a few nodepools for different purposes (as bigger projects that may need bigger VMs typologies or compute proccesses that need to run on a dedicated nodepools to don't affect other workloads) with autoscaling on. The specific use of each nodepool can be controlled with node selectors, taints and tolerances.

#### Visit tracker app
For scalability in visit-tracker-app app I used an horizontal pod autoscaler (HPA) with [metrics server](https://github.com/kubernetes-sigs/metrics-server)
 To test the performance of the HPA with our API I used a busy box image
```yaml
kubectl run -i --tty load-generator --rm --image=busybox:1.28 --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://visit-tracker-app-svc.sre-challenge.svc; done"
```

#### Redis
For Redis on cluster mode, if we really need to to be very elastics (high or low peaks) I would evaluate the SaaS/DBaaS approach. If the the average and mean are good, we may evaluate a Vertical Pod Autoscaler (VPA) approach after specified a fixed number of nodes. Apparently, when we scale out the redis cluster, it won't rebalance/reshard the currend data, which is very problematic.


### Cost optimization - expense control while maintaining performance and reliability.
There are many approaches on this huge topic, as this also implies to spend time and effort from people resources that are expensive. Some of my main advises are:
- Implementing Granular Resource Tagging
- Utilizing Alerts and Thresholds for Cost Anomalies
- Leverage Kubernetes Cost Monitoring Tools

You can start cheap with open-source tools as [OpenCost](https://opensource.com/article/23/3/kubernetes-cloud-cost-monitoring)


### Security
#### Container images
- Taking for granted that the code itself is being evaluated using at least Dinamyc/Static security Testing tools, the container environment can't be least. 
I added a Snyk scan on the ci-check Github Actions Workflow as demo purposes, where you may see minor and medium incidents.

#### Pods and service accounts
- For pod security I [restricted escalation and root privileges](https://learn.microsoft.com/en-us/azure/aks/developer-best-practices-pod-security)
- Secure service accounts with Role-Based Access Control (RBAC) and network policies

#### Networking
- Services Meshes are complex, but provide features as handling mTLS communication between microservices and authentication and authorization.

#### Secrets Management
- We must always use a Vault to store our credentials, never written down on code within our repositories.   
If we directly use Kubernetes Secrets implies that we will push sensitive data into the repository (insecure) or that we have applied those changes manually (not repetable deployments).   
The solution is to use Vaults and synchronize any sensitive data from there, where IAM (Identity and Access Management) controls are in placed and secrets can be rotated from a single source of truth.   
The technology I recommend is [external secrets](https://external-secrets.io/), which supports all main providers (AWS Secrets Manager, Azure Key Vault, Google Cloud Secret Manager, HashiCorp Vault, 1Password, etc.) reusing the same kubernetes objects for synchronizing those secrets. Kubernetes Operators, or a dedicated team, would need to manage the secret store middle layer.

  On [ops/core-layer/](ops/core-layer) I created as reference (it's commented out) what is neccesary to put it into action. The ideal combination is to use the Vault Service from the Cloud Provider where the Managed Kubernetes Service is deployed to avoid the setup of service account credentials directly into Kubernetes. In example, for Google Kubernetes Engine (GKE) and Google Certificate Manager you can use Workload Identity Service Accounts.


### Deployments

#### GitOps
I recommend the use of **GitOps**, so we embrace a pull approach and keep (almost) the whole state and evolution of deployments into a Kubernetes Cluster in a git repository.   
This is also more secure as the CI/CD tool is decoupled from the infrastructure where components are deployed (you don't need to touch the firewall).
 One of the tools I recommends is [Flux2](https://fluxcd.io/). The installation, configuration and implementation of the continuos delivery/deployment using a git repo with the changes pushed by a GitHub Action is outside of the scope of this project.

### Expose the application - Public access
At the end, our application need to be reachable from the final user. There are several approaches:
- Use a Service of type LoadBalancer (a real load balancer will be allocated by the Cloud Controller Manager or using MetalLB in onpremise deployments)
- Kubernetes Ingress (several implementations flavours as Ngnix, HaProxy, Traefik, etc)
- Kubernetes Gateway
- Service Mesh (as Istio or Linkerd)

I recommend to use the most simple tool which fulfil your short and mid term requirements.
For this project, the pick is Ingress with the default [Nginx](https://kubernetes.github.io/ingress-nginx/deploy/#quick-start) implementation. I created:
- Ingress Controller
- Ingress Kubernetes Object, which is similar to a configuration file from a Nginx or Apache Server Reverse Proxy
- Services binded to the deployments

For Kubernetes Services from Cloud vendors, I recommend to install [Cert Manager](https://cert-manager.io/docs/tutorials/acme/nginx-ingress/) to expose our services throught a TLS endpoint signed by a legit certificate granted by Let's Encrypt (free).


## Disclaimer
- I had to add the sharp package to the OCI image so the container generated through the runner target can start on production, running on NextJS standalone mode. Apparently, the code uses

```javascript
import Image from "next/image";
```
That have [Built-In Image Optimization](https://nextjs.org/docs/messages/install-sharp#why-this-error-occurred), and the error wasn't thrown in dev: https://nextjs.org/docs/messages/sharp-missing-in-production
- I added a dummy test with Jest for POC purposes, so I was able to run it as a step from the ci-check GH action workflow. That's not a reference of a real unit test.




## Exercise 3 - Docs

### Development & Installation
Once you clone this repository, you only need to set your environment variables and active your kubecontext to start the work.
I provided a [Makefile](./Makefile) to build and deploy the application (make, act, kubectl and helm are required)

```bash
make help

  help:
  ci-check: 
  ci-build: 
  ci-deploy-core-layer:
  ci-deploy:
  ci-deploy-local:
  ci-deploy-dev:
  ci-deploy-stage:
  ci-deploy-prod:
```

- Only the first time
```bash
make ci-deploy-core-layer
```

- Deploy to local - no publishing the image on Docker Hub
```bash
make ci-check
make ci-deploy-local
```

- Deploy to dev - using one of the commits from the trunk branch
```bash
make ci-deploy-dev
```

- Deploy to dev - publishing the image on Docker Hub
```bash
make ci-build
make ci-deploy-dev
```

As you won't use the same DockerHub organisation, when you want to deploy to `dev` instead of `local` using a new version, you will have to override my registry url
```yaml
registry:
  url: alejandroreba
# imagePullSecretKey: ''
```
with your registry url. In the case the pull access is restricted, you will have to create a docker-registry secret and reference it on `imagePullSecretKey` value.