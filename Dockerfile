FROM --platform=$BUILDPLATFORM golang:1.16 AS builder-src

ARG VERSION=v0.7.0
ARG BUILDPLATFORM

WORKDIR /workdir
RUN git clone https://github.com/OT-CONTAINER-KIT/redis-operator

# Copy sources
WORKDIR /workdir/redis-operator

RUN git checkout ${VERSION}
RUN go mod download 




FROM --platform=$BUILDPLATFORM builder-src AS builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM

RUN GOOS=$(echo $TARGETPLATFORM | cut -f1 -d/) && \
    GOARCH=$(echo $TARGETPLATFORM | cut -f2 -d/) && \
    GOARM=$(echo $TARGETPLATFORM | cut -f3 -d/ | sed "s/v//" ) && \
    CGO_ENABLED=0 GOOS=${GOOS} GOARCH=${GOARCH} GOARM=${GOARM} go build -ldflags '-extldflags "-static"' -a -v -o manager main.go



FROM gcr.io/distroless/static

COPY --from=builder /workdir/redis-operator/manager /manager

USER 65532:65532

ENTRYPOINT ["/manager"]

