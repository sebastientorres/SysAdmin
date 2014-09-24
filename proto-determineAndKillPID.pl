#!/usr/bin/perl -w

my @ps3dxsrv = `ps -C cfexecd`;

my $isDriverRunning = checkDriverRunning($ps3dxsrv);

if( $isDriverRunning eq "YES" ) {

	print "$isDriverRunning command running\n";
	
	my $pidToKill =  getDriverPID($ps3dxsrv);

	print $pidToKill;

	#kill 'KILL', $pidToKill;
	
} else {
	print "$isDriverRunning command running\n";
}

exit 0;

sub checkDriverRunning {

	while(<@ps3dxsrv>) {
		if ($_ =~ /cfexecd/) {
			$isDriverRunning = "YES";
		} else {
			$isDriverRunning = "NO";
		}
	}
	
	return $isDriverRunning;
}

sub getDriverPID {


	$PID3dxsrv = $ps3dxsrv[1];
    $PID3dxsrv =~ s/^\s+//;
    ($ps_pid, $ps_terminal, $ps_time, $ps_command) =  split(/ /, $PID3dxsrv);

	return $ps_pid;
}
