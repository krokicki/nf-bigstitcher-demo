# Create final image
FROM multifish/biocontainers-spark:3.1.3

LABEL software="stitching-spark" \
    base_image="apache/spark" \
    container="stitching-spark" \
    about.summary="Reconstructing large microscopy images from overlapping image tiles on a high-performance Spark cluster" \
    about.home="https://github.com/saalfeldlab/stitching-spark" \
    software.version="1.9.0" \
    version="1" \
    about.license="SPDX:GPL-2.0" \
    about.license_file="/app/LICENSE.txt" \
    extra.binaries="/opt/spark/bin" \
    about.tags="implemented-in::java, interface::commandline, role::program"

WORKDIR /app
COPY BigStitcher-Spark-0.0.2-SNAPSHOT.jar /app/app.jar
