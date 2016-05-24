<!-- vim: set ts=2 sw=2 et spell -->

# xenserver-build-env

This docker configuration provides an environment to build and work on
XenServer packages. For developers inside Citrix it provides optional
access to internal repositories.

By default, the container references a yum repository that comes from the
nightly snapshot uploads to [xenserver.org](http://xenserver.org).

## Building the Container

You'll need to install Docker. Follow the instructions for your platform
on [docker.com](https://www.docker.com/).

Build the docker image:

    make

The build takes into account your UID and GID to ensure that files
shared between host and container have the right identity.

The name of the container is:

    xenserver-build-env:lindig 

## Developing XenServer Packages – Overview

XenServer packages are build with Yum and distributed as source as well
as binary RPMs. A package can be either re-build from a source package
or compiled from its source code on GitHub. This creates different
scenarios that we are discussing below. 

Most packages are written in [OCaml]. OCaml projects typically manage
their dependencies with OCaml's package manager Opam that installs the
necessary libraries.  This is _not_ the case for the RPM packages here:
build dependencies are provided by other RPMs and Opam is not used. This
makes it difficult to use OCaml libraries during development that are
not provided as Yum packages (RPMs) - we will discuss this scenario,
too.

## Building a Package from its SRPM

Let's assume you want to build [xenopsd] from its source code package.
I suggest to mount a local directory into the container under `/mnt`
although it is not strictly necessary.

On the host:

    IMG=xenserver-build-env:lindig
    docker run -i -t -v $PWD:/mnt $IMG /bin/bash

Inside the container

    ./citrix trunk-ring3  # if you work at Citrix
    cd /mnt               # if you prefer to edit files on the host

    sudo yum-builddep xenopsd
    yumdownloader --source xenopsd
    rpm -i xenopsd*       # installs source package into ./rpmbuild/
    # the souce code is in rpmbuild/BUILD/xenopsd*
    rpmbuild -ba rpmbuild/SPECS/xenopsd.spec # builds it as a package
    
## Building a Package from GitHub

Let's assume you want to build [xenopsd] from its sources on GitHub.

On the host:
    
    git clone git://github.com/xapi-project/xenopsd.git
    IMG=xenserver-build-env:lindig
    docker run -i -t -v $PWD:/mnt $IMG /bin/bash

Inside the container:

The code is available under `/mnt`.
    
    ./citrix trunk-ring3  # if you work at Citrix
    sudo yum-builddep xenopsd

    cd /mnt               
    ./configure
    make

You can change the code and use Git to manage changes. Changes become
visible outside the container.

This method relies on the installation of all dependencies with
`yum-builddep` before building the package with `make`.  If you extend
the code and need additional packages, you have to install them with
yum:

    sudo yum -y install ocaml-bisect-ppx-devel

A problem arises if you need a package that is not yet available as a Yum
package. Typically one would use the OCaml package manager Opam to
install it. However, Opam does not interact nicely with Yum.
    
## Using Opam

    sudo yum -y install ocaml
    sudo yum -y install ocaml-findlib-devel
    sudo yum -y install opam
    opam init
    eval $(opam config env)
    sed -i.bak '/path/s!"$!:/home/builder/.opam/system/lib"!'

[xenopsd]:  http://github.com/xapi-project/xenopsd 
[OCaml]:    http://www.ocaml.org/
