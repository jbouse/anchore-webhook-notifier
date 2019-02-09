# Anchore Engine webhook-notifier

The webhook-notifier is built upon a NGINX web server using the NGINX Lua module
to provide the content for the endpoint.

There are 2 endpoints available:

* /general/<notification_type>/<user_id>
* /health

The first is the notification URI endpoint to configure in Anchore Engine through
the ANCHORE_WEBHOOK_DESTINATION_URL environment variable to the catalog service.

The second is a helpful healthcheck URI endpoint that can be used if behind a
load balancer as it will return OK if it can successfully communicate with AWS
Simple Notification Service

## Configuring webhook-notifier

### Environment variables

The container handles the following environment variables. Most are optional and
do not need to be provided unless they apply.

| Environment Variable | Explanation |
|:---|:---|
|SNS_TOPIC_ARN|Full AWS ARN for SNS Topic. Optional if SNS_TOPIC_ARN_PREFIX provided.|
|SNS_TOPIC_ARN_PREFIX|Prefix of AWS ARN for SNS Topic that is appended with value of <user_id> from URI if SNS_TOPIC_ARN is not provided|
|AWS_DEFAULT_REGION|Optional AWS CLI environment variable. Defaults to 'us-east-1'|
|AWS_REGION|Optional AWS CLI environment variable. Defaults to 'us-east-1'|
|AWS_ACCESS_KEY_ID|Optional AWS CLI environment variable|
|AWS_SECRET_ACCESS_KEY|Optional AWS CLI environment variable|
|AWS_DEFAULT_PROFILE|Optional AWS CLI environment variable|
|AWS_SHARED_CREDENTIALS_FILE|Optional AWS CLI environment variable if mounting shared credentials file|
|AWS_CONFIG_FILE|Optional AWS CLI environment variable if mounting config file|
|AWS_CONTAINER_CREDENTIALS_RELATIVE_URI|AWS CLI environment variable set if running container under ECS IAM Task Role|
|AWS_EXECUTION_ENV|AWS CLI environment variable set if running container under AWS ECS|

### AWS SNS topic

At a bare minimum you need to provide either the `SNS_TOPIC_ARN` or
`SNS_TOPIC_ARN_PREFIX` if you setup a multiple SNS topics for each Anchore user
using a common naming prefix.

If you have the following Anchore users:

* `admin`
* `user1`
* `user2`

Then you setup the following SNS topics for users to subscribe to:

* `Anchore-admin`
* `Anchore-user1`
* `Anchore-user2`

You could then set your `SNS_TOPIC_ARN_PREFIX` to
`arn:aws:sns:<AWS REGION>:<AWS ACCOUNT ID>:Anchore-` and the SNS topic for
notifications to each Anchore user would be:

* `arn:aws:sns:<AWS REGION>:<AWS ACCOUNT ID>:Anchore-admin`
* `arn:aws:sns:<AWS REGION>:<AWS ACCOUNT ID>:Anchore-user1`
* `arn:aws:sns:<AWS REGION>:<AWS ACCOUNT ID>:Anchore-user2`


### SNS Topic Message Attributes and Subscription Filters

If you only provide the `SNS_TOPIC_ARN` users can still setup subscription filters
with SNS to only receive the notifications that they wish to. The webhook-notifier
will set the following `MessageAttributes` that can be used for subscription filters.

* notification_type
* subscription_key

These are set to the `notification_type` and `subscription_key` values of the
notification payload.

The `notification_type` being either `analysis_update`, `policy_eval`, `tag_update` or `vuln_update`.


The `subscription_key` being the Image Full Tag name
