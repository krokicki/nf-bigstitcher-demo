process BIGSTITCHER_STITCH {
    tag "${meta.id}"
    container 'registry.int.janelia.org/biocontainers-bigstitcher:0.0.2'
    cpus { spark.driver_cores }
    memory { spark.driver_memory }

    input:
    tuple val(meta), val(spark)
    path(input_dir)
    path(output_dir)

    output:
    tuple val(meta), val(spark)

    when:
    task.ext.when == null || task.ext.when

    script:
    extra_args = task.ext.args ?: ''
    executor_memory = spark.executor_memory.replace(" KB",'k').replace(" MB",'m').replace(" GB",'g').replace(" TB",'t')
    driver_memory = spark.driver_memory.replace(" KB",'k').replace(" MB",'m').replace(" GB",'g').replace(" TB",'t')
    """
    /opt/scripts/runapp.sh "${workflow.containerEngine}" "${spark.work_dir}" "${spark.uri}" \
        /app/app.jar net.preibisch.bigstitcher.spark.AffineFusion \
        ${spark.parallelism} ${spark.worker_cores} "${executor_memory}" ${spark.driver_cores} "${driver_memory}" \
        -x ${meta.input_dir}/dataset.xml \
        -o ${meta.output_dir}/${meta.output_n5_name} \
        -d ${meta.data_set} \
        ${extra_args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spark: \$(cat /opt/spark/VERSION)
        bigstitcher: 0.0.2
    END_VERSIONS
    """
}
