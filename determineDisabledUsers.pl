#!/usr/bin/perl -w 

# Perform a listing on given filesystem and report on the disabled users.
# A user is determined to be disabled if the account has 'Disabled' in the DN.

# Implement:
# - Move \ delete \ archive actions?
# - Total disk space used? - DONE
# - If it's a numeric ID, check against list of oper accounts?
# - Current working directory check...


my %userslisting;
open (LSUSERS,"-|","ls -l <filesystemmountpoint>");

while (<LSUSERS>) {
	chomp;
	my @fields = split /\s+/;
	next if ($_ =~ /total/);
	my($user, $dir) = ($fields[2], $fields[8]);
	#$dir = "/filesystemmountpoint/".$dir;
	# Skip adding the user if the user column is numeric OR contains certain strings
	next if ($user =~ /(accounts|to|ignore)/ || $user =~ /\d+/);
	# For the instances where 'DOMAIN\' is part of the username, give the username to pbis in double quotes
	# unknown user other wise
	if ($user =~ /DOMAIN/) {
		$user = "\"$user\"";
	}
	$userslisting{$user} = "/filesystemmountpoint".$dir;
}

my %disabledUsers;

while (($user, $dir) = each %userslisting) {
	#print "$user\n";
	checkDisabled($user);
}

my $du;
while (($user, $dir) = each %disabledUsers) {
	my @duRaw = split(/\s+/, `du -s $dir`);
	$du+=$duRaw[0];
}
$du = sprintf("%.2f", $du /1024 /1204);
print "Space consumed: ".$du."Gb\n";

exit 0;

sub checkDisabled {
	
	$userdetails = `/opt/pbis/bin/find-user-by-name --level 2 $user`;
	if($userdetails =~ /Disabled/){
		print "Matched:$user\t$dir\n";
		$disabledUsers{$user} = $dir;
	}
}
