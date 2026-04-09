LOGIN 		= $(shell grep LOGIN .env | cut -d '=' -f2)
DOMAIN		= $(shell grep DOMAIN_NAME .env | cut -d '=' -f2)

DATA_DIR	= /home/bde-mada/data

all:
	@echo "Checking the prerequisites:"
	@if ! grep -q "$(DOMAIN)" /etc/hosts; then \
		echo "Adding $(DOMAIN) to hosts file (/etc/hosts)"; \
		sudo sh -c 'echo "127.0.0.1 $(DOMAIN)" >> /etc/hosts'; \
		echo "Domain added to hosts file"; \
		else echo "Domain already in hosts file"; \
	fi
	@if [ ! -f .env ]; then \
		echo ".env file not defined"; \
		echo "copy the .env.example file, fill the required fields, and place it on the root of the project"; \
		else echo ".env file found"; \
	fi
	@if [ ! -d $(DATA_DIR)/mariab ]; then \
		echo "Mariadb data folder missing. Creating..."; \
		mkdir -p $(DATA_DIR)/mariab; \
		else echo "Mariadb data folder already in place"; \
	fi
	@if [ ! -d $(DATA_DIR)/wordpress ]; then \
		echo "Wordpress data folder missing. Creating..."; \
		mkdir -p $(DATA_DIR)/wordpress; \
		else echo "Wordpress data folder already in place"; \
	fi

	@echo "Prerequisites validated."
	@echo "Building the project..."
	docker compose -f srcs/docker-compose.yml up -d --build

up: all

down:
	docker compose -f srcs/docker-compose.yml -p inception down

clean:
	docker compose -f srcs/docker-compose.yml -p inception down --rmi all -v

fclean: clean
	rm -rf $(DATA_DIR)/mariadb/*
	rm -rf $(DATA_DIR)/wordpress/*
	docker system prune -af

re: fclean all

logs:
	docker compose logs -f

.PHONY: all up down clean fclean re logs
