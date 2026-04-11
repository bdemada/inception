LOGIN 		= $(shell grep LOGIN .env | cut -d '=' -f2)
DOMAIN		= $(shell grep DOMAIN_NAME .env | cut -d '=' -f2)
DATA_DIR	= /home/bde-mada/data

all:
	@echo "Checking the prerequisites:"
	@if ! grep -q "$(DOMAIN)" /etc/hosts; then \
		echo "Adding $(DOMAIN) to hosts file (/etc/hosts)"; \
		echo "⚠️You might be asked for your sudo password"; \
		sudo sh -c 'echo "127.0.0.1 $(DOMAIN)" >> /etc/hosts'; \
		echo "Domain added to hosts file✅"; \
		else echo "Domain already in hosts file✅"; \
	fi
	@if [ ! -f .env ]; then \
		echo ".env file not defined❌"; \
		echo "❗copy the .env.example file, fill the required fields, and place it on the root of the project"; \
		exit 1; \
		else echo ".env file found✅"; \
	fi
	@if [ ! -d secrets ]; then \
		echo "secrets folder missing❌"; \
		echo "❗create the secrets folder at the root of the project and add the required secret files"; \
		exit 1; \
		else echo "secrets folder found✅"; \
	fi
	@if [ ! -d $(DATA_DIR)/mariadb ]; then \
		echo "Mariadb data folder missing❌. Creating..."; \
		echo "⚠️You might be asked for your sudo password"; \
		sudo mkdir -p $(DATA_DIR)/mariadb; \
		else echo "Mariadb data folder in place✅"; \
	fi
	@if [ ! -d $(DATA_DIR)/wordpress ]; then \
		echo "Wordpress data folder missing❌. Creating..."; \
		echo "⚠️You might be asked for your sudo password"; \
		sudo mkdir -p $(DATA_DIR)/wordpress; \
		else echo "Wordpress data folder in place✅"; \
	fi

	@echo "Prerequisites validated."
	@echo "Building the project..."
	docker compose -f srcs/docker-compose.yml up -d --build
	@echo "Application running successfully"
	@echo "You can access pressing ctrl+click on the following link "
	@echo "https://$(DOMAIN)"
	@echo "Access the admin portal here"
	@echo "https://$(DOMAIN)/wp-admin"

up: all

down:
	docker compose -f srcs/docker-compose.yml -p srcs down

clean:
	docker compose -f srcs/docker-compose.yml -p srcs down --rmi all -v

fclean: clean
	docker system prune -af
	echo "⚠️You might be asked for your sudo password"; \
	sudo rm -rf $(DATA_DIR)/mariadb/*
	sudo rm -rf $(DATA_DIR)/wordpress/*

re: fclean all

logs:
	docker compose logs -f srcs/docker-compose.yml

.PHONY: all up down clean fclean re logs
