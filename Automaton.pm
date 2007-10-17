package Net::UKDomain::Nominet::Automaton;

use 5.006;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our $errstr;	# Global error string for returning error condition details

## BEGIN variables ##

# Email Match
our $email_match='(([A-Za-z0-9]+_+)|([A-Za-z0-9]+\-+)|([A-Za-z0-9]+\.+)|([A-Za-z0-9]+\++))*[A-Za-z0-9]+@((\w+\-+)|(\w+\.))*\w{1,63}\.[a-zA-Z]{2,6}';

# List of emails used for certain operations
our %emails = (
	'REQUEST' => 'applications@nic.uk',
	'RECEIVE' => 'applications@nic.uk',
	'account MODIFY' => 'applications@nic.uk',
	'contact MODIFY' => 'applications@nic.uk',
	'nameserver MODIFY' => 'applications@nic.uk',
	'LIST' => 'auto-list@nic.uk',
	'BULK' => 'auto-bulk@nic.uk',
	'MODIFY' => undef,
	'DELETE' => undef,
	'QUERY' => undef,
	'RELEASE' => undef,
	'RENEW' => undef
);

# List of emails based on SLD, for other operations
our %emails_sld = (
	'co.uk' => 'auto-co@nic.uk',
	'me.uk' => 'auto-me@nic.uk',
	'org.uk' => 'auto-org@nic.uk',
	'net.uk' => 'auto-net@nic.uk',
	'ltd.uk' => 'auto-ltd@nic.uk',
	'plc.uk' => 'auto-plc@nic.uk',
	'sch.uk' => 'auto-sch@nic.uk'
);

our @slds = keys %emails_sld; # Gets a list of SLDS
our $sldsi = join('|',@slds); # Join list for regex use

our @operations = keys %emails; # Gets a list of operations
our $operationsi = join('|',@operations); # Join list for regex use

# List of regex rules for fields
our %rules = (
		'operation' => "($operationsi)",
		'key'		=> '([A-Za-z0-9\-]\.('.$sldsi.')){1,63}$',
		'account-name'	=> '[[:print:]]{1,80}',
		'account-id'	=> '[[:print:]]{1,80}',
		'contact-id'	=> '[[:print:]]{1,80}',
		'name'		=> '[[:print:]]{1,80}',
		'trad-name'	=> '[[:print:]]{1,80}',
		'type'		=> '(LTD|PLC|PTNR|LLP|STRA|IND|IP|SCH|RCHAR|GOV|CRC|STAT|OTHER|FIND|FCORP|FOTHER)',
		'opt-out'	=> '(y|Y|n|N)',
		'co-no'		=> '[0-9]{1,10}',
		'addr'		=> '[[:print:]]{1,256}',
		'city'		=> '[[:print:]]{1,80}',
		'locality'	=> '[[:print:]]{1,80}',
		'county'	=> '[[:print:]]{1,80}',
		'postcode'	=> '[A-Z0-9 ]{1,10}',
		'country'	=> '[A-Z]{2}', # See: http://www.iso.org/iso/iso3166_en_code_lists.txt
		'email'		=> 	$email_match,
		'phone'		=> '[\+0-9][0-9\.\-]{1,20}',
		'fax'		=> '[\+0-9][0-9\.\-]{1,20}',
		'dns'		=> '([a-z0-9][a-z0-9\-\.\, ]+)',
		'dns-id'	=> '([a-z0-9][a-z0-9\-\.\, ]+)',
		'dns0'		=> '([a-z0-9][a-z0-9\-\.\, ]+)',
		'dns0-id'	=> '([a-z0-9][a-z0-9\-\.\, ]+)',
		'dns1'		=> '([a-z0-9][a-z0-9\-\.\, ]+)',
		'dns1-id'	=> '([a-z0-9][a-z0-9\-\.\, ]+)',
		'dns2'		=> '([a-z0-9][a-z0-9\-\.\, ]+)',
		'dns2-id'	=> '([a-z0-9][a-z0-9\-\.\, ]+)',
		'dns3'		=> '([a-z0-9][a-z0-9\-\.\, ]+)',
		'dns3-id'	=> '([a-z0-9][a-z0-9\-\.\, ]+)',
		'dns4'		=> '([a-z0-9][a-z0-9\-\.\, ]+)',
		'dns4-id'	=> '([a-z0-9][a-z0-9\-\.\, ]+)',
		'dns5'		=> '([a-z0-9][a-z0-9\-\.\, ]+)',
		'dns5-id'	=> '([a-z0-9][a-z0-9\-\.\, ]+)',
		'dns6'		=> '([a-z0-9][a-z0-9\-\.\, ]+)',
		'dns6-id'	=> '([a-z0-9][a-z0-9\-\.\, ]+)',
		'dns7'		=> '([a-z0-9][a-z0-9\-\.\, ]+)',
		'dns7-id'	=> '([a-z0-9][a-z0-9\-\.\, ]+)',
		'dns8'		=> '([a-z0-9][a-z0-9\-\.\, ]+)',
		'dns8-id'	=> '([a-z0-9][a-z0-9\-\.\, ]+)',
		'dns9'		=> '([a-z0-9][a-z0-9\-\.\, ]+)',
		'dns9-id'	=> '([a-z0-9][a-z0-9\-\.\, ]+)',
		'a1-name'	=> '([a-z0-9][a-z0-9\-\.\, ]+)',
		'a1-email'	=> $email_match,
		'a1-phone'	=> '[\+0-9][0-9\.\-]{1,20}',
		'a1-fax'	=> '[\+0-9][0-9\.\-]{1,20}',
		'a1-mobile'	=> '[\+0-9][0-9\.\-]{1,20}',
		'a2-name'	=> '([a-z0-9][a-z0-9\-\.\, ]+)',
		'a2-email'	=> $email_match,
		'a2-phone'	=> '[\+0-9][0-9\.\-]{1,20}',
		'a2-fax'	=> '[\+0-9][0-9\.\-]{1,20}',
		'a2-mobile'	=> '[\+0-9][0-9\.\-]{1,20}',
		'a3-name'	=> '([a-z0-9][a-z0-9\-\.\, ]+)',
		'a3-email'	=> $email_match,
		'a3-phone'	=> '[\+0-9][0-9\.\-]{1,20}',
		'a3-fax'	=> '[\+0-9][0-9\.\-]{1,20}',
		'a3-mobile'	=> '[\+0-9][0-9\.\-]{1,20}',
		'b-addr'	=> '[[:print:]]{1,256}',	
		'b-locality'	=> '[[:print:]]{1,80}',		
		'b-city'	=> '[[:print:]]{1,80}',
		'b-county'	=> '[[:print:]]{1,80}',
		'b-postcode'	=> '[A-Z0-9 ]{1,10}',
		'b-country'	=> '[A-Z]{2}', # See: http://www.iso.org/iso/iso3166_en_code_lists.txt
		'b1-name'	=> '([a-z0-9][a-z0-9\-\.\, ]+)',
		'b1-email'	=> $email_match,
		'b1-phone'	=> '[\+0-9][0-9\.\-]{1,20}',
		'b1-fax'	=> '[\+0-9][0-9\.\-]{1,20}',
		'b1-mobile'	=> '[\+0-9][0-9\.\-]{1,20}',
		'b2-name'	=> '([a-z0-9][a-z0-9\-\.\, ]+)',
		'b2-email'	=> $email_match,
		'b2-phone'	=> '[\+0-9][0-9\.\-]{1,20}',
		'b2-fax'	=> '[\+0-9][0-9\.\-]{1,20}',
		'b2-mobile'	=> '[\+0-9][0-9\.\-]{1,20}',
		'b3-name'	=> '([a-z0-9][a-z0-9\-\.\, ]+)',
		'b3-email'	=> $email_match,
		'b3-phone'	=> '[\+0-9][0-9\.\-]{1,20}',
		'b3-fax'	=> '[\+0-9][0-9\.\-]{1,20}',
		'b3-mobile'	=> '[\+0-9][0-9\.\-]{1,20}',
		'registrar-tag'	=> '[A-Z0-9\-]+',
		'first-bill'	=> '(th|bc)',
		'recur-bill'	=> '(th|bc)',
		'auto-bill'	=> '[0-9]{0,3}',
		'next-bill'	=> '[0-9]{0,3}',
		'notes'		=> '[[:print:]]*',
		'month'		=>	'[0-9]{4}-[0-9]{2}|all',
		'expiry'		=>	'[0-9]{4}-[0-9]{2}',
);
		
our @fields = keys %rules; # Gets a list of fields

# We need to map the old depreciated fields onto the new ones...
our %depreciated = (
	'domain' => 'key',
	'for' => 'account-name',
	'reg-trad-name' => 'trad-name',
	'reg-type' => 'type',
	'reg-opt-out' => 'opt-out',
	'reg-co-no' => 'co-no',
	'reg-addr' => 'addr',
	'reg-city' => 'city',
	'reg-locality' => 'locality',
	'reg-county' => 'county',
	'reg-postcode' => 'postcode',
	'reg-country' => 'country',
	'reg-ref' => undef,
	'reg-contact' => 'a1-name',
	'reg-email' => 'a1-email',
	'reg-phone' => 'a1-phone',
	'reg-fax' => 'a1-fax',
	'reg-mobile' => 'a1-mobile',
	'admin-c' => undef,
	'a-addr' => undef,
	'a-phone' => undef,
	'a-fax' => undef,
	'a-email' => undef,
	'billing-c' => undef,
	'b-email' => 'b1-email',
	'b-phone' => 'b1-phone',
	'b-fax' => 'b1-fax',
	'b-mobile' => 'b1-mobile',
	'ips-key' => 'registrar-tag'
);

## END variables ##

our @ISA = qw(Exporter);
our @EXPORT = qw();
our $VERSION = '1.07';

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Net::UKDomain::Nominet::Automaton - Module to handle the Nominet Automaton for domain registration and modification.

=head1 SYNOPSIS

	use Net::UKDomain::Nominet::Automaton;
	my $d = Net::UKDomain::Nominet::Automaton->new( keyid 	=> 'MYKEYID',
						passphrase 	=> 'HARDTOREMEMBER',
						tag 				=> 'ISPTAG',
						smtpserver	=> 'smtp.my.net',
						emailfrom		=> 'MyISP <domains@my.isp>',
						secring			=> '/path/to/secret/keyring',
						pubring			=> '/path/to/public/keyring',
						compat			=> 'PGP2',
						testemail		=> 'myown@email.here',
						);

	my $domain = 'domain.sld.uk';

	if ( ! $d->valid_domain($domain) ) {
		print "Invalid domain - " . $d->errstr;
		}

	if ( ! $d->domain_available($domain) ) {
		print "Domain not available.";
		}

	if ( ! $d->register($domain, $details) ) {
		print "Unable to issue register domain operation - ". $d->errstr;
		}

	if ( ! $d->modify($domain, $details) ) {
		print "Unable to issue modify '$domain' operation - " . $d->errstr;
		}

	if ( ! $d->query($domain) ) {
		print "Unable to issue query '$domain' operation - " . $d->errstr;
		}

	if ( ! $d->renew($domain) ) {
		print "Unable to issue renew '$domain' operation - " . $d->errstr;
		}

	if ( ! $d->release($domain, $othertag) ) {
		print "Unable to issue release '$domain' operation to '$othertag' - " . $d->errstr;
		}

	if ( ! $d->delete($domain) ) {
		print "Unable to issue delete '$domain' operation - " . $d->errstr;
		}

=head1 DESCRIPTION

A simple module for the Nominet .UK email based automaton.

This is designed to allow you to handle all of the actions normally associated with registering and managing a .UK domain - ie checking that the proposed name is valid and available, registering it or modifying it.

Note that Nominet's Automaton is an asyncronous process. Requests are sent to it via email (using Net::SMTP) and it replies by email to the nofification email address Nominet hold on record for the tag holder.

Be warned that the error strings returned by the module are not intended to be returned directly to users of your script.

Note: It is recommended you have 'Automaton field options' set to 'Use new field set' via https://secure.nominet.org.uk/tags/manage-options.html

=head1 USAGE

I<Net::UKDomain::Nominet::Automaton> has the following object based interface. On failure, all methods will return undef and set the errstr object with a suitable message.

=head2 Net::UKDomain::Nominet::Automaton->new( %args )

Constructs a new I<Net::UKDomain::Nominet::Automaton> instance and returns that object. 
Returns C<undef> on failure.

I<%args> can include:

=over 4

=item KEYID

The PGP or GPG key ID used to sign messages to the Nominet automaton.

=item PASSPHRASE

Your PGP passphrase

=item TAG

Your Nominet IPS TAG

=item SMTPSERVER

The smtp server through which messages to Nominet's automaton will be sent

=item EMAILFROM

The Email address from which messages to Nominet's automaton should be sent.

=item SECRING

The location of the secret keyring. This should be the absolute path to the file.

=item PUBRING

The location of the public keyring. This should be the absolute path to the file.

=item COMPAT

The compatibility mode for Crypt::OpenPGP.

=item TESTEMAIL

If you provide an email address here the PGP signed emails created
will be sent to you and B<not> to Nominet. Use this for debuging
purposes but make sure you remember to remove it on live systems.

=back

All arguements are required except I<COMPAT> and I<TESTEMAIL>. 
If I<COMPAT> is not provided it will default to PGP2.

=head1 Net::UKDomain::Nominet::Automaton->valid_domain($domain);

Validates the domain for the .UK name space. 

=head1 Net::UKDomain::Nominet::Automaton->domain_available($domain);

Checks whether the domain is available. Returns true if it is.

=head1 Net::UKDomain::Nominet::Automaton->register($domain, $details);

Sends a message to the Nominet Automaton to register the domain.

The %details hash should contact all the registrant and other
details for the registration using the standard Nominet Automaton
field names.

The data will be verified for validity.

If the message is sent successfully returns true. Note that this 
does not confirm that the domain is actually registered. Nominet
is an asynchronous registry so you need to check your email to
confirm that the domain is registered. Your system should include
a means of doing that and holding all the necessary details in 
some database. 

=head1 Net::UKDomain::Nominet::Automaton->modify($domain, $details);

Sends a message to the Automaton to modify the domain.

The %details hash should include only the fields you want to 
update. The fields need to be as per the Nominet Automaton 
standard fields.

=head1 Net::UKDomain::Nominet::Automaton->release($domain, $ipstag);

Releases the domain to the given IPS TAG. 

This is the means Nominet use to transfer the management of a 
doamin from one TAG holder to another.

=head1 Net::UKDomain::Nominet::Automaton->renew($domain);

Renews the domain for the standard 2 year period. 

=head1 Net::UKDomain::Nominet::Automaton->delete($domain);

Deletes the domain. There are limits on the use of this facility.
See the Nominet website for more details.

=head1 Net::UKDomain::Nominet::Automaton->query($domain);

Sends a message to the Automaton requesting a listing of all of the
details associated with the domain registration. 

The data will be returned by email - it's an asyncronous registry.

=head2 EXPORT

None - use the object interface as set out above.

=head1 AUTHOR

Jason Clifford, E<lt>jason@ukpost.comE<gt>
James Wade, E<lt>perl@jameswade.netE<gt>

=head1 SEE ALSO

http://www.jasonclifford.com/
http://www.jameswade.net/
http://www.nominet.org.uk/

L<perl>.

=cut


sub new {
	my $class = shift;
	my $self = bless { }, $class;
	return $self->init(@_);
}

sub init {
	my $self = shift;
	my %param = (@_);
	
	foreach (keys %param) {
		$self{$_} = $param{$_};
	}
	
	@params=('keyid','passphrase','tag','smtpserver','emailfrom','secring','pubring');
	foreach my $parami (@params) {
		if (!defined $self{$parami}) {
			$errstr = "parameter '$parami' is required";
			return;
		}	
	}
	if (!defined $self{'compat'}) { $self{'compat'} = 'PGP2'; }

	return $self;
}

sub operation {
	# http://www.nominet.org.uk/registrars/systems/auto/operations/
	my $idetails = shift;
	#use Data::Dumper; print Dumper(\$idetails);
	
	if (!$idetails) {
		$errstr = "details are required";
		return;
	}
	
	my $operation = uc($idetails->{'operation'});
	
	if ($operation && $operation !~ m/^$operationsi$/i) {
		$errstr = "unrecognised operation";
		return;
	}
	
	# We need to map the depreciated fields onto the synonym or drop them
	my @depreciated_fields = keys %depreciated;
	foreach my $field (@depreciated_fields) {
		if ($idetails->{$field}) { 
			$idetails->{$depreciated{$field}} = $idetails->{$field};
			delete $idetails->{$field};
		}
	}

	# Denied fields
	if ($operation ne 'REQUEST' && $idetails->{'account-name'}) {
		$errstr = "The account name cannot be modified";
		return;
	}
	if ($operation eq 'MODIFY' && $idetails->{'co-no'} && $idetails->{'key'} =~ m/\.sch\.uk$/i) {
		$errstr = "The 'co-no' field cannot be modified for an sch.uk domain name";
		return;
	}
	
	if ($operation =~ /QUERY|MODIFY/) {
		if (!($idetails->{'key'} || $idetails->{'dns-id'} || $idetails->{'account-id'} || $idetails->{'contact-id'})) {
			$errstr = "missing field 'key' or 'dns-id' or 'account-id' or 'contact-id' for operation";
			return;
		}
	}

	if ($idetails->{'type'} && $idetails->{'country'} && $idetails->{'country'} !~ /GB/i) {
		if ($idetails{'type'} eq 'IND') { $idetails->{'type'}='FIND'; }
		if ($idetails{'type'} eq 'OTHER') { $idetails->{'type'}='FOTHER'; }
	}
	
	# IND and FIND are special
	if ($idetails->{'type'} && $idetails->{'type'} !~ /IND|FIND/i) {
		if ($idetails->{'opt-out'}) { $idetails->{'opt-out'} = 'n'; }
	}
	if ($idetails->{'type'} && $idetails->{'type'} =~ /IND|FIND/i) {
		if ($idetails->{'co-no'}) { $idetails->{'co-no'} = undef; }
	}

	# Check mandatory fields
	if (!&is_mandatory($idetails)) { return; } # $errstr is set in the subroutine

	# Let's check the tag exists if we specify one
	if ($idetails->{'registrar-tag'} && !&tag_exists($idetails->{'registrar-tag'})) {
		# $errstr will be set in the subroutine
		return;
	}

	# We won't validate the domain, we expect you to do that before it enters the hash

	my $msg = &build_msg($idetails);
	if (!$msg) { return; } # $errstr is set in the subroutine

	my $sign = &sign($msg);
	if (!$sign) { return; } # $errstr is set in the subroutine
	
	my $to = &send_to($idetails);
	
	# This corrects the subject (must appear after $sign is set)
	if ($operation eq 'QUERY' || $operation eq 'MODIFY') {
		if ($idetails->{'contact-id'}) { $operation = 'contact '.$operation; }
		elsif ($idetails->{'dns-id'}) { $operation = 'nameserver '.$operation; }
		elsif ($idetails->{'account-id'}) { $operation = 'account '.$operation; }
	}

	my $subject = $self{tag}." ".$operation;
	
	if (!&send_mail($to, $subject, $sign)) {
		if (!$errstr) { $errstr = "Unable to send email request"; }
		return;
	}
	return 1;
}

sub is_mandatory {
	# http://www.nominet.org.uk/registrars/systems/data/fields/
	
	my $idetails = shift;
	my $operation = uc($idetails->{'operation'});
	my @mandatory;

	# Operation is always mandatory
	push(@mandatory,'operation');

	my $key_operations = 'REQUEST|DELETE|RENEW|MODIFY';
	# Domain (key) is always mandatory for the above operations
	if (($operation =~ m/^$key_operations$/i)) {
			push(@mandatory,'key');
	}

	if ($operation eq 'REQUEST') {
		# If account-id is not supplied, the below fields are also mandatory
		if (!defined($idetails->{'account-id'})) {
			push(@mandatory,('account-name','addr','country','a1-name','a1-email'));
		}
		# If opt-out is supplied, type is also mandatory
		if (defined($idetails->{'opt-out'})) { push(@mandatory,'type'); }
	}
	
	# registrar-tag is mandatory for release requests only
	if ($operation eq 'RELEASE') { push(@mandatory,'registrar-tag'); }
	
	# case-id is mandatory for the handshake
	if ($operation eq 'RECEIVE') { push(@mandatory,'case-id'); }

	# If a2-name is supplied, a2-email is also mandatory
	if (defined($idetails->{'a2-name'})) { push(@mandatory,'a2-email'); }

	# If a3-name is supplied, a3-email is also mandatory
	if (defined($idetails->{'a3-name'})) { push(@mandatory,'a3-email'); }

	# If b1-name is supplied, b1-email is also mandatory
	if (defined($idetails->{'b1-name'})) { push(@mandatory,'b1-email'); }

	# If b2-name is supplied, b2-email is also mandatory
	if (defined($idetails->{'b2-name'})) { push(@mandatory,'b2-email'); }
	
	# If b3-name is supplied, b3-email is also mandatory
	if (defined($idetails->{'b3-name'})) { push(@mandatory,'b3-email'); }
	
	my $need_postcode = "(GB|JE|GG|IM)"; # See: http://www.iso.org/iso/iso3166_en_code_lists.txt
	# If country code is in the list, postcode is also mandatory
	if ($idetails->{'country'} =~ /^$need_postcode$/) { push(@mandatory,'postcode'); }

	# If billing country code is in the list, postcode is also mandatory
	if ($idetails->{'b-country'} =~ /^$need_postcode$/) { push(@mandatory,'b-postcode'); }

	my $need_co_no = 'LTD|PLC|LLP|IP';
	# If domain is a company sld, company number (co-no) is also mandatory
	if (($idetails->{'type'} =~ /$need_co_no/i)) { push(@mandatory,'co-no'); }

	#my %mandatory_hash = ();
	#for (@mandatory) { $mandatory_hash{$_} = 1; }

	foreach $field (@mandatory) {
		if (!defined $idetails->{$field}) {
			$errstr = "mandatory field '$field' is missing";
			return;
		}
		if (!$idetails->{$field}) {
			$errstr = "mandatory field '$field' is empty";
			return;
		}
	}
	return 1;
}

sub build_msg {
	# Body text

	my $idetails = shift;

	# Build the message
	my $eol = "\n";
	my $msg = undef;
	my $flag = undef;

	foreach my $field (@fields) {
		if ($idetails->{$field}) {
			if ($idetails->{$field} =~ m/$rules{$field}/i ) {
				$msg .= "$field: ".$idetails->{$field}.$eol;
			}
			else {
				$errstr = "data in field '$field' is invalid, should match ".$rules{$field};
				return;
			}
		}
	}
	return $msg;
}

sub sign {
	# http://www.nominet.org.uk/registrars/systems/auto/pgp/
	
	my $data = shift;
	
	use Crypt::OpenPGP;
	
	my $pgp = undef;
	$pgp = Crypt::OpenPGP->new( SecRing => $self{secring},
	                            PubRing => $self{pubring},
	                            Compat  => $self{compat}
	);
	my $sign = undef;
	$sign = $pgp->sign(
	                           Data	 	=> $data,
	                           KeyID 	=> $self{keyid},
	                           Passphrase	=> $self{passphrase},
	                           Armour	=> 1,
	                           Clearsign	=> 1,
	);

	if (!$sign ) {
		$errstr = "Unable to sign message for '".$self{keyid}."' - ".$pgp->errstr;
		return;
	}

	return $sign;
}

sub send_to {
	# http://www.nominet.org.uk/registrars/systems/auto/queues/
	my $idetails = shift;
	if ( defined $self{'testemail'} ) {
		return $self{'testemail'};
		}
	my $operation = uc($idetails->{'operation'});
	my $to;
	
	if ($idetails->{'key'} =~ m/([^.]+\.uk)$/i) { my $sld=lc($1); } # Get the SLD
	if ($emails{$operation}) { $to = $emails{$operation}; }
	elsif ($emails_sld{$sld}) { $to = $emails_sld{$sld}; }
	if (!$to) { $to = 'applications@nic.uk'; }
	
	return $to;
}

sub tag_exists {
	my $taglist_url='http://www.nominet.org.uk/registrars/becomeregistrar/taglist/';
	
	my $tag = shift;
	
	# Check that the TAG exists
	use LWP::UserAgent;
	my $ua = LWP::UserAgent->new(timeout => 30);
	my $response = $ua->get($taglist_url);
	if (!$response->is_success) {
		$errstr = "Unable to lookup tag: ".$response->status_line;
		return;
	}
	if (!$response->content =~ /$tag/im) {
		$errstr = "The tag '$tag' is unrecognised";
		return;
	}
	return $tag;
}

sub register {
	# http://www.nominet.org.uk/registrars/systems/auto/request/
	my $operation = 'request';

	my $self = shift;
	my $domain = shift;
	my $idetails = shift;
	
	if (!$domain) {
		$errstr = "domain is required";
		return;
	}
	
	if (!$idetails) {
		$errstr = "details are required";
		return;
	}

	$idetails->{'operation'} = $operation;
	$idetails->{'key'}=$domain;

	if (!&operation($idetails)) {
		# $errstr will be set in the subroutine
		return;
	}

	return 1;
}

sub modify {
	# http://www.nominet.org.uk/registrars/systems/auto/modify/
	my $operation = 'modify';
	my $self = shift;
	my $domain;
	if (@_[1]) { $domain = shift; }
	my $idetails = shift;
	if ($domain) { $idetails->{'key'} = $domain; }
    
	if (!$idetails) {
		$errstr = "details are required";
		return;
	}
	
	$idetails->{'operation'} = $operation;

	if (!&operation($idetails)) {
		# $errstr will be set in the subroutine
		return;
	}

	return 1;
}

sub query {
	# http://www.nominet.org.uk/registrars/systems/auto/query/
	my $operation = 'query';
	
	my $self = shift;
	if (@_[1]) { $domain = shift; }
	my $idetails = shift;
	if ($domain) { $idetails->{'key'} = $domain; }
	
	if (!$idetails) {
		$errstr = "details are required";
		return;
	}
	
	$idetails->{'operation'} = $operation;

	if (!&operation($idetails)) {
		# $errstr will be set in the subroutine
		return;
	}
	return 1;
}

sub release {
	# http://www.nominet.org.uk/registrars/systems/auto/release/
	my $operation = 'release';
	
	my $self = shift;
	my $domain = shift;
	my $tag = shift;
	my $idetails;

	if (!$domain) {
		$errstr = "domain is required";
		return;
	}
	
	if (!$tag) {
		$errstr = "registrar-tag is required";
		return;
	}

	$idetails->{'operation'} = $operation;
	$idetails->{'key'}=$domain;
	$idetails->{'registrar-tag'}=$tag;

	if (!&operation($idetails)) {
		# $errstr will be set in the subroutine
		return;
	}

	return 1;
}


sub renew {
	# http://www.nominet.org.uk/registrars/systems/auto/renew/
	my $operation = 'renew';

	my $self = shift;
	my $domain = shift;

	if (!$domain) {
		$errstr = "domain is required";
		return;
	}

	$idetails->{'operation'} = $operation;
	$idetails->{'key'}=$domain;

	if (!&operation($idetails)) {
		# $errstr will be set in the subroutine
		return;
	}
	return 1;
}

sub delete {
	# http://www.nominet.org.uk/registrars/systems/auto/delete/
	my $operation = 'delete';
	
	my $self = shift;
	my $domain = shift;
    
	if (!$domain) {
		$errstr = "domain is required";
		return;
	}

	$idetails->{'operation'} = $operation;
	$idetails->{'key'}=$domain;

	if (!&operation($idetails)) {
		# $errstr will be set in the subroutine
		return;
	}
	return 1;
}

sub list {
	# http://www.nominet.org.uk/registrars/systems/auto/list/
	my $operation = 'list';
	
	my $self = shift;
	my $idetails = shift;
	
	if (!$idetails) {
		$errstr = "details are required";
		return;
	}
	
	$idetails->{'operation'} = $operation;

	if (!&operation($idetails)) {
		# $errstr will be set in the subroutine
		return;
	}
	return 1;
}

sub valid_domain {
	# Checks domain length, whitespace, SLD, and invalid chars
	
	my $self = shift;
	my $domain = lc shift;
	
	if (!$domain) {
		$errstr = "domain is required";
		return;
	}

	my $MAX_LENGTH = 63;

	if (length $domain > $MAX_LENGTH) {
		$errstr = "Domain name too long - max 63 characters";
		return;
	}
	if ($domain =~ m/\s/) {
		$errstr = "Domain cannot contain space character";
		return;
	}
	if ($domain !~ /$sldsi$/i) {
		$errstr = "Invalid domain name SLD";
		return;
	}
	if ($domain !~ /^[a-zA-Z0-9][.a-zA-Z0-9\-]*[a-zA-Z0-9]$sldsi$/i) {
		$errstr = "Domain contains invalid characters. Use only A-Z 0-9 and -";
		return;
	}
	return 1;
}

sub domain_available {
	# Takes a domain name and returns true if it is not already registered.

	my $self = shift;
	my $domain = shift;
        
	return undef if ! $self->valid_domain($domain);
    
	use Net::XWhois;

	my $whois = Net::XWhois->new( Domain=>$domain );
    
	if ( ! $whois ) {
		$errstr = "Cannot connect to whois server for domain '$domain'";
		return undef;
		}
	my $response = $whois->response;
	if ( ! $response ) {
		$errstr = "No response from whois server for domain '$domain'";
		return undef;
		}
	if ( $response =~ m/no match for/i ) {
		return 1;
 		}
 	else {
		$errstr = "Domain already registered";
		return undef;
		}
}

sub send_mail {
	# Takes a message and sends it to specified recpient.

	my $recipient = shift;
	my $subject = shift;
	my $message = shift;
	
	if (defined $self{testemail}) {
		$recipient = $self{testemail};
	}

	if (!$recipient) {
		$errstr = "recipient is empty";
		return;
	}

	if (!$subject ) {
		$errstr = "subject is empty";
		return;
		}

	if (!$message ) {
		$errstr = "message is empty";
		return;
	}
	
	# If the user sets the testemail as testemail, we'll skip this part

	if ($recipient eq 'testemail') { return 1; }

	use Net::SMTP;
	my $smtp = Net::SMTP->new($self{smtpserver});
    
	$errstr = "unable to connect to " . $self{smtpserver} . " smtpserver", return if ! $smtp;

 
	return if ! $smtp->mail($self{emailfrom});
	return if ! $smtp->to($recipient);
    
	return if ! $smtp->data();
	return if ! $smtp->datasend("To: $recipient\n");
	return if ! $smtp->datasend("From: ".$self{emailfrom}."\n");
	return if ! $smtp->datasend("X-Sent-Via: Net::UKDomains::Nominet::Automaton\n");
	return if ! $smtp->datasend("Subject: $subject\n\n");
    
	return if ! $smtp->datasend($message);
	return if ! $smtp->dataend();
	return if ! $smtp->quit;
    
	return 1;
}

sub errstr {
	return $errstr if $errstr;
}
