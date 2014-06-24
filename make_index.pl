use strict;
use File::Temp qw/tempfile/;
use File::Basename;

my @Rscript = glob("example/*.R");

open HTML, ">index.html";

print HTML "
<html>
<head>
<title>Hello circlize</title>
<style>
img {
	width:300px;
}

#comment {
	border: 1px black solid;
	margin:10px 0px;
}
</style>

</head>
<body>
<h2>Examples of using <i>circlize</i></h2>
<p>Click on the figures to view source code. If you have fancy figures generated by <i>circlize</i>, you can send me the figures and code and I will put them here.</p>
<table>";

my $i = 1;
foreach my $R (sort { (stat($b))[10] <=> (stat($a))[10] } @Rscript) {
	print "running $R\n";

	my $png = $R;
	my $html = $R;
	$png =~s/R$/png/;
	$html =~s/R$/html/;

	if($i % 4 == 1) {
		print HTML "<tr>";
	}
	
	print HTML "<td><a href='$html'><img src='$png'/></a></td>";

	open HTML2, ">$html";
	print HTML2 "<html>
<head><meta charset='UTF-8' />
<title>$R</title>
<link rel='stylesheet' href='styles/github.css'>
<script src='highlight.pack.js'></script>
<script>hljs.initHighlightingOnLoad();</script>
</head><body><p><img src='".basename($png)."' /></p>\n";
	open R, $R;
	my $comment = "";
	while(my $line = <R>) {

		if($line =~/^##/) {
			$line =~s/^##\s+//;
			$comment .= "$line ";
		}
	}
	print HTML2 "<p id='comment'>$comment</p>\n";
	
	print HTML2 "<p id='code'><pre><code>";
	open R, $R;
	while(my $line = <R>) {

		if($line =~/^##/) {
			next;
		}
		$line =~s/\t/    /g;
		print HTML2 $line;
	}
	print HTML2 "</code></pre></p>\n</body></html>";
	close HTML2;
	close R;

	if($i % 4 == 0) {
		print HTML "</tr>\n";
	}

	$i ++;

	if(-e $png) {
		next;
	}

	open R, $R;

	my ($fh, $filename) = tempfile();
	print $fh "library(Cairo);CairoPNG('$png', width = 600, height = 600)\n";
	while(<R>) {
		print $fh $_;
	}
	print $fh "\ndev.off()\n";
	close($fh);

	system("Rscript $filename");
	unlink($filename);
} 

if($i % 4 != 0) {
	print HTML "</tr>\n";
}

print HTML "</body></html>";