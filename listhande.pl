use warnings;
use strict;

#  LISTHANDE
# Lists characters from H&E file
# MCbx 2015, for K.D.

open (INFILE, "<", $ARGV[0]) or die "Not able to open the file. \n";
binmode INFILE;
my $buffer="";
my $length=0;
my $character = 0;
my $numLines=0; 

while ( (read (INFILE, $buffer, 1)) != 0 ) 
{
	if ($length<100)
	{
		#PARSE HEADER
		if ($length==12)
		{
			$numLines=ord($buffer);
			$length++;
			next;
		}
		#End of parsing header.
	
		$length++;
		next; 
	}
	$buffer=ord($buffer);
	my $row = sprintf("%08b",$buffer);
	$row =~ s/0/ /g;
	$row =~ s/1/X/g; 
	print $row,"\n";
	if (($length-99)%$numLines==0)
	{
		print "Offset: ",$length-$numLines+1, " Character ",$character," Press Return\n";
		$character++;
		if ($#ARGV==0)
		{
			<STDIN>
		}
	}		
	$length++;
}
	
exit;
