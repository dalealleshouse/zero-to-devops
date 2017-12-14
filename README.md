# Zero to DevOps in Under an Hour with Kubernetes 

This repo contains the demo code presented in the Zero to DevOps talk. Slides
available [here](http://slides.com/dalealleshouse/kube-pi)

## Abstract

The benefits of containerization cannot be overstated. Tools like Docker have
made working with containers easy, efficient, and even enjoyable. However,
management at scale is still a considerable task. That's why there's Kubernetes
(K8S).  Come see how easy it is to create a manageable container environment.
Live on stage (demo gods willing), you'll witness a full K8S configuration on a
Raspberry Pi cluster. In less than an hour, we'll build an environment capable
of: Automatic Binpacking, Instant Scalability, Self-healing, Rolling
Deployments, and Service Discovery/Load Balancing.

## Demo System

The image below outlines the system we are going to host on K8S.

![Demo System](/demo-sys.PNG)

The demo system consists of five separate applications that work together.

1. NGINX serves a static HTML file to a browser. The page makes requests to the
   ASP.NET core REST API and displays the results.
1. ASP.NET Core REST API accepts requests from the browser and returns queue
   stats
1. RabbitMQ is configured as a standard work queue
1. Ruby Producer pushes a message with a random number on the queue every
   second
1. Java Consumer pulls messages from the queue one at a time and generates
   Fibonacci numbers in order to simulate CPU bound work

## Prerequisites

All of the following software must be installed in order to run this demo.

1) [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
1) [Docker](https://www.docker.com/community-edition)
1) [kubectl](https://kubernetes.io/docs/tasks/kubectl/install/)

## Clone the Repo

Although it most likely goes without saying, the first thing you need to do is
clone this repo.

``` bash
git clone -b pi https://github.com/dalealleshouse/zero-to-devops.git
```

## Kubernetes Cluster

In order to run the demo, you must have a working K8S cluster. Creating a
cluster is easy with all three of the major cloud providers.

- [Google Cloud](https://cloud.google.com/container-engine/docs/quickstart)
- [Azure](https://docs.microsoft.com/en-us/azure/container-service/container-service-kubernetes-walkthrough)
- [Amazon](https://kubernetes.io/docs/getting-started-guides/aws/)

There are also many [other
options](https://kubernetes.io/docs/getting-started-guides/) for running
virtually anywhere, including on premise.

This demo utilizes a cluster made from Raspberry Pis, as described in [Scott
Hanselman's excellent
blog](https://www.hanselman.com/blog/HowToBuildAKubernetesClusterWithARMRaspberryPiThenRunNETCoreOnOpenFaas.aspx).
Although it will run in other cluster environments, there will be minor
configuration changes. These instructions apply specifically to this
configuration.

## Specific Cluster Configuration

This section outlines the configuration that is specific to the demo cluster
and cannot be inferred from the previous section.

There are four pis in the demo cluster.
- k8-master
- k8-node-1
- k8-node-3
- k8-node-3

In order to provide durable IP addresses for each pi, the router issues static
leases. Detailed information is available
[here](https://www.howtogeek.com/184310/ask-htg-should-i-be-setting-static-ip-addresses-on-my-router/).

The demo utilizes a Microsoft Surface Book to access the cluster.
Manual entries to the [hosts
file](https://support.rackspace.com/how-to/modify-your-hosts-file/) provide
domain name resolution. The exact entries are listed below. Obviously, your IP
addresses will be different.

```
192.168.1.3 k8-master
192.168.1.4 k8-node-1
192.168.1.5 k8-node-2
192.168.1.6 k8-node-3
```

Finally, the demo utilizes the
[WSL](https://docs.microsoft.com/en-us/windows/wsl/about) ubuntu shell (yes,
it's really Ubuntu, distributed by Cononical, running on Windows). If you
haven't tried this amazing new feature, do it. What are you waiting for, do it
NOW! The same entries from the windows hosts file need to go in the /etc/hosts
file to provide domain name resolution for the shell.


If everything is set up correctly, you should be able to ssh into each pi.

``` bash
# eg ssh pi@k8-master or ssh pi@k8-node-3
ssh pi@<pi name>
```

## Image Registry

Typically, organizations have private Docker repositories. However, for the
sake of brevity, this demo utilizes my personal [docker hub
account](https://hub.docker.com/u/dalealleshouse/). It is possible to create a
[local docker registry](https://docs.docker.com/registry/deploying/) but the
complexity surrounding security distracts from our purpose. 

Below is the commands to build and deploy each container to docker-hub.

``` bash
docker build --tag dalealleshouse/html-frontend:1.0 html-frontend/
docker push dalealleshouse/html-frontend:1.0

docker build --tag dalealleshouse/html-frontend:2.0 html-frontend-err/
docker push dalealleshouse/html-frontend:2.0

docker build --tag dalealleshouse/java-consumer:1.0 java-consumer/
docker push dalealleshouse/java-consumer:1.0

docker build --tag dalealleshouse/ruby-producer:1.0 ruby-producer/
docker push dalealleshouse/ruby-producer:1.0

docker build --tag dalealleshouse/status-api:1.0 status-api/
docker push dalealleshouse/status-api:1.0
```

The internet connectivity at conferences can be a bit capricious. Therefore,
the images are manually downloaded on each pi before the demo. During the on
stage demonstration, the containers will be available locally.  Therefore, K8S
will not attempt to download them. Navigate to the project directory and run
the commands below.

``` bash
docker pull dalealleshouse/html-frontend:1.0
docker pull dalealleshouse/html-frontend:2.0
docker pull dalealleshouse/java-consumer:1.0
docker pull dalealleshouse/ruby-producer:1.0
docker pull dalealleshouse/status-api:1.0
docker pull rabbitmq:3.6.6-management
```
   
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
kubectl run html-frontend --image=html-frontend:1.0 --port=80 --env STATUS_HOST=status.demo.com
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

Each pod represents a container running on the K8S cluster.  kubectl mirrors
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
As a side note, the command above reveals a service that we didn't create named
kubernetes. This is used for communication with the core API. It is possible to
consume this REST API without going through kubectl. In fact, there are a few
[client
libraries](https://github.com/kubernetes/community/blob/master/contributors/devel/client-libraries.md)
readily available. This is beyond the scope of the demo, but more information
is available
[here](https://kubernetes.io/docs/concepts/overview/kubernetes-api/).

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

## Dashboard/Monitoring

K8S comes equipped with two decent monitoring tools out of the box:
[dashboard](https://kubernetes.io/docs/user-guide/ui/) and
[heapster](http://blog.kubernetes.io/2015/05/resource-usage-monitoring-kubernetes.html).
The following command outputs several useful K8S URLs, notice there is a URL
for both tools.

``` powershell
kubectl cluster-info
```

If you are using Minikube, Heapster is not enabled by default and the dashboard
URL isn't quite right. Use the following command to see both tools using Minikube.

``` powershell
minikube addons enable heapster
minikube addons open heapster
minikube dashboard open
```

The monitoring tools are implemented as plug ins so they easy to replace/modify.

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
robin load balance requests to the replicas. Notice the name of the pod on the
web page changes for every subsequent request.

The ability to manually scale pods quickly is great; however, K8S has an even
better option. It's possible to scale in response to load. The command below
tells K8S to maintain between 1 and 5 replicas based on fifty percent CPU
usage. This means if the allocated CPU for the all pods goes above 50%, new
replicas will be added. If it goes below 50%, replicas are removed. Most
details on the auto scaling algorithm can be found
[here](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/horizontal-pod-autoscaler.md)

``` powershell
kubectl autoscale deployment java-consumer --min=1 --max=5 --cpu-percent=50
```

After running the command above, notice that the number of java-consumer
replicas slowly climbs. As of the 1.5 release, CPU is the only metric available
to scale on. However, there are plans to add more in upcoming releases.

The autoscale command creates a *Horizontal Pod Scaling* resource. Just like
any other K8S resource, it can be manipulated via a yaml file. The following
commands display information about the resource.

``` powershell
kubectl get hpa
kubectl describe hpa
kubectl get hpa -o yaml
```

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

Of course, it's not very often that a container just completely shuts down.
That's why K8S provides liveness and readiness checks. Look at the bottom
section of the [html-frontend deployment file](/kube/html-frontend.dply.yml).
The section of interest is shown below.

``` yaml
...
        livenessProbe:
          httpGet:
            path: /healthz.html
            port: 80
          initialDelaySeconds: 3
          periodSeconds: 2
        readinessProbe:
          httpGet:
            path: /healthz.html
            port: 80
          initialDelaySeconds: 3
          periodSeconds: 2
```

This tells K8S to request healthz.html every 2 seconds and restart the pod upon
a bad request. The following commands simulate such a failure.

```
kubectl get pods
kubectl exec *POD_NAME* rm usr/share/nginx/html/healthz.html
```

Running `kubectl get pods` again should produce an output similar to below:

``` powershell
NAME                             READY     STATUS    RESTARTS   AGE
html-frontend-1306390030-t1sqx   1/1       Running   1          12m
...
```

Notice the pod is question has one restart. Likewise, navigating to the
replication controller via the dashboard or, running `kubectl describe
*POD_NAME*` will reveal a *Liveness Probe Failed* event. When the health check
failed, K8S automatically killed the old container and stood a new one up.
Likewise, if a readiness probe were to fail the pod would never be brought
online which would stop any rolling updates in progress.

## Rolling Deployment/Rollback

When K8S updates a deployment, it pulls one pod out of the system at a time,
updates it, and waits till it's up before moving on to the next.  This ensures
that users never experience an outage. The following command will update the
html-frontend deployment container image.

``` powershell
kubectl set image deployment/html-frontend html-frontend=html-frontend:2.0
kubectl get deployments 
```

The output of the last command shows that the update was made almost instantly.
Navigating to demo.com should show a significant error. Obviously, the 2.0
image is flawed. Luckily, with K8S it's rolling back to the previous images is
as easy as the following command:

``` powershell
kubectl rollout undo deployment html-frontend
```

There are a few different options for rollbacks. The following commands display
the roll out history of a deployment.  Putting a *--revision=#* after the
*rollout undo* command will roll back to specific version.

``` powershell
kubectl rollout history deployment html-frontend
kubectl rollout history deployment html-frontend --revision=*REVISION_NUMBER*
```

## Other Cool Stuff

- [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Volumes](https://kubernetes.io/docs/concepts/storage/volumes/)
- [Stateful Sets](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [Daemon Sets](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/)
- [Jobs](https://kubernetes.io/docs/concepts/jobs/run-to-completion-finite-workloads/)
- [Cron Jobs](https://kubernetes.io/docs/user-guide/cron-jobs/)
- [So Much More](https://kubernetes.io/docs/home/)
