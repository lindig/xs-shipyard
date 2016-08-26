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
	( echo "FROM $(NAME)"; \
	echo "RUN sudo ./yum-setup --citrix"; \
	echo "RUN sudo yum-builddep -y $@" ) | docker build -t $(NAME)-$@ -

pvs:
	( echo "FROM $(NAME)"; \
	echo "RUN sudo ./yum-setup --citrix trunk-pvs-direct"; \
	echo "RUN sudo yum-builddep -y xapi" ) | docker build -t $(NAME)-$@ -

# 
# create a container with Opam set up.
#

OPAM += opam
OPAM += ocaml
OPAM += ocaml-findlib-devel

OPAM_SED = /path/s!ocaml!ocaml:/home/builder/.opam/system/lib!

opam:
	( echo "FROM $(NAME)"; \
	echo 'RUN sudo ./yum-setup --citrix';\
	echo 'RUN sudo yum install -y $(OPAM)';\
	echo "RUN sudo sed -i.bak '$(OPAM_SED)' /etc/ocamlfind.conf" ;\
	echo 'RUN opam init --no-setup';\
	echo 'RUN eval $$(opam config env)';\
	) | docker build -t $(NAME)-$@ -
