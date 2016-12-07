<!-- vim: set ts=2 sw=2 et spell -->

[![Build Status](https://travis-ci.org/lindig/xs-shipyard.svg?branch=master)](https://travis-ci.org/lindig/xs-shipyard)
[![Docker Layers](https://images.microbadger.com/badges/image/lindig/xs-shipyard.svg)](https://microbadger.com/images/lindig/xs-shipyard)

# XenServer Shipyard

This [Docker] configuration provides an environment for building
XenServer toolstack packages.  By default, the container uses a Yum
repository that comes from the nightly snapshot uploads to
[xenserver.org](http://xenserver.org).  For developers inside Citrix it
provides optional access to internal repositories.

XenServer Shipyard is a fork of [xenserver-build-env].

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

    sudo ./yum-setup --citrix trunk-ring3  # if you work at Citrix
    sudo yum-builddep xenopsd

The last step installs the dependencies. It assumes that the code in the
GitHub repository doesn't need additional packages.

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

## The Shortcut: Pre-Building Images

You will notice that developing a packages requires to install a large
number of packages inside the container. The `Makefile` supports this by
creating Docker images that already have these installed:

    make trunk-ring3/xapi
    make CITRIX= xapi       # when working outside citrix

This creates a container `lindig/xs-shipyard-xapi:trunk-ring3` that has
all packages pre-installed for compiling the `xapi` component:

    make trunk-ring3/xapi
    git clone git://github.com/xapi-project/xen-api.git
    cd xen-api
    docker run --rm -itv $PWD:/mnt lindig/xs-shipyard-xapi

Inside the container:

    cd /mnt
    make

## Using Opam

To set up [OCaml] with Opam inside the container, do:

    make opam             # when working inside citrix
    make CITRIX= opam     # when working outside citrix

This creates an image lindig/xs-shipyard-opam which has Opam installed.
This is achieved by running the following commands as part of the build

    sudo yum -y install ocaml
    sudo yum -y install ocaml-findlib-devel
    sudo yum -y install opam
    opam init
    eval $(opam config env)
    sudo sed -i.bak '/path/s!"$!:/home/builder/.opam/system/lib"!' /etc/ocamlfind.conf

The last line ensures that [OCaml] packages (and libraries) installed
via Yum and those installed via Opam are both visible to OCamlfind, which
is responsible for locating libraries for the compiler. The `sed`
command extends the search path for libraries. You can now install
additional libraries and tools from the Opam ecosystem.

## Building a Package from its SRPM

Let's assume you want to build [xenopsd] from its source code package.
I suggest to mount a local directory into the container under `/mnt`
although it is not strictly necessary.

On the host, do:

    IMG=lindig/xs-shipyard
    docker run -i -t -v $PWD:/mnt $IMG

Inside the container, do:

    sudo ./yum-setup --citrix trunk-ring3           # if you work at Citrix
    ./build xenopsd

The `build` script executes these steps that you could also do manually:

    sudo yum-builddep xenopsd
    yumdownloader --source xenopsd
    rpm -i xenopsd*
    rpmbuild -ba /mnt/rpmbuild/SPECS/xenopsd.spec # builds it as a package

The results are under /mnt/rpmbuild -- see below. Usually `rpm` creates
`$HOME/rpmbuild` but we are using a modified `%_topdir /mnt/rpmbuild`
definition (in `$HOME/.rpmmacros`) to direct the RPM hierarchy to `/mnt`
which can be shared with the host.

    New RPMs built
    ./RPMS/x86_64/xenopsd-0.12.1-1+s0+0.12.0+107+ge1ebb93.el7.centos.x86_64.rpm
    ./RPMS/x86_64/xenopsd-debuginfo-0.12.1-1+s0+0.12.0+107+ge1ebb93.el7.centos.x86_64.rpm
    ./RPMS/x86_64/xenopsd-simulator-0.12.1-1+s0+0.12.0+107+ge1ebb93.el7.centos.x86_64.rpm
    ./RPMS/x86_64/xenopsd-xc-0.12.1-1+s0+0.12.0+107+ge1ebb93.el7.centos.x86_64.rpm
    ./RPMS/x86_64/xenopsd-xc-cov-0.12.1-1+s0+0.12.0+107+ge1ebb93.el7.centos.x86_64.rpm
    ./RPMS/x86_64/xenopsd-xenlight-0.12.1-1+s0+0.12.0+107+ge1ebb93.el7.centos.x86_64.rpm

    Build directory with all code
    ./BUILD/xenopsd-0.12.1/.......

    ./SOURCES/xenopsd-0.12.0+107+ge1ebb93.tar.gz
    ./SOURCES/xenopsd-64-conf
    ./SOURCES/xenopsd-conf
    ./SOURCES/xenopsd-libvirt-init
    ./SOURCES/xenopsd-network-conf
    ./SOURCES/xenopsd-simulator-init
    ./SOURCES/xenopsd-xc-init
    ./SOURCES/xenopsd-xenlight-init

    ./SPECS/xenopsd.spec

    ./SRPMS/xenopsd-0.12.1-1+s0+0.12.0+107+ge1ebb93.el7.centos.src.rpm


# List of Packages

It is not obvious which packages can be built using these images. Here
is an incomplete list:

    cppo
    ezlvm
    ffs
    forkexecd
    gdk
    gpumon
    message-switch
    oasis
    ocaml
    ocaml-async
    ocaml-async-extra
    ocaml-async-find
    ocaml-async-inotify
    ocaml-async-kernel
    ocaml-async-rpc-kernel
    ocaml-async-unix
    ocaml-backtrace
    ocaml-base64
    ocaml-biniou
    ocaml-bin-prot
    ocaml-bisect-ppx
    ocaml-bisect-summary
    ocaml-camldm
    ocaml-camlp4
    ocaml-cdrom
    ocaml-cmdliner
    ocaml-cohttp
    ocaml-comparelib
    ocaml-conduit
    ocaml-core
    ocaml-core-kernel
    ocaml-cow
    ocaml-crc
    ocaml-cstruct
    ocaml-ctypes
    ocaml-custom-printf
    ocaml-dyntype
    ocaml-easy-format
    ocaml-enumerate
    ocaml-ezjsonm
    ocaml-fd-send-recv
    ocaml-fieldslib
    ocaml-fileutils
    ocaml-findlib
    ocaml-flock
    ocaml-getopt
    ocaml-gnt
    ocaml-herelib
    ocamlify
    ocaml-inotify
    ocaml-io-page
    ocaml-ipaddr
    ocaml-jsonm
    ocaml-libvhd
    ocaml-lwt
    ocaml-mirage-block-unix
    ocaml-mirage-clock-unix
    ocaml-mirage-profile
    ocaml-mirage-types
    ocamlmod
    ocaml-mtime
    ocaml-nbd
    ocaml-netdev
    ocaml-netlink
    ocaml-obuild
    ocaml-oclock
    ocaml-ocplib-endian
    ocaml-odn
    ocaml-omd
    ocaml-opasswd
    ocaml-ounit
    ocaml-pa-bench
    ocaml-pa-ounit
    ocaml-pa-pipebang
    ocaml-pa-structural-sexp
    ocaml-pa-test
    ocaml-pci
    ocaml-ppxtools
    ocaml-qmp
    ocaml-re
    ocaml-react
    ocaml-rpc
    ocaml-rrdd-plugin
    ocaml-rrd-transport
    ocamlscript
    ocaml-sexplib
    ocaml-sha
    ocaml-shared-block-ring
    ocaml-ssl
    ocaml-stdext
    ocaml-stringext
    ocaml-systemd
    ocaml-tapctl
    ocaml-tar
    ocaml-text
    ocaml-type-conv
    ocaml-typerep
    ocaml-ulex
    ocaml-uri
    ocaml-uuidm
    ocaml-uutf
    ocaml-variantslib
    ocaml-vhd
    ocaml-xcp-idl
    ocaml-xcp-inventory
    ocaml-xcp-rrd
    ocaml-xen-api-client
    ocaml-xen-api-libs-transitional
    ocaml-xenops
    ocaml-xenstore
    ocaml-xenstore-clients
    ocaml-xmlm
    ocaml-yojson
    omake
    opam
    optcomp
    rrd2csv
    rrd-client-lib
    rrdd-plugins
    sm-cli
    squeezed
    stunnel_xs
    vhd-tool
    xapi
    xapi-storage
    xapi-storage-datapath-plugins
    xapi-storage-script
    xapi-test-utils
    xcp-networkd
    xcp-rrdd
    xenops-cli
    xenopsd
    xsifstat
    xsiostat

[Docker]:   https://www.docker.com/
[xenopsd]:  http://github.com/xapi-project/xenopsd
[OCaml]:    http://www.ocaml.org/
[xenserver-build-env]: http://github.com/xenserver/xenserver-build-env
