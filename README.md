<!-- vim: set ts=2 sw=2 et spell -->

[![Build Status](https://travis-ci.org/lindig/xs-shipyard.svg?branch=master)](https://travis-ci.org/lindig/xs-shipyard)
[![Docker Layers](https://images.microbadger.com/badges/image/lindig/xs-shipyard.svg)](https://microbadger.com/images/lindig/xs-shipyard)

# XenServer Shipyard

This [Docker] configuration provides an environment for building
XenServer packages.  The build environment is based on CentOS and all
packages and their dependencies are managed as RPM packages.

XenServer Shipyard is a fork of [xenserver-build-env]. For work inside
Citrix I recommend using `planex-buildenv` which also builds docker
containers for building toolstack components.

**This Docker configuration cannot be used to create binaries
that are 100% compatible with official ones. Recent official builds of
XenServer rely on a patched CentOS base image. This creates
incompatibilities between binaries created with this Docker image and
binaries created with official builds. This Docker configuration is
still good for development.**

## Building and Using the Container

The main use case is to create a container that provides all
dependencies such that a given component can be built inside of it.

```sh
make dundee-bugfix/xenopsd
```

The above command constructs a container suitable to build the [xenopsd]
component in the Dundee release:

```sh
$ cd src/xenopsd
$ docker run -i -t -v $PWD:/mnt lindig/xs-shipyard-xenopsd:dundee-bugfix
[builder@c6326320a1f2 ~]$ cd /mnt/
[builder@c6326320a1f2 mnt]$ ./configure
[builder@c6326320a1f2 mnt]$ make
```

The current directory with the source code of xenopsd is mounted under
`/mnt` and then built inside the container.

## Releases

The following releases are available:

* ely-bugfix
* dundee-bugfix
* falcon

[Docker]:   https://www.docker.com/
[xenopsd]:  http://github.com/xapi-project/xenopsd
[OCaml]:    http://www.ocaml.org/
[xenserver-build-env]: http://github.com/xenserver/xenserver-build-env
