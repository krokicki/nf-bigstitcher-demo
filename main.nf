#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { SPARK_START         } from './subworkflows/local/spark/start/main'
include { SPARK_TERMINATE     } from './modules/local/spark/terminate/main'
include { BIGSTITCHER_PREPARE } from './modules/local/bigstitcher/prepare/main'
include { BIGSTITCHER_STITCH  } from './modules/local/bigstitcher/stitch/main'


workflow STITCH {
    take:
    meta
    input_dir
    output_dir
    spark_cluster
    spark_workers
    spark_worker_cores
    spark_gb_per_core
    spark_driver_cores
    spark_driver_memory

    main:
    BIGSTITCHER_PREPARE(
        meta,
        output_dir,
    )
    spark_local_dir = "/tmp/spark-${workflow.sessionId}"
    spark_work_dirs = BIGSTITCHER_PREPARE.out.map { it.spark_work_dir }

    // When running locally, the driver needs enough resources to run a spark worker
    spark_cluster_res = spark_work_dirs.map { [ 'local[*]', it ] }
    workers = 1
    driver_cores = spark_driver_cores + spark_worker_cores
    driver_memory = (2 + spark_worker_cores * spark_gb_per_core) + " GB"

    if (spark_cluster) {
        workers = spark_workers
        driver_cores = spark_driver_cores
        driver_memory = spark_driver_memory
        spark_cluster_res = SPARK_START(
            spark_local_dir,
            spark_work_dirs,
            input_dir,
            output_dir,
            workers,
            spark_worker_cores,
            spark_gb_per_core
        )
    }

    log.debug "Setting workers: $workers"
    log.debug "Setting driver_cores: $driver_cores"
    log.debug "Setting driver_memory: $driver_memory"

    // Rejoin Spark clusters to data
    data = BIGSTITCHER_PREPARE.out.map {
        def meta = it
        log.debug "Prepared $meta.id"
        [meta, meta.spark_work_dir]
    }
    .join(spark_cluster_res, by:1)
    .map {
        def (spark_work_dir, meta, spark_uri ) = it
        def spark = [:]
        spark.uri = spark_uri
        spark.work_dir = spark_work_dir
        spark.workers = workers ?: 1
        spark.worker_cores = spark_worker_cores
        spark.driver_cores = driver_cores ?: 1
        spark.driver_memory = driver_memory
        spark.parallelism = (workers * spark_worker_cores)
        spark.executor_memory = (spark_worker_cores * spark_gb_per_core)+" GB"
        log.debug "Assigned Spark context: "+spark
        [meta, spark]
    }

    BIGSTITCHER_STITCH(
        data,
        input_dir,
        output_dir
    )

    // terminate stitching cluster
    if (spark_cluster) {
        done_cluster = BIGSTITCHER_STITCH.out.map { [it[1].uri, it[1].work_dir] }
        done = SPARK_TERMINATE(done_cluster) | map { it[1] }
    }
    else {
        done = BIGSTITCHER_STITCH.out.map { it[1].work_dir }
    }

    emit:
    done
}

workflow NFCORE_BIGSTITCHER {
        
    // Validate input parameters
    if (params.spark_workers > 1 && !params.spark_cluster) {
        log.error "You must enable --spark_cluster if --spark_workers is greater than 1."
        System.exit(1)
    }

    // For now, this pipeline only accepts a singleton input
    def meta = [:]
    meta.id = "input"
    meta.input_dir = params.input_dir
    meta.output_dir = params.outdir
    meta.output_n5_name = params.output_n5_name
    meta.data_set = params.data_set

    stitch_out = STITCH(
        Channel.from([meta]),
        params.input_dir,
        params.outdir,
        params.spark_cluster,
        params.spark_workers as int,
        params.spark_worker_cores as int,
        params.spark_gb_per_core as int,
        params.spark_driver_cores as int,
        params.spark_driver_memory
    )
}

workflow {
    NFCORE_BIGSTITCHER ()
}
