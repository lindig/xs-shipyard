#
# Build Docker container for developing XenServer packages
#

CITRIX = --citrix
BRANCH = trunk-ring3

NAME = lindig/xs-shipyard
ARGS += --build-arg uid=$$(id -u)
ARGS += --build-arg gid=$$(id -g)

all:	Dockerfile
	docker build -t $(NAME) $(ARGS) .

# create a derived Docker image that includes build dependencies
# use as: "make xenopsd"
# These are set up to be used inside Citrix

%:
	( echo "FROM $(NAME)";\
	echo "RUN sudo ./yum-setup $(CITRIX) $(BRANCH)";\
	echo "RUN sudo yum-builddep -y $@";\
	) | docker build -t $(NAME)-$@:$(BRANCH) -

#
# create a container with Opam set up.
#

OPAM += opam
OPAM += ocaml
OPAM += ocaml-findlib-devel
OPAM += m4

OPAM_SED = /path/s!ocaml!ocaml:/home/builder/.opam/system/lib!

opam:
	( echo "FROM $(NAME)";\
	echo 'RUN sudo ./yum-setup $(CITRIX) $(BRANCH)';\
	echo 'RUN sudo yum install -y $(OPAM)';\
	echo "RUN sudo sed -i.bak '$(OPAM_SED)' /etc/ocamlfind.conf" ;\
	echo 'RUN opam init --no-setup';\
	echo 'RUN eval $$(opam config env)';\
	) | docker build -t $(NAME)-$@:$(BRANCH) -


PPX_OCAML = 4.02.3
PPX_OPAM  = https://github.com/xapi-project/opam-repo-dev
PPX_OPAM  = https://github.com/mseri/opam-repo-dev/
PPX_SED   = /path/s!ocaml!ocaml:/home/builder/.opam/$(PPX_OCAML)/lib!

PPX       += opam
PPX       += ocaml-findlib-devel
PPX       += m4

ppx:
	( echo "FROM $(NAME)";\
	echo 'RUN sudo ./yum-setup $(CITRIX) $(BRANCH)';\
	echo 'RUN sudo yum install -y $(PPX)';\
	echo "# RUN sudo sed -i.bak '$(PPX_SED)' /etc/ocamlfind.conf" ;\
	echo 'RUN opam init --no-setup --comp $(PPX_OCAML)';\
	echo 'RUN opam repo add -k git citrix $(PPX_OPAM)' ;\
	echo 'RUN opam install -y ocamlfind' ;\
	echo 'RUN opam install -y depext';\
	echo 'ENTRYPOINT [ "opam", "config", "exec", "--" ]' ;\
	echo 'CMD ["bash"]' ;\
	) | docker build -t $(NAME)-ppx:$(BRANCH) -

ppx/%:
	( echo "FROM $(NAME)";\
	echo 'RUN sudo ./yum-setup $(CITRIX) $(BRANCH)';\
	echo 'RUN sudo yum install -y $(PPX)';\
	echo "# RUN sudo sed -i.bak '$(PPX_SED)' /etc/ocamlfind.conf" ;\
	echo 'RUN opam init --no-setup --comp $(PPX_OCAML)';\
	echo 'RUN opam repo add -y -k git citrix $(PPX_OPAM)' ;\
	echo 'RUN opam install -y ocamlfind' ;\
	echo 'RUN opam install -y depext';\
	echo 'RUN .opam/$(PPX_OCAML)/bin/opam-depext $(@F)' ;\
	echo 'RUN opam install -y --deps-only $(@F)';\
	echo 'ENTRYPOINT [ "opam", "config", "exec", "--" ]' ;\
	echo 'CMD ["bash"]' ;\
	) | docker build -t $(NAME)-ppx-$(@F):$(BRANCH) -


