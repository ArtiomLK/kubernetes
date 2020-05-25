# Docker Commands

| Command                                                                                                                       | Description                                                             |
| ----------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| `docker build -t {DOCKER_IMAGE_NAME}:{TAG} -f {FILE_NAME} .`                                                                  | Creates a docker image from a Dockerfile in the current directory       |
| `docker images`                                                                                                               | Displays docker images                                                  |
| `docker volume ls`                                                                                                            | Displays docker volumes                                                 |
| `docker rmi {DOCKER_IMAGE_NAME}`                                                                                              | Deletes a docker image                                                  |
| `docker run -v ${PWD}:/app -v /app/node_modules -p 3001:3000 --rm {DOCKER_IMAGE_NAME}:{TAG}`                                  | Runs a docker image                                                     |
| `docker run -itd --rm -v ${PWD}:/app -v /app/node_modules -p 3001:3000 -e CHOKIDAR_USEPOLLING=true {DOCKER_IMAGE_NAME}:{TAG}` | Runs a docker image with hot-reloading                                  |
| `docker inspect {DOCKER_CONTAINER}`                                                                                           | Displays detailed information about the container                       |
| `docker ps .`                                                                                                                 | Displays running docker containers                                      |
| `docker stop {DOCKER_CONTAINER}`                                                                                              | Stops a docker container                                                |
| `docker rm -v {DOCKER_CONTAINER}`                                                                                             | Removes a docker container and its volumes                              |
| `docker rm -f {DOCKER_CONTAINER}`                                                                                             | Stops and deletes a docker container                                    |
| `docker rm -f $(docker ps -a -q)`                                                                                             | Stops and deletes all docker containers                                 |
| `docker rmi --force $(docker images -q --filter "dangling=true")`                                                             | Deletes all dangling images including those with **none** names or tags |
