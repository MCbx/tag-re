use warnings;
use strict;
use Switch;

##################
#     UNTAG      #
##################
# ver. 20150612  #
# MCbx           #
#  PRELIMINARY   #
##################

my $SECRETS=0;
#change to 1 for getting unwanted/deleted content from files

print "UNTAG v. 0.01\n";
print "MCbx 2015\n";
#blatantly assuming that console can do unicode...
sub convert_encoding { #convert TAG diacritized characters to UTF8
	my ($cnvStr)=@_;
	$cnvStr=~ s/\xA8/Ę/g;
	$cnvStr=~ s/\xA4/Ą/g;
	$cnvStr=~ s/\x97/Ś/g;
	$cnvStr=~ s/\xE3/Ń/g;
	$cnvStr=~ s/\x8F/Ć/g;
	$cnvStr=~ s/\xBD/Ż/g;
	$cnvStr=~ s/\x8D/Ź/g;
	$cnvStr=~ s/\xE0/Ó/g;
	$cnvStr=~ s/\x9D/Ł/g;
	$cnvStr=~ s/\xA9/ę/g;
	$cnvStr=~ s/\xA5/ą/g;
	$cnvStr=~ s/\x98/ś/g;
	$cnvStr=~ s/\xE4/ń/g;
	$cnvStr=~ s/\x86/ć/g;
	$cnvStr=~ s/\xBE/ż/g;
	$cnvStr=~ s/\xAB/ź/g;
	$cnvStr=~ s/\xA2/ó/g;
	$cnvStr=~ s/\x88/ł/g;
	return $cnvStr;
}

if ($#ARGV!=1)
{
	print "Usage: Untag file.tag file.htm\n";
	exit;
}

print "LOADING        ";
open (INFILE, "<", $ARGV[0]) or die "Not able to open the source file. \n";
binmode INFILE;


print "OK\nINSTALLATION   ";
#Here: read fonts and colors info from config file.
open (OUTFILE, ">", $ARGV[1]) or die "Not able to open the destination file!\n";
print OUTFILE "<html>\n<head>\n<title>",$ARGV[0],"</title>\n";
print OUTFILE "<meta name=\"generator\" content=\"unTAG.pl\">\n";
print OUTFILE "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n";
my $style="<style>\n";
my $body="</style>\n</head>\n<body>\n";
my $buffer;

#compare magic bytes
read (INFILE, $buffer, 8);
if ($buffer ne pack("cccccccc",0x01, 0x00, 0x54, 0x41, 0x47, 0x00, 0x00, 0x00))
{
	print "Not a TAG file.\n";
	exit;
}

#############################################################
#                         H E A D E R                       #
#############################################################
my $evenHdr=0;
my $oddHdr=0;
my $evenFtr=0;
my $oddFtr=0;
my $styleOffset=0;
my $textOffset=0;
my $hdrOffset=0;
my $stylesNo=0;
my $skipHFT=0; #Header/footer First/Last Text/Chapter
my $skipHLT=0;
my $skipFFT=0;
my $skipFLT=0;
my $skipHFC=0;
my $skipHLC=0;
my $skipFFC=0;
my $skipFLC=0;
#TODO: Page size, orientation and margins from header.

print "OK\n----FILE INFO----\n";
read (INFILE, $buffer, 1);
print "File version: ",ord($buffer),".";
read (INFILE, $buffer, 1);
print ord($buffer),"\t\t";
read (INFILE, $buffer, 2); #skip 2 zeros

read (INFILE, $buffer, 2);
print "Page width: ",unpack("v",$buffer),"\n";
read (INFILE, $buffer, 1);

read (INFILE, $buffer, 1);
print "Print mode: ";
switch (ord($buffer)) {
	case 1 { print "Full NLQ" }
	case 2 { print "Fast NLQ" }
	case 4 { print "TextMode" }
	else   { print "unknown " }
}
print " (",sprintf("0x%02X",ord($buffer)),")\t";

read (INFILE, $buffer, 1);
print "Print offset: ",ord($buffer),"\n";

read (INFILE, $buffer, 1);
print "Bind margin: ",ord($buffer),"\t\t\t";

read (INFILE, $buffer, 1);
print "Print media: ";
switch (ord($buffer)) {
	case 0 { print "Continuous" }
	case 1 { print "Single sheet" }
	else   { print "unknown     " }
}
print " (",sprintf("0x%02X",ord($buffer)),")\n";

read (INFILE, $buffer, 1);
print "Print pages: ";
switch (ord($buffer)) {
	case 0 { print "Even" }
	case 1 { print "Odd " }
	case 2 { print "All " }
	else   { print "??? " }
}
print " (",sprintf("0x%02X",ord($buffer)),")\t";

read (INFILE, $buffer, 4);
print "Creation date: ";
$buffer=unpack("V",$buffer);
my @aaa = gmtime($buffer);
print $aaa[5]+1900,"-",$aaa[4],"-",$aaa[3]," ",$aaa[2],":",$aaa[1],":",$aaa[0],"\n";

read (INFILE, $buffer, 4);
print "Mod date: ";
$buffer=unpack("V",$buffer);
@aaa = gmtime($buffer);
print $aaa[5]+1900,"-",$aaa[4],"-",$aaa[3]," ",$aaa[2],":",$aaa[1],":",$aaa[0],"\t";

read (INFILE, $buffer, 4);
print "Work time: ";
$buffer=unpack("V",$buffer);
@aaa = gmtime($buffer);
print $aaa[4],"-",$aaa[3]-1," ",$aaa[2],":",$aaa[1],":",$aaa[0],"\n";

read (INFILE, $buffer, 2);
print "Page height: ",unpack("v",$buffer),"\t\t";

read (INFILE, $buffer, 1);
print "Headers/footers presence: ";
if (ord($buffer) == 1)
{
	$evenHdr=1;
	print "EH ";
}
read (INFILE, $buffer, 1);
if (ord($buffer) == 1)
{
	$oddHdr=1;
	print "OH ";
}
read (INFILE, $buffer, 1);
if (ord($buffer) == 1)
{
	$evenFtr=1;
	print "EF ";
}
read (INFILE, $buffer, 1);
if (ord($buffer) == 1)
{
	$oddFtr=1;
	print "OF ";
}
print "\n";
read (INFILE, $buffer, 4);

read (INFILE, $buffer, 4);
$hdrOffset=unpack("V",$buffer);
read (INFILE, $buffer, 4);
$styleOffset=unpack("V",$buffer);
read (INFILE, $buffer, 1);
$stylesNo=ord($buffer);
read (INFILE, $buffer, 1); #go past 02
read (INFILE, $buffer, 4);
$textOffset=unpack("V",$buffer);

read (INFILE, $buffer, 1); #Print headers/footers
$buffer=ord($buffer);
print "Skip print: ";
if ($buffer & 0b00000001)
{
	print "Header-first-text ";
	$skipHFT=1;
}
if ($buffer & 0b00000010)
{
	print "Header-last-text ";
	$skipHLT=1;
}
if ($buffer & 0b00000100)
{
	print "Footer-first-text ";
	$skipFFT=1;
}
if ($buffer & 0b00001000)
{
	print "Footer-last-text ";
	$skipFLT=1;
}
if ($buffer & 0b00010000)
{
	print "Header-first-chapter ";
	$skipHFC=1;
}
if ($buffer & 0b00100000)
{
	print "Header-last-chapter ";
	$skipHLC=1;
}
if ($buffer & 0b01000000)
{
	print "Footer-first-chapter ";
	$skipFFC=1;
}
if ($buffer & 0b10000000)
{
	print "Footer-last-chapter ";
	$skipFLC=1;
}
print "\n";

read (INFILE, $buffer, 2); #28 00 ??

read (INFILE, $buffer, 1);
print "Top Margin: ",ord($buffer),"\t\t\t";

read (INFILE, $buffer, 1);
print "Bottom Margin: ",ord($buffer),"\n";

read (INFILE, $buffer, 1);
print "Text revision: ",ord($buffer);
read (INFILE, $buffer, 1);
print ".",ord($buffer),"\t\t";

read (INFILE, $buffer, 1);
print "Portrait mode: ";
if (ord($buffer) == 1) 
{
	print "Yes";
}
else
{
	print "No";
}
print "\n";

#Then description goes...
read (INFILE,$buffer,170);
print "------------DESCRIPTION------------\n";
$buffer =~ s/(.{1,36})/$1\n/gs;
my @descr=split("\n",$buffer);
foreach my $x (@descr)
{
	if ($SECRETS==0)
	{
			$x=~s/\x00.*//; #remove everything after 0x00 from string.			
	}
	$x=convert_encoding($x);
	print $x,"\n";
}

print "-----------------------------------\n";

#############################################################
#                T E X T    H I E R A R C H Y               #
#############################################################

print "-----------TEXT HIERARCHY----------";
my @titles;
my @offsets;
my @nextItems;
my @underItems;
my @lengths;
my @depths;
seek(INFILE,256,0);

while (tell(INFILE)<$textOffset) #read hierarchy into structures
{
	read(INFILE,$buffer,67);
	$buffer =~ s/\x00.*//;
	$buffer=convert_encoding($buffer);
	push (@titles, $buffer);
	read(INFILE,$buffer,4);
	$buffer=unpack("V",$buffer);
	push(@nextItems,$buffer);
	read(INFILE,$buffer,4);
	$buffer=unpack("V",$buffer);
	push(@underItems,$buffer);
	read(INFILE,$buffer,1); #skip useless things
	read(INFILE,$buffer,1);
	$buffer=ord($buffer);
	push(@depths,$buffer);
	read(INFILE,$buffer,3); #skip useless things
	read(INFILE,$buffer,4);
	$buffer=unpack("V",$buffer);
	push(@offsets,$buffer);
	read(INFILE,$buffer,4);
	$buffer=unpack("V",$buffer);
	push(@lengths,$buffer);	
	read(INFILE,$buffer,12);
}

#visualize structure - recursive thing
sub dispStruct {
	my ($place)=@_;
	if ($place>$#titles)
	{
		return 0;
	}
	print "\n";
	for (my $x=0; $x<$depths[$place];$x++)
	{
		print " ";
	}
	print $titles[$place];
	if ($place>0)
	{
		$body=$body."<li><a href=#".$offsets[$place].">".$titles[$place]."</a></li>\n";
	}
	else
	{
		$body=$body."<ul><li>".$titles[$place]."</li>\n";
	}
	if ($underItems[$place]!=255)
	{
		$body=$body."<ul>\n";
		dispStruct($underItems[$place]);
	}
	if ($nextItems[$place]!=255)
	{
		dispStruct($nextItems[$place]);
	}
	else
	{
		$body=$body."</ul>\n";
	}
	return 0;
}
dispStruct(0); #Visualize hierarchy
$body=$body."<hr>\n\n";
print "\n-----------------------------------\n";


#############################################################
#                        S T Y L E S                        #
#############################################################
print "---------------STYLES--------------\n";
seek (INFILE,$styleOffset,0);
for (my $stC=0;$stC<$stylesNo;$stC++)
{
	#check for corrections
	read (INFILE, $buffer, 35);
	seek (INFILE, tell(INFILE)-35,0);
	my $num1 = $buffer =~ tr/\x00//;
	if($num1==35)
	{
		read (INFILE, $buffer, 35);
		next;
	}
	
	#read styles
	print "STYLE NO. ",$stC,"\n";
	read (INFILE, $buffer, 1); #Left margin
	print "  Left: ",ord($buffer),"\t";
	read (INFILE, $buffer, 1); #Right margin
	print "  Right: ",ord($buffer),"\n";
	
	read (INFILE, $buffer, 20); #tab stops
	print "  Tab Stops: ";
	foreach my $stp (split('',$buffer))
	{
		print ord($stp),", ";
	}
	print "\n";
	
	read (INFILE, $buffer, 1); #Text alignment
	
	read (INFILE, $buffer, 1); #Font
	
	read (INFILE, $buffer, 1); #Color
	
	read (INFILE, $buffer, 10); #Name
	$buffer=~s/\x00.*//;
	print "  Name: ",$buffer,"\n";
}
print "-----------------------------------\n";

print OUTFILE $style;
print OUTFILE $body;
print OUTFILE "</body>\n</html>\n";
close(OUTFILE);
exit;

#Parse headers/footers.
#Parse text

close(INFILE);
