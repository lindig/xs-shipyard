#
# Build Docker container for developing XenServer packages
#

NAME = lindig/xs-shipyard
ARGS += --build-arg uid=$$(id -u)
ARGS += --build-arg gid=$$(id -g)

all:	Dockerfile
	docker build -t $(NAME) $(ARGS) .

# create a derived Docker image that includes build dependencies
# use as: "make xenopsd"
# These are set up to be used inside Citrix

%:
	@test `dirname $@` != . || (echo "use: $(MAKE) trunk-ring3/$@"; false)
	( echo "FROM $(NAME)";\
	echo "RUN sudo ./yum-setup $(@D)";\
	echo "RUN sudo yum-builddep -y $(@F)";\
	) | docker build -t $(NAME)-$(@F):$(@D) -



