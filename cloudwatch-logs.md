# Deploy and connect to CloudWatch Logs for log search and visualisation

If you set `deploy_cloudwatch_container_insights_logs` to `True` in `cluster-bootstrap/cdk.json` then the template will deploy a Fluent Bit shipping all of your logs to CloudWatch Logs with the Kubernetes Filter enriching them with the Kubernetes metadata/context.

A couple examples of querying these logs:
1. Go to the Logs Insights in the AWS Console
1. In the `Select log group(s)` dropdown choose `fluent-bit-cloudwatch`
1. Click the `Run query` button wih the default query. This is displaying the timestamp in one column then the full JSON message/document from FluentBit.
1. If you click the arrow/carrot next to one of the entries this will expand and show you a breakdown of the different fields in the message document.
1. Replace the top line of the query with `fields @timestamp, kubernetes.container_name, log` and then click `Run query`
1. This is now showing you the timestamp, the kubernetes container_name label of the workload shipping the log, and then the log line the application actually shipped.
1. If you know a particular time range you are interested in you can choose it by choosing the custom button with the calendar icon to the right of the `Select log group(s)` dropdown.
1. You can also filter which apps' log lines are returned by adding the line `| filter kubernetes.container_name = "kubernetes-external-secrets"` to the as the 2nd line of the query and then clicking the `Run query` button
1. For query ideas click the Help button on the right side and learn more about fields, filter, stats, sort, limit and parse which you can use in the queries.