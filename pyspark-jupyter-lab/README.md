# PySpark Jupyter Lab Notebook - Python v3.10

Jupyter Lab Notebook with root access, **Apache Spark 3.3.0** and PySpark preinstalled.
EaseWithApacheSpark notebooks provided to start with.

### To create container from image
    docker run -d -p 8888:8888 -p 4040:4040 --name jupyter-lab easewithdata/pyspark-jupyter-lab:3.3.0_multi_arch

Then open http://localhost:8888 (Spark UI on http://localhost:4040).

## Architecture support (Windows / Mac / Linux)

Docker images are Linux images regardless of your host OS -- Windows and macOS
both run them inside a Linux VM. What actually differs between machines is the
**CPU architecture**, not the operating system.

The `latest` tag is `linux/amd64` only. On an Apple Silicon Mac (M1/M2/M3/M4)
that runs the JVM under emulation, which is slow and can make notebook kernels
appear to hang on "busy".

The `3.3.0_multi_arch` tag is published as a multi-architecture manifest and
Docker automatically pulls the right one:

| Machine | Architecture pulled |
|---|---|
| Windows on Intel/AMD | `linux/amd64` |
| Intel Mac | `linux/amd64` |
| Apple Silicon Mac | `linux/arm64` (native, no emulation) |
| Windows on ARM | `linux/arm64` |

Check what your machine actually pulled:
```shell
docker image inspect easewithdata/pyspark-jupyter-lab:3.3.0_multi_arch --format '{{.Architecture}}'
```

## Building the image yourself

Single architecture (your machine's own):
```shell
docker build --tag easewithdata/pyspark-jupyter-lab .
```

Both architectures:
```shell
./build-multiarch.sh           # build both architectures locally, no push
./build-multiarch.sh --push    # build and publish to Docker Hub
```

Multi-arch builds need a buildx builder with the `docker-container` driver; the
script creates one named `multiarch` if it is missing. It never touches the
`latest` tag.

#### Note on the base image and JDK
The image used to build `FROM python:3.10-bullseye` with OpenJDK 11. Debian 11
(bullseye) is end-of-life and its security `Release` file has expired, so
`apt-get update` now fails outright and that Dockerfile can no longer be built at
all. The base is now `python:3.10.21-bookworm` with OpenJDK 17, which Spark 3.3.0
supports (Java 17 support landed in Spark 3.3.0).

`JAVA_HOME` is derived from buildx's `TARGETARCH` build arg rather than being
hardcoded to `...-openjdk-amd64`, which is what previously made arm64 builds
produce a broken image.

#### Note on pinned versions
The Python dependencies in the `Dockerfile` are pinned deliberately, to the exact
versions verified working in the previously published image. Leaving them
unpinned lets `ipykernel` resolve to 7.x, which breaks the kernel in this image
(kernels stick on "busy" and the server eventually stops responding). Pinning
`jupyterlab` on its own is **not** enough -- it declares a loose `ipykernel`
constraint and still pulls 7.x -- which is why the whole Jupyter core stack is
pinned explicitly. Please don't relax these pins without testing a notebook end
to end.

### References & Credits
1. **Ease With Data YouTube Channel (https://youtube.com/@easewithdata)**

### Maintainer
Ease With Data (easewithdata@gmail.com)
