#!/usr/bin/perl -w

# Author: Sebastien Torres 

# Wrapper to determine which driver to call according to which driver returns that a device is plugged in
# Should be called be either upstart or by udev

# Given arguments are either 'udev' or 'upstart'
$scriptRunBy = @ARGV;

$psGrep3dxsrv = `ps -ef | grep 3dxsrv | grep -v grep`;

if( checkDriverRunning($psGrep3dxsrv) == "YES" ) {

	killDriverProc(getDriverPID());
}

#checkDriverRunning($psCheck3dxsrv);

determineScriptRunBy();

$driverToUse = determineDriverToStart();

startDriverToUse($driverToUse);

exit 0;

########################
## End of what happens
########################


########################
## Defined sub routines
########################


sub checkDriverRunning($psGrep3dxsrv) {

	if ( $psGrep3dxsrv =~ /3dxsrv/ ) {
		$isDriverRunning = "YES";
	} else $isDriverRunning = "NO";
	
	return $isDriverRunning;
}

sub getDriverPID() {
	$PID3dxsrv[1] = $split(/ /, $psCheck3dxsrv);
	
	$PID3dxsrv = $PID3dxsrv[1];
	
	return $PID3dxsrv;
}

sub killDriverProc($PID3dxsrv) {
	kill 'KILL', $PID3dxsrv;
}

sub determineScriptRunBy($scriptRunBy) {
	
	if( $scriptRunBy =~ /udev/ ) {
		if ( checkRunlevel() !~ "5" ){
			print "Not in runlevel to start the 3dxsrv, exiting.\n";
			exit 1;
		}
	} 
	
#	$driverToUse = determineDriverToStart();
		
}

sub checkRunlevel() {
	$getRunlevel = `/sbin/runlevel`;
	
	$runLevel[2] = split(/ /, $getRunlevel);
	
	$runlevel = $runLevel[2];
	
	return $runLevel;
}

sub determineDriverToStart() {

	$driverPath1DOT7 = "/etc/3DxWare-1.7/daemon/3dxsrv";
	$driverPath1DOT4 = "/etc/3DxWare/daemon/3dxsrv";
	
	$driverDevOnPortArg = "-devOnPort usb";
	
	if( `$driverPath1DOT7." ".$driverDevOnPortArg` ~= /YES/ ) {

		$driverToUse = $driverPath1DOT7;
		break;

	} elsif ( `$driverPath1DOT4." ".$driverDevOnPortArg` ~= /YES/ ) {
		
		$driverToUse = $driverPath1DOT4;
		break;
	
	} else {
		
		print "No recognised device connected";
		exit 3;
	}
	
	return $driverToUse;
}

sub startDriver($driverToUse) {

	exec $driverToUse, "-d usb";
	exit 0;
}
