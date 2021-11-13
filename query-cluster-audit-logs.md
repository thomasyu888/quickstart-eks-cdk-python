# Explore the cluster's audit logs in CloudWatch Logs

This template automatically enables the shipping of the cluster's logs to CloudWatch Logs.

Here are just a few sample queries that can tell you what is happening in your cluster in CloudWatch Logs Insights.

1. Go to Logs Insights in the AWS Console
1. In the `Select log group(s)` dropdown choose `aws/eks/(clustername)/cluster` 
1. Explore some of these queries by pasting them into the query box (overwritting the existing text) and clicking `Run query`:

Show you the 10 most common users accounts connecting to the kubernetes API and what IP they are coming from. These will usually either be Kubernetes service accounts or AWS IAM Roles:
```
fields sourceIPs.0, user.username
| filter ispresent (sourceIPs.0) and user.username not like /system/
| stats count (*) as SRC_IP by sourceIPs.0, user.username
| sort SRC_IP desc
| limit 10
```

Here is the same query if we cared more about the userAgent string (what the client identifies itself as to the API) rather than the IP:
```
fields userAgent, user.username
| filter ispresent (userAgent) and user.username not like /system/
| stats count (*) as UA by userAgent, user.username
| sort UA desc
| limit 10
```

And here is a query to show us the top 10 users getting forbidden from doing things by the API who are authenticated but don't have authorization for what they are trying to do:
```
fields `annotations.authorization.k8s.io/decision` , user.username
| filter `annotations.authorization.k8s.io/decision` like /forbid/ and user.username not like /system/
| stats count (*) as decision by `annotations.authorization.k8s.io/decision`, user.username
| sort decision desc
| limit 10
```