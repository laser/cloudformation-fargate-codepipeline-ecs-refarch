# cloud-formation-ecs-docker-circle-ci

![aws ecs reference architecture 2](https://user-images.githubusercontent.com/884507/34399624-d24950fe-eb3d-11e7-8c28-80afee284d53.png)

## What's the Point?

The purpose of this repository is to provide the necessary tools for a
single-command provisioning of a high-availability, Fargate-backed ECS cluster
to which you can deploy your application. *The included templates, CircleCI
configuration, and shell scripts should be reviewed before you use them in a 
production environment.*

The provided Cloud Formation templates can easily be extended to support
multiple web services, to integrate with AWS CI/CD tools (in lieu of CircleCI),
to use an Auto Scaling Group controlled by CloudWatch, _et cetera_.

## What You'll Get

After successfully creating the Cloud Formation stack and configuring CircleCI,
you'll have:

- a high-availability (multi-AZ) ECS cluster
- a load balancer routing requests to 4 instances of a Rails 5 application connected to an RDS Postgres database
- zero-downtime deploys from CircleCI to ECS
- automatic application of cluster-safe migrations
- centralized logging with CloudWatch
- a human-readible (kinda) hostname (from the LB) at which you can point your web browser

## What You Won't Get

There are a few things deliberately omitted from this repository, namely:

- CertificateManager/SSL support
- Zone53/DNS integration

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

Once your stack reaches the `CREATE_COMPLETE` state, you're ready to proceed.

### 2. Configure CircleCI

First, obtain the AWS secret key and AWS access key id that was provisioned for
your stack:

```sh
# access key id
aws cloudformation \
    describe-stacks \
    --region us-east-1 \
    --query 'Stacks[0].Outputs[?OutputKey==`ContinuousIntegrationAccessKeyId`].OutputValue' \
    --stack-name ${MASTER_STACK_NAME}-ecr | jq -r '.[0]'

# secret access key
aws cloudformation \
    describe-stacks \
    --region us-east-1 \
    --query 'Stacks[0].Outputs[?OutputKey==`ContinuousIntegrationSecretAccessKey`].OutputValue' \
    --stack-name ${MASTER_STACK_NAME}-ecr | jq -r '.[0]'
```

Then, log into CircleCI and configure a new project for your fork. When you've
done that, add a new environment variable (see _Build Setting_ section of the
settings screen's left-hand sidebar) called `MASTER_STACK_NAME` whose value is
whatever you've been using in place of `${MASTER_STACK_NAME}`. Finally, add the
AWS key id and AWS secret access key to your project's settings via the
_Permissions_ section of the settings screen's left-hand sidebar. The next push
you make to your GitHub-hosted repo should kick off a build (and deploy).

### 3. Trigger a Build

Simulate something that a developer would do, e.g. update the app:

```sh
perl -e \
    'open IN, "</usr/share/dict/words";rand($.) < 1 && ($n=$_) while <IN>;print $n' \
        | { read palabra; sed -i -e "s/\(<marquee>\).*\(<\/marquee>\)/<marquee>${palabra}<\/marquee>/g" ./app/app/views/static_pages/about.html.erb; }
```

Then, simply push your changes to your repository's `master` branch. You should
see your changes being built. Once the build is complete, ECS will perform a
blue/green deploy to your cluster.

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

Note: It can take a few minutes for a successful build to make its way to the ECS cluster.

### 4. Deleting Everything

To delete all the stacks you've created, run the following:

```sh
./infrastructure/cloud-formation/delete-stacks.sh $MASTER_STACK_NAME
```

### 5. Messing with the Cloud Formation Templates

If you've made changes to the Cloud Formation YAML and want to see those changes
reflected in your stack, run the following:

```sh
./infrastructure/cloud-formation/scripts/update-master-stack.sh ${MASTER_STACK_NAME}
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
