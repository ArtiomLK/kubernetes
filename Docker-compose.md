# docker-compose Commands

| Command                                              | Description                                                     |
| ---------------------------------------------------- | --------------------------------------------------------------- |
| `docker-compose -f {COMPOSE_FILE} build`             | Builds containers based on the provided docker-compose file     |
| `docker-compose -f {COMPOSE_FILE} up`                | Starts the containers based on the provided docker-compose file |
| `docker-compose -f {COMPOSE_FILE} down --rmi all -v` | Stop and remove containers, networks, images, and volumes       |
