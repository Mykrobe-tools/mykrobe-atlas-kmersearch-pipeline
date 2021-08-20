params.batchSize = 1000
params.combine_memory_limit = 2000000000
params.samples = "samples.tsv"
params.predefinedSignatureSizes = [12000000, 13000000, 15000000, 20000000, 40000000, 80000000, 160000000]
params.image = "kms.sif"
params.term_size = 31
params.false_positive_rate = 0.3
params.outputDir = "/nfs/leia/research/iqbal/zhicheng/giang-cobs-pipeline/my-branch/output"

samples = file(params.samples)
image = file(params.image)

process splitSamplesIntoBatches {
	output:
	file 'x*' into (batches,  batch_names) mode flatten

	"""
	split -l $params.batchSize $samples
	"""
}

signature_sizes = Channel.from(params.predefinedSignatureSizes)
batch_names.combine(signature_sizes).set{combined}

process makeBatchIndexDirectories {
    errorStrategy 'retry'
    maxRetries 3
    maxForks 20

    input:
    set batch_name, signature_size from combined

    output:
    val true into done_makeBatchIndexDirectories

    """
	mkdir -p $params.outputDir/step1/$batch_name.baseName/index/$signature_size
	mkdir -p $params.outputDir/step2/index/$signature_size
	mkdir -p $params.outputDir/merged/index/$signature_size
    """
}

process buildBatches {
	// COBS output benchmark info to STDERR to they registers as errors
	errorStrategy 'ignore'
        maxForks 10

	input:
	val flag from done_makeBatchIndexDirectories.collect()
	file batch from batches

	output:
    val true into done_buildBatches

	"""
	singularity exec $image build --classic_index_dir $params.outputDir/step1/$batch.baseName/index --term_size $params.term_size --false_positive_rate $params.false_positive_rate $batch
	"""
}

process collectBatches {
	// Don't really need input but need to wait for the last process to finish
	input:
	val flag from done_buildBatches.collect()
	val signature_size from Channel.from(params.predefinedSignatureSizes)

	output:
    val true into done_collectBatches

	"""
	find $params.outputDir/step1/ -regex .*/$signature_size/.*cobs_classic | xargs -I{} mv --backup=t {} $params.outputDir/step2/index/$signature_size/
	"""
}

process mergeIndices {
	input:
	val flag from done_collectBatches.collect()
	val signature_size from Channel.from(params.predefinedSignatureSizes)

	"""
	[ "\$(ls -A $params.outputDir/step2/index/$signature_size/)" ] && singularity exec $image cobs classic-combine -m $params.combine_memory_limit $params.outputDir/step2/index/$signature_size/ $params.outputDir/merged/index/$signature_size/ $params.outputDir/merged/index/$signature_size/merged.cobs_classic || echo 0
	"""
}
