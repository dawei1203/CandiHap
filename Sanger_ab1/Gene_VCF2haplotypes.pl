#!/usr/bin/perl
open IN, "$ARGV[0]" or die $!;
open OUT,">test.txt" or die $!;
while (<IN>) {
    $_ =~ s/\r*\n*//g;
    @names = split(/\t/,$_) if $_ =~ /CHROM/;
    $n  = "$names[1]\t$names[3]\t$names[4]\t$names[7]\t" . join ("\t",@names[9..$#names]);
    @a = split(/\t/,$_);
    for ($i = 9;$i <= $#a;$i++){
        if ($a[$i] =~ /\.\/\./) {
            $a[$i] = 'N/N' ;
        }
        elsif ($a[$i] =~ /(.)(.)(.)/ ) {
        $Fir = $1;
        $Sen = $3;
        @alt = split(/,/,$a[4]);
        unshift( @alt, $a[3]); 
        $a[$i] = $alt[$Fir].'/'.$alt[$Sen];
        $a[$i] = $alt[$Fir].'/'.$alt[$Sen].'**' if ($Fir eq '1' and $Sen eq '1') ;
        }
    }
    #$a[7] =~ /EFF=(.*)/;
    $l = "$a[1]\t$a[3]\t$a[4]\t$1\t" . join ("\t",@a[9..$#a]);
    #push @lxk2 , $l;
    push @lxk2 , $l if ($l =~ /\*\*/);
}
push @lxk2 , $n;
#@a ='';
for (@lxk2) {
    my @a = split /\t/, $_;
    for (my $i=0;$i<@a;$i++){
        $out{$i}{$a[0]} = $a[$i];
    }
}

foreach my $k (sort {$a<=>$b} keys %out ){
    my $out;
    foreach $d (sort {$a<=>$b} keys %{$out{$k}}){
        $out .= "$out{$k}{$d}\t";
    }
    $out =~ s/\t$//g;
    print OUT "$out\n";
}
close IN;
close OUT;
@a ='';
open FILE, "test.txt" or die $!;
while (<FILE>) {
    if ($_ =~ /^POS/ ) {
        $_ =~ s/\r*\n*//g;
        @a = split(/\t/,$_);
        $POS = "SNP positions\t". join ("\t",@a[1..$#a]) . "\tNumber of samples\tSample ID";
        next;
    }
    if ($_ =~ /^REF/  ) {
        $_ =~ s/\r*\n*//g;
        @a = split(/\t/,$_);
        $ref = "References allele\t". join ("\t",@a[1..$#a]);
        next;
    }
    if ($_ =~ /^ALT/ ) {
        $_ =~ s/\r*\n*//g;
        @a = split(/\t/,$_);
        $alt = "Alternative allele\t". join ("\t",@a[1..$#a]);
        next;
    }
    if ($_ =~ /^INFO/ ) {
        $_ =~ s/\r*\n*//g;
        @a = split(/\t/,$_);
        $EFF = "SNP annotation\t". join ("\t",@a[1..$#a]);
        next;
    }
    if ($_ =~ /^Allele/ ) {
        $_ =~ s/\r*\n*//g;
        @a = split(/\t/,$_);
        $All = "Allele Frequency\t". join ("\t",@a[1..$#a]);
        next;
    }
    $_ =~ s/\r*\n*//g;
    @a = split(/\t/,$_);
    $n = join ("\t",@a[1..$#a]);
    $lxk{$n} .= "$a[0], ";
    $lxk2{$n} ++;
}
#print "$ref\n$alt\n$EFF\n$POS\n";
print "$ref\n$alt\n$POS\n";
$i =1 ;
foreach my $k (sort {$lxk2{$b} <=> $lxk2{$a} } keys %lxk2 ){
    $lxk{$k} =~ s/, $//g;
    $hap = Hap_ . $i;
    print "$hap\t$k\t$lxk2{$k}\t$lxk{$k}\n";
    $i ++;
}
system 'rm  -rf test.txt';


