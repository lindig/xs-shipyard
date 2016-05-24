FROM                                    centos:7.2.1511
MAINTAINER                              John Else <john.else@citrix.com>

# set up yum repo
COPY    files/RPM-GPG-KEY-Citrix-6.6    /etc/pki/rpm-gpg/RPM-GPG-KEY-Citrix-6.6
COPY    files/xs.repo                   /etc/yum.repos.d/xs.repo

# Build requirements
RUN     yum install -y \
            gcc \
            gcc-c++ \
            git \
            make \
            mercurial \
            mock \
            rpm-build \
            rpm-python \
            sudo \
            yum-utils \
            epel-release

# Niceties
RUN     yum install -y \
            tig \
            tmux \
            vim \
            wget \
            which

# Install planex
RUN     yum -y install https://xenserver.github.io/planex-release/release/rpm/el/planex-release-7-1.noarch.rpm
RUN     yum -y install planex

# OCaml in XS is slightly older than in CentOS
RUN     sed -i "/gpgkey/a exclude=ocaml*" /etc/yum.repos.d/Cent* /etc/yum.repos.d/epel*

# Let's have aspcud
RUN     yum install -y \
            http://download.opensuse.org/repositories/home:/ocaml/CentOS_7/x86_64/aspcud-1.9.0-2.1.x86_64.rpm \
            http://download.opensuse.org/repositories/home:/ocaml/CentOS_7/x86_64/clasp-3.0.1-4.1.x86_64.rpm \
            http://download.opensuse.org/repositories/home:/ocaml/CentOS_7/x86_64/gringo-4.3.0-10.1.x86_64.rpm

# override these when building the container
# docker build --build-arg uid=$(id -u) --build-arg gid=$(id -g) .
ARG uid=1000
ARG gid=1000

RUN echo 'builder ALL=(ALL:ALL) NOPASSWD:ALL' > /etc/sudoers.d/builder 
RUN chmod 440 /etc/sudoers.d/builder 
RUN chown root:root /etc/sudoers.d/builder 
RUN sed -i.bak 's/^Defaults.*requiretty//g' /etc/sudoers 
RUN groupadd -f -g $gid builder
RUN useradd -d /home/builder -u $uid -g builder -m -s /bin/bash builder
RUN passwd -l builder 
RUN chown -R builder:builder /home/builder
RUN usermod -G mock builder

# now become user builder
USER    builder
ENV     HOME /home/builder
WORKDIR /home/builder
COPY    files/citrix citrix
CMD     [ "/bin/bash" ]



