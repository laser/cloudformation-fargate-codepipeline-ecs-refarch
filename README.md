# cloud-formation-ecs-docker-circle-ci



Provision an Fargate-backed ECS cluster (and related infrastructure) with
CloudFormation. Zero-downtime (blue/green) deploys are kicked off by a push to
GitHub, via CircleCI. The application relies upon an RDS Postgres instance, also
provisioned by Cloud Formation. Logs are sent to a CloudWatch group.

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

- [Docker Compose](https://docs.docker.com/compose/)
- [AWS CLI](https://github.com/aws/aws-cli) version >= `1.14.11` configured to use the `us-east-1` as its default region (for Fargate support)
- [jq](https://github.com/stedolan/jq) version >= `jq-1.5`, for querying stack output-JSON
- an AWS [access key id and secret access key](http://docs.aws.amazon.com/general/latest/gr/managing-aws-access-keys.html)
- a fork of this repository (so that you can integrate with CircleCI)

### 1. Create the Stacks

First, pick an alphanumeric name for your stack:

```
export MASTER_STACK_NAME=riskypiglet
```

The following command will create the ECR stack (which holds your application's
Docker images), the S3 stack (which holds your Cloud Formation templates), and
the master stack (which defines a VPC, ALB, ECS cluster, etc.). Note: Your
application will be built and pushed to this new ECR repository during the
stack creation process.

```sh
./infrastructure/cloud-formation/scripts/create-stacks.sh ${MASTER_STACK_NAME}
```

#### Bonus: Updating the Main Stack

To tell Cloud Formation about changes you've made to the master stack's YAML
files, run:

```sh
./infrastructure/cloud-formation/scripts/update-master-stack.sh ${MASTER_STACK_NAME}
```

### 2. CI: Updating the ECS Service

Simulate something that a developer would do, e.g. update the app:

```sh
perl -e \
    'open IN, "</usr/share/dict/words";rand($.) < 1 && ($n=$_) while <IN>;print $n' \
        | { read palabra; sed -i -e "s/\(<body>\).*\(<\/body>\)/<body>${palabra}<\/body>/g" ./app/index.html; }
```

Log in to ECR:

```sh
$(aws ecr get-login --no-include-email --region us-east-1)
```

Build the Docker image:

```sh
docker-compose -p app -f ./app/docker-compose.yml build
```

and push to ECR (CI would typically do this):

```sh
./infrastructure/ci/scripts/tag-image-and-push-to-ecr.sh ${MASTER_STACK_NAME}
```

Update the ECS service such that it uses the new task definition (CI would
typically do this):

```sh
./infrastructure/ci/scripts/deploy-latest-build-to-ecs.sh ${MASTER_STACK_NAME}
```

### 3. Interact with the Application

After the stack has come online, make a request to it and verify that everything
works:

```sh
curl -v $(aws cloudformation \
    describe-stacks \
    --query 'Stacks[0].Outputs[?OutputKey==`WebServiceUrl`].OutputValue' \
    --stack-name ${MASTER_STACK_NAME} | jq '.[0]' | sed -e "s;\";;g")
```

...or in a loop:

```sh
while true; do curl -v $(aws cloudformation \
   describe-stacks \
   --query 'Stacks[0].Outputs[?OutputKey==`WebServiceUrl`].OutputValue' \
   --stack-name ${MASTER_STACK_NAME} | jq '.[0]' | sed -e "s;\";;g"); sleep 1; done
```

### 4. Configure CircleCI

First, obtain the AWS secret key and AWS access key id that was provisioned for
your stack:

```sh
# access key id
aws cloudformation \
    describe-stacks \
    --region us-east-1 \
    --query 'Stacks[0].Outputs[?OutputKey==`ContinuousIntegrationAccessKeyId`].OutputValue' \
    --stack-name ${MASTER_STACK_NAME}-ecr | jq '.[0]' | sed -e "s;\";;g")

# secret access key
aws cloudformation \
    describe-stacks \
    --region us-east-1 \
    --query 'Stacks[0].Outputs[?OutputKey==`ContinuousIntegrationSecretAccessKey`].OutputValue' \
    --stack-name ${MASTER_STACK_NAME}-ecr | jq '.[0]' | sed -e "s;\";;g")
```

Then, log into CircleCI and configure a new project using your fork. When you've
done that, add a new environment variable (see _Build Setting_ section of the
settings screen's left-hand sidebar) called `MASTER_STACK_NAME` whose value is
whatever you've been using in place of `${MASTER_STACK_NAME}`. Finally, add the
AWS key id and AWS secret access key to your project's settings via the
_Permissions_ section of the settings screen's left-hand sidebar. The next push
you make to your GitHub-hosted repo should kick off a build (and deploy).

### 5. Deleting Everything

To delete all the stacks you've created, run the following:

```sh
./infrastructure/cloud-formation/delete-stacks.sh $MASTER_STACK_NAME
```

### TODO

- [ ] replace embedded app with Rails
- [ ] SSL
- [ ] Route53
- [ ] tailing (or equivalent) CloudWatch logs example
- [ ] ensure that the ALB path is configured correctly (add more paths to app)
- [ ] Code Pipeline + Code Deploy (or CircleCI)
- [x] modify healthcheck to help differentiate from user requests in the logs
- [x] RDS instance + app to read database
- [x] provision an IAM user for CI and add AmazonEC2ContainerRegistryFullAccess policy
- [x] deploy script should get container and task family names from stack output
- [x] one-off task to run migrations before updating service

### Blog Post
- [ ] COPY versus VOLUME during dev
- [ ] docker-entrypoint.sh reads environment variables for decision to run migrations
- [ ] attaching a debugger to the app
- [ ] running multiple (local) instances with Docker Compose
- [ ] deploys with downtime
- [ ] secrets in an S3 bucket
- [ ] ENTRYPOINT shell versus exec form and interaction with Docker Compose
- [ ] CircleCI executor types (machine versus docker)
