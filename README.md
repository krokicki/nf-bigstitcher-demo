# Demo of BigStitcher as nf pipline

Quick and dirty implementation of BigStitcher Spark pipeline using nf-core/Nextflow.

Build and push container:
```
docker build . -t registry.int.janelia.org/biocontainers-bigstitcher:0.0.2
docker push registry.int.janelia.org/biocontainers-bigstitcher:0.0.2
```

Run pipeline locally:
```
nextflow run main.nf -profile singularity
```

Run on the Janelia cluster using a 2 node Spark cluster:
```
nextflow run main.nf -profile janelia --spark_cluster=true --spark_workers=2 --spark_worker_cores=4 --spark_gb_per_core=15 --lsf_opts="-P scicompsoft" --extra_opts="--demoSleepSeconds 3"
```

