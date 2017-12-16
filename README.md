# cloud-formation-ecs-docker-circle-ci

Provision an ECS cluster (and related infrastructure) with CloudFormation, updating services with new tasks created by CircleCI

## Creating and Updating Docker Image

### Building

docker-compose build

### Running

docker-compose up

### Updating App

```sh
perl -e 'open IN, "</usr/share/dict/words";rand($.) < 1 && ($n=$_) while <IN>;print $n' | { read test; sed -i '' -e "s/\(<body>\).*\(<\/body>\)/<body>$test<\/body>/g" index.html; }
```

## Cloud Formation

### Upload Stack YAML to S3

```
ENV_NAME=brazenface ./bootstrap.sh
```

```
aws s3 sync ./cloud-formation "s3://$ENV_NAME/template-storage/" --acl public-read --delete
```

### Create the Stack

```
aws cloudformation create-stack --stack-name $ENV_NAME \
    --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM \
    --template-body file://./cloud-formation/master.yml \
    --parameters "ParameterKey=S3TemplateKeyPrefix,ParameterValue=https://s3.amazonaws.com/$ENV_NAME/template-storage/"
```
