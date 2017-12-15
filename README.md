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
