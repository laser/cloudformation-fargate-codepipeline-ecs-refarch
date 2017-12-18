# cloud-formation-ecs-docker-circle-ci

Provision an Fargate-backed ECS cluster (and related infrastructure) with 
CloudFormation. Zero-downtime (blue/green) deploys are kicked off by a push to 
GitHub, via CircleCI. Logs are sent to an app-specific CloudWatch group.

A simulated cluster to use during development is provided by Docker Compose.

## Local Development

To run the application in development mode:

```sh
docker-compose -f ./app/docker-compose.yml up
```

then, verify that the application is accessible:

```sh
curl -v 'http://localhost:3333'
```

## Deploying to AWS + CI

### 0. Tools and Dependencies

- [AWS CLI](https://github.com/aws/aws-cli) version >= `1.14.11`, for interacting with AWS
- [jq](https://github.com/stedolan/jq) version >= `jq-1.5`, for querying stack output-JSON
- an AWS [access key id and secret access key](http://docs.aws.amazon.com/general/latest/gr/managing-aws-access-keys.html)

### 1. Provision ECR and S3

```sh
./infrastructure/cloud-formation/scripts/bootstrap-stack-dependencies.sh your-app-name-here
```

### 2. Upload Stack YAML to S3

CloudFormation templates are stored in S3 - primarily so that our stack can be 
broken into separate files referenced via `TemplateURL` (see `master.yml`):

```sh
./infrastructure/cloud-formation/scripts/sync-cloud-formation-templates.sh your-app-name-here
```

### 3. Build and Push (to ECR) Service Image (first time)

Simulate something that a developer would do, e.g. update the app:

```sh
./app/scripts/simulate-development.sh
```

Build the Docker image and push to ECR:

```sh
./infrastructure/ci/scripts/build-app-and-push-to-ecr.sh your-app-name-here
```

### 4. Create the Stack

Create the VPC, security groups, ALB, ECS services, _et cetera_ (takes ~15 
minutes):

```sh
./infrastructure/cloud-formation/scripts/create-stack.sh your-app-name-here
```

To get the URL of the load balancer, use `describe-stacks`:

```sh
aws cloudformation --region us-east-1 describe-stacks --stack-name your-app-name-here \
    --query 'Stacks[0].Outputs[*].OutputValue'
```

###### Update the Stack

If you need to make changes to the stack, make edits to your YAML files, run 
the `sync-cloud-formation-templates.sh` script, and then `update-stack`:

```sh
aws cloudformation update-stack --stack-name your-app-name-here \
    --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM \
    --template-body file://./infrastructure/cloud-formation/templates/master.yml \
    --parameters "ParameterKey=S3TemplateKeyPrefix,ParameterValue=https://s3.amazonaws.com/your-app-name-here/infrastructure/cloud-formation/templates/"
```

### 5. Update the Service

Simulate something that a developer would do, e.g. update the app:

```sh
./app/scripts/simulate-development.sh
```

Build the Docker image and push to ECR:

```sh
./infrastructure/ci/scripts/build-app-and-push-to-ecr.sh your-app-name-here
```

Update the ECS service such that it uses the new task definition (CI would typically do this):

```sh
./infrastructure/ci/scripts/deploy-latest-build-to-ecs.sh your-app-name-here
```

### 6. Interact with the API

After the your-app-name-here stack has come online, make a request to it and 
verify that everything works:

```sh
curl $(aws cloudformation \
        describe-stacks \
        --query 'Stacks[0].Outputs[?OutputKey==`HelloworldServiceUrl`].OutputValue' \
        --stack-name your-app-name-here | jq '.[0]' | sed -e "s;\";;g")
```

...or in a loop:

```sh
while true; do curl $(aws cloudformation \
                       describe-stacks \
                       --query 'Stacks[0].Outputs[?OutputKey==`HelloworldServiceUrl`].OutputValue' \
                       --stack-name your-app-name-here | jq '.[0]' | sed -e "s;\";;g"); sleep 1; done
```

### TODO

- [ ] SSL termination
- [ ] Route53
- [ ] RDS instance + app to read database
- [ ] one-off task to run migrations before updating service
- [ ] create bastion instance for SSH
- [ ] CloudWatch logs example
- [ ] add a second service and demonstrate intra-network routing
- [ ] why "${TASK_FILE}" instead of "$TASK_FILE" ?