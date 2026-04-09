# User Documentation

### Services provided by the stack:
1. **nginx**: Acts as a reverse proxy server, forwarding incoming HTTP requests to the WordPress container. It is the exclusive SSL/TLS entrypoint, validating users exclusively on port 443 before proxying to WordPress
2. **WordPress**: Hosts the WordPress application, serving dynamic content and handling PHP processing. It is configured to communicate with the MariaDB container for database operations and acts as the promary Content Management System (CMS) for the stack.
3. **MariaDB**: Provides the database service for WordPress, storing all the necessary data such as posts, user information, and configuration settings. It is configured to allow connections only from the WordPress container, ensuring secure communication between the two services.

### How to start and stop the application:
To start the services natively:
```bash
make
# or alternatively
make all
```

To stop the application, run:
```bash
make down
# or alternatively to remove all containers and images
make clean
# or for a deep wipe of all containers, images, and volumes
make fclean
```

### Accessing the website and the admin panel:
Open your browser and navigate to `https://<your_username>.42.fr` to access the WordPress website.
To access the admin panel, navigate to `https://<your_username>.42.fr/wp-admin` and log in with the credentials you set up during the WordPress installation process.
Note: You might get a security warning due to the self-signed SSL certificate. You can safely bypass this warning to access the site.

### Credentials management:
All environment configurations, database user roles and administratos are governed by the `srcs/.env` file, and the respective passwords for each user are stored securely in the `secrets/` directory, which is mounted as a volume in the respective containers. This ensures that sensitive information is not hardcoded into the application and can be easily managed and updated without modifying the codebase. The `.env` file should contain all necessary environment variables for the application to function correctly, including database credentials, WordPress configuration settings, and any other relevant parameters required for the services to operate seamlessly.

### Service diagnostics:
Check running status on the terminal with:
```bash
docker compose -f srcs/docker-compose.yml ps
```

Or view discrete logs for each container with:
```bash
docker logs <container_name>
```