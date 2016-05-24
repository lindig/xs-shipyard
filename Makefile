# 
# Build Docker container for developing XenServer packages
#

BASE = 'aHR0cDovL3hzLXl1bS1yZXBvcy5zMy13ZWJzaXRlLXVzLWVhc3QtMS5hbWF6b25hd3MuY29tLzQ0OWU1MmE0LTI3MWEtNDgzYS1iYWE3LTI0YmYzNjI4NjZmNy9kb21haW4wCg=='

NAME = 	xenserver/xenserver-build-env:lindig
ARGS += --build-arg uid=$$(id -u)
ARGS += --build-arg gid=$$(id -g)
ARGS += --build-arg baseurl=$$(echo $(BASE) | base64 -d)

all:	Dockerfile
	docker build -t $(NAME) $(ARGS) .

args:
	echo $(ARGS)
