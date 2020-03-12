#!/bin/bash
##Usage : sh  sanger_CandiHap.sh  ref.fa
##  e.g.:  time  sh  sanger_CandiHap.sh  PHYC.txt
##################################################
GATK=/home/data1/bin/GenomeAnalysisTK.jar
Picard=/home/data1/bin/picard.jar

BWA=bwa
if [ ! -x "$BWA" ] ; then
  if ! which bwa ; then
    echo "Could not find bwa in current directory or in PATH"
    exit 1
  else
    BWA=`which bwa`
  fi
fi
Samtools=samtools
if [ ! -x "$Samtools" ] ; then
  if ! which samtools ; then
    echo "Could not find samtools in current directory or in PATH"
    exit 1
  else
    Samtools=`which samtools`
  fi
fi
Bcftools=bcftools
if [ ! -x "$Bcftools" ] ; then
  if ! which bcftools ; then
    echo "Could not find bcftools in current directory or in PATH"
    exit 1
  else
    Bcftools=`which bcftools`
  fi
fi
Bgzip=bgzip
if [ ! -x "$Bgzip" ] ; then
  if ! which bgzip ; then
    echo "Could not find bgzip in current directory or in PATH"
    exit 1
  else
    Bgzip=`which bgzip`
  fi
fi
Java=java
if [ ! -x "$Java" ] ; then
  if ! which java ; then
    echo "Could not find java in current directory or in PATH"
    exit 1
  else
    Java=`which java`
  fi
fi
Perl=perl
if [ ! -x "$Perl" ] ; then
  if ! which perl ; then
    echo "Could not find perl in current directory or in PATH"
    exit 1
  else
    Perl=`which perl`
  fi
fi

##################################################
for i in *.ab1
do
  $Perl ab1-fastq.pl  $i
done
REF=$1;
cp $REF  ref.fa
$BWA index ref.fa
$Java -jar $Picard CreateSequenceDictionary R=ref.fa
# single-end reads
for i in *F.fq
do
  $BWA mem  -R "@RG\tID:${i%%_F.fq}\tSM:${i%%_F.fq}"  ./ref.fa   $i   |samtools view -bh |samtools sort -o ${i%%_F.fq}.sort.bam
done

$Samtools faidx  ./ref.fa

for i in *sort.bam
do
  $Samtools index  $i
  $Java -Xmx30g -jar $GATK HaplotypeCaller -R ./ref.fa -ERC GVCF -I $i  -O ${i%%sort.bam}vcf
done

for i in *.vcf
do
  $Bgzip -c -f $i> $i.gz
  $Bcftools index  $i.gz
done
$Bcftools merge *vcf.gz -o merge.g.VCF
rm  -rf  *fq  *vcf.gz  *gz.csi  *idx  *bam  *bai  *vcf

$Java -Xmx30g  -jar $GATK GenotypeGVCFs  -R ./ref.fa --variant merge.g.VCF -O raw.merged_gvcf.vcf
sed -i 's/\.\/\./0\/0/g' raw.merged_gvcf.vcf
$Perl Gene_VCF2haplotypes.pl raw.merged_gvcf.vcf  > Hap_raw-result-${REF%%.*}.txt
### SNPs
$Java -Xmx30g  -jar $GATK SelectVariants -R ./ref.fa -V raw.merged_gvcf.vcf --select-type SNP -O merge.raw.snp.vcf
$Java -Xmx30g  -jar $GATK VariantFiltration -R ./ref.fa -V merge.raw.snp.vcf --filter-expression "QD < 2.0 || MQ < 40.0 || FS > 60.0 || SOR > 3.0 || MQRankSum < -12.5 || ReadPosRankSum < -8.0" --filter-name 'Filter' -O merge.raw.snp.filt.vcf
$Java -Xmx30g  -jar $GATK SelectVariants  -R ./ref.fa -V merge.raw.snp.filt.vcf --exclude-filtered  -O merge.raw.snp.pass.vcf
#### indel
$Java -Xmx30g -jar $GATK SelectVariants -R ./ref.fa -V raw.merged_gvcf.vcf --select-type INDEL -O merge.raw.indel.vcf
$Java -Xmx30g -jar $GATK VariantFiltration -R ./ref.fa -V merge.raw.indel.vcf --filter-expression "QD < 2.0 || FS > 200.0 || SOR > 10.0 || MQRankSum < -12.5 || ReadPosRankSum < -8.0" --filter-name 'Filter' -O merge.raw.indel.filt.vcf
$Java -Xmx30g -jar $GATK SelectVariants  -R ./ref.fa -V merge.raw.indel.filt.vcf --exclude-filtered  -O merge.raw.indel.pass.vcf
### all
$Java -Xmx30g -jar $GATK MergeVcfs -I merge.raw.snp.pass.vcf -I merge.raw.indel.pass.vcf -O all.snp.indel.pass.vcf
sed -i 's/\.\/\./0\/0/g' all.snp.indel.pass.vcf
$Perl Gene_VCF2haplotypes.pl all.snp.indel.pass.vcf  > Hap_Filter-result-${REF%%.*}.txt
rm  -rf  merge.g.VCF  merge.raw*  ref.*  *.idx