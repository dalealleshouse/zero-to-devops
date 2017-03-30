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

- Enable HyperV (If you are able to run Docker, it should be)
- Create a Virtual Switch in Hyper-V:
  - Open Hyper-V Manager
  - Select Virtual Switch Manager
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
## Ingress

The demo employs an [ingress](https://kubernetes.io/docs/user-guide/ingress/)
to route incoming cluster traffic to desired K8S services.  The terms *service*
and *pod* are used frequently.  Don't worry if you don't understand these
concepts yet, they are covered in the demo.

An ingress is a set of rules that allow inbound connections to reach K8S
services. In K8S, an ingress has two components: an ingress resource and an
ingress controller. An ingress resource is a K8S object that defines routing
rules. The one used for this demo is located [here](/kube/ingress.yml). An
ingress controller is a daemon that runs as a K8S pod (similar to a container).
It is responsible for watching the ingress resource and satisfying requests to
the ingress. In short, it's special load balancer.

In typical scenarios, you may be required to supply your own ingress controller
using something like NGINX or Traefik. Minikube comes with a preconfigured NGIX
[ingress controller](https://github.com/kubernetes/minikube/tree/master/deploy/addons/ingress). Use the following command to enable it.

``` powershell
minikube addons enable ingress
```

Next, create the K8S ingress resource. Assuming you are in this project's root
directory, run the following command.

``` powershell
kubectl create -f .\kube\ingress.yml
```

Barring any errors, the command below should display information about the
ingress you just created.

``` powershell
kubectl describe ing
```

The astute reader will notice that the ingress rules are routing traffic from
demo.com and status.demo.com. For demo purposes, we are going to update our
hosts file to map those domains to the IP address of the cluster. The command
below will reveal the Minikube address.

``` powershell
minikube ip
```

Add the entries below to your hosts file. Make sure to use the IP address from
the above command. In case you need it, here are instructing for updating the
hosts file on
[windows](https://support.rackspace.com/how-to/modify-your-hosts-file/) and
[mac](http://www.imore.com/how-edit-your-macs-hosts-file-and-why-you-would-want)


```
*MINIKUBE_IP* demo.com
*MINIKUBE_IP* status.demo.com
```

Make sure to remove these after the demo in case you ever want to visit the
actual demo.com website.

## Image Registry

Using an external Docker registry isn't a viable option for the demo because
internet access isn't guaranteed. It is possible to create a local docker
registry but the complexity surrounding security distracts from the purpose.
Therefore, we are going to manually build (in advance) the demo containers
using Minikube's docker daemon. With the containers already available locally,
K8S will not attempt to download them. Navigate to the project directory and
run the commands below.

``` powershell
# point to the docker daemon on the minikube machine 
# eval $(minikube docker-env) on Mac/Linux 
& minikube docker-env | Invoke-Expression

docker build --tag=html-frontend:1.0 html-frontend/
docker build --tag=html-frontend:2.0 html-frontend-err/
docker build --tag=java-consumer:1.0 java-consumer/ 
docker build --tag=ruby-producer:1.0 ruby-producer/
docker build --tag=status-api:1.0 status-api/
docker pull rabbitmq:3.6.6-management

# point back to the local docker daemon
# eval $(minikube docker-env -u) on Mac/Linux 
& minikube docker-env -u | Invoke-Expression
```

## Demo System

With all the requisite setup out of the way, it's time to start the actual
demo. The image below outlines the system we are going to host on K8S.

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
   
## Deployments

The K8S [*Pod*](https://kubernetes.io/docs/user-guide/pods/) object represents
a group of one or more containers that act as a single logical unit. The demo
consists of five individual containers that act autonomously so each *Pod* has
a single container.

A K8S [*Replica Set*](https://kubernetes.io/docs/user-guide/replicasets/)
specifies the number of desired pod replicas. K8S continually monitors *Replica
Sets* and adjusts the number of replicas accordingly.

A K8S [*Deployment*](https://kubernetes.io/docs/user-guide/deployments/) is a
higher level object that encompasses both *Pod*s and *Replica Set*s. The
commands below create *Deployment*s for each container in the demo system.

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
kubectl get rs
kubectl get pods
```

Each pod represents a container running on the K8S cluster.  kubectrl mirrors
several Docker commands. For instance, you can obtain direct access to a pod
with exec or view stdout using log.

``` powershell
kubectl exec -it *POD_NAME* bash
kubectl logs *POD_NAME*
```

## Services

Viewing the logs of the ruby producer reveals that it unable to connect to the
queue. Each pod has an IP address that is reachable inside the K8S cluster. One
could simply determine the IP address of the queue and update the ruby
producer. However, the address is ephemeral.  If the pod dies and is
regenerated the IP address will change. K8S services provide a durable endpoint
for pods. The command below creates a *Cluster IP* service and exposes ports
for the queue pod.

``` powershell
kubectl expose deployment queue --port=15672,5672 --name=queue
```

It may take a minute or two, but inspecting the logs from the ruby producer pod
should show that the service is now sending messages to the queue. *Cluster IP*
services enable inner-cluster communication.

Applications running in K8S are firewalled from external traffic by default.
This includes *Cluster IP* services.  In order to expose pods externally, it is
necessary to create either a *Node Port* or *Load Balancer* service.  As the
names imply, a *Node Port* service connects a port on the cluster to a pod and
a *Load Balancer* service connects an external load balancer to a pod. Most
cloud providers offer a convenient means of creating *Load Balancer* services.
However, this isn't an option with Minikube. Therefore, the demo employs *Node
Port* services.

The commands below create *Node Port* services for the NGINX and REST API pods. 

``` powershell
kubectl expose deployment html-frontend --port=80 --name=html-frontend --type=NodePort
kubectl expose deployment status-api --port=80 --target-port=5000 --name=status-api --type=NodePort
```

To ensure the services were created correctly, run the command below.

``` powershell
kubectl get services
```

If everything is configured correctly, navigating to demo.com will display the
page served up from the NGINX pod.

## Infrastructure as Code

Although the object creation commands introduced above are sufficient, there
are many advantages to storing infrastructure as code. Keeping system
configuration in source control makes it easy to examine and allows for instant
regeneration on different hardware. Additionally, it affords the ability to
view changes over time.  There is no down side to it. K8S supports
creating/removing/altering objects from yaml files. All the deployments and
services for this demo are in the kube project folder.

To delete every object from the demo, use the following command:

``` powershell
kubectl delete -f .\kube\
```

It's easy to recreate everything with the following command:

``` powershell
kubectl create -f .\kube\
```

The commands above also work for individual files. A single object is updated
with the following command:

``` powershell
kubectl replace -f .\kube\html-frontend.dply.yml
```

Configuration files stored in source control is the recommended way to work
with K8S.

## Scaling

Increasing the number of pod replicas on a deployment is as easy as running the
command below.

``` powershell
kubectl scale deployment html-frontend --replicas=3
```

Running this command reveals that the three requested replicas are already up
and running.

``` powershell
kubectl get pods -l run=html-frontend
```

After the service has time to register the change, it will automatically round
robin load balance requests. Notice the name of the pod on the web page changes
for every subsequent request.

## Self Healing

Replica controllers automatically add new pods when scaling up.  Likewise, they
generate a new pod when one goes down. See the commands below.

``` powershell
# point to the docker daemon on the minikube machine 
# eval $(minikube docker-env) on Mac/Linux 
& minikube docker-env | Invoke-Expression

# View the html-frontend pods
docker ps -f label=io.kubernetes.container.name=html-frontend

# Forcibly shut down container to simulate a node\pod failure
docker rm -f *CONTAINER*

# Containers are regenerated immediately
docker ps -f label=io.kubernetes.container.name=html-frontend
```



## Rolling Deployment/Rollback

``` powershell
kubectl set image deployment/html-frontend html-frontend=html-frontend:2.0
kubectl rollout status deployment/html-frontend
```

``` powershell
kubectl rollout history deployment/html-frontend

kubectl rollout history deployment/html-frontend --revision=2
```


``` powershell
kubectl rollout undo deployment/html-frontend --to-revision=2
```

## Auto Scaling

kubectl autoscale deployment nginx-deployment --min=10 --max=15 --cpu-percent=80

## Dashboard/Monitoring

## Ignore everything under this line...

```
kubectl set image deployment/html-frontend html-frontend=html-frontend:2.0
kubectl scale deployment java-consumer --replicas=10

kubectl config use-context minikube

minikube addons enable heapster
minikube addons open heapster
```

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
    - Auto Scaling
    - Monitoring
