# cloud-formation-ecs-docker-circle-ci

Provision an ECS cluster (and related infrastructure) with CloudFormation, 
updating services with new tasks created by CircleCI

## 1. Provision ECR and S3

```
./bootstrap.sh your-app-name-here
```

## 2. Upload Stack YAML to S3

CloudFormation templates are stored in S3 - primarily so that our stack can be 
broken into separate files referenced via `TemplateURL` (see `master.yml`):

```
./sync-cloud-formation-templates.sh your-app-name-here
```

## 3. Build and Push (to ECR) Service Image (first time)

Simulate something that a developer would do, e.g. update the app:

```sh
./update-website.sh
```

Build the Docker image and push to ECR:

```sh
./build-and-push.sh your-app-name-here
```

## 4. Create the Stack

Create the VPC, security groups, ALB, ECS services, _et cetera_ (takes ~15 
minutes):

```
aws cloudformation create-stack --stack-name your-app-name-here \
    --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM \
    --template-body file://./cloud-formation/master.yml \
    --parameters "ParameterKey=S3TemplateKeyPrefix,ParameterValue=https://s3.amazonaws.com/$ENV_NAME/template-storage/"
```

To get the URL of the load balancer, use `describe-stacks`:

```
aws cloudformation --region us-east-1 describe-stacks --stack-name your-app-name-here \
    --query 'Stacks[0].Outputs[*].OutputValue'
```

### Update the Stack

If you need to make changes to the stack, make edits to your YAML files, run 
the `sync-cloud-formation-templates.sh` script, and then `update-stack`:

```
aws cloudformation update-stack --stack-name your-app-name-here \
    --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM \
    --template-body file://./cloud-formation/master.yml \
    --parameters "ParameterKey=S3TemplateKeyPrefix,ParameterValue=https://s3.amazonaws.com/$ENV_NAME/template-storage/"
```

## 5. Update the Service

## TODO

- [ ] get rid of the multi-region load balancing stuff
- [ ] domain name?
- [ ] Fargate?
- [ ] when to use default VPC? When to create new one?
- [ ] SSL
- [ ] RDS
- [ ] update app to use a database (use `word` to create a new migration)
- [ ] Migrationsß