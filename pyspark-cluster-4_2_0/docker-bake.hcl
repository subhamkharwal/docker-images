# Build definition for the Spark 4.2.0 cluster images.
#
# master and worker are `FROM easewithdata/spark-base:4.2.0`. The `contexts`
# mapping below redirects that reference to the local `base` target, so the
# whole set builds in one go -- for both architectures -- without spark-base
# having to exist on Docker Hub first.

variable "REGISTRY" {
  default = "easewithdata"
}

variable "TAG" {
  default = "4.2.0"
}

group "default" {
  targets = ["base", "master", "worker", "jupyter"]
}

target "_common" {
  platforms = ["linux/amd64", "linux/arm64"]
}

target "base" {
  inherits = ["_common"]
  context  = "./base"
  tags     = ["${REGISTRY}/spark-base:${TAG}"]
}

target "master" {
  inherits = ["_common"]
  context  = "./master"
  contexts = {
    "easewithdata/spark-base:4.2.0" = "target:base"
  }
  tags = ["${REGISTRY}/spark-master:${TAG}"]
}

target "worker" {
  inherits = ["_common"]
  context  = "./worker"
  contexts = {
    "easewithdata/spark-base:4.2.0" = "target:base"
  }
  tags = ["${REGISTRY}/spark-worker:${TAG}"]
}

target "jupyter" {
  inherits = ["_common"]
  context  = "./jupyter"
  tags     = ["${REGISTRY}/pyspark-jupyter:${TAG}"]
}
