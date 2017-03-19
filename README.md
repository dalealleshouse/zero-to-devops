# Zero to DevOps in Under an Hour with Kubernetes 

This repo contains the code presented in the talk. Slides available [here](http://slides.com/dalealleshouse/kube)

## Abstract

The benefits of containerization cannot be overstated. Tools like Docker have
made working with containers easy, efficient, and even enjoyable. However,
management at scale is still a considerable task. That's why there's Kubernetes.
Come see how easy it is to create a manageable container environment. Live on
stage (demo gods willing) you'll witness a full Kubernetes configuration. In
less than an hour, we'll build an environment capable of: Automatic Binpacking,
Instant Scalability, Self-healing, Rolling Deployments, and Service
Discovery/Load Balancing.

## Prerequisites

1) [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
1) [Docker](https://www.docker.com/community-edition)
1) [kubectl](https://kubernetes.io/docs/tasks/kubectl/install/)
1) [Minikube](https://github.com/kubernetes/minikube)

The demo should work fine on Mac OS or Linux. However, it hasn't been tested. I used a Windows 10 machine and Powershell, which required  special minikube configuration. It's doubtful that this will work on older windows machines. However, if you are able to get it working, add information about your experince and I'll happily accept a pull request.

Special Windows 10 minikube configuration:

- Configure HyperV (If you are able to run Docker, it should be)
- Create a Virtual Switch in Hyper-V:
  - Open Hyper-V Manager
  - Select Virtual Switch Manager
  - Select the "Internal" switch type
  - Click the "Create Virutal Switch" button
  - Name the switch "minikube"
  - Close Virtual Switch Manager and Hyper-V Manager
- Expose the Virtual Switch
    - Click the Windows Button and type "View Network Connection" and it
    - Right click on your network connection and select "Properties"
    - On the Sharing Tab, Select "Allow other network users to connect through .."
    - Select "vEthernet (minikube)" from the drop down list
    - Click OK and close Network Connections
- Path minikube
    - Download [minikube exe](https://storage.googleapis.com/minikube/releases/v0.17.1/minikube-windows-amd64.exe) for windows
    - Save the file in an easily accessible path
    - Modify your powershell profile by adding "New-Alias minikube **PATH-TO-MINIKUBE-EXE**" (Alternativly, you can just type this in the command prompt everytime you use minikube)


## Preparing the Demo

Start minikube

New-Alias minikube C:\tools\minikube\minikube-windows-amd64.exe

Unable to connect to the server: dial tcp [fe80::215:5dff:fec8:5c07]:8443: connectex: No connection could be made because the target machine actively refused it.

https://github.com/kubernetes/minikube/issues/754#issuecomment-258129252

``` powershell
minikube --vm-driver=[OS-DEPENDANT] --hyperv-virtual-switch=minikube start
```

Clone this project

``` powershell
git clone https://github.com/dalealleshouse/zero-to-devops.git
```

Install Minikube
[https://github.com/kubernetes/minikube](https://github.com/kubernetes/minikube)

Build all Docker images and place them in a local registry

``` powershell
docker run -d -p 5000:5000 --restart=always --name registry registry:2.6

docker build --file=html-frontend/Dockerfile --tag=localhost:5000/html-frontend
docker push localhost:5000/html-frontend
```