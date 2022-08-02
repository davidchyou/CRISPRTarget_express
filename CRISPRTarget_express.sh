SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`
INFILE=$1
DB=$2
grep 'binding_site' $INFILE | \
perl -F'\t' -lane '{($genome_id,$start,$end,$comment)=@F[0,3,4,8];
($array_index,$spacer_index,$spacer_start,$spacer_end,$array_start,$array_end,$seq)=
($comment=~/ID=CRISPR(\d+)_\S+(\d+)_(\d+)_(\d+);Name=\S+;Parent=CRISPR\d+_(\d+)_(\d+);Note=(\S+);Dbxref=\S+;.*/);
$spacer_id=$genome_id."_".$array_index."_".$spacer_index."|".$spacer_start."_".$spacer_end;print ">$spacer_id\n$seq";
}' | $SCRIPTPATH/blastn -query - -db $DB -num_threads 20 \
-outfmt '6 sseqid stitle sstart send qseqid qstart qend sstrand length evalue mismatch gaps qlen slen' \
-word_size 7 -evalue 1 -gapopen 10 -gapextend 2 -penalty -1 -reward 1 -dbsize 1000000000 | \
perl -F'\t' -lane 'BEGIN{$count=0;}{
($seq_id,$seq_desc,$seq_len,$spacer_id,$spacer_len,$aln_mismatch,$aln_gap)=@F[0,1,13,4,12,10,11];
$count++; $bedtools_id="$seq_id#$spacer_id#$count";
$target_ori=(@F[7]eq"plus")?"-":"+";
$aln_target_start=(@F[2]>@F[3])?@F[3]:@F[2];
$aln_target_end=(@F[2]>@F[3])?@F[2]:@F[3];
$aln_spacer_start=(@F[5]>@F[6])?@F[6]:@F[5]; 
$aln_spacer_end=(@F[5]>@F[6])?@F[5]:@F[6];
$n_miss_5p=$aln_spacer_start-1;
$n_miss_3p=$spacer_len-$aln_spacer_end;
$true_target_start=$aln_target_start-$n_miss_5p;
$true_target_end=$aln_target_end+$n_miss_3p;
$true_target_start=($true_target_start>=1)?$true_target_start:1;
$true_target_end=($true_target_end<=$seq_len)?$true_target_end:$seq_len;
$score=$spacer_len-2*($aln_mismatch+$n_miss_5p+$n_miss_3p)-$aln_gap;
$true_target_start=$true_target_start-1;
print "$seq_id\t$true_target_start\t$true_target_end\t$bedtools_id\t$score\t$target_ori";
}' | sort -k1,1 -k2,2n 2>/dev/null
