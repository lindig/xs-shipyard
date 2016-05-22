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

XenServer packages are build with `yum` and distributed as source and
binary RPMs. A package can be either re-build from a source package or
compiled from its source code on GitHub. This creates different
scenarios that we are discussing below. 

Most packages are written in [OCaml]. OCaml projects typically manage
their dependencies with OCaml's package manager Opam that installs the
necessary libraries.  This is _not_ the case for the RPM packages here:
build dependencies are provided by other RPMs and Opam is not used. This
makes it difficult to use OCaml libraries during development that are
not provided as RPMs - we will discuss this scenario, too.

## Building a Package from its SRPM

Let's assume you want to build [xen-api].  I suggest to mount a local
directory into the container under `/mnt` although it is not strictly
necessary.

On the host:

    IMG=xenserver-build-env:lindig
    docker run -i -t -v $PWD:/mnt $IMG /bin/bash

Inside the container:

    ./citrix trunk-ring3  # if you work at Citrix
    cd /mnt               # if you prefer to edit files on the host
    yumdownloader xen-api
    rpm -i xen-api*       # installs source package
    sudo yum-builddep -y yumbuild/SPEC/xen-api.spec




## Building a Package from GitHub

Let's assume you want to build the [Xen
API](https//github.com/xapi-project/xen-api) using the Docker container
you just built.

1.  Clone the project to your local machine:

        git clone git://github.com/xapi-project/xen-api

2.  Start the container and mount the local `xen-api` directory under
    `/mnt` inside the container:

        cd xen-api
        IMG=xenserver/xenserver-build-env:lindig
        docker run -i -t -v $PWD:/mnt $IMG

  Now the code can be edited inside and outside the container.

3.  If you are a developer at Citrix, you might want to use a 
    local branch; set it up inside the container:

        ./citrix trunk-ring3

4.  Inside the container, install the dependencies for the `xen-api`
    package:

        sudo yum-builddep xen-api

5.  Inside the container, build the package:

        cd /mnt
        ./configure 
        make
  
    Changes made inside `/mnt` are reflected on the local machine and vice
    versa. Hence, you can use the editor and tools on your local machine
    to work with the code inside the container.

## 

[xen-api]:  http://github.com/xapi-project/xen-api
[OCaml]:    http://www.ocaml.org/
