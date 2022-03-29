FROM ubuntu:14.04

ARG NVDLA_CONFIGURATION=nv_small

# get prerequisites
RUN apt-get update && apt-get install -y --force-yes \ 
    g++ cmake libboost-dev python-dev libglib2.0-dev libpixman-1-dev liblua5.2-dev swig libcap-dev git vim libattr1-dev wget perl-modules git \
    openjdk-7-jre-headless libyaml-perl libcapture-tiny-perl libxml-simple-perl \
    && rm -rf /var/lib/apt/lists/*

# setup SystemC
RUN mkdir -p /usr/src/systemc-2.3.0a
WORKDIR /usr/src/systemc-2.3.0a

RUN wget -O systemc-2.3.0a.tar.gz --no-check-certificate http://www.accellera.org/images/downloads/standards/systemc/systemc-2.3.0a.tar.gz \
    && tar xzvf systemc-2.3.0a.tar.gz \
    && cd /usr/src/systemc-2.3.0a/systemc-2.3.0a \
    && mkdir -p /usr/local/systemc-2.3.0/ \
    && mkdir objdir \
    && cd objdir \
    && ../configure --prefix=/usr/local/systemc-2.3.0 \
    && make  \
    && make install \
    && rm -rf /usr/src/systemc-2.3.0a

# setup HW
COPY ./hw /usr/src/hw
WORKDIR /usr/src/hw

RUN USE_NV_ENV=1 \
    NV_CPP=/usr/bin/cpp \
    NV_GCC=/usr/bin/gcc \
    NV_CXX=/usr/bin/g++ \
    NV_PERL=/usr/bin/perl \
    NV_JAVA=/usr/bin/java \
    NV_SYSTEMC=/usr/local/systemc-2.3.0 \
    NV_PYTHON=/usr/bin/python2 \
    make && tools/bin/tmake -build cmod_top

# setup VP
RUN cd /usr/src && git config --global url."https://github".insteadOf git://github && git clone --recursive https://github.com/nvdla/vp.git && cd vp \
    && cmake -DCMAKE_INSTALL_PREFIX=/usr/local/vp -DSYSTEMC_PREFIX=/usr/local/systemc-2.3.0 -DNVDLA_HW_PREFIX=/usr/src/hw -DNVDLA_HW_PROJECT=$NVDLA_CONFIGURATION \
    && make -j 8 \
    && make install \
    && make clean \
    && mkdir -p /usr/local/nvdla && ln -s /usr/local/vp/sw/images/linux-4.13.3/rootfs.ext4 /usr/local/nvdla/rootfs.ext4 && ln -s /usr/local/vp/sw/images/linux-4.13.3/Image /usr/local/nvdla/Image \
    && rm -rf /usr/src/vp

COPY ./sw/prebuilt/arm64-linux /usr/local/vp/sw
COPY ./sw/prebuilt/x86-ubuntu /usr/local/nvdla-compiler

WORKDIR /usr/local/vp
