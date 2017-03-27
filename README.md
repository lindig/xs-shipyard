<!-- vim: set ts=2 sw=2 et spell -->

[![Build Status](https://travis-ci.org/lindig/xs-shipyard.svg?branch=master)](https://travis-ci.org/lindig/xs-shipyard)
[![Docker Layers](https://images.microbadger.com/badges/image/lindig/xs-shipyard.svg)](https://microbadger.com/images/lindig/xs-shipyard)

# XenServer Shipyard

This [Docker] configuration provides an environment for building
XenServer toolstack packages.  By default, the container uses a Yum
repository that comes from the nightly snapshot uploads to
[xenserver.org](http://xenserver.org).

XenServer Shipyard is a fork of [xenserver-build-env]. For work inside
Citrix I recommend using `planex-buildenv` which also builds docker
containers for building toolstack components.

**This Docker configuration as of 27. March 2017 does not work reliably.
The official build of XenServer relies on a patched CentOS base image
that isn't publically available. This creates incompatibilities between
binaries created with this Docker image and binaries created with
official builds. In can be still used to compile code, though.**

## Building the Container

You'll need to install [Docker]. Follow the instructions for your platform
on [docker.com](https://www.docker.com/).

Build the docker image:

    make

The build takes into account your UID and GID to ensure that files
shared between host and container have the right identity.

The name of the container image is;

    lindig/xs-shipyard

You can also download pre-built containers from Docker:

    docker pull lindig/xs-shipyard

A pre-built container has the disadvantage that the files it creates in
a mounted volume don't have your UID/GID but 1000/1000. Therefore I
recommend building the container from the Dockerfile.

## Developing XenServer Packages - Overview

XenServer packages are built with Yum and distributed as source as well
as binary RPMs. A package can be either re-built from a source package
or compiled from its source code on GitHub. This creates different
scenarios that we are discussing below.

Most packages are written in [OCaml]. OCaml projects typically manage
their dependencies with OCaml's package manager Opam that installs the
necessary libraries.  This is _not_ the case for the RPM packages here:
build dependencies are provided by other RPMs and Opam is not used. This
makes it difficult to use OCaml libraries during development that are
not provided as Yum packages (RPMs) - we will discuss this scenario,
too.


## Building a Package from GitHub

Let's assume you want to build [xenopsd] from its sources on GitHub.

On the host, do:

    git clone git://github.com/xapi-project/xenopsd.git
    IMG=lindig/xs-shipyard
    docker run -i -t -v $PWD:/mnt $IMG

Inside the container, do:

The code is available under `/mnt`.

    sudo yum-builddep xenopsd

The last step installs the dependencies. It assumes that the code in the
GitHub repository doesn't need additional packages.

    cd /mnt
    . /etc/profile.d/opam.sh
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

## The Shortcut: Pre-Building Images

You will notice that developing a packages requires to install a large
number of packages inside the container. The `Makefile` supports this by
creating Docker images that already have these installed:

    make ring3/xapi

This creates a container `lindig/xs-shipyard-xapi:ring3` that has
all packages pre-installed for compiling the `xapi` component:

    git clone git://github.com/xapi-project/xen-api.git
    cd xen-api
    docker run --rm -itv $PWD:/mnt lindig/xs-shipyard-xapi:ring3

Inside the container:

    cd /mnt
    . /etc/profile.d/opam.sh
    make



[Docker]:   https://www.docker.com/
[xenopsd]:  http://github.com/xapi-project/xenopsd
[OCaml]:    http://www.ocaml.org/
[xenserver-build-env]: http://github.com/xenserver/xenserver-build-env
