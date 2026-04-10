*This project has been created as part of the 42 curriculum by bde-mada*

# 🚀 Inception: System Administration with Docker

## Project Overview
Inception is a foundational System Administration project at 42 that introduces the power of **containerization**. Instead of setting up services directly on a host machine, we use Docker to build a small, isolated infrastructure. The goal is to create a multi-container environment where each service runs in its own "bubble," ensuring that the entire setup is portable, reproducible, and secure.

This infrastructure consists of:
- **Nginx**: The web server and only entry point, secured with mandatory TLS (v1.2/v1.3).
- **WordPress & PHP-FPM**: The application layer that serves the website content.
- **MariaDB**: The database engine that stores all WordPress data.
- **Docker Volumes**: Specialized storage zones that keep your data safe even if containers are deleted.
- **Docker Network**: A private virtual "switch" that allows containers to talk to each other while staying hidden from the outside world.

---

## 🛠️ Instructions for Use

### Prerequisites
- A Debian-based system (or a Virtual Machine running Debian).
- Docker and Docker Compose installed.
- Your user must be part of the `docker` group (so you don't need `sudo` for every command).

### Quick Start
1. **Clone the Repo**: Download the project files to your machine.
2. **Configure Environment**: Create a `.env` file at the root (use `.env.example` as a template). 
   > **Note**: In the volume paths, make sure to replace `login` with your actual system username.
3. **Build and Launch**:
   ```bash
   make
   ```
   This command is automated to do the heavy lifting: it checks your configuration, sets up local folders for data, adds your domain to `/etc/hosts`, and builds the images from scratch.

### Useful Commands
- `make stop`: Pauses the containers without deleting them.
- `make clean`: Removes the containers and the virtual network.
- `make fclean`: The "factory reset" — removes everything, including your persistent database and website files.
- `make logs`: View the live output from all services to see what's happening under the hood.

---

## 📚 Resources & Learning Path
If you are new to the world of containers, these resources are essential:
- [Docker for Beginners](https://docs.docker.com/get-started/): Understand the "What" and "Why" of containers.
- [Docker Compose Overview](https://docs.docker.com/compose/): Learn how to orchestrate multiple services.
- [Nginx TLS Guide](https://nginx.org/en/docs/http/configuring_https_servers.html): Deep dive into making your connection secure.

### AI Usage Disclosure
AI was consulted during this project to:
- Debug complex shell scripts used for container initialization (e.g., fixing shebang issues and variable typos).
- Help draft clear, pedagogical explanations for technical concepts in this documentation.

---

## 🧠 Project Design & Fundamentals

### Why Docker?
In traditional sysadmin work, installing a database or a web server directly on your host can lead to "dependency hell"—where different apps need different versions of the same tool. Docker solves this by letting us package the app and its specific needs into a **Container Image**. We chose **Alpine Linux** as our base because it is incredibly lightweight (only ~5MB), reducing the attack surface and resource usage.

### Fundamental Comparisons

#### 1. Virtual Machines vs. Docker
*   **Virtual Machines (VMs)**: Each VM includes a full copy of an Operating System. It's like running a computer inside a computer. This is "heavy" because it emulates hardware and consumes a lot of RAM and CPU just to keep the guest OS running.
*   **Docker**: Containers share the host's Linux kernel. They don't need their own OS. Think of it as processes that are isolated by a "curtain" rather than a "brick wall." This makes them much faster and lighter.

#### 2. Secrets vs. Environment Variables
*   **Environment Variables**: Easy to use but "leaky." If you run `docker inspect`, anyone with access can see your passwords. Use these for non-sensitive settings (like a domain name).
*   **Secrets**: Much safer for passwords. Docker mounts secrets into the container as files in a temporary location (`/run/secrets/`). They are never stored in the image and are harder to accidentally expose.

#### 3. Docker Network vs. Host Network
*   **Docker Network**: By default, Docker creates a private virtual network. Containers can talk to each other using their service names (like `mariadb` or `wordpress`) as hostnames. This provides a layer of security by keeping most traffic off your real network.
*   **Host Network**: The container sits directly on your machine's network. While faster, it's risky because any vulnerability in the container is directly exposed to your local network.

#### 4. Docker Volumes vs. Bind Mounts
*   **Docker Volumes**: Managed entirely by Docker. They are high-performance and portable. If you move your project to another machine, volumes are easier to migrate.
*   **Bind Mounts**: A direct link to a folder on your host machine. Great for development, but they make the container dependent on your specific host's file structure, which goes against the goal of "build once, run anywhere."
