# Zero to DevOps in Under an Hour with Kubernetes 

This repo contains the demo code presented in the Zero to DevOps talk. Slides
available [here](http://slides.com/dalealleshouse/kube)

## Abstract

The benefits of containerization cannot be overstated. Tools like Docker have
made working with containers easy, efficient, and even enjoyable. However,
management at scale is still a considerable task. That's why there's Kubernetes
(K8S).  Come see how easy it is to create a manageable container environment.
Live on stage (demo gods willing), you'll witness a full K8S configuration. In
less than an hour, we'll build an environment capable of: Automatic Binpacking,
Instant Scalability, Self-healing, Rolling Deployments, and Service
Discovery/Load Balancing.

## Prerequisites

All of the following software must be installed in order to run this demo.

1) [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
1) [Docker](https://www.docker.com/community-edition)
1) [kubectl](https://kubernetes.io/docs/tasks/kubectl/install/)

## Clone the Repo

Although it most likely goes without saying, the first thing you need to do is
clone this repo.

``` powershell
git clone https://github.com/dalealleshouse/zero-to-devops.git
```

## Kubernetes Cluster

In order to run the demo, you must have a K8S cluster. Creating a cluster is
easy with all three of the major cloud providers.

- [Google Cloud](https://cloud.google.com/container-engine/docs/quickstart)
- [Azure](https://docs.microsoft.com/en-us/azure/container-service/container-service-kubernetes-walkthrough)
- [Amazon](https://kubernetes.io/docs/getting-started-guides/aws/)

There are also many other options for running virtually anywhere, including on
premise: [Kubernetes](https://kubernetes.io/docs/getting-started-guides/)

The demo utilizes [Minikube](https://github.com/kubernetes/minikube) as a
lightweight option for demo purposes only.

## Minikube

[Minikube](https://github.com/kubernetes/minikube) is a single-node K8S cluster
that runs inside a virtual machine intended for development use and testing
only. It's a great option for presentations (like this one) because it provides
a means to work with K8S locally without an internet connection. Yes, believe
it or not, internet connectivity is a bit capricious at conferences and meet
ups.

The demo should work fine on Mac or Linux. However, it hasn't been tested. I
used a Windows 10 machine and Powershell, which required  special minikube
configuration. It's doubtful that this will work on older windows machines at
all.  However, if you are able to get it working, add information about your
experience and I'll happily accept a pull request.

Special Windows 10 minikube configuration:

- Configure HyperV (If you are able to run Docker, it should be)
- Create a Virtual Switch in Hyper-V:
  - Open Hyper-V Manager Select Virtual Switch Manager
  - Select the "Internal" switch type
  - Click the "Create Virtual Switch" button
  - Name the switch "minikube"
  - Close Virtual Switch Manager and Hyper-V Manager
- Expose the Virtual Switch
  - Click the Windows Button and type "View Network Connection", open it
  - Right click on your network connection and select "Properties"
  - On the Sharing Tab, Select "Allow other network users to connect through ..."
  - Select "vEthernet (minikube)" from the drop down list
  - Click OK and close Network Connections
- Path minikube
  - Download [minikube](https://storage.googleapis.com/minikube/releases/v0.17.1/minikube-windows-amd64.exe) for windows
  - Save the file in an easily accessible path
  - Run the command below

``` powershell
# add this to your profile to make it permanent
New-Alias minikube *PATH-TO-MINIKUBE-EXE* 
```

Start minikube which will automatically configure kubectl. This requires
opening Powershell in administration mode.

``` powershell
minikube --vm-driver=hyperv --hyperv-virtual-switch=minikube start 
```

Verify everything is configured correctly with the following command.

``` powershell 
kubectl get cs
```

It should produce output such as the following:

``` powershell
NAME                 STATUS    MESSAGE              ERROR
controller-manager   Healthy   ok
scheduler            Healthy   ok
etcd-0               Healthy   {"health": "true"}
```
## Minikube Ingress

Applications running in K8S are *firewalled* from external traffic by default.
In order to make them externally accessible, it is necessary to expose them
using services.  Most cloud providers offer a convenient means of connecting an
external load balancer with a static IP to a service. However, this isn't an
option with Minikube.  Without this convince, the demo is relegated to exposing
services via node ports. In order to map the node ports to an address that will
not change, we are going to use an Ingress. An ingress is a set of rules that
allow inbound connections to reach K8S services.

First, enable the Minikube ingress addon with the following command.

``` powershell
minikube addons open ingress
```

This creates an NGINX ingress controller. Next, create the K8S ingress object
that contains all the ingress rules. Use the following command.

``` powershell
kubectl create -f *PATH_TO_INGRESS.YML*
```

The ingress.yml file is located in the kube directory of this project. Verify
the ingress was created correctly with the following command.

``` powershell
kubectl describe ing
```

The ingress is expecting traffic from demo.com and status.demo.com. In order to
route traffic accordingly, you will need to update your hosts file. First
obtain the Minikube IP address.

``` powershell
minikube ip
```

Add these entries to your hosts file:

```
*MINIKUBE_IP* demo.com
*MINIKUBE_IP* status.demo.com
```

Make sure to remove these after the demo in case you ever want to visit the
actual demo.com website.

## Image Registry

Ideally, all images should reside in a private registry. This isn't a viable
option for the demo because reliable internet access isn't guaranteed. It is
possible to create a local docker registry but the complexity surrounding
security distracts from the demo's purpose. Therefore, the commands below build
all containers using the docker daemon on the minikube machine. If you are
trying to reproduce the demo, I recommend using docker hub (or something
equivalent), pushing images there, and allowing Kubernetes to pull them.

``` powershell
git clone https://github.com/dalealleshouse/zero-to-devops.git
cd zero-to-devops

# point to the docker daemon on the minikube machine 
# eval $(minikube docker-env) on Mac/Linux 
& minikube docker-env | Invoke-Expression

docker build --tag=html-frontend:1.0 html-frontend/
docker build --tag=java-consumer:1.0 java-consumer/ 
docker build --tag=ruby-producer:1.0 ruby-producer/
docker build --tag=status-api:1.0 status-api/
docker pull rabbitmq:3.6.6-management

# point to the local docker daemon
# eval $(minikube docker-env -u) on Mac/Linux 
& minikube docker-env -u | Invoke-Expression
```

## Demo

With all the requisite setup out of the way, it's time to start the actual
demo.  The image below outlines the system we are going to host on K8S.

![Demo System](/demo-sys.PNG)

The demo system consists of five separate applications that work together.

1. NGINX serves a static HTML file to a browser
1. ASP.NET Core REST API accepts requests from the browser and returns queue
   stats
1. RabbitMQ is configured as a standard work queue
1. Ruby Producer pushes a message with a random number on the queue every
   second
1. Java Consumer pulls messages from the queue one at a time and generates
   Fibonacci numbers in order to simulate CPU bound work

The first thing to do is get each Dockerized application running in K8s. For
this, we'll create deployments. K8S deployments package *pods* and *replica
sets*. A pod is one or more containers that share context and act as a single
autonomous unit. Aptly named, replica sets specify the number of desired
replicas.

``` powershell
kubectl run html-frontend --image=html-frontend:1.0 --port=80
kubectl run java-consumer --image=java-consumer:1.0
kubectl run ruby-producer --image=ruby-producer:1.0
kubectl run status-api --image=status-api:1.0 port=5000
kubectl run queue --image=rabbitmq:3.6.6-management
```

Verify the objects were created correctly with the following command.

``` powershell
kubectl get deployments
kubectl get pods
kubectl get rs
```

Each pod represents a Docker container running somewhere on the K8S cluster.
kubectrl mirrors several Docker commands so the pods can be manipulated
directly. For instance, you can obtain direct access to a pod with an exec
command or view the output from stdout using a log command.

``` powershell
kubectl exec -it *POD_NAME* bash
kubectl logs *POD_NAME*
```

If you view the logs of the ruby producer, you will notice that it unable to
connect to the queue. This is because by default, pods are exposed via an IP
address that may change. A K8S service provides a durable address that will
route traffic to the specified pods. The command below create a service that
exposes ports for the queue pod.

``` powershell
kubectl expose deployment queue --port=15672,5672 --name=queue
```

Now, if you view the logs from the ruby producer, you should see that it
connected the queue and is sending messages. The underlying pod can change,
containers can be created, destroyed, moved to different nodes and the service
will be able to route traffic to them.

With the queue in place, we still need to expose the nginx and status-api pods
to external traffic


``` powershell
kubectl expose deployment html-frontend --port=80 --name=html-frontend --type=NodePort
kubectl expose deployment status-api --port=80 --target-port=5000 --name=status-api --type=NodePort
```

Ignore everything under this line...

----------------------
Now we can scale
kubectl scale deployment html-frontend --replicas=3

The replica set will watch the pods and keep them running.

docker ps --filter name=html-frontend
docker rm -f *CONTAINER*
docker ps --filter name=html-frontend

See how machine name changes

Before beginning, as explained above, you should have a kubernetes cluster
running and kubectl configured to point to it. Additionally, all the five
container images should either be locally available on your cluster or the
cluster should have access to download them.

kubectl set image deployment/html-frontend html-frontend=html-frontend:2.0
kubectl scale deployment java-consumer --replicas=10

kubectl config use-context minikube

minikube addons enable heapster
minikube addons open heapster


1. High level overview of Kubernetes
    - Node layout
    - Master Nodes
    - Services Running On Each Node
    - Scheduler
        - Binpacking
1. Demo
    - Deployments
        - Health Checks
        - Rolling Deployments
    - Services
        - External
        - Internal
    - Auto Scaling
    - Monitoring
