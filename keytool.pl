use warnings;
use strict;

if ($#ARGV!=0)
{
	print ("TAG keytool\nuse keytool tag.ovl\n");
	exit;
}

#####################
#      KEYTOOL      #
#####################
# MCbx 2015         #
#Takes TAG.OVL and  #
#produces the key.  #
#                   #
#####################

sub numerate {	#convert as according to Turbo C compiler padding
	my ($key)=@_;
	my @items;
	foreach my $chr (split('',$key))
	{
		if ( $chr =~ /^[0-9]+$/ )
		{
			push(@items,$chr);
		}
		else
		{
			push(@items,ord($chr)-55);
		}
	}
	return @items;
}

sub denumerate {	#takes one character a time
	my ($key)=@_;
		if ( $key < 10 )
		{
			return $key;
		}
		else
		{
			return chr($key+55);
		}
}

open (INFILE, "<", $ARGV[0]) or die "Not able to open the source file. \n";
my $buffer;
read (INFILE, $buffer, 16);
close (INFILE);

if (substr($buffer,0,2) ne 'TA')
{
	print "This doesn't look like TAG SN. Exiting.\n";
	exit;
}
print "\n";
my $ready=substr($buffer,0,10);
my $analyse = substr($buffer,10,6);
my $tramen=2;
foreach my $chr (numerate($analyse))
{
	$ready=$ready.denumerate(($chr-$tramen)%36);
	$tramen=$tramen+2;
}
print $ready;
print "\n";
