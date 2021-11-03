# EKS CDK Quick Start (in Python)

> **DEVELOPER PREVIEW NOTE:** This project is currently available as a preview and should not be considered for production use at this time. 


This Quick Start is a reference architecture and example template on how to use the [AWS Cloud Development Kit (CDK)](https://docs.aws.amazon.com/cdk/latest/guide/home.html) to orchestrate both the provisioning of the [Amazon Elastic Kubernetes Service (EKS)](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html) cluster as well as the [Amazon Virtual Private Cloud (VPC)](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html) network that it will live in - or letting you specify an existing VPC to use instead. 

When provisioning the cluster it gives the option of either using EC2 worker [Nodes](https://kubernetes.io/docs/concepts/architecture/nodes/) via a [EKS Managed Node Group](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html), with either [OnDemand or Spot capacity types](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html#managed-node-group-capacity-types), or building a [Fargate](https://docs.aws.amazon.com/eks/latest/userguide/fargate.html)-only cluster.

It will also help provision various associated add-ons to provide capabilities such as:
![diagram](diagram.png)
- Integration with the [AWS Network Load Balancer (NLB)](https://docs.aws.amazon.com/elasticloadbalancing/latest/network/introduction.html) for [Services](https://kubernetes.io/docs/concepts/services-networking/service/) and [Application Load Balancer (ALB)](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html) for [Ingresses](https://kubernetes.io/docs/concepts/services-networking/ingress/) via the [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/#aws-load-balancer-controller).
- Integration with [Amazon Route 53](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/Welcome.html) via the [ExternalDNS controller](https://github.com/kubernetes-sigs/external-dns).
- Integration with [Amazon Elastic Block Store (EBS)](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AmazonEBS.html) and [Amazon Elastic File System (EFS)](https://docs.aws.amazon.com/efs/latest/ug/whatisefs.html) via the [Kubernetes Container Storage Interface (CSI) Drivers](https://kubernetes-csi.github.io/docs/drivers.html) for them both. 
    - When enabling EBS we also create a StorageClass using the CSI Driver called `ebs`
    - When enabling EFS we also create an EFS Filesystem as well as a StorageClass set up for dynamic provisioning to it via folders called `efs`
- Integration with [EC2 Auto Scaling](https://docs.aws.amazon.com/autoscaling/ec2/userguide/AutoScalingGroup.html) of the underlying worker [Nodes](https://kubernetes.io/docs/concepts/architecture/nodes/) via the [Cluster Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler) - which scales in/out the Nodes to ensure that all of your [Pods](https://kubernetes.io/docs/concepts/workloads/pods/) are schedulable but your cluster is not over-provisioned.
- Integration with [CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html) for metrics and/or logs for cluster monitoring via [CloudWatch Container Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContainerInsights.html).
- Integration with [Amazon OpenSearch Service (successor to Amazon Elasticsearch Service)](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/what-is.html) for logs for cluster monitoring - both provisioning the OpenSearch Domain as well as a [Fluent Bit](https://fluentbit.io/) to ship the logs from the cluster to it.
- Integration with the [Amazon Managed Service for Prometheus (AMP)](https://docs.aws.amazon.com/prometheus/latest/userguide/what-is-Amazon-Managed-Service-Prometheus.html) for cluster metrics and monitoring - both provisioning the AMP Workspace as well as a local short-retention Prometheus on the cluster to collect and push the metrics to it.
    - This includes an optional local self-hosted [Grafana](https://grafana.com/) to visualise the metrics. You can opt instead to use an [Amazon Managed Grafana](https://docs.aws.amazon.com/grafana/latest/userguide/what-is-Amazon-Managed-Service-Grafana.html) instead in production - but setting that up and pointing it at the AMP is outside the scope of this Quick Start.
- The [Kubernetes Metrics Server](https://github.com/kubernetes-sigs/metrics-server) which is required for, amoung other things, the [Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) to work.
- Integration with [Security Groups](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html) for network firewalling via [Amazon Container Network Interface (CNI)](https://github.com/aws/amazon-vpc-cni-k8s) plugin re-configured to enforce [Security groups for pods](https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html).
- Alternatively, the [Calico](https://docs.aws.amazon.com/eks/latest/userguide/calico.html) network policy engine which enforces Kubernetes [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) by managing host firewalls on all the Nodes.
- Integration with [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html) via the [External Secrets operator](https://github.com/external-secrets/external-secrets) and/or the [Secrets Store CSI Driver](https://docs.aws.amazon.com/secretsmanager/latest/userguide/integrating_csi_driver.html)
- Insight into costs and how to allocate them to particular workloads via the open-source [Kubecost](https://github.com/kubecost/cost-model)

Also, since the Quick Start deploys both EKS as well as many of the observability tools like OpenSearch and Grafana into private subnets (i.e. not on the Internet), we provide two secure mechanisms to access and manage them:
- A bastion EC2 Instance preloaded with the right tools and associated with the right IAM role/permissions that is not reachable on the Internet - only via [AWS Systems Manager Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)
- An [AWS Client VPN](https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/what-is.html)

While these are great for a proof-of-concept (POC) or development environment, in production you will likely have a [site-to-site VPN](https://docs.aws.amazon.com/vpn/latest/s2svpn/VPC_VPN.html) or a [DirectConnect](https://docs.aws.amazon.com/directconnect/latest/UserGuide/Welcome.html) to facilitate this secure access in a more scalable way.

The provisioning of all these add-ons can be enabled/disabled by changing parameters in the [cdk.json](https://github.com/aws-quickstart/quickstart-eks-cdk-python/blob/main/cluster-bootstrap/cdk.json) file.

### Why CDK?

The CDK is a great tool to use since it can orchestrate both the AWS and Kubernetes APIs from the same template(s) - as well as set up things like the IAM Roles for Service Accounts (IRSA) mappings between the two.

> **NOTE:** You do not need to know how to use the CDK, or know Python, to use this Quick Start as-is with the instructions provided. We expose enough parameters in [cdk.json]() to allow you to customise it to suit most usecases without changing the template (just changing the parameters). You can, of course, also fork it and use it as the inspiration or the foundation for your own bespoke templates as well - but many customers won't need to do so.

## How to use the Quick Start

The template to provision the cluster and and the add-ons is in the [cluster-bootstrap/](https://github.com/aws-quickstart/quickstart-eks-cdk-python/tree/main/cluster-bootstrap) folder. The [cdk.json](https://github.com/aws-quickstart/quickstart-eks-cdk-python/blob/main/cluster-bootstrap/cdk.json) contains the parameters to use and the template is mostly in the [eks_cluster.py](https://github.com/aws-quickstart/quickstart-eks-cdk-python/blob/main/cluster-bootstrap/eks_cluster.py) file - though it imports/leverages the various other .py and .yaml files within the folder. If you have the CDK as well as the required packages from pip installed then running `cdk deploy` in this folder will deploy the Quick Start.

The ideal way to deploy this template, though, is via [AWS CodeBuild](https://docs.aws.amazon.com/codebuild/) - which provides a GitOps-style pipeline for not just the initial provisioning and then ongoing changes/maintenance of the environment. This means that if you want to change something about the running cluster you just need to change the cdk.json and/or eks_cluster.py and then merge the change to the git branch/repo and then CodeBuild will automatically apply it for you. 

We provide both the [buildspec.yml](https://github.com/aws-quickstart/quickstart-eks-cdk-python/blob/main/cluster-bootstrap/buildspec.yml) to tell CodeBuild how to install the CDK (via npm and pip) and then do the `cdk deploy` command for you as well as both a [CDK](https://github.com/aws-quickstart/quickstart-eks-cdk-python/blob/main/cluster-codebuild/eks_codebuild.py) and resulting [CloudFormation](https://github.com/aws-quickstart/quickstart-eks-cdk-python/blob/main/cluster-codebuild/EKSCodeBuildStack.template.json) template (pre-generated for you with a `cdk synth` command from the `eks_codebuild.py` CDK template) to set up the CodeBuild project in the [cluster-codebuild/](https://github.com/aws-quickstart/quickstart-eks-cdk-python/tree/main/cluster-codebuild) folder. 

To save you from the circular dependency of using the CDK (on your laptop?) to create the CodeBuild to then run the CDK for you to provision the cluster you can just use the [cluster-codebuild/EKSCodeBuildStack.template.json](https://github.com/aws-quickstart/quickstart-eks-cdk-python/blob/main/cluster-codebuild/EKSCodeBuildStack.template.json) CloudFormation template directly.

Alternatively, you can install and use CDK directly (not via CodeBuild) on another machine such as your laptop or an EC2 Bastion. This approach is documented [here](https://github.com/aws-quickstart/quickstart-eks-cdk-python/blob/main/manual-install.md).

## The three sample cdk.json sets of parameters

While you can toggle any of the parameters to in a custom configuration, we include three `cdk.json` files in [cluster-bootstrap/](https://github.com/aws-quickstart/quickstart-eks-cdk-python/tree/main/cluster-bootstrap) around three possible configurations:

1. The default [cdk.json or cdk.json.default](https://github.com/aws-quickstart/quickstart-eks-cdk-python/blob/main/cluster-bootstrap/cdk.json) - if you don't change anything the default parameters will deploy you the most managed yet minimal EKS cluster including:
    - Managed Node Group of m5.large Instances
    - AWS Load Balancer Controller
    - ExternalDNS
    - EBS & EFS CSI Drivers
    - Cluster Autoscaler
    - Bastion
    - Metrics Server
    - CloudWatch Container Insights for Metrics and Logs
        - With a log retention of 7 days
    - Security Groups for Pods for network firewalling
    - Secrets Manager CSI Driver (for Secrets Manager Integration)
1. The Cloud Native Community [cdk.json.community](https://github.com/aws-quickstart/quickstart-eks-cdk-python/blob/main/cluster-bootstrap/cdk.json.community) - replace the `cdk.json` file with this file (making it cdk.json instead) and get:
    - Managed Node Group of m5.large Instances
    - AWS Load Balancer Controller
    - ExternalDNS
    - EBS & EFS CSI Drivers
    - Cluster Autoscaler
    - Bastion
    - Metrics Server
    - Amazon OpenSearch Service (successor to Amazon Elasticsearch Service) for logs
    - Amazon Managed Service for Prometheus (AMP) w/self-hosted Grafana
    - Calico for Network Policies for network firewalling
    - External Secrets Controller (for Secrets Manager Integration)
1. The Fargate-only [cdk.json.fargate](https://github.com/aws-quickstart/quickstart-eks-cdk-python/blob/main/cluster-bootstrap/cdk.json.fargate) - replace the `cdk.json` file with this file (making it cdk.json instead) and get:
    - Fargate profile to run everything in the `kube-system` and `default` Namespaces via Fargate
    - AWS Load Balancer Controller
    - ExternalDNS
    - Bastion
    - Metrics Server
    - CloudWatch Logs (because the Kubernetes Filter for sending to Elastic/OpenSearch doesn't work with Fargate ATM)
    - Amazon Managed Service for Prometheus (AMP) w/self-hosted Grafana (because CloudWatch Container Insights doesn't work with Fargate ATM)
    - Security Groups for Pods for network firewalling (built-in to Fargate so we don't need to reconfigure the CNI)
    - External Secrets Controller (for Secrets Manager Integration)

## How to deploy via CodeBuild

1. Fork this [Git Repo](https://github.com/aws-quickstart/quickstart-eks-cdk-python) to your own GitHub account - for instruction see https://docs.github.com/en/get-started/quickstart/fork-a-repo
1. Generate a personal access token on GitHub - https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token 
1. Run `aws codebuild import-source-credentials --server-type GITHUB --auth-type PERSONAL_ACCESS_TOKEN --token <token_value>` to provide your token to CodeBuild
1. Select which of the [three cdk.json files](#the-three-cdkjson-sets-of-parameters) (cdk.json.default, cdk.json.community or cdk.json.fargate) you'd like as a base and copy that over the top of `cdk.json` in the `cluster-bootstrap/` folder.
1. Edit the `cdk.json` file to further customise it to your environment. For example:
    - If you want to use an existing IAM Role to administer the cluster instead of creating a new one (which you'll then have to assume to administer the cluster) set `create_new_cluster_admin_role` to False and then add the ARN for your role in `existing_admin_role_arn`
        - **NOTE** that if you bring an existing role AND deploy a Bastion that this role will get assigned to the Bastion by default as well (so that the Bastion can manage the cluster). This means that you need to allow `ec2.amazonaws.com` to perform action `sts:AssumeRole` on the Trust Policy / Assumed Role Policy of this role as well as add the Managed Policy `AmazonSSMManagedInstanceCore` to this role (so that your Bastion can register with SSM via this role and Session Manager will work)
    - If you want to change the VPC CIDR or the the mask/size of the public or private subnets to be allocated from within that block change `vpc_cidr`, `vpc_cidr_mask_public` and/or `vpc_cidr_mask_private`.
    - If you want to use an existing VPC rather than creating a new one then set `create_new_vpc` to False and set `existing_vpc_name` to the name of the VPC. The CDK will connect to AWS and work out the VPC and subnet IDs and which are public and private for you etc. from just the name.
    - If you'd like an instance type different from the default `m5.large` or to set the desired or maximum quantities change `eks_node_instance_type`, `eks_node_quantity`, `eks_node_max_quantity`, etc.
        - **NOTE** that not everything in the Quick Start appears to work on Graviton/ARM64 Instance types. Initial testing shows the following addons do not work (do not have multi-arch images) - and we'll track them and enable when possible: kubecost, calico and the CSI secrets store provider.
    - If you'd like the Managed Node Group to use Spot Instances instead of the default OnDemand change `eks_node_spot` to True
    - And there are other parameters in the file to change with names that are descriptive as to what they adjust. Many are detailed in the [Additional Documentation](#additional-documentation) around the the add-ons below.
1. Find and replace `https://github.com/aws-quickstart/quickstart-eks-cdk-python.git` with the address to your GitHub fork in [cluster-codebuild/EKSCodeBuildStack.template.json](https://github.com/aws-quickstart/quickstart-eks-cdk-python/blob/main/cluster-codebuild/EKSCodeBuildStack.template.json)
1. (Only if you are not using the main branch) Find and replace `main` with the name of your branch.
1. Go to the the console for the CloudFormation service in the AWS Console and deploy your updated [cluster-codebuild/EKSCodeBuildStack.template.json](https://github.com/aws-quickstart/quickstart-eks-cdk-python/blob/main/cluster-codebuild/EKSCodeBuildStack.template.json)
1. Go to the CodeBuild console, click on the Build project that starts with `EKSCodeBuild`, and then click the Start build button.
1. (Optional) You can click the Tail logs button to follow along with the build process

![gitops_diagram](gitops-diagram.png)

**_NOTE:_** This also enables a GitOps pattern where changes merged to the cluster-bootstrap folder on the branch mentioned (main by default) will re-trigger this CodeBuild to do another `npx cdk deploy` via web hook.

## Additional Documentation
- [Deploy and connect to the Bastion](https://github.com/aws-quickstart/quickstart-eks-cdk-python/blob/main/bastion.md)
- [Deploy and connect to the Client VPN](https://github.com/aws-quickstart/quickstart-eks-cdk-python/blob/main/clientvpn.md)
- [Deploy and connect to OpenSearch for log search and visualisation](https://github.com/aws-quickstart/quickstart-eks-cdk-python/blob/main/opensearch.md)
- [Deploy and connect to Prometheus (AMP) and Grafana for metrics search and visualisation](https://github.com/aws-quickstart/quickstart-eks-cdk-python/blob/main/amp.md)
- [Deploy and connect to Kubecost for cost/usage analysis and attribution](https://github.com/aws-quickstart/quickstart-eks-cdk-python/blob/main/kubecost.md)
- [Deploy Open Policy Agent (OPA) Gatekeeper and sample policies via the Flux GitOps Operator](https://github.com/aws-quickstart/quickstart-eks-cdk-python/blob/main/gatekeeper.md)
- [Upgrading your EKS Cluster and add-ons via the CDK](https://github.com/aws-quickstart/quickstart-eks-cdk-python/blob/main/upgrades.md)
- [Deploying a few included demo/sample applications showing how to use the various add-ons](https://github.com/aws-quickstart/quickstart-eks-cdk-python/tree/main/demo-apps#readme)
