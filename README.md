# Preconfigured Proxy for Fedora and CentOS

## Start the proxy

You can start a container called `rpm-mirror` with the following command:

    podman run --name rpm-mirror -d -p 127.0.0.1:3128:3128 quay.io/gleboude/rpm-mirror


## Configure your DNF/YUM

You need the adjust the files from /etc/yum.repos.d/

- Adjust the metalink URL to use `http` instead of `https`.
- Set the proxy key and point on the IP of your mirror.

    sed -i 's,^metalink=https://\(.*\)$,metalink=http://\1\&protocol=http\nproxy=127.0.0.1:3128\n,' /etc/yum.repos.d/*.repo
