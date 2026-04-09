LOGIN 		?= $(shell grep LOGIN .env | cut -d '=' -f2)
DOMAIN		?= $(shell grep DOMAIN_NAME .env | cut -d '=' -f2)

DATA_DIR	= /home/$(LOGIN)/data

all:
	echo "Creating the resources for $(DOMAIN_NAME)"
	mkdir -p $(DATA_DIR)/mariab
	mkdir -p $(DATA_DIR)/wordpress

	docker compose -f srcs/docker-compose.yml up -d --build

up:
	docker compose -f srcs/docker-compose.yml -p inception up -d

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
