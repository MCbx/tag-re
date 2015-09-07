use warnings;
use strict;
use Switch;

##################
#     UNTAG      #
##################
# ver. 20150717  #
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
if (! -e "template.css") 
{
	die ("No template.css file!\n");
}
open (OUTFILE, ">", $ARGV[1]) or die "Not able to open the destination file!\n";
print OUTFILE "<html>\n<head>\n<title>",$ARGV[0],"</title>\n";
print OUTFILE "<meta name=\"generator\" content=\"unTAG.pl\">\n";
print OUTFILE "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n";
my $style="<style>\n";
#Read default styles block
$style=$style."/* Default styles */\n";
open(DEFCSS, 'template.css') or die "Can't open template.css file!\n";
local $/;  
my $tempcss = <DEFCSS>; 
close (DEFCSS); 
$style=$style.$tempcss."\n";
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
my $width=0;
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
$width=unpack("v",$buffer);
print "Page width: ",$width,"\n";
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

#Takes single font byte. Returns font style 
sub get_attr_name {
	my ($bajt)=@_;
	my $attrs="";
	if (($bajt & 0b00000001)&&($bajt & 0b00000010))
	{
		$attrs=$attrs." szerWys";
	}
	else
	{
		if ($bajt & 0b00000001)
		{
			$attrs=$attrs." wysoki";
		}
		if ($bajt & 0b00000010)
		{
			$attrs=$attrs." szeroki";
		}
	}
	if ($bajt & 0b00000100)
	{
		$attrs=$attrs." podkreslony";
	}
	if ($bajt & 0b00001000)
	{
		$attrs=$attrs." gruby";
	}
	if ($bajt & 0b00010000)
	{
		$attrs=$attrs." kursywa";
	}
	return $attrs;
}

sub get_font_name {
	my ($bajt)=@_;
	my $num=0;
	if ($bajt & 0b10000000)
	{
		$num=$num+4;
	}
	if ($bajt & 0b01000000)
	{
		$num=$num+2;
	}
	if ($bajt & 0b00100000)
	{
		$num=$num+1;
	}
	switch ($num) {
		case 0 { return ""; } #Special - tables, matemat modified
		case 1 { return " courier"; }
		case 2 { return " artdeco"; }
		case 3 { return " engraved"; }
		case 4 { return " russkij"; }
		case 5 { return " oldelish"; }
		case 6 { return " matemat"; }
		case 7 { return " sanserif"; }
	}

}

sub get_color_name {
	my ($bajt)=@_;
	my $num=0;
	if ($bajt & 0b10000000)
	{
		$num=$num+4;
	}
	if ($bajt & 0b01000000)
	{
		$num=$num+2;
	}
	if ($bajt & 0b00100000)
	{
		$num=$num+1;
	}
	return " col".$num;
}

sub get_align_name {
	my ($bajt)=@_;
	my $num=0;
	if ($bajt & 0b00001000)
	{
		$num=$num+2;
	}
	if ($bajt & 0b00000100)
	{
		$num=$num+1;
	}
	switch ($num) {
		case 0 { return " left"; }
		case 1 { return " justified"; }
		case 2 { return " centered"; }
		case 3 { return " right"; }
	}
}

sub get_linespace_name {
	my ($bajt)=@_;
	my $num=0;
	if ($bajt & 0b01000000)
	{
		return " line2";
	}
	if ($bajt & 0b00000010)
	{
		$num=$num+2;
	}
	if ($bajt & 0b00000001)
	{
		$num=$num+1;
	}
	switch ($num) {
		case 0 { return " line0"; }
		case 1 { return " line12"; }
		case 2 { return " line1"; }
		case 3 { return " line32"; }
	}
}

print "---------------STYLES--------------\n";
$style=$style."/* User-generated styles */\n";

my @styleFontMod; #This keeps fonts for styles;
my @styleColorMod; #this keeps color for styles;
my @styleAlignMod; #this keeps text alignment for styles;
my @styleLinespaceMod; #Keeps line spacing for styles;
#This is made because in CSS classes are not inheritable

seek (INFILE,$styleOffset,0);
for (my $stC=0;$stC<$stylesNo;$stC++)
{
	push(@styleFontMod, "");
	push(@styleColorMod, "");
	push(@styleAlignMod, "");
	push(@styleLinespaceMod, "");

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
	$style=$style.".sty".$stC." {\n";
	read (INFILE, $buffer, 1); #Left margin
	print "  Left: ",ord($buffer),"\t";
	$style=$style."\t margin-left: ".ord($buffer)."ch;\n";
	read (INFILE, $buffer, 1); #Right margin
	print "  Right: ",ord($buffer),"\n";
#		$style=$style."\t margin-right: ".ord($buffer)."ch;\n";
	read (INFILE, $buffer, 20); #tab stops
	print "  Tab Stops: ";
	foreach my $stp (split('',$buffer))
	{
		print ord($stp),", ";
	}
	print "\n";
	
	read (INFILE, $buffer, 1); #Text alignment
	print "  Align: ".get_align_name(ord($buffer))."\n";
	$styleAlignMod[$stC]=get_align_name(ord($buffer));
		print "  Linespace: ".get_linespace_name(ord($buffer))."\n";
	$styleLinespaceMod[$stC]=get_linespace_name(ord($buffer));
	
	read (INFILE, $buffer, 1); #Font
	print "  Font: ".get_font_name(ord($buffer))."\n";
	print "   Attributes: ".get_attr_name(ord($buffer))."\n";
	$styleFontMod[$stC]=get_font_name(ord($buffer).get_attr_name(ord($buffer)));
	
	read (INFILE, $buffer, 1); #Color
	print "   Color: ".get_color_name(ord($buffer))."\n";
	$styleColorMod[$stC]=get_color_name(ord($buffer));
	
	
	read (INFILE, $buffer, 10); #Name
	$buffer=~s/\x00.*//;
	print "  Name: ",$buffer,"\n";
	$style=$style."} /* END OF USER STYLE ".$buffer."*/\n";
}
$style=$style."/* End of user styles */\n";

print "-----------------------------------\n";

print "--------------TEXT-----------------\n";

sub get_style_name {
	my ($bajt)=@_;
	my $num=0;
	if ($bajt & 0b00010000)
	{
		$num=$num+16;
	}
	if ($bajt & 0b00001000)
	{
		$num=$num+8;
	}
	if ($bajt & 0b00000100)
	{
		$num=$num+4;
	}
	if ($bajt & 0b00000010)
	{
		$num=$num+2;
	}
	if ($bajt & 0b00000001)
	{
		$num=$num+1;
	}
	return "sty".$num;
}

#gets paragraph length from offset
sub get_paragraph_length {
	my ($address)=@_;
	$address=$address+4;
	seek(INFILE, $address,0);
	my $buf=16;
	my $count=3;
	while (ord($buf)>8)
	{
		read (INFILE, $buf, 1);
		$count++;
	}
	return  $count;
}


#generates paragraph from offset
sub generate_paragraph {
	my ($address)=@_;
	#print $address." - ".($address+get_paragraph_length($address))."\n";
	seek(INFILE, $address,0);
	my $buf=0;
	my $division="";
	my $start2="<div class=\"";  ########
	
	read (INFILE, $buf, 1);   #Line breakage - Byte "B".
	if (ord($buf)==0)
	{
		$division="<br>";
	}
	if (ord($buf)==1)
	{
		$division="<br>";
	}
	if (ord($buf)==2)  #page break
	{
		$division="<hr>";
	}
	if (ord($buf)==3)
	{
		$division="<hr>";
	}
	
	read (INFILE, $buf, 1);     #Styles&colors: Byte "C".
	$start2=$start2.get_style_name(ord($buf))." ".get_color_name(ord($buf));
	
	read (INFILE, $buf, 1);
	if (ord($buf) == 0x12)
	{
		$start2=$start2." indGorny";
	}
	if (ord($buf) == 0x12)
	{
		$start2=$start2." indDolny";
	}
	
	my $span=0;
	my $space=0;
	read (INFILE, $buf, 1);     #font: Byte "D".
	$start2=$start2." ".get_font_name(ord($buf))." ".get_attr_name(ord($buf));
	my $text="\">";
	#my $f1=0;
	#my $f2=0;
	while (ord($buf)>8)
	{
		read (INFILE, $buf, 1);
		if (ord($buf)==0xFF)
		{
			#$text=$text."&nbsp;";
			next;
		}
		
		if (ord($buf)==0x10)	#font change
		{
			read (INFILE, $buf, 1);
			if ($span==1)
			{
				$text=$text."</span>";
				$span=0;
			}
			my $tmp1=get_font_name(ord($buf));
			$tmp1 =~ s/^\s+//;
			$text=$text."<span class=\"".$tmp1.get_attr_name(ord($buf))."\">";	
			$span=1;
			next;
		}
		
		if (ord($buf)==0x11)	#font change - SUBscript
		{
			read (INFILE, $buf, 1);
			if ($span==1)
			{
				$text=$text."</span>";
				$span=0;
			}
			my $tmp1=get_font_name(ord($buf));
			$tmp1 =~ s/^\s+//;
			$text=$text."<span class=\"".$tmp1.get_attr_name(ord($buf))."\">";	
			$span=1;
			next;
		}
		
		if (ord($buf)==0x12)	#font change - SUPERscript
		{
			read (INFILE, $buf, 1);
			if ($span==1)
			{
				$text=$text."</span>";
				$span=0;
			}
			my $tmp1=get_font_name(ord($buf));
			$tmp1 =~ s/^\s+//;
			$text=$text."<span class=\"".$tmp1.get_attr_name(ord($buf))."\">";	
			$span=1;
			next;
		}
		
		if (ord($buf)==0x18)	#TODO: Image in document
		{
			next;
		}
		
		if (ord($buf)==0x20)  #HTML space handling
		{
			if ($space==1)
			{
				$text=$text."&nbsp;";
				$space=0;
			}
			else
			{
				$text=$text." ";
				$space=1;
			}
			next;
		}
		#$f1=$f2;
		#$f2=$buf;
		#$buf=convert_encoding($buf);
		$text=$text.$buf;
		$space=0;
		
	}
	chop($text);
	my $paragraphAlign=chop($text);
	$text=convert_encoding($text);
	
	#Byte "A" - alignment and spacing;
	$start2=$start2." ".get_align_name(ord($paragraphAlign));
	$start2=$start2." ".get_linespace_name(ord($paragraphAlign));
	if ($span==1)
	{
		$text=$text."</span>";
		$span=0;
	}
	my $end="</div>"; 
	
	$start2 =~ tr/ //s;
	return $start2.$text.$end.$division."\n";
	#tell(INFILE);
}



my $wi2=($width/10)*2;
$body=$body."<div style=\"width: ".$wi2."ch; margin: 0 auto; overflow: hidden;\">";

print "Getting paragraphs...";
my $myThing=$textOffset;
while ($myThing<$hdrOffset)
{	
	if (grep( /^$myThing$/, @offsets ))
	{
		$body=$body." <a name=\"".$myThing."\">";
		print $myThing;
	}
	$body=$body." ".generate_paragraph($myThing);
	$myThing=$myThing+get_paragraph_length($myThing);
	print ".";
}
print $myThing."B OK.\n";
$body=$body."</div>";

#Emit HTML
print OUTFILE $style;
print OUTFILE $body;
print OUTFILE "</body>\n</html>\n";
print "-----------------------------\n";
close(OUTFILE);
exit;

#Parse headers/footers.
#Parse text

close(INFILE);
