FROM --platform=$BUILDPLATFORM golang:1.13 AS builder-src

ARG VERSION=v1.0.0
ARG TARGETPLATFORM
ARG BUILDPLATFORM

WORKDIR /go/src/github.com/spotahome
RUN git clone https://github.com/spotahome/redis-operator

# Copy sources
WORKDIR /go/src/github.com/spotahome/redis-operator

RUN git checkout ${VERSION}

RUN go get -d github.com/golang/dep
RUN go install -i -v github.com/golang/dep/cmd/dep

RUN /go/bin/dep ensure



FROM --platform=$BUILDPLATFORM builder-src AS builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM

RUN GOOS=$(echo $TARGETPLATFORM | cut -f1 -d/) && \
    GOARCH=$(echo $TARGETPLATFORM | cut -f2 -d/) && \
    GOARM=$(echo $TARGETPLATFORM | cut -f3 -d/ | sed "s/v//" ) && \
    CGO_ENABLED=0 GOOS=${GOOS} GOARCH=${GOARCH} GOARM=${GOARM} go build -ldflags '-extldflags "-static"' -a -v -o redis-operator ./cmd/redisoperator/



FROM gcr.io/distroless/static

COPY --from=builder /go/src/github.com/spotahome/redis-operator/redis-operator /bin/

USER 2000:2000

ENTRYPOINT ["/bin/redis-operator"]

