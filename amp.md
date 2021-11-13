# Deploy and connect to Prometheus (AMP) and Grafana for metrics search and visualisation

If you set `deploy_amp` to `True` in `cluster-bootstrap/cdk.json` then the template will deploy a managed Prometheus workspace as well as set up a local ephemeral and short-retention Prometheus on the cluster shipping your metrics to it.

If you set `deploy_grafana_for_amp` to `True` in `cluster-bootstrap/cdk.json` then the template will deploy a self-hosted/self-managed Grafana onto your cluster to visualise the metrics in the AMP. Alternatively, you can configure the [AWS Managed Grafana (AMG)](https://docs.aws.amazon.com/grafana/latest/userguide/what-is-Amazon-Managed-Service-Grafana.html) to do that instead.

We have deployed an in-VPC private Network Load Balancer (NLB) (i.e. Not on the Internet) to access this Grafana service to visualize the metrics from the Prometheus we've deployed onto the cluster.

To access this enter the following command `kubectl get service grafana-for-amp --namespace=kube-system` to find the address of this under EXTERNAL-IP. Alternatively, you can find the Grafana NLB in the AWS EC2 console and get its address from there.

The default username is `admin` and you get the initial password by running `kubectl get secrets grafana-for-amp -n kube-system -o jsonpath='{.data.admin-password}'|base64 --decode`. You can change this password as well as create/managed additional users once you are signed in.

We have set up AMP as a datasource and loaded a few sample dashboards for you to visualise the metrics on your EKS cluster:
* `Cluster Monitoring for Kubernetes` to see cluster and node-level CPU, memory, network IO and free disk space
* `Kubernetes Metrics - Deployments vs StatefulSets vs DaemonSets` to drill down on your workloads whether they be deployments, statefulsets or daemonsets
* `Pod Stats & Info` to drill down on everything about a particular Pod
* `Kubernetes apiserver` to see some metrics about how the EKS Control Plane is performing and the load the Kubernetes API is experiencing

Click the word/link Home on the top of the Grafana page to see a list your Dashboards.
