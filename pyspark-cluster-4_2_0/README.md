# Spark Cluster with Jupyter v4.2.0

**Apache Spark version 4.2.0** Cluster with 1 master, 2 worker nodes & PySpark Jupyter Lab.

### To setup the complete Cluster in docker
```shell
docker compose up
```

| Service | URL |
|---|---|
| Jupyter Lab | http://localhost:8888 |
| Spark Master UI | http://localhost:8080 |
| Spark Worker UIs | http://localhost:8081, http://localhost:8082 |
| Spark application UI | http://localhost:4040 |

From a notebook, connect to the cluster with:
```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .master("spark://ewd-spark-master:7077") \
    .appName("my-app") \
    .getOrCreate()
```

## What's inside

| Component | Version |
|---|---|
| Apache Spark | 4.2.0 (Scala 2.13) |
| Java | OpenJDK 21 (LTS) |
| Python | 3.12 -- identical on the Jupyter driver and the workers |
| OS | Debian 13 (trixie) |
| Delta Lake | 4.4.0 (`delta-spark`) |
| JupyterLab / ipykernel | 4.6.3 / 6.31.0 |
| pandas / pyarrow / numpy | 2.3.3 / 25.0.1 / 2.5.3 -- identical on driver and workers |

Images:

| Image | Used by |
|---|---|
| `easewithdata/pyspark-jupyter:4.2.0` | Jupyter Lab (driver) |
| `easewithdata/spark-master:4.2.0` | Spark master |
| `easewithdata/spark-worker:4.2.0` | Spark workers |
| `easewithdata/spark-base:4.2.0` | Base image for master and worker |

### Upgrade notes (coming from 3.5.5)
- **Java 21** instead of Java 8/11. Spark 4 requires Java 17 or newer.
- **Python 3.12 everywhere.** PySpark needs the driver and the executors on the same
  Python minor version; 3.5.5 mixed versions between Jupyter and the workers.
- **Spark Connect is built in.** No separate `spark-connect` JAR and no `--jars` flag.
- **Delta Lake JARs are pre-downloaded** into the Jupyter image, so Delta works without
  internet access. The driver ships them to the executors.
- **pandas 2.3** (not 3.x): PySpark 4.2.0 requires pandas >= 2.2 and warns that it does
  not yet fully support pandas 3.

## Architecture support (Windows / Mac / Linux)

Docker images are Linux images regardless of your host OS -- Windows and macOS
both run them inside a Linux VM. What actually differs between machines is the
**CPU architecture**, not the operating system.

All 4.2.0 images are published as multi-architecture manifests and Docker
automatically pulls the right one:

| Machine | Architecture pulled |
|---|---|
| Windows on Intel/AMD | `linux/amd64` |
| Intel Mac | `linux/amd64` |
| Apple Silicon Mac | `linux/arm64` (native, no emulation) |
| Windows on ARM | `linux/arm64` |

Check what your machine actually pulled:
```shell
docker image inspect easewithdata/pyspark-jupyter:4.2.0 --format '{{.Architecture}}'
```

## Delta Lake

`delta-spark` 4.4.0 is installed and its JARs are already cached in the image.
```python
from delta import configure_spark_with_delta_pip
from pyspark.sql import SparkSession

builder = SparkSession.builder \
    .master("spark://ewd-spark-master:7077") \
    .appName("delta") \
    .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
    .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog")

spark = configure_spark_with_delta_pip(builder).getOrCreate()

spark.range(10).write.format("delta").mode("overwrite").save("/data/delta/numbers")
spark.read.format("delta").load("/data/delta/numbers").show()
```
Write Delta tables under `/data` -- it is a volume shared by Jupyter, the master and
both workers, so executors can read and write the same files. In Jupyter Lab the same
volume also appears as the `data` folder in the file browser (`/home/jupyter/data`);
in Spark code always use the `/data/...` path, which is identical on every node.

### References & Credits
1. **Ease With Data YouTube Channel (https://youtube.com/@easewithdata)**
2. Docker Image references - BDE2020 (https://hub.docker.com/u/bde2020)

### Maintainer
Ease With Data (easewithdata@gmail.com)
