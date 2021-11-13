# Demo Applications

## hello-kubernetes

Here we're deploying the container from https://github.com/paulbouwer/hello-kubernetes but via a custom Deployment and Ingress Spec.

This is to provide an example of a Kubernetes Deployment as well as how to present a service out to the Internet via the AWS Load Balancer controller as your Ingress Controller or an NLB Service.

To deploy with the ALB run `kubectl apply -f hello-kubernetes-alb.yaml` and with the NLB run `kubectl apply -f hello-kubernetes-nlb.yaml`

The Deployment implements CPU and memory requests and limits, readiness and liveness probes (Kubernetes' healthchecks) as well as is explicit about its use of non-root UID and GID and dropping of unnecessary capabilities and privileges (which are enforced by our example Gatekeeper polices).

Clean up with `kubectl delete -f hello-kubernetes-alb.yaml` and/or `kubectl delete -f hello-kubernetes-nlb.yaml`.

### HTTPS and/or Route53 Alias
The Ingress (and the required Service it uses) and the NLB Service both service this app via HTTP. If you have a valid ACM certificate and/or a valid Route53 domain name you can uncomment the annotations to make this HTTPS and/or automatically create a DNS alias to a 'proper' DNS name.

## Horizontal Pod Autoscaler (HPA) and Cluster Autoscaler (CA)

There is a good example in the [Kubernetes documentation](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/) of using the Horizontal Pod Autoscaler. This requires the [metrics-server](https://github.com/kubernetes-sigs/metrics-server) which we also include in the Quick Start.

Note that if you are running a workload on Fargate then only this one tool is required to scale (each Pod is its own Node/VM and AWS automatically scales them for you) whereas if you are running with a Managed Node Group you need a 2nd tool, also included, to scale the Nodes called the [Cluster Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler) to be deployed as well. This will scale out more Nodes whenever Pods are unschedulable due to insufficient capacity (which could be caused by the HPA scaling them out).

To test the HPA (and vicariously the CA scaling out Nodes to fit the new Pods if running on EC2 mode):
1. Run `kubectl apply -f hpa-example.yaml` to deploy the example app php-apache.
1. Run `kubectl autoscale deployment php-apache --cpu-percent=25 --min=1 --max=10` - this will create a Horizontal Pod Autoscaler that maintains between 1 and 10 replicas of the Pods controlled by the php-apache deployment. Roughly speaking, HPA will increase and decrease the number of replicas (via the deployment) to maintain an average CPU utilization across all Pods of 25%.
1. Run `kubectl get hpa` to see our new hpa
1. Run `kubectl run load-generator --image=busybox --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://php-apache; done"` to generate load to trigger the scaling.
1. Wait a minute then run `kubectl get hpa` to see it scaling up the Pods
1. (Optional) Ramp it up with a 2nd load generator `kubectl run load-generator-2 --image=busybox --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://php-apache; done"`

## EBS

Elastic Block Storage (EBS) is the AWS block storage service in AWS. We've integrated it with our EKS environment by adding the CSI driver AWS maintains to the cluster as an add-on in the Quick Start. We've also added a [StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/) into the cluster (called `ebs` - as opposed to the `gp2` that is included with EKS but uses the deprecated in-tree driver instead of the CSI driver we've installed for you) so you can consume it via [Dynamic Provisioning](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/) without any other work.

We provide two examples here - [ebs-pod.yaml](https://github.com/aws-quickstart/quickstart-eks-cdk-python/blob/main/demo-apps/ebs-pod.yaml) and [ebs-statefulset.yaml](https://github.com/aws-quickstart/quickstart-eks-cdk-python/blob/main/demo-apps/ebs-statefulset.yaml). While `ebs-pod.yaml`, which illustrates how to create a [PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims) and [Pod](https://kubernetes.io/docs/concepts/workloads/pods/) that consumes it, is useful for a demo you would never really deploy it for real - especially in apps that are stateful. If you did then a Managed Node Group upgrade or the Pod was disrupted for any reason it isn't automatically re-created/healed. A [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/) will do that for you - recreate a Pod with the same name and network address and PersistentVolumes attached to it - on a new Node if required. As such, we'll be using the `ebs-statefulset.yaml` as our example.

To deploy this example run:
1. `kubectl apply -f ebs-statefulset.yaml` to create a StatefulSet that generates PersistentVolumeClaims from the VolumeClaimTemplate defined there against the StorageClass creaed by the Quick Start `ebs`.
1. `kubectl get pods` and see our new `storage-test-ebs-0` running
1. `kubectl exec -it storage-test-ebs-0 -- /bin/bash` to give us an interactive shell into the running Pod
1. `df -h` to show us the mounted Volumes - you can see our 1GB volume mounted to /mnt/test as we requested.
1. `exit` to return to the bastion's shell
1. Go to the EC2 Service in the AWS console
1. Go to Volumes on the left-hand side navigation pane
1. Sort by Size such that the 1GB volume we created is at the top of the list by clicking on the Size heading
1. Run `kubectl delete pod storage-test-ebs-0` to simulate a `kubectl drain` or other action that will disrupt our Pod
1. Run `kubectl get pods` and see how our StatefulSet re-created it with the same name and remounting the same existing volume it had before
1. Run `kubectl delete statefulset storage-test-ebs` to clean up the StatefulSet (which will clean up the Pod too) and `kubectl delete pvc myebs-storage-test-ebs-0` to clean up the PersistentVolume (which will lead to the CSI driver deleting the EBS volume).

## EFS

Elastic File System (EFS) is a managed service that presents filesystems that can be mounted by NFS clients.

Unlike the EBS CSI Driver, the EFS CSI driver requires an EFS Filesytem to already exist and for us to tell it which one to use as part of each StorageClass. We created both such an EFS Filesystem as well as a StorateClass referencing it called `efs` in the Quick Start.

We provide two examples here - [efs-pod.yaml](https://github.com/aws-quickstart/quickstart-eks-cdk-python/blob/main/demo-apps/efs-pod.yaml) and [efs-statefulset.yaml](https://github.com/aws-quickstart/quickstart-eks-cdk-python/blob/main/demo-apps/efs-statefulset.yaml). While `efs-pod.yaml`, which illustrates how to create a [PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims) and [Pod](https://kubernetes.io/docs/concepts/workloads/pods/) that consumes it, is useful for a demo you would never really deploy it for real - especially in apps that are stateful. If you did then a Managed Node Group upgrade or the Pod was disrupted for any reason it isn't automatically re-created/healed. A [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/) will do that for you - recreate a Pod with the same name and network address and PersistentVolumes attached to it - on a new Node if required. As such, we'll be using the `efs-statefulset.yaml` as our example.

**NOTE:** By default we set the EFS Filesystem's Security Group to allow NFS connections from the Cluster's Security Group. If you are using Security Groups for Pods and the Pods don't have that Security Group attached you'll need to update the Filesystem's Security Group to allow them to connect. This example doesn't include a SG for the Pod so, unless you have set one on the default namespace etc. it should work.

To deploy this example run:
1. `kubectl apply -f efs-statefulset.yaml` to create a StatefulSet that generates PersistentVolumeClaims from the VolumeClaimTemplate defined there against 
1. `kubectl get pods` and see our new `storage-test-efs-0` running
1. `kubectl exec -it storage-test-efs -- /bin/bash` to give us an interactive shell into the running Pod
1. `df -h` to show us the mounted Volumes - you can see our unlimited (it shows as 8 Exabytes!) volume mounted to /mnt/test as we requested.
1. `exit` to return to the bastion's shell
1. Go to the EFS Service in the AWS Console
1. Go to `Access points` on the left-hand navigation pane
1. Note that the EFS CSI Driver created a path for this PersistentVolumeClaim in the volume tied to an EFS Access Point to control access to that path for us automatically.
1. Run `kubectl delete pod storage-test-efs-0` to simulate a `kubectl drain` or other action that will disrupt our Pod
1. Run `kubectl get pods` and see how our StatefulSet re-created it with the same name and remounting the same existing volume it had before
1. Run `kubectl delete statefulset storage-test-efs` to clean up the StatefulSet (which will clean up the Pod too) and `kubectl delete pvc myefs-storage-test-efs-0` to clean up the PersistentVolume (which will lead to the CSI driver deleting the EFS Access Point and the data).

## Ghost
Note that this requires the Kubernetes External Secrets Opeartor (https://github.com/external-secrets/kubernetes-external-secrets). This is an optional part of the Quick Start so you can enable it there. Alternatively, you can flip `deploy_external_secrets` to true in `cdk.json` to true and this CDK example will deploy it for you as well. 

To deploy our CDK-based Ghost example:
1. `cd ghost-cdk`
1. (If npm isn't already installed) `sudo npm install -g aws-cdk`
1. `pip3 install -r requirements.txt` to install the required Python CDK packages
1. `cdk synth` to generate the CloudFormation from the `ghost_example.py` CDK template and make sure everything is working. It will not only output it to the screen but also store it in the `cdk.out/` folder
1. `cdk deploy` to deploy template this to our account in a new CloudFormation stack
1. Answer `y` to the security confirmation and press Enter/Return

### Understanding what this example is doing

When we run our `ghost_example.py` CDK template there are both AWS and Kubernetes components that CDK provisions for us.
![Git Flow Diagram](diagram1.PNG?raw=true "Git Flow Diagram")

We are also adding a new controller/operator to Kubernetes - [kubernetes-external-secrets](https://github.com/external-secrets/kubernetes-external-secrets) - which is UPSERTing the AWS Secrets Manager secret that CDK is creating into Kubernetes so that we can easily consume this in our Pod(s). This joins the existing [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/) which turns our Ingress Specs into an integration/delegation to the AWS Application Load Balancer (ALB).
![Operator Flow Diagram](diagram2.PNG?raw=true "Operator Flow Diagram")

### Bringing in our YAML Manifest files directly

You'll notice that rather than copying/pasting the YAML mainifests into our Python template as JSON (as we did for a few things in eks_cluster.py) here we added some code using a Python library called pyaml to import the files at runtime. This allows people to deal with their Kubernetes manifest files directly but CDK to facilitate their deployment.

```
import yaml

...

ghost_deployment_yaml_file = open("ghost-deployment.yaml", 'r')
ghost_deployment_yaml = yaml.load(ghost_deployment_yaml_file, Loader=yaml.FullLoader)
ghost_deployment_yaml_file.close()
#print(ghost_deployment_yaml)
eks_cluster.add_manifest("GhostDeploymentManifest",ghost_deployment_yaml)
```

### Cross-Stack CDK

We're deploying Ghost in a totally seperate CDK stack in a seperate template. This is made possible by a few things:
1. Some CDK Constructs like VPC can import object, with all the associated properties and methods, from existing environments. In the case of VPC you'll see this is all it takes to import our existing VPC we want to deploy into by its name:
```
vpc = ec2.Vpc.from_lookup(self, 'VPC', vpc_name="EKSClusterStack/VPC")
```
1. Other Constructs like EKS we need to tell it several of the parameters for it to reconstruct the object. Here we need to tell it a few things like the `open_id_connect_provider`, the `kubectl_role_arn`, etc. for it to give us an object we can call/use like we'd created the EKS cluster in *this* template. 

We pass these parameters across our Stacks using CloudFormation Exports (Outputs in one CF stack we can reference in another):

Here is an example of exporting the things we need in eks_cluster.py
```
core.CfnOutput(
    self, "EKSClusterName",
    value=eks_cluster.cluster_name,
    description="The name of the EKS Cluster",
    export_name="EKSClusterName"
)
```

And here is an example of importing them in ghost_example.py to reconstitute an eks.Cluster object from the required attributes.
```
eks_cluster = eks.Cluster.from_cluster_attributes(
  self, "cluster",
  cluster_name=core.Fn.import_value("EKSClusterName"),
  open_id_connect_provider=eks.OpenIdConnectProvider.from_open_id_connect_provider_arn(
    self, "EKSClusterOIDCProvider",
    open_id_connect_provider_arn = core.Fn.import_value("EKSClusterOIDCProviderARN")
  ),
  kubectl_role_arn=core.Fn.import_value("EKSClusterKubectlRoleARN"),
  vpc=vpc,
  kubectl_security_group_id=core.Fn.import_value("EKSSGID"),
  kubectl_private_subnet_ids=[vpc.private_subnets[0].subnet_id, vpc.private_subnets[1].subnet_id]
)
```
And here is what those Exports look like in the CloudFormation console
![CF Exports](diagram3.PNG?raw=true "CF Exports")

### Exploring Ghost after it is deployed

1. Run `kubectl get ingresses` to see the address for the ALB in front of our service
1. Go to that address in your web browser to see the service
1. In your browser append a `/ghost` to the end of the address to get to the Ghost management interface. Set up your initial account there (before some random person/bot on the Internet does it for you!)
1. Go to the EC2 Service in the AWS Console
1. Go to `Load Balancers` on the left hand navigation pane
1. Select the `k8s-default-ghost-...` Load Balancer - this is the ALB that the AWS Ingress Controller created for us
1. Select the Monitoring Tab to see some metrics about the traffic flowing though to our new Ghost
1. Select `Target Groups` on the left-hand navigation pane
1. Select the `k8s-default-ghost-...` Target Group
1. Select the Targets tab on the lower pane
1. The AWS Load Balancer controller adds/removes the Pod IPs directly as LB Targets as they come and go
1. Go to the Secrets Manager service in the AWS Console
1. Click on the Secret named `RDSSecret...`
1. Scroll down until you see the `Secret value` section and click the `Retrieve secret value` button. This secret was created by the CDK as part of its creation of the MySQL RDS. We map this secret into a Kubernetes secret our app consumes to know how to connect to the database with the [kubernetes-external-secrets](https://github.com/external-secrets/kubernetes-external-secrets) add-on we install in this stack. That in turn is passed in at runtime by Kubernetes as environment variables.
1. `kubectl describe externalsecrets` shows the mapping document telling kubernetes-external-secrets what secret(s) to fetch and what Kubernetes secrets to put them in
1. `kubectl descibe secret ghost-database` shows the resulting Kubernetes secret that we're importing into our Ghost Pods via environment variables

## Network Policies / Calico

Calico enforces/enables you to use NetworkPolicies (as opposed to Security Group Policies). The AWS documentation has a [good demo](https://docs.aws.amazon.com/eks/latest/userguide/calico.html#calico-stars-demo) illustrating NetworkPolices and how they work.

Note that once you put a Pod in-scope for a SecurityGroupPolicy the NetworkPolicy no longer applies - so at the moment only one of the two firewalling mechanisms can apply to a particular Pod/workload.