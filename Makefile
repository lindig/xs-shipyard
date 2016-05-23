# 
# Build Docker container for developing XenServer packages
#

NAME = 	xenserver/xenserver-build-env:lindig
# ARGS += --build-arg uid=$$(id -u)
# ARGS += --build-arg gid=$$(id -g)

all:	Dockerfile
	docker build -t $(NAME) $(ARGS) .

