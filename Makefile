#
# Build Docker container for developing XenServer packages
#

NAME = lindig/xs-shipyard
ARGS += --build-arg uid=$$(id -u)
ARGS += --build-arg gid=$$(id -g)

all:	Dockerfile
	docker build -t $(NAME) $(ARGS) .

args:
	echo $(ARGS)
