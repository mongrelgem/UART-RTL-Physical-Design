## (c) Krishna Subramanian <https://github.com/mongrelgem>
## UART Project <https://github.com/mongrelgem/USART-RTL-Physical-Design>
## Report Bugs and Issues <https://github.com/mongrelgem/USART-RTL-Physical-Design/issues>

#!/usr/local/bin/perl -w


##### description
print("This script file modifies an abgen .lef file for use with Silicon Ensemble:\n");
print("Four files are necessary for proper .lef conversion:\n");
print("1. Technology file - from Envisia Abstract - provides header information\n");
print("2. Abgen file - from Cadence Abgen - provides cell macro data\n");
print("3. ASCII dump file - from Cadence - provides obstruction data\n");
print("4. Output file - existing or created now\n");


##### prompt and receive I/O filenames
print("Please enter technology header file name: ");
$headerfile=<STDIN>;
chomp ($headerfile);
print("Please enter abgen file name: ");
$abgenfile=<STDIN>;
chomp ($abgenfile);
print("Please enter ascii dump file name: ");
$asciifile=<STDIN>;
chomp ($asciifile);
print("Please enter output file name: ");
$outputfile=<STDIN>;
chomp ($outputfile);


##### open input files, assign filehandles
open(HEADER,$headerfile) || die "Cannot open $headerfile for reading!";
open(ABGEN,$abgenfile) || die "Cannot open $abgenfile for reading!";
$noascii = 0;
open(ASCII,$asciifile) or $noascii = 1;


##### open output file
if (-e $outputfile)
{
	$reply = "";
	until (($reply eq "y") || ($reply eq "n"))
	{
		print("$outputfile exists, overwrite[y/n]? ");
		$reply=<STDIN>;
		chomp ($reply);
	}
	if ($reply eq "y")
	{
		print("Okay!\n");
		open(WRITEOUTPUT,">$outputfile") || die;
	}
	elsif ($reply eq "n")
	{
		print("No changes made");
		exit;
	}
}
else
{
	print("$outputfile created!\n");
	open(WRITEOUTPUT,">$outputfile") || die "Cannot overwrite $outputfile!";

}

##### enter global power pin
print("Please enter global power pin name or <ret> for default (vdd!) : ");
$power=<STDIN>;
chomp ($power);
if ($power eq "")
{
	$power = "VDD!";
}
print("\n");


##### enter global ground pin
print("Please enter global ground pin name or <ret> for default (gnd!) : ");
$ground=<STDIN>;
chomp ($ground);
if ($ground eq "")
{
	$ground = "GND!";
}
print("\n");


##### enter global clock pins
print("Please enter global clock pin names separated by spaces or <ret> for none : ");
$clockin=<STDIN>;
chomp ($clockin);
@clock = split (/ /, $clockin);
print("\n");


##### enter global signal pins
print("Please enter global signal pin names separated by spaces or <ret> for none : ");
$globalin=<STDIN>;
chomp ($globalin);
@global = split (/ /, $globalin);
print("\n");


##### enter shape abutment pins
print("Please enter horizontal rail pin names separated by spaces or <ret> for default\n (vdd! gnd!) : ");
$railin=<STDIN>;
chomp ($railin);
if ($railin eq "")
{
	@rail = ("VDD!", "GND!");
}
else
{
	@rail = split (/ /, $railin);
}
print("\n");


##### prompt for symmetry
$xsym = "";
until (($xsym eq "y") || ($xsym eq "n"))
{
	print("X symmetry for all cells[y/n]? ");
	$xsym=<STDIN>;
	chomp ($xsym);
}
print ("\n");
$ysym = "";
until (($ysym eq "y") || ($ysym eq "n"))
{
	print("Y symmetry for all cells[y/n]? ");
	$ysym=<STDIN>;
	chomp ($ysym);
}


##### enter pitch
print("Please enter pin pitch: ");
$pitch=<STDIN>;
chomp ($pitch);
print("\n");


##### main processing
if (-e $outputfile)
{
	##### HEADER

	print("Writing header...\n");
	while (<HEADER>)
	{
		s/CUSTOM_PITCH/$pitch/;
		print WRITEOUTPUT $_;
	}
	print("Done!\n");


	##### SITE

	print("Writing site data...\n");

	$abg = <ABGEN>;
	until ($abg =~ /macro|(end library)/i)							# bypass non-macro data
	{
		$abg = <ABGEN>;
	}
	until ($abg =~ /end library/i)								# until end of abgen file
	{
		if ($abg =~ /macro/i)
		{
			$macroname = $abg;
			chomp ($macroname);
			$macroname =~ s/macro| //ig;
		}
		if ($abg =~ /size/i)
		{
			$size = $abg;
			chomp ($size);
			$size =~ s/by/,/ig;
			$size =~ s/[a-z]|;| //ig;
			($xsize, $ysize) = split (/,/, $size);
			push(@xlist, $xsize);
			push(@ylist, $ysize);
			
			if ((1000*$xsize)%(1000*$pitch))
			{
				print(" ERROR: cell $macroname boundary width is off-grid!\n");
				$error = 1;
			}
			
			if ((1000*$ysize)%(1000*$pitch))
			{
				print(" WARNING: cell $macroname boundary height is off-grid!\n");
			}
		}
		$abg = <ABGEN>;
	}

	if ($error)
	{
		exit;
	}

	@xlist = sort({$b <=> $a} @xlist);
	@ylist = sort({$b <=> $a} @ylist);

	$coreheight = $ylist[0];
=head
	print WRITEOUTPUT "\nSITE  CoreSite\n";
	print WRITEOUTPUT "    CLASS       CORE ;\n";
	print WRITEOUTPUT "    SYMMETRY    Y ;\n";
	printf WRITEOUTPUT "    SIZE        %.3f BY %.3f ;\n", $pitch, $coreheight;
	print WRITEOUTPUT "END  CoreSite\n\n";
	
	print WRITEOUTPUT "SITE  TDCoverSite\n";
	print WRITEOUTPUT "    CLASS       CORE ;\n";
	print WRITEOUTPUT "    SIZE        0.100 BY 0.100 ;\n";
	print WRITEOUTPUT "END  TDCoverSite\n\n";
	
	print WRITEOUTPUT "SITE  SBlockSite\n";
	print WRITEOUTPUT "    CLASS       CORE ;\n";
	print WRITEOUTPUT "    SIZE        0.100 BY 0.100 ;\n";
	print WRITEOUTPUT "END  SBlockSite\n\n";
	
	print WRITEOUTPUT "SITE  PortCellSite\n";
	print WRITEOUTPUT "    CLASS       PAD ;\n";
	print WRITEOUTPUT "    SIZE        0.100 BY 0.100 ;\n";
	print WRITEOUTPUT "END  PortCellSite\n\n";
	
	print WRITEOUTPUT "SITE  Core\n";
	print WRITEOUTPUT "    CLASS       CORE ;\n";
	print WRITEOUTPUT "    SYMMETRY    Y ;\n";
	printf WRITEOUTPUT "    SIZE        %.3f BY %.3f ;\n", $pitch, $coreheight;
	print WRITEOUTPUT "END  Core\n\n";
=cut

	##### MACROS
	
	seek(ABGEN, 0, 0);
	$abg = <ABGEN>;
	until ($abg =~ /end library/i)								# until end of abgen file
	{
		until ($abg =~ /macro|(end library)/i)						# bypass non-macro data
		{
			$abg = <ABGEN>;
		}
		if ($abg !~ /end library/i)							# if a macro exists
		{
			$macroname = $abg;							# record its name
			chomp($macroname);
			$macroname =~ s/macro| //ig;
			print("Writing macro $macroname...\n");	
			print WRITEOUTPUT "MACRO $macroname\n";
			$abg = <ABGEN>;
			while ($abg !~ /end $macroname/i)
			{
				print WRITEOUTPUT $abg;
				if ($abg =~ /size/i)
				{
					if ($xsym eq "y" && $ysym eq "n")
					{
						print WRITEOUTPUT "    SYMMETRY X ;\n";
					}
					elsif ($xsym eq "n" && $ysym eq "y")
					{
						print WRITEOUTPUT "    SYMMETRY Y ;\n";
					}
					elsif ($xsym eq "y" && $ysym eq "y")
					{
						print WRITEOUTPUT "    SYMMETRY X Y ;\n";
					}
					print WRITEOUTPUT "    SITE CoreSite ;\n";
				}
				elsif ($abg =~ /pin/i)
				{
					$pinname = $abg;
					chomp $pinname;
					$pinname =~ s/pin| //ig;
					$abg = <ABGEN>;
					print WRITEOUTPUT $abg;
					if ($pinname =~ /$power/i)
					{
						print WRITEOUTPUT "\tUSE POWER ;\n";
					}
					elsif ($pinname =~ /$ground/i)
					{
						print WRITEOUTPUT "\tUSE GROUND ;\n";
					}
					else
					{
						foreach $name (@clock)
						{
							if ($pinname =~ /$name/i)
							{
								print WRITEOUTPUT "\tUSE CLOCK ;\n";
							}
						}
						foreach $name (@global)
						{
							if ($pinname =~ /$name/i)
							{
								print WRITEOUTPUT "\tUSE SIGNAL ;\n";
							}
						}
					}
					foreach $name (@rail)
					{
						if ($pinname =~ /$name/i)
						{
							print WRITEOUTPUT "\tSHAPE ABUTMENT ;\n";
						}
					}
				}
				$abg = <ABGEN>;
			}


			if ($noascii == 0)
			{

				##### MACRO:OBS:LAYER M1

				seek(ASCII, 0, 0);
				$ascii = <ASCII>;
				$position = 0;
				until (($ascii =~ /cell name : $macroname/i)||($ascii =~ /end library/i))
				{
					$ascii = <ASCII>;
				}
				until (($ascii =~ /end cell definition/i)||($ascii =~ /end library/i))
				{
					if (($ascii =~ /rectangle/i)&&($ascii =~ /layer : 16/i))
					{
						if ($position == 0)
						{
							print WRITEOUTPUT "    OBS\n      LAYER M1 ;\n";
							print(" Writing obstruction data\n");
							$position = 1;
						}
						$pos = index($ascii, "(");
						$ascii = substr($ascii, $pos);
						chomp ($ascii);		# remove \n
						$ascii =~ s/ //g;	# remove whitespace
						$ascii =~ s/\)\(/,/g;	# replace )( with ,
						$ascii =~ s/\(|\)//g;	# remove ( and )
						@coordinates = split (/,/, $ascii);
						print WRITEOUTPUT "\tRECT  ";
						foreach $num (@coordinates)
						{
							$num = $num / 1000;
							printf WRITEOUTPUT "%.3f ", $num;
						}
						print WRITEOUTPUT ";\n";
						$ascii = <ASCII>;
					}
					elsif (($ascii =~ /polygon/i)&&($ascii =~ /layer : 16/i))
					{
						if ($position == 0)
						{
							print WRITEOUTPUT "    OBS\n      LAYER M1 ;\n";
							print(" Writing obstruction data\n");
							$position = 1;
						}
						print WRITEOUTPUT "\tPOLYGON  ";
						$ascii = <ASCII>;
						while ($ascii =~ /^ \(/i)
						{
							chomp ($ascii);		# remove \n
							$ascii =~ s/ //g;	# remove whitespace
							$ascii =~ s/\)\(/,/g;	# replace )( with ,
							$ascii =~ s/\(|\)//g;	# remove ( and )
							@coordinates = split (/,/, $ascii);
							foreach $num (@coordinates)
							{
								$num = $num / 1000;
								printf WRITEOUTPUT "%.3f ", $num;
							}
							$ascii = <ASCII>;
						}
						print WRITEOUTPUT ";\n";
					}
					elsif (($ascii =~ /path/i)&&($ascii =~ /layer : 16/i))
					{
						if ($position == 0)
						{
							print WRITEOUTPUT "    OBS\n      LAYER M1 ;\n";
							print(" Writing obstruction data\n");
							$position = 1;
						}

						@ascii_peices = split (/ /, $ascii);
						$layer_width = $ascii_peices[16];
						$layer_width_real = $layer_width/1000;
						$num_points = $ascii_peices[13];
						print WRITEOUTPUT "\tWIDTH $layer_width_real ;\n";

						print WRITEOUTPUT "\tPATH  ";
						$ascii = <ASCII>;
						$pos = 0;
						while ($ascii =~ /^ \(/i)
						{
							chomp ($ascii);		# remove \n
							$ascii =~ s/ //g;	# remove whitespace
							$ascii =~ s/\)\(/,/g;	# replace )( with ,
							$ascii =~ s/\(|\)//g;	# remove ( and )
							if ($pos == 0)
							{
							    $path_points = $ascii;
							    $pos = 1;
							}
							else
							{
							    $path_points = $path_points . ",";
							    $path_points = $path_points . $ascii;
							}
							$ascii = <ASCII>;
						}
							@coordinates = split (/,/, $path_points);
							if ($coordinates[0] == $coordinates[2] && $coordinates[1] < $coordinates[3])	#path starts moving up
							{
								$i = 0;
								until ($i == 2*$num_points - 2)
								{
									if ($i == 1)
									{	
										$num = ($coordinates[$i] / 1000) + $layer_width_real/2;
										printf WRITEOUTPUT "%.3f ", $num;
									}
									else
									{
										$num = ($coordinates[$i] / 1000);
										printf WRITEOUTPUT "%.3f ", $num;
									}
									$i++;
								}
							}
							elsif ($coordinates[0] == $coordinates[2] && $coordinates[1] >= $coordinates[3])	#path starts moving down
							{
								$i = 0;
								until ($i == 2*$num_points - 2)
								{
									if ($i == 1)
									{	
										$num = ($coordinates[$i] / 1000) - $layer_width_real/2;
										printf WRITEOUTPUT "%.3f ", $num;
									}
									else
									{
										$num = ($coordinates[$i] / 1000);
										printf WRITEOUTPUT "%.3f ", $num;
									}
									$i++;
								}
							}
							elsif ($coordinates[1] == $coordinates[3] && $coordinates[0] < $coordinates[2])	#path starts moving to the right
							{
								$i = 0;
								until ($i == 2*$num_points - 2)
								{
									if ($i == 0)
									{	
										$num = ($coordinates[$i] / 1000) + $layer_width_real/2;
										printf WRITEOUTPUT "%.3f ", $num;
									}
									else
									{
										$num = ($coordinates[$i] / 1000);
										printf WRITEOUTPUT "%.3f ", $num;
									}
									$i++;
								}
							}
							elsif ($coordinates[1] == $coordinates[3] && $coordinates[0] >= $coordinates[2])	#path starts moving to the left
							{
								$i = 0;
								until ($i == 2*$num_points - 2)
								{
									if ($i == 0)
									{	
										$num = ($coordinates[$i] / 1000) - $layer_width_real/2;
										printf WRITEOUTPUT "%.3f ", $num;
									}
									else
									{
										$num = ($coordinates[$i] / 1000);
										printf WRITEOUTPUT "%.3f ", $num;
									}
									$i++;
								}
							}
							$lasty = 2*$num_points - 1;
							$lastx = 2*($num_points-1);
							$next_lasty = $lasty - 2;
							$next_lastx = $lastx - 2;
							if ($coordinates[$lastx] == $coordinates[$next_lastx] && $coordinates[$lasty] < $coordinates[$next_lasty])	#path ends moving down
							{
								$i = 2*$num_points - 2;
								until ($i == 2*$num_points)
								{
									if ($i == $lasty)
									{	
										$num = ($coordinates[$i] / 1000) + $layer_width_real/2;
										printf WRITEOUTPUT "%.3f ", $num;
									}
									else
									{
										$num = ($coordinates[$i] / 1000);
										printf WRITEOUTPUT "%.3f ", $num;
									}
									$i++;
								}
							}
							elsif ($coordinates[$lastx] == $coordinates[$next_lastx] && $coordinates[$lasty] >= $coordinates[$next_lasty])	#path ends moving up
							{
								$i = 2*$num_points - 2;
								until ($i == 2*$num_points)
								{
									if ($i == $lasty)
									{	
										$num = ($coordinates[$i] / 1000) - $layer_width_real/2;
										printf WRITEOUTPUT "%.3f ", $num;
									}
									else
									{
										$num = ($coordinates[$i] / 1000);
										printf WRITEOUTPUT "%.3f ", $num;
									}
									$i++;
								}
							}
							elsif ($coordinates[$lasty] == $coordinates[$next_lasty] && $coordinates[$lastx] < $coordinates[$next_lastx])	#path ends moving to the left
							{
								$i = 2*$num_points - 2;
								until ($i == 2*$num_points)
								{
									if ($i == $lastx)
									{	
										$num = ($coordinates[$i] / 1000) + $layer_width_real/2;
										printf WRITEOUTPUT "%.3f ", $num;
									}
									else
									{
										$num = ($coordinates[$i] / 1000);
										printf WRITEOUTPUT "%.3f ", $num;
									}
									$i++;
								}
							}
							elsif ($coordinates[$lasty] == $coordinates[$next_lasty] && $coordinates[$lastx] >= $coordinates[$next_lastx])	#path ends moving to the right
							{
								$i = 2*$num_points - 2;
								until ($i == 2*$num_points)
								{
									if ($i == $lastx)
									{	
										$num = ($coordinates[$i] / 1000) - $layer_width_real/2;
										printf WRITEOUTPUT "%.3f ", $num;
									}
									else
									{
										$num = ($coordinates[$i] / 1000);
										printf WRITEOUTPUT "%.3f ", $num;
									}
									$i++;
								}
							}
						print WRITEOUTPUT ";\n";
					}
					else
					{
						$ascii = <ASCII>;
					}
				}


				##### MACRO:OBS:LAYER M2

				seek(ASCII, 0, 0);	# send filehandle to beginning of file
				$ascii = <ASCII>;
				until (($ascii =~ /cell name : $macroname/i)||($ascii =~ /end library/i))
				{
					$ascii = <ASCII>;
				}
				until (($ascii =~ /end cell definition/i)||($ascii =~ /end library/i))
				{
					if (($ascii =~ /rectangle/i)&&($ascii =~ /layer : 18/i))
					{
						if ($position == 0)
						{
							print WRITEOUTPUT "    OBS\n      LAYER M2 ;\n";
							print(" Writing obstruction data\n");
							$position = 1;
						}
						elsif ($position == 1)
						{
							print WRITEOUTPUT "      LAYER M2 ;\n";
							$position = 2;
						}
						$pos = index($ascii, "(");
						$ascii = substr($ascii, $pos);
						chomp ($ascii);						# remove \n
						$ascii =~ s/ //g;					# remove whitespace
						$ascii =~ s/\)\(/,/g;					# replace )( with ,
						$ascii =~ s/\(|\)//g;					# remove ( and )
						@coordinates = split (/,/, $ascii);
						print WRITEOUTPUT "\tRECT  ";
						foreach $num (@coordinates)
						{
							$num = $num / 1000;
							printf WRITEOUTPUT "%.3f ", $num;
						}
						print WRITEOUTPUT ";\n";
						$ascii = <ASCII>;
					}
					elsif (($ascii =~ /polygon/i)&&($ascii =~ /layer : 18/i))
					{
						if ($position == 0)
						{
							print WRITEOUTPUT "    OBS\n      LAYER M2 ;\n";
							print(" Writing obstruction data\n");
							$position = 1;
						}
						elsif ($position == 1)
						{
							print WRITEOUTPUT "      LAYER M2 ;\n";
							$position = 2;
						}
						print WRITEOUTPUT "\tPOLYGON  ";
						$ascii = <ASCII>;
						while ($ascii =~ /^ \(/i)
						{
							chomp ($ascii);					# remove \n
							$ascii =~ s/ //g;				# remove whitespace
							$ascii =~ s/\)\(/,/g;				# replace )( with ,
							$ascii =~ s/\(|\)//g;				# remove ( and )
							@coordinates = split (/,/, $ascii);
							foreach $num (@coordinates)
							{
								$num = $num / 1000;
								printf WRITEOUTPUT "%.3f ", $num;
							}
							$ascii = <ASCII>;
						}
						print WRITEOUTPUT ";\n";
					}
					elsif (($ascii =~ /path/i)&&($ascii =~ /layer : 18/i))
					{
						if ($position == 0)
						{
							print WRITEOUTPUT "    OBS\n      LAYER M2 ;\n";
							print(" Writing obstruction data\n");
							$position = 1;
						}
						elsif ($position == 1)
						{
							print WRITEOUTPUT "      LAYER M2 ;\n";
							$position = 2;
						}

						@ascii_peices = split (/ /, $ascii);
						$layer_width = $ascii_peices[16];
						$layer_width_real = $layer_width/1000;
						$num_points = $ascii_peices[13];
						print WRITEOUTPUT "\tWIDTH $layer_width_real ;\n";

						print WRITEOUTPUT "\tPATH  ";
						$ascii = <ASCII>;
						$pos = 0;
						while ($ascii =~ /^ \(/i)
						{
							chomp ($ascii);		# remove \n
							$ascii =~ s/ //g;	# remove whitespace
							$ascii =~ s/\)\(/,/g;	# replace )( with ,
							$ascii =~ s/\(|\)//g;	# remove ( and )
							if ($pos == 0)
							{
							    $path_points = $ascii;
							    $pos = 1;
							}
							else
							{
							    $path_points = $path_points . ",";
							    $path_points = $path_points . $ascii;
							}
							$ascii = <ASCII>;
						}
							@coordinates = split (/,/, $path_points);
							if ($coordinates[0] == $coordinates[2] && $coordinates[1] < $coordinates[3])	#path starts moving up
							{
								$i = 0;
								until ($i == 2*$num_points - 2)
								{
									if ($i == 1)
									{	
										$num = ($coordinates[$i] / 1000) + $layer_width_real/2;
										printf WRITEOUTPUT "%.3f ", $num;
									}
									else
									{
										$num = ($coordinates[$i] / 1000);
										printf WRITEOUTPUT "%.3f ", $num;
									}
									$i++;
								}
							}
							elsif ($coordinates[0] == $coordinates[2] && $coordinates[1] >= $coordinates[3])	#path starts moving down
							{
								$i = 0;
								until ($i == 2*$num_points - 2)
								{
									if ($i == 1)
									{	
										$num = ($coordinates[$i] / 1000) - $layer_width_real/2;
										printf WRITEOUTPUT "%.3f ", $num;
									}
									else
									{
										$num = ($coordinates[$i] / 1000);
										printf WRITEOUTPUT "%.3f ", $num;
									}
									$i++;
								}
							}
							elsif ($coordinates[1] == $coordinates[3] && $coordinates[0] < $coordinates[2])	#path starts moving to the right
							{
								$i = 0;
								until ($i == 2*$num_points - 2)
								{
									if ($i == 0)
									{	
										$num = ($coordinates[$i] / 1000) + $layer_width_real/2;
										printf WRITEOUTPUT "%.3f ", $num;
									}
									else
									{
										$num = ($coordinates[$i] / 1000);
										printf WRITEOUTPUT "%.3f ", $num;
									}
									$i++;
								}
							}
							elsif ($coordinates[1] == $coordinates[3] && $coordinates[0] >= $coordinates[2])	#path starts moving to the left
							{
								$i = 0;
								until ($i == 2*$num_points - 2)
								{
									if ($i == 0)
									{	
										$num = ($coordinates[$i] / 1000) - $layer_width_real/2;
										printf WRITEOUTPUT "%.3f ", $num;
									}
									else
									{
										$num = ($coordinates[$i] / 1000);
										printf WRITEOUTPUT "%.3f ", $num;
									}
									$i++;
								}
							}
							$lasty = 2*$num_points - 1;
							$lastx = 2*($num_points-1);
							$next_lasty = $lasty - 2;
							$next_lastx = $lastx - 2;
							if ($coordinates[$lastx] == $coordinates[$next_lastx] && $coordinates[$lasty] < $coordinates[$next_lasty])	#path ends moving down
							{
								$i = 2*$num_points - 2;
								until ($i == 2*$num_points)
								{
									if ($i == $lasty)
									{	
										$num = ($coordinates[$i] / 1000) + $layer_width_real/2;
										printf WRITEOUTPUT "%.3f ", $num;
									}
									else
									{
										$num = ($coordinates[$i] / 1000);
										printf WRITEOUTPUT "%.3f ", $num;
									}
									$i++;
								}
							}
							elsif ($coordinates[$lastx] == $coordinates[$next_lastx] && $coordinates[$lasty] >= $coordinates[$next_lasty])	#path ends moving up
							{
								$i = 2*$num_points - 2;
								until ($i == 2*$num_points)
								{
									if ($i == $lasty)
									{	
										$num = ($coordinates[$i] / 1000) - $layer_width_real/2;
										printf WRITEOUTPUT "%.3f ", $num;
									}
									else
									{
										$num = ($coordinates[$i] / 1000);
										printf WRITEOUTPUT "%.3f ", $num;
									}
									$i++;
								}
							}
							elsif ($coordinates[$lasty] == $coordinates[$next_lasty] && $coordinates[$lastx] < $coordinates[$next_lastx])	#path ends moving to the left
							{
								$i = 2*$num_points - 2;
								until ($i == 2*$num_points)
								{
									if ($i == $lastx)
									{	
										$num = ($coordinates[$i] / 1000) + $layer_width_real/2;
										printf WRITEOUTPUT "%.3f ", $num;
									}
									else
									{
										$num = ($coordinates[$i] / 1000);
										printf WRITEOUTPUT "%.3f ", $num;
									}
									$i++;
								}
							}
							elsif ($coordinates[$lasty] == $coordinates[$next_lasty] && $coordinates[$lastx] >= $coordinates[$next_lastx])	#path ends moving to the right
							{
								$i = 2*$num_points - 2;
								until ($i == 2*$num_points)
								{
									if ($i == $lastx)
									{	
										$num = ($coordinates[$i] / 1000) - $layer_width_real/2;
										printf WRITEOUTPUT "%.3f ", $num;
									}
									else
									{
										$num = ($coordinates[$i] / 1000);
										printf WRITEOUTPUT "%.3f ", $num;
									}
									$i++;
								}
							}
						print WRITEOUTPUT ";\n";
					}
					else
					{
						$ascii = <ASCII>;
					}
				}
				if ($position == 0)
				{
					print (" No obstruction information found\n");
				}
				else
				{
					print WRITEOUTPUT "    END\n"
				}
			}

			print WRITEOUTPUT "END $macroname\n\n";
		}
	}
	print WRITEOUTPUT "END LIBRARY\n";


}
close (HEADER);
close (ABGEN);
close (ASCII);
close (WRITEOUTPUT);
