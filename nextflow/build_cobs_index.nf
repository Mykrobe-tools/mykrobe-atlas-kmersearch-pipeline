params.batchSize = 1000
params.combine_memory_limit = 2000000000
params.samples = "samples.tsv"
params.predefinedSignatureSizes = [12000000, 13000000, 15000000, 20000000, 40000000, 80000000, 160000000]
params.image = "kms.sif"
params.term_size = 31
params.false_positive_rate = 0.3

samples = file(params.samples)
image = file(params.image)

process splitSamplesIntoBatches {
	output:
	file 'x*' into batches mode flatten

	"""
	split -l $params.batchSize $samples
	"""
}

sigSizes = params.predefinedSignatureSizes.collect()

process buildBatches {
	// COBS output benchmark info to STDERR to they registers as errors
	errorStrategy 'ignore'

	input:
	file batch from batches

	output:
	file '*' into batchSignatureSizeDirs

	"""
	mkdir -p index/{12,13,15,20,40,80,160}000000
	singularity exec $image build --classic_index_dir index --term_size $params.term_size --false_positive_rate $params.false_positive_rate $batch
	"""
}

process collectBatches {
	// Don't really need input but need to wait for the last process to finish
	input:
	file 'dir' from batchSignatureSizeDirs.collect()

	output:
	file '*' into collectedSignatureSizeDirs

	"""
	mkdir {12,13,15,20,40,80,160}000000
	find $workDir -regex .*/12000000/.*cobs_classic | xargs -I{} mv --backup=t {} 12000000/
	find $workDir -regex .*/13000000/.*cobs_classic	| xargs	-I{} mv --backup=t {} 13000000/
	find $workDir -regex .*/15000000/.*cobs_classic	| xargs	-I{} mv --backup=t {} 15000000/
	find $workDir -regex .*/20000000/.*cobs_classic	| xargs	-I{} mv --backup=t {} 20000000/
	find $workDir -regex .*/40000000/.*cobs_classic	| xargs	-I{} mv --backup=t {} 40000000/
	find $workDir -regex .*/80000000/.*cobs_classic	| xargs	-I{} mv --backup=t {} 80000000/
	find $workDir -regex .*/160000000/.*cobs_classic | xargs -I{} mv --backup=t {} 160000000/
	find $workDir -name *~ | xargs -I{} mv {} {}.cobs_classic
	"""
}

process mergeIndices {
	input:
	file dir from collectedSignatureSizeDirs.flatten()

	"""
	[ "\$(ls -A $dir)" ] && singularity exec $image cobs classic-combine -m $params.combine_memory_limit $dir $dir ${dir}/merged.cobs_classic || echo 0
	"""
}
