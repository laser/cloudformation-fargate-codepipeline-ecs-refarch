# cloud-formation-ecs-docker-circle-ci

Provision an Fargate-backed ECS cluster (and related infrastructure) with 
CloudFormation. Zero-downtime (blue/green) deploys are kicked off by a push to
GitHub, via CircleCI. Logs are sent to an app-specific CloudWatch group.

The deployed application is a simple web server which responds to HTTP requests
with the contents of an HTML file, `index.html`. Locally, we simulate the AWS
environment that our application will be running in through our use of Docker
Compose.

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

### 1. Create the Stacks

The following command will create the ECR stack (which holds your application's
Docker images), the S3 stack (which holds your Cloud Formation templates), and
the master stack (which defines a VPC, ALB, ECS cluster, etc.). Note: Your 
application will be built and pushed to this new ECR repository during the 
stack creation process.

```sh
./infrastructure/cloud-formation/scripts/create-stacks.sh your-app-name-here
```

### 2. Updating the Main Stack

To tell Cloud Formation about changes you've made to the master stack's YAML 
files, run:

```sh
./infrastructure/cloud-formation/scripts/update-master-stack.sh your-app-name-here
```

### 3. CI: Updating the ECS Service

Simulate something that a developer would do, e.g. update the app:

```sh
./app/scripts/simulate-development.sh
```

Build the Docker image and push to ECR (CI would typically do this):

```sh
./infrastructure/ci/scripts/build-app-and-push-to-ecr.sh your-app-name-here
```

Update the ECS service such that it uses the new task definition (CI would 
typically do this):

```sh
./infrastructure/ci/scripts/deploy-latest-build-to-ecs.sh your-app-name-here
```

### 4. Interact with the Application

After the your-app-name-here stack has come online, make a request to it and 
verify that everything works:

```sh
curl $(aws cloudformation \
    describe-stacks \
    --query 'Stacks[0].Outputs[?OutputKey==`WebServiceUrl`].OutputValue' \
    --stack-name your-app-name-here | jq '.[0]' | sed -e "s;\";;g")
```

...or in a loop:

```sh
while true; do curl $(aws cloudformation \
   describe-stacks \
   --query 'Stacks[0].Outputs[?OutputKey==`WebServiceUrl`].OutputValue' \
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