#!/usr/bin/env bash

set -eux

ctr1=$(buildah from "${1:-registry.fedoraproject.org/fedora}")

## Get all updates and install our minimal httpd server
buildah run "$ctr1" -- dnf update -y
buildah run "$ctr1" -- dnf install -y squid golang
buildah add "$ctr1" etc /etc
buildah run "$ctr1" -- go get github.com/rchunping/squid-urlrewrite
buildah run "$ctr1" -- mv /root/go/bin/squid-urlrewrite /etc/squid
buildah run "$ctr1" -- rm -rf /root/go
buildah run "$ctr1" -- dnf remove -y golang
buildah run "$ctr1" -- dnf clean all
buildah run "$ctr1" -- squid -zN

## Include some buildtime annotations
buildah config --annotation "com.example.build.host=$(uname -n)" "$ctr1"

## Run our server and expose the port
buildah config --cmd "/usr/sbin/squid --foreground -d 5" "$ctr1"
buildah config --port 3128 "$ctr1"

## Commit this container to an image name
buildah commit "$ctr1" rpm-mirror-test
podman run --name rpm-mirror-test -d -p 127.0.0.1:3128:3128 rpm-mirror-test
https_proxy=127.0.0.1:3128 curl --head https://linuxfr.org && false
http_proxy=127.0.0.1:3128 curl curl http://somewhere.org/pub/fedora/linux/releases/35/Everything/x86_64/os/repodata/repomd.xml|grep http://linux.duke.edu/metadata/repo
podman stop rpm-mirror-test
buildah commit "$ctr1" quay.io/gleboude/rpm-mirror
