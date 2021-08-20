# mykrobe-atlas-kmersearch-pipeline
Pipeline for generating kmersearch index for samples

## Running the pipelines
An example of running the cobs index building pipeline:
```shell script
nextflow run -c mykrobe-atlas-kmersearch-pipeline/nextflow/nextflow.config 
    mykrobe-atlas-kmersearch-pipeline/nextflow/build_cobs_index.nf
    --samples samples.tsv
    --image kms.simg
    --outputDir output
```
In addition to the parameters in above example, other parameters could be found in `nextflow/build_cobs_index.nf`.