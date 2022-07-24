# Deploy and connect to the Bastion (an EC2 Instance accessed securely via Systems Manager's Session Manager)

If you set `deploy_bastion` to `True` in `cluster-bootstrap/cdk.json` then the template will deploy an EC2 instance with all the tools to manage your cluster.

To access this bastion:
1. Go to the Systems Manager Server in the AWS Console
1. Go to Fleet Manager on the left hand navigation pane
1. Select the instance with the name `EKSClusterStack/CodeServerInstance`
1. Under the Instance Actions menu on the upper right choose Start Session
1. Run `aws eks update-kubeconfig --name <cluster name> --region <your region> to populate your ~/.kube/config file
1. Run `kubectl get nodes` to see that all the tools are there and set up for you!
