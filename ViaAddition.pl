## (c) Krishna Subramanian <https://github.com/mongrelgem>
## UART Project <https://github.com/mongrelgem/USART-RTL-Physical-Design>
## Report Bugs and Issues <https://github.com/mongrelgem/USART-RTL-Physical-Design/issues>

#!/usr/local/bin/perl 

#####
print("This script file will remove nrd nrs m and OFF parameters\n");
print("from a netlist file.\n");
print("Modified by Xiangyu.\n");

#### USAGE
$num_args=$#ARGV;
if ($num_args!=1){
	die ("\n%USAGE: netclean.pl <infile> <outfile>\n");
}

##### enter input file
$inputfile=@ARGV[0];
#print $inputfile;

$outputfile=@ARGV[1];
#print " $outputfile\n";

##### open input file
open(READINPUT,$inputfile) || die "Cannot open $inputfile for reading!";

##### open output file
if (-e $outputfile){
	print ("Overwriting $outputfile\n");
}
else {
	print("Creating $outputfile!\n");
}

open(WRITEOUTPUT,">$outputfile") || die "Cannot overwrite $outputfile!";

##### process the file
if (-e $outputfile)
{
#	print("Start processing $inputfile!\n");
		while(<READINPUT>)
		{
			#print $_;
			s/VIAS 2 ;/\VIAS 5 ;
- via1
 + RECT M1 ( -70 -70 ) ( 70 70 )
 + RECT M2 ( -50 -90 ) ( 50 90 )
 + RECT V1 ( -50 -50 ) ( 50 50 )
;
- via2
 + RECT M2 ( -50 -90 ) ( 50 90 )
 + RECT M3 ( -60 -60 ) ( 60 60 )
 + RECT V2 ( -50 -50 ) ( 50 50 )
;
- via3
 + RECT M3 ( -70 -70 ) ( 70 70 )
 + RECT M4 ( -60 -60 ) ( 60 60 )
 + RECT V3 ( -50 -50 ) ( 50 50 ) 
;
- via4
 + RECT M4 ( -70 -70 ) ( 70 70 )
 + RECT M5 ( -60 -60 ) ( 60 60 )
 + RECT V4 ( -50 -50 ) ( 50 50 )
;
- via5
 + RECT M5 ( -70 -70 ) ( 70 70 )
 + RECT M6 ( -60 -60 ) ( 60 60 )
 + RECT V5 ( -50 -50 ) ( 50 50 )
 ;
/ig;		
			s/via1Array_0/via1/ig;
			s/via1Array_2/via1/ig;
			s/via1Array_1/via1/ig;		
			print WRITEOUTPUT $_;
		}
		print("Done!\n");
}
close (READINPUT);
close (WRITEOUTPUT);

