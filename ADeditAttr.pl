#!/usr/bin/perl -w

# requires the perl-LDAP.noarch package to be installed
use Net::LDAP;

# Start by getting the details we want by retreiving the results of specific dmidecode string keywords
# Clean up the string using chomp, we don't want any whitespace\newlines\carriage returns at the end of it - it will make things look messy at the end.

chomp($manufacturer = `/usr/sbin/dmidecode -s system-manufacturer`);

# find out the manufacturer of the machine
# If it's LENOVO, then set $model using two dmiedecode strings, otherwise, we're assuming it's HP kit
if ( $manufacturer =~ /LENOVO/m ) {
        chomp($sysver = `/usr/sbin/dmidecode -s system-version`);
        chomp($sysprodname = `/usr/sbin/dmidecode -s system-product-name`);
        $model = $sysver." (".$sysprodname.")";
}
else {
        chomp($model = `/usr/sbin/dmidecode -s system-product-name`);
}

chomp($serial = `/usr/sbin/dmidecode -s system-serial-number`);

# +---------------------------------------------------------------------+
# This can be improved in the event that BeyondTrust alter the output of 'domainjoin-cli query' to be something other than what 
# we're looking for here.
# Instead, loop through the contents of @computerobj, match on "Distinguised Name", then perform a split on the line.

# Some lines to get the DN (Active Directory speak for 'Distinguished Name'; all( I think) AD objects have one of these.
# @computerobj is an array as the results of 'domainjoin-cli query' is multi-lined.
@computerobj = `domainjoin-cli query`;

# Whilst @computerobj contains entries, then do a match on each line until you match CN at the beginning of that line
# this value is the Distinguished Name of the machine - much nicer and neater than before
while(<@computerobj>){
        if($_=~/^CN/m){
                chomp($dn=$_);
        }
}

# +---------------------------------------------------------------------+

# Find out who is logged in to the X session, display :0
chomp($login = `/usr/bin/who |/bin/grep ":0" | /usr/bin/awk '{print \$1}' | /usr/bin/uniq`);

# Query rpm to find out if PBIS or Likewise is installed
$lworpbis = `rpm -qa | egrep \"pbis|likewise\"`;

# Set paths and command according to what is installed
if($lworpbis=~/^pbis-enterprise\S+/m) {
        $userquery = "/opt/pbis/bin/find-user-by-name --level 2";
}
elsif($lworpbis=~/^likewise-base\S+/m) {
        $userquery = "/opt/likewise/bin/lw-find-user-by-name --level 2";
}

# Get the contents of the query
$lwquery = `$userquery $login`;

# Match on the line containting UPN at the beggning of the line (there is another line that is "Generated UPN") and do some whitespace stuff
# the value is the second entry on the line, chomp it
if($lwquery=~/^UPN:\s*(\S+)$/m){
        chomp($user = $1);
}

# Build the contents of the description in the rquired format
$description = "$user / $model / $serial";

# open connection to AD \ LDAP to the domain "onshore.pgs.com"
my $ldap = Net::LDAP->new("DOMAINGOESHERE") or die "error connecting to domain $@\n";

# login / bind using the service account
# +--------------------------------------+
# Find a way to make this secure 
# +--------------------------------------+
# We don't actually have to give the contents to the bind to $mesg as it's not being used anywhere.
# push the contents of $ldap into the bind() function, using the details listed.
$mesg = $ldap->bind( "USERNAME GOES HERE - in LDAP format, CN=xxx,OU=,xxxx,DC=xxxx",
			password => "password here",
			version => 3 );

# Push the contents of $ldap into modify() funtion, capture the results into $result
$result = $ldap->modify ( $dn,
	replace => { description => $description }
);

# If there is a warn \ error in $result, then print out
$result->code && warn "error: ", $result->error;

# logout  / unbind, again capture the results if you want them for later......
$mesg = $ldap->unbind;

# Finished
exit 0;
