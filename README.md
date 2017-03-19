# Zero to DevOps in Under an Hour with Kubernetes 

This repo contains the code presented in the talk. Slides available
[here](http://slides.com/dalealleshouse/kube)

## Abstract

The benefits of containerization cannot be overstated. Tools like Docker have
made working with containers easy, efficient, and even enjoyable. However,
management at scale is still a considerable task. That's why there's
Kubernetes.  Come see how easy it is to create a manageable container
environment. Live on stage (demo gods willing) you'll witness a full Kubernetes
configuration. In less than an hour, we'll build an environment capable of:
Automatic Binpacking, Instant Scalability, Self-healing, Rolling Deployments,
and Service Discovery/Load Balancing.

## Prerequisites

1) [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
1) [Docker](https://www.docker.com/community-edition)
1) [kubectl](https://kubernetes.io/docs/tasks/kubectl/install/)

## Kubernetes Cluster

In order to run the demo, you must have a Kubernetes cluster and configure
kubectl to point to it. Creating a cluster is easy with all three of the major
cloud providers.

- [Google Cloud](https://cloud.google.com/container-engine/docs/quickstart)
- [Azure](https://docs.microsoft.com/en-us/azure/container-service/container-service-kubernetes-walkthrough)
- [Amazon](https://kubernetes.io/docs/getting-started-guides/aws/)

There are also many other options for running virtually anywhere, including on
premise: [Kubernetes](https://kubernetes.io/docs/getting-started-guides/)

The demo utilizes [Minikube](https://github.com/kubernetes/minikube) as a
lightweight option for presentation purposes only.

## Minikube

[Minikube](https://github.com/kubernetes/minikube) is a single-node kubernetes
cluster that runs inside a virtual machine intended for development use and
testing only. It's a great option for presentations (like this one) because it
provides a means to work with kubernetes locally without an internet
connection. Yes, believe it or not, internet connectivity is a bit capricious
at conferences and meet ups.

The demo should work fine on Mac or Linux. However, it hasn't been tested. I
used a Windows 10 machine and Powershell, which required  special minikube
configuration. It's doubtful that this will work on older windows machines.
However, if you are able to get it working, add information about your
experience and I'll happily accept a pull request.

Special Windows 10 minikube configuration:

- Configure HyperV (If you are able to run Docker, it should be)
- Create a Virtual Switch in Hyper-V:
  - Open Hyper-V Manager Select Virtual Switch Manager
  - Select the "Internal" switch type Click the "Create Virtual Switch" button
  - Name the switch "minikube" Close Virtual Switch Manager and Hyper-V Manager
- Expose the Virtual Switch
  - Click the Windows Button and type "View Network Connection", open it
  - Right click on your network connection and select "Properties"
  - On the Sharing Tab, Select "Allow other network users to connect through .."
  - Select "vEthernet (minikube)" from the drop down list Click OK and close Network Connections
- Path minikube
  - Download [minikube exe](https://storage.googleapis.com/minikube/releases/v0.17.1/minikube-windows-amd64.exe)
  - Save the file in an easily accessible path
  - Run the command below

``` powershell
New-Alias minikube *PATH-TO-MINIKUBE-EXE* 
```

Start minikube which will automatically configures kubectl. This requires
opening Powershell in administration mode.

``` powershell
minikube --vm-driver=hyperv --hyperv-virtual-switch=minikube start 
```

Verify everything is configured correctly with the following command.

``` powershell 
kubectl cluster-info 
```

It should produce output such as the following:

``` powershell
Kubernetes master is running at https://*YOUR-IP*:8443
KubeDNS is running at https://*YOUR-IP*:8443/api/v1/proxy/namespaces/kube-system/services/kube-dns
kubernetes-dashboard is running at https://*YOUR-IP*:8443/api/v1/proxy/namespaces/kube-system/services/kubernetes-dashboard
```

TODO: kubectl get cs

## Image Registry

Ideally, all images should reside in a private registry. This isn't a viable
option for the demo because reliable internet access isn't guaranteed. It is
possible to create a local docker registry but the complexity surrounding
security distracts from the demo's purpose. Therefore, the commands below build
all containers using the docker daemon on the minikube machine. If you are
trying to reproduce the demo, I recommend using docker hub (or something
equivalent), pushing images there, and allowing Kubernetes to pull them.

``` powershell git clone https://github.com/dalealleshouse/zero-to-devops.git
cd zero-to-devops

# point to the docker daemon on the minikube machine # eval $(minikube
docker-env) on Mac/Linux & minikube docker-env | Invoke-Expression

docker build --tag=html-frontend:1.0 html-frontend/ docker build
--tag=java-consumer:1.0 java-consumer/ docker build --tag=ruby-producer:1.0
ruby-producer/ docker build --tag=status-api:1.0 status-api/ docker pull
rabbitmq:3.6.6-management

# point to the local docker daemon # eval $(minikube docker-env -u) on
Mac/Linux & minikube docker-env -u | Invoke-Expression ```

## Demo

Before beginning, as explained above, you should have a kubernetes cluster
running and kubectl configured to point to it. Additionally, all the five
container images should either be locally available on your cluster or the
cluster should have access to download them.
