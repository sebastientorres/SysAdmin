#!/usr/bin/perl -w

use IO::Uncompress::Gunzip qw(gunzip $GunzipError) ;
use File::Copy;
use File::Path;

# Process 'pacct-*' files to search for the string "delivery" to total the cpu time spent on delivery processes.
# Run this in the directory where the hostname directories are located.
# RUN ON THE HOST THAT GENERATED THE FILE...

# Take the hostname as an argument, there should be a directory for the specicied host.
# IDEA: run in the dir where host dirs are, list the dirs there and ask which host to run against??

# Process each file into one big array for the month

# TODO list:
# - Argument validation
# -- If they are empty, print a usage type message
# -- monthToProcess should be digits only

 ($host, $monthToProcess, $processToMonitor) = @ARGV;
 $processToMonitor = lc($processToMonitor);
 opendir(my $dirHandle, $host);
 @hostDirList = readdir($dirHandle);
 
 # WARNING: MAGIC NUMBER ALERT!!! Skipping through the array to get a file and not a directory or a '.' or '..'....
 $monthDir = $monthToProcess;
 
 #$monthDir = getMonth($hostDirList[4]);
 
 chdir($dirHandle);
 
 $runArchiveDir = "$monthDir/archives";
 mkpath($runArchiveDir);
 mkpath('reports');

# Set up some global vars - even though I think that it's possible that subroutines are able to return variables 
 my @mergedAcctInfo;
 my $totalSystemTime = 0;
 my $totalUserTime = 0;
 my $totalElapsedTime = 0;
 while(<@hostDirList>) {
 	
 	next if($_ eq "." || $_ eq ".." || $_ eq ".archive" || $_ eq "reports" );
 	processArchiveFile();
 	processAcctFile();
 	extractCpuAcctInfo();
 	tidyUp();
 }
 my @outputData;
 writeReportFile();
 
 exit 0;
 ##### END OF SCRIPT #####
 
 ##### SUB DECLARATIONS ##### 
 
 sub getMonth{
 	# So this can be used in more than one place, allow it to be passed an argument
 	# Get the month we're processing for from the filename, the format should be YYYYMM
 	local $month;
 	(local $filename) = (@_);
 	if ($filename =~ /gz/){
 		$month = substr($filename,6, -5);
 	}else {
 		$month = substr($filename,6, -2);	
 	}
 	
 	return $month;
 }
 
 sub processArchiveFile {
 	
 	$gzSaFile = $_;
 	$saExtractedFile = substr($gzSaFile, 0, -3);
 	next if (getMonth($gzSaFile) ne $monthToProcess); 
 	gunzip($_, $saExtractedFile);
 }
 
 sub processAcctFile {
 	my @tempProcessAcctFile = `/usr/sbin/dump-acct $saExtractedFile`;
 	$monthOfFile = checkMonthOfFile($saExtractedFile);
 	next if ($monthToProcess ne $monthOfFile);
 	for($counter=0; $counter < $#tempProcessAcctFile;$counter++ ){
 		push(@mergedAcctInfo, $tempProcessAcctFile[$counter]);
 	}

 }
 
 sub tidyUp {
 	# Tidy up files
 	move($gzSaFile, "$runArchiveDir/$gzSaFile");
 	unlink $saExtractedFile;
 }
 
 sub extractCpuAcctInfo {
 	
	for ($counter = 0; $counter < $#mergedAcctInfo; $counter++){

		$mergedAcctInfo[$counter] = lc($mergedAcctInfo[$counter]);
		
		if($mergedAcctInfo[$counter] =~ m/$processToMonitor/){

			@tmpArr = $mergedAcctInfo[$counter];
			$tmpLine = @tmpArr[0];
			chomp $tmpLine;
			($command, $userTime, $systemTime, $elapsedTime, $uid, $gid, $mem, $io, $submittedTime) = split(/\|/, $tmpLine);
			# Get rid of the whitespace at the beggining of $elapsedTime			
			$elapsedTime =~ s/^\s+//;
			$systemTime =~ s/^\s+//;
			$userTime =~ s/^\s+//;
			# Get rid of trailing whitespace at the end of $command
			$command =~ s/(\s+)$//;
			# $io appears to be pid and ppid with white space in between, split on whitespce...
			$io =~ s/^\s*//;
			($pid, $ppid) = split(/\s+/, $io);
			push(@outputData, "$submittedTime,$command,$elapsedTime,$userTime,$pid,$ppid");
		}
		
		$totalElapsedTime += $elapsedTime;
		$totalUserTime += $userTime;
	}
 } 
 
 sub writeReportFile{
 	$outputFileName = "reports/report-$monthToProcess.csv";
 	system('/bin/touch', $outputFileName);
 	$outputFile = "$outputFileName";
 	open(FILEHANDLE, ">>$outputFile");
 	print FILEHANDLE "Submitted Time,Command Run,Elapsed CPU time,User CPU Time,ProcessID,Parent ProcessID\n";
 	
	for($counter = 0; $counter < $#outputData; $counter++){
		print FILEHANDLE "$outputData[$counter]\n";
	}
 	
 	close FILEHANDLE;
 }
 
 sub checkMonthOfFile{
 	(local $filename) = (@_);
 	local $monthOfFile = getMonth($filename);
 	return $monthOfFile;
 }
 
 ##### END OF SUB DECLARATIONS #####
