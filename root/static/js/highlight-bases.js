//This is a re-implemtation of the highlightBases function in root/site/user/pointmutation/miseq_alleles_frequency.tt. It is necessary to re-implement it, with slight changes, as we don't have access to the position of the crispr within the original sequence. We have to refind it here.

function highlightBases(sequence, alleleData, crisprData) {
    let alleleDatum = getAlleleDataForSequence(sequence, alleleData);
    let positionOfCrispr = positionOfCrisprInReferenceSequence(alleleDatum.reference_sequence, crisprData);
    let type = insertionDeletionOrMutaion(alleleDatum.aligned_sequence, alleleDatum.reference_sequence)
    let outputSequence = alleleDatum
	.aligned_sequence
	.split('')
	.map(
            (s, i) => {
	        return `<span class="${type[i]}">${s}</span>`
	    }
        )
	.map(
	    (s, i) => {
	    	if (i == positionOfCrispr.start) {
		    return `<span class="target">${s}`
		}
	    	if (i == positionOfCrispr.end) {
		    return `${s}</span>`
		}
		return s
	    }
	)
        .join('');
    return outputSequence;
}

function insertionDeletionOrMutaion(alignedSequence, referenceSequence) {
    return alignedSequence.split('').map(
        (a, i) => {
	    if (a == '-') {
	       return "deletion"
	    } else if (referenceSequence[i] == '-') {
                return 'insertion'
	    } else if (a != referenceSequence[i]) {
	        return 'mutation'
	    } else {
	        return ''
	    }
	}
    )
}

function getAlleleDataForSequence(sequence, alleleData) {
    return alleleData.find(item => item.aligned_sequence == sequence);
}

function positionOfCrisprInReferenceSequence(referenceSequence, crisprSequence) {
    let crisprRegExp = RegExp(crisprSequence.split("").join("-*"));
    let reverseComplementRegExp = RegExp(reverseComplement(crisprSequence).split("").join("-*"));
    let match = referenceSequence.match(crisprRegExp) || referenceSequence.match(reverseComplementRegExp);
    return {
        start: match.index,
	end:  match.index + match[0].length - 1,
    };
}

function reverseComplement(sequence) {
    let complement = {'A': 'T', 'C': 'G', 'G': 'C', 'T': 'A'};
    return sequence.split('').map(el => complement[el]).reverse().join('');
}
