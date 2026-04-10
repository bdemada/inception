# Developer Documentation

### Environment Setup:
To configure your codebase:
1. Formulate the `.env`in the `srcs\` directory, based on the .env.example file and fill in the necessary values.
2. Create the secrets files in the `secrets\` directory, based on the secrets.example file and fill in the necessary values.:
   * `db_name`
   * `db_user`
   * `db_password`
   * `db_root_password`
   * `wp_admin_password`
   * `wp_admin_email`
   * `wp_user`
   * `wp_user_password`
   * `wp_user_email`
**NOTE**: Creaate the `/home/<your_username>/data/mariadb` and `/home/<your_username>/data/wordpress` directories manually on your local machine to store the database and WordPress data if Makefile permissions fault. Ensure Doocker runtime can bind against local host directories securely.

### Building and Running the Application:
1. Navigate to the root directory of the project in your terminal.
2. Run `make` to build the Docker images and start the containers. This command will execute the following steps:
   - Build the Docker images for nginx, WordPress, and MariaDB using the provided Dockerfiles.
   - Create and start the containers based on the defined services in the `docker-compose.yml` file.
   - Set up the necessary volumes and networks for inter-container communication.

* To stop the application, run `make stop` to gracefully shut down the containers.
* To clean up the environment, run `make clean` to remove the containers, images, and volumes created during the setup.
* **Deep Wipe**: If you want to remove all containers, images, and volumes, run `make fclean`. This will ensure a complete cleanup of the environment, clearing all mounted local volumes as well.

### Container & Volume Management:
* `docker compose -f srcs/docker-compose.yml ps` - List all running containers and their status.
* `docker compose -f srcs/docker-compose.yml logs` - View the logs of all containers to monitor their output and debug any issues.
* `docker compose -f srcs/docker-compose.yml build` - Validate Dockerfile implementation iteratively without daemon lock.
* `docker network ls` - Confirm `inception_net` is created and inspect its configuration.


### Architecture Summary
```
Internet
   │
   ▼
[nginx:80]  ←──── frontend network (public)
   │                       │
   │ fastcgi (port 9000)   │ static files (shared volume)
   ▼                       │
[wordpress:9000] ──────────┘
   │
   │ TCP 3306
   ▼
[mariadb:3306]
        ↑
   backend network (internal: true — no host exposure)

### Persistency logic:
Data is mounted distinctly out of the ephemeral container instances back to the local host filesystem, ensuring that database and WordPress content persist across container restarts and rebuilds. This is achieved through Docker volumes defined in the `docker-compose.yml` file, which map the container directories to specific paths on the host machine.
* WordPress data is stored in `/home/<your_username>/data/wordpress` on the host, mapped to `/var/www/html` in the WordPress container.
* MariaDB data is stored in `/home/<your_username>/data/mariadb` on the host, mapped to `/var/lib/mysql` in the MariaDB container.
Docker abstracts these ussing internal named volumes defined strictly securely under the `volumes` section of the `docker-compose.yml`, ensuring that data integrity is maintained while allowing for easy management and backup of persistent data.
