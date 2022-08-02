# CRISPRTarget_lite

**What it does**

Genomes targeted by CRISPR spacers can be identified by sequence alignment. The highly-cited web-application CRISPRTarget does this (Biswas et al 2013). CRISPRTarget uses the application blastn to align spacers to genomic sequences, computing spacer-match scores by incrementing every nucleotide match by 1 and decrementing every mismatch by 1 (scoring is detailed in Biswas et al 2013 and 2015 and can be changed in the script). Because blastn is a local-alignment tool, there will be unaligned nucleotides at the end of CRISPR spacer (i.e. unaligned free ends), and these nucleotides were treated as mismatches. Similarly, when reporting the spacer targets, the start-end of each target were extended to cover unaligned free ends of the spacer. The web version of CRISPRTarget generates graphical HTML outputs with URLs link to websites hosting the targeted sequences, as well as scoring for known PAMs. 

In many occasions, users only need essential protospacer (spacer-target) data from CRISPRTarget, namely the ID of the genome being targeted, the start-end of the target, the targeted strand, the targeting spacers and the +1/-1 spacer-match scores, with additional penalizing for unaligned free ends of spacers. Instead of running CRISPRTarget online, all these data can be obtained by running blastn standalone with an appropriate set of command-line arguments first, followed by simple post-processing. Furthermore, having a command-line version of CRISPRTarget, or a simpler, standalone tool that generates essential spacer target data, allows analyses to be done with more flexibly.

The application CRISPRTarget_lite does this. It reads in a set of CRISPR arrays in CRISPRDetect-GFF format (NC_002737.crispr.gff, as an example), extracts spacer sequences from the GFF file and runs blastn with an appropriate set of command-line arguments to tabulate data required for the score calculation as well as attributes of spacers and the targeted genomes. With an AWK-like data-process command (perl -lane), essential spacer target data are computed and displayed in BED6 format.

The BED6 file can be used to extract the target sequences and the flanking regions using the application Bedtools for further analyses. For example, one can extract the target flanks and look for PAMs.

**Dependencies**
linux like environment 
blastn
bedtools

**General usage**

The application CRISPRTarget_lite is a Shell script. The user need to specify the path to a CRISPR-array file in CRISPRDetect-GFF format, and a database of genomic sequences in BLASTDB format. Spacer target data will be printed to 'stdout' by default, but can also be directed into a file.

Depending on the organisms, if CRISPR arrays are likely to be present, one should predict CRISPR arrays first (using CRISPRDetect, or fast predictors like MINCED) and then mask them out before creating the BLASTDB. This is to avoid false targets due to self-matches. 

Note that CRISPRTarget_lite is a "Linux one-liner", made of just one Linux command!

Commands:

        sh CRISPRTarget_lite.sh <crispr_array.gff> <blast_db>
        sh CRISPRTarget_lite.sh <crispr_array.gff> <blast_db> > <target_data.bed>

The only dependency is the application BLASTN, which is provided, and the script is pointing to it.

In the BED6 output, column 4 (the "name" column) is formatted as "genome_accession#spacer_id#count", where the "count" is a series of integer that makes all the names unique. Bedtools uses the name field as FASTA header when extracting sequences. 

**More information**

The application CRISPRTarget_lite runs the following BLASTN command:

        blastn -query <spacers.fna> -db <blast_db> -num_threads <a_number> -outfmt '6 sseqid stitle sstart send qseqid qstart qend sstrand length evalue mismatch gaps qlen slen' -word_size 7 -evalue 1 -gapopen 10 -gapextend 2 -penalty -1 -reward 1 -dbsize 1000000000
        
In particular, sequence alignment is performed with the same set of command-line argumented used by CRISPRTarget by default. The blastn command generates a tabular output, and the query length (i.e. the spacer length) is requested by asking for the 'qlen' data. The number of mismatches is also requested. In this way, we have everything for :

        unaligned_5p_end = alignment_start - 1
        unaligned_3p_end = query_length - alignment_end
        strand = (alignment_start > alignment_end) ? - : +
        match_score = query_length - 2 * (mismatches + unaligned_5p_end + unaligned_3p_end)
        
Because gap opening and gap extension is heavily penalized, the blastn is essentially gap-free, and chances are that we will never see gaps in the alignment. In the very rare cases where gaps does show up, matching to a gap is also considered as a mismatches. Knowing that each gap extends the alognment by one nucleotide, we can request for the number of gap and adjust the match score:

        alignment_length = query_length + gaps
        match_score = alignment_length - 2 * (mismatches + unaligned_5p_end + unaligned_3p_end + gaps)
        = query_length - 2 * (mismatches + unaligned_5p_end + unaligned_3p_end) - gaps
        
By analyzing the problem mathematically first and trying to be patient with the rather complicated BLASTN user manual, we can build a Linux command that solves a seemingly complicated problem!

**Is there a command-line version of "the" orgiginal CRISPRTarget?**

Yes, one is under development, and will be made available in the near future.

References
Biswas, A., et al. (2015). "Computational Detection of CRISPR/crRNA Targets." Methods in Molecular Biology 1311: 77-89.DOI: 10.1007/978-1-4939-2687-9_5

Biswas, A., et al. (2013). "CRISPRTarget: Bioinformatic prediction and analysis of crRNA targets." RNA biology 10(5): 817-827.DOI: 10.4161/rna.24046
	


