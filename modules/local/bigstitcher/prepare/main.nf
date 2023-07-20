process BIGSTITCHER_PREPARE {
    tag "${meta.id}"
    label 'process_single'

    input:
    val(meta)
    path(output_dir) // for mounting
    
    output:
    val(meta)

    script:
    abs_output_dir = output_dir.resolveSymLink().toString()
    // Absolute paths for Spark cluster to access
    meta.output_dir = "${abs_output_dir}"
    meta.spark_work_dir = "${abs_output_dir}/spark/${workflow.sessionId}"
    """
    umask 0002
    mkdir -p ${meta.output_dir}/${meta.output_n5_name}
    mkdir -p ${meta.spark_work_dir}
    """
}
