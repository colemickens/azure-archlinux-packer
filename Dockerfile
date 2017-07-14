FROM buildpack-deps:xenial

ENV QEMU_SRC_PACKAGES="genisoimage mtools dosfstools rlwrap jq ca-certificates pkg-config python build-essential zlib1g-dev libtool checkinstall intltool-debian libglib2.0-dev libfdt-dev libpixman-1-dev zlib1g-dev libaio-dev libbluetooth-dev libbrlapi-dev libbz2-dev libcap-dev libcap-ng-dev libcurl4-gnutls-dev libgtk-3-dev libibverbs-dev libjpeg8-dev libncurses5-dev libnuma-dev librbd-dev librdmacm-dev libsasl2-dev libsdl1.2-dev libseccomp-dev libsnappy-dev libssh2-1-dev libvde-dev libvdeplug-dev libvte-2.91-dev libxen-dev liblzo2-dev valgrind xfslibs-dev"

ENV PACKAGES="${QEMU_SRC_PACKAGES} python python-pip"

RUN apt-get update && apt-get -y upgrade \
    && apt-get -y install ${PACKAGES} \
        git make vim curl wget unzip ca-certificates jq \
    && rm -rf /var/lib/apt/lists/*

# Build qemu 2.7.0
ENV QEMU_VERSION "v2.7.0"
RUN mkdir -p /opt/qemu \
    && git clone "http://git.qemu.org/git/qemu.git" /opt/qemu \
    && (cd /opt/qemu \
    && git checkout "${QEMU_VERSION}" \
    && mkdir build && cd build \
    && ../configure --target-list=x86_64-softmmu \
    && make \
    && make install) \
    && rm -rf /opt/qemu

RUN apt-get update && apt-get -y upgrade \
    && apt-get -y install \
        rlwrap \
    && rm -rf /var/lib/apt/lists/*

# Install azure-cli
RUN pip install azure-cli

# Install azure-vhd-utils for fast vhd upload
ENV GOPATH "$HOME/gopath"
ENV PATH="$PATH:$GOPATH/bin"
RUN bash -c "\
    mkdir -p $GOPATH && \
    wget 'https://godeb.s3.amazonaws.com/godeb-amd64.tar.gz' && \
    tar xvfz godeb-amd64.tar.gz && \
    ./godeb install 1.7"
RUN bash -c "go get github.com/Microsoft/azure-vhd-utils"

# Install Packer
ENV PACKER_VERSION=0.10.2
RUN wget "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip" -O /tmp/packer.zip
RUN mkdir -p /opt/packer
RUN unzip /tmp/packer.zip -d "/opt/packer"
ENV PATH="${PATH}:/opt/packer"
