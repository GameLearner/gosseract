FROM centos:latest

ARG TESS="4.00.00dev"
ARG LEPTO="1.74.2"
ARG GO="1.9.1"

RUN yum update -y -q
RUN yum install -y -q \
  gcc-c++ \
  git \
  wget \
  make \
  autoconf \
  automake \
  libtool \
  libjpeg-devel \
  libpng-devel \
  libtiff-devel \
  zlib-devel


ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/lib
ENV TESSDATA_PREFIX=/usr/local/share

# Compile Leptonica
WORKDIR /
RUN mkdir -p /tmp/leptonica \
  && wget -nv https://github.com/DanBloomberg/leptonica/archive/${LEPTO}.tar.gz \
  && tar -xzvf ${LEPTO}.tar.gz -C /tmp/leptonica \
  && mv /tmp/leptonica/* /leptonica
WORKDIR /leptonica

RUN autoreconf -i \
  && ./autobuild \
  && ./configure \
  && make \
  && make install

# Compile Tesseract
WORKDIR /
RUN mkdir -p /tmp/tesseract \
  && wget -nv https://github.com/tesseract-ocr/tesseract/archive/${TESS}.tar.gz \
  && tar -xzvf ${TESS}.tar.gz -C /tmp/tesseract \
  && mv /tmp/tesseract/* /tesseract
WORKDIR /tesseract

RUN ./autogen.sh \
  && ./configure \
  && make \
  && make install

# Load languages
RUN wget -nv https://github.com/tesseract-ocr/tessdata/raw/master/eng.traineddata -P /usr/local/share/tessdata

# Recover location
WORKDIR /

# Install Go
RUN wget -nv https://storage.googleapis.com/golang/go${GO}.linux-amd64.tar.gz \
  && tar -xzvf go${GO}.linux-amd64.tar.gz
RUN mv /go /.go
ENV GOROOT=/.go

# Prepare GOPATH
RUN mkdir /go
ENV GOPATH=/go
ENV PATH=${PATH}:${GOROOT}/bin:${GOPATH}/bin

# Dependencies for tests
RUN go get github.com/otiai10/mint

# Mount source code of gosseract project
ADD . ${GOPATH}/src/github.com/otiai10/gosseract
WORKDIR ${GOPATH}/src/github.com/otiai10/gosseract

CMD go test