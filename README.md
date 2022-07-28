# CRISPRTarget_lite

**What it does**

Genomes targeted by CRISPR spacers can be identified by sequence alignment. The highly-cited web-application CRISPRTarget does exactly this job. CRISPRTarget uses the application BLASTN to align spacers to genomic sequences, compute spacer-match scores by incrementing every nucleotide match by 1 and decrementing every mismatch by 1. Because BLASTN is a local-alignment tool, there will be unaligned nucleotides at the end of CRISPR spacer (i.e. unaligned free ends), and these nucleotides were treated as mismatches. Similarly, when reporting the spacer targets, the start-end of each target were extended to cover unaligned free ends of the spacer. CRISPRTarget generates graphical HTML outputs with URLs link to websites hosting the targeted sequences, as well as scoring for known PAMs. 

In many occasions, we only need essential spacer target data of from CRISPRTarget, namely the genome being targeted, the start-end of the target, the targeted strand, the targeting spacers and the +1/-1 spacer-match scores penalizing for unaligned free ends of spacers. Instead of running CRISPRTarget online, all these data can be obtained by running BLASTN standalone with an appropriate set of command-line arguments first, followed by simple post-processing. Furthermore, having a command-line version of CRISPRTarget allows CRISPR analyses to be done with more flexibly.

The application CRISPRTarget_lite does exactly the above-mentioned. It reads in a set of CRISPR arrays in CRISPRDetect-GFF format, extracts spacer sequences from the GFF file and run BLASTN with an appropriate set of command-line arguments to tabulate data required for the score calculation as well as attributes of spacers and the targeted genomes. With an AWK-like data-process command (perl -lane), essential spacer target data are computed and displayed in BED6 format.

The BED6 file can be used to extract the target sequences and the flanking regions using the application Bedtools for further analyses. For example, one can extract the target flanks and look for PAMs.

**General usage**

The application CRISPRTarget_lite is a Shell script. The user need to specify the path to a CRISPR-array file in CRISPRDetect-GFF format, and a database of genomic sequences in BLASTDB format. Spacer target data will be printed to 'stdout' by default, but can also be directed into a file.

Commands:

        sh CRISPRTarget_lite.sh <crispr_array.gff> <blast_db>
        sh CRISPRTarget_lite.sh <crispr_array.gff> <blast_db> > <target_data.bed>

The only dependency is the application BLASTN, which is provided, and the script is pointing to it.

**More information**

The application CRISPRTarget_lite runs the following BLASTN command:

        blastn -query <spacers.fna> -db <blast_db> -num_threads <a_number> -outfmt '6 sseqid stitle sstart send qseqid qstart qend sstrand length evalue mismatch gaps qlen slen' -word_size 7 -evalue 1 -gapopen 10 -gapextend 2 -penalty -1 -reward 1 -dbsize 1000000000
        
In particular, sequence alignment is performed with the same set of command-line argumented used by CRISPRTarget by default. The BLASTN command generates a tabular output, and the query length (i.e. the spacer length) is requested by asking for the 'qlen' data. The number of mismatches is also requested. In this way, we have everything for :

        unaligned_5p_end = alignment_start - 1
        unaligned_3p_end = query_length - alignment_end
        strand = (alignment_start > alignment_end) ? - : +
        match_score = query_length - 2 * (mismatches + unaligned_5p_end + unaligned_3p_end)
        
Because gap opening and gap extension is heavily penalized, the BLASTN is essentially gap-free, and chances are that we will never see gaps in the alignment. In the very rare cases where gaps does show up, matching to a gap is also considered as a mismatches. Knowing that each gap extends the alognment by one nucleotide, we can request for the number of gap and adjust the match score:

        alignment_length = query_length + gaps
        match_score = alignment_length - 2 * (mismatches + unaligned_5p_end + unaligned_3p_end + gaps)
        = query_length - 2 * (mismatches + unaligned_5p_end + unaligned_3p_end) - gaps
        
By analyzing the problem mathematically first and trying to be patient with the rather complicated BLASTN user manual, we can build a Linux command that solves a seemingly complicated problem!

**But I want a command-line version of "the" CRISPRTarget?**

Yes, one is under development, and will be made available in the near future.
