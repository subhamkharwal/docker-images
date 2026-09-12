# PySpark Jupyter Lab Notebook - Python v3.7

Jupyter Lab Notebook with root access.
EaseWithApacheSpark notebooks provided to start with.

Spark 3.3.0 | Python 3.7 | OpenJDK 17 | Debian 12 (bookworm)

## Multi-architecture image (recommended)

    docker pull easewithdata/pyspark-jupyter-lab-old:3.3.0_multi_arch
    docker run -d -p 8888:8888 -p 4040:4040 --name jupyter-lab easewithdata/pyspark-jupyter-lab-old:3.3.0_multi_arch

`3.3.0_multi_arch` is a single tag that carries **both `linux/amd64` and
`linux/arm64`**. Docker picks the right one automatically when you pull, so the
same command works everywhere.

### What actually differs is the CPU architecture, not the operating system

A common misreading is that you need a different image for Windows vs macOS vs
Linux. You don't. Docker containers always run a Linux userspace, whatever the
host OS is. What the image has to match is the **CPU architecture**:

| Your machine | Architecture pulled |
| --- | --- |
| Intel/AMD Windows, Intel/AMD Linux, Intel Mac | `linux/amd64` |
| Apple Silicon Mac (M1/M2/M3/M4), Windows on ARM, ARM Linux | `linux/arm64` |

The older single-architecture image was `amd64` only. On Apple Silicon that
forced the whole JVM and Spark stack to run under QEMU emulation, which is slow
and occasionally unstable. The `arm64` half of this tag removes the emulation
layer entirely.

## To build the image yourself

Single architecture, matching your own machine:

    docker build --tag easewithdata/pyspark-jupyter-lab-old .

Both architectures (needs `docker buildx` with a `docker-container` driver):

    ./build-multiarch.sh          # build only
    ./build-multiarch.sh --push   # build and publish

## Notes on what changed and why

**Base image moved from Debian 11 (bullseye) to Debian 12 (bookworm).**
Bullseye reached end of life and its security `Release` file expired, so
`apt-get update` now fails outright and `FROM python:3.7-bullseye` could no
longer be built at all.

**JDK moved from OpenJDK 11 to OpenJDK 17.** Bookworm does not ship an
`openjdk-11` package. Spark 3.3.0 officially supports Java 8/11/17 and bundles
the `--add-opens` module options that Java 17 requires, so this is a supported
combination. It was verified end to end (SparkSession plus a Delta Lake
write/read round trip) on both architectures.

**`JAVA_HOME` is no longer hardcoded to `-amd64`.** It is now derived from
buildx's `TARGETARCH` build argument, with a `test -d` guard so a wrong path
fails the build loudly instead of producing a broken image.

> [!WARNING]
> **Do not relax the version pins in the Dockerfile.**
>
> The Python package versions in the Dockerfile are not cosmetic. They are the
> exact versions taken from the last known-good published image. The original
> `pip install jupyterlab` was unpinned, and resolving it fresh today installs an
> `ipykernel` that breaks this stack: notebook kernels get stuck on "busy" and
> the server eventually stops responding.
>
> Pinning `jupyterlab` **alone is not sufficient** -- it declares only a loose
> `ipykernel` constraint, so the entire jupyter core stack (`ipykernel`,
> `jupyter_client`, `jupyter_core`, `jupyter_server`, `ipython`, `traitlets`,
> `tornado`, `pyzmq`, `nbconvert`, `nbformat`, `nbclient`, ...) must stay pinned
> explicitly. Python 3.7 is itself end-of-life, so these are the last releases
> that support it and they will not be updated.

## The original single-architecture image

The previous `latest` tag is unchanged and still available:

    docker pull easewithdata/pyspark-jupyter-lab-old
