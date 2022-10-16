.PHONY: up
up:
	docker compose up -d

.PHONY: build
build:
	docker compose build

.PHONY: down
down:
	docker compose down

.PHONY: clean
clean:
	# ignore the exit status of the following commands
	# https://www.gnu.org/software/make/manual/make.html#Errors-in-Recipes
	-docker stop $$(docker ps -qa)
	-docker rm $$(docker container ls -qa)
	-docker image rm $$(docker image ls -qa)
	-docker volume rm $$(docker volume ls -q)
	-docker network rm $$(docker network ls -q) 2> /dev/null

.PHONY: lint
lint:
	hadolint --ignore DL3008 srcs/requirements/**/Dockerfile
