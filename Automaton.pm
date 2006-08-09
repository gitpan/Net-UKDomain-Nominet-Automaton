package Net::UKDomain::Nominet::Automaton;

use 5.006;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

use Mail::CheckUser qw(check_email);
$Mail::CheckUser::Skip_Network_Checks = 1;

our $errstr = undef;	# Global error string for returning error condition details

our %ukrules = (
               'for' 		=> '[[:print:]]{1,80}',
               'reg-contact'	=> '[[:print:]]{1,80}',
               'reg-trad-name'	=> '[[:print:]]{1,80}',
               'reg-type'	=> '(LTD|PLC|PTNR|LLP|STRA|IND|IP|SCH|RCHAR|GOV|CRC|STAT|OTHER|FIND|FCORP|FOTHER)',
	       'reg-opt-out'	=> '(y|n)',
               'reg-co-no'	=> '[0-9]{1,10}',
               'reg-addr'	=> '[[:print:]]{1,256}',
               'reg-city'	=> '[[:print:]]{1,80}',
	       'reg-locality'	=> '[[:print:]]{1,80}',
               'reg-county'	=> '[[:print:]]{1,80}',
               'reg-postcode'	=> '[A-Z0-9 ]{1,10}',
               'reg-country'	=> '[A-Z]{2}',
               'reg-fax'	=> '[\+0-9][0-9\.\-]{1,20}',
               'reg-phone'	=> '[\+0-9][0-9\.\-]{1,20}',
               'reg-email'	=> '.*',
	       'reg-ref'	=> '.*',
               'dns0'		=> '[a-z0-9][a-z0-9\-\.\,]+',
               'dns1'		=> '[a-z0-9][a-z0-9\-\.\,]+',
               'dns2'		=> '[a-z0-9][a-z0-9\-\.\,]+',
               'dns3'		=> '[a-z0-9][a-z0-9\-\.\,]+',
               'dns4'		=> '[a-z0-9][a-z0-9\-\.\,]+',
               'dns5'		=> '[a-z0-9][a-z0-9\-\.\,]+',
               'dns6'		=> '[a-z0-9][a-z0-9\-\.\,]+',
               'dns7'		=> '[a-z0-9][a-z0-9\-\.\,]+',
               'dns8'		=> '[a-z0-9][a-z0-9\-\.\,]+',
               'dns9'		=> '[a-z0-9][a-z0-9\-\.\,]+',
               'admin-c'	=> '[[:print:]]{1,80}',
               'a-addr'		=> '[[:print:]]{1,256}',
               'a-phone'	=> '[\+0-9][0-9\.\-]{1,20}',
               'a-fax'		=> '[\+0-9][0-9\.\-]{1,20}',
               'a-email'	=> '.*',
               'billing-c'	=> '[[:print:]]{1,80}',
               'b-addr'		=> '[[:print:]]{1,256}',
	       'b-locality'	=> '[[:print:]]{1,80}',
	       'b-city'		=> '[[:print:]]{1,80}',
	       'b-county'	=> '[[:print:]]{1,80}',
	       'b-postcode'	=> '[A-Z0-9 ]{1,10}',
	       'b-country'	=> '[A-Z]{2}',
               'b-phone'	=> '[\+0-9][0-9\.\-]{1,20}',
               'b-fax'		=> '[\+0-9][0-9\.\-]{1,20}',
               'b-email'	=> '.*',
               'ips-key'	=> '[A-Z0-9\-]+',
               'first-bill'	=> '(th|bc)',
               'recur-bill'	=> '(th|bc)',
               'auto-bill'	=> '[0-9]{0,3}',
               'next-bill'	=> '[0-9]{0,3}',
               'notes'		=> '[[:print:]]*',
               );
our %ukmandatory = (
                   'for' => 1,
                   'reg-contact' => 1,
                   'reg-addr' => 1,
                   'reg-city' => 1,
                   'reg-country' => 1,
                   );
                   
our @ukfields = ('for', 'reg-contact', 'reg-trad-name', 'reg-type', 'reg-co-no', 'reg-locality',
                 'reg-addr', 'reg-city', 'reg-county', 'reg-country', 'reg-postcode',
                 'reg-phone', 'reg-fax', 'reg-email', 'reg-ref', 'admin-c', 'a-phone', 
		 'a-fax', 'a-email', 'a-addr', , 'billing-c', 'b-phone', 'b-fax', 
		 'b-email', 'b-addr', 'b-locality', 'b-city', 'b-county', 'b-postcode', 
		 'b-country', 'b-addr', 'ips-key', 'first-bill', 'recur-bill', 'auto-bill', 
		 'next-bill', 'notes', 'dns0', 'dns1', 'dns2', 'dns3', 'dns4',
		 'dns5', 'dns6', 'dns7', 'dns8', 'dns9');

our $regtypes = "(ltd|plc|ptnr|stra|llp|ip|ind|sch|rchar|gov|crc|stat|other|find|fcorp|fother)";
our $emailfields = "(reg-email|a-email|b-email)";

our @ISA = qw(Exporter);

#our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );
# our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();
our $VERSION = '1.04';

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Net::UKDomain::Nominet::Automaton - Module to handle the Nominet Automaton for domain registration and modification.

=head1 SYNOPSIS

	use Net::UKDomain::Nominet::Automaton 
	my $d = Net::UKDomain::Nominet::Automaton->new( keyid 	=> 'MYKEYID',
						passphrase 	=> 'HARDTOREMEMBER',
						tag 		=> 'ISPTAG',
						smtp		=> 'smtp.my.net',
						emailfrom	=> 'MyISP <domains@my.isp>',
						secring		=> '/path/to/secret/keyring',
						pubring		=> '/path/to/public/keyring',
						compat		=> 'PGP2',
						testemail	=> 'myown@email.here',
						);

	my $domain = 'domain.sld.uk';

	if ( ! $d->valid_domain($domain) ) {
		print "Invalid domain - " . $d->errstr;
		}

	if ( ! $d->domain_available($domain) ) {
		print "Domain not available.";
		}

	if ( ! $d->register($domain, \%details) ) {
		print "Unable to register domain - ". $d->errstr;
		}

	if ( ! $d->modify($domain, \%details) ) {
		print "Unable to modify $domain - " . $d->errstr;
		}

	if ( ! $d->query($domain) ) {
		print "Unable to query $domain - " . $d->errstr;
		}

	if ( ! $d->renew($domain) ) {
		print "Unable to renew $domain - " . $d->errstr;
		}

	if ( ! $d->release($domain, $othertag) ) {
		print "Unable to release $domain to $othertag - " . $d->errstr;
		}

	if ( ! $d->delete($domain) ) {
		print "Unable to delete $domain - " . $d->errstr;
		}

=head1 DESCRIPTION

A simple module for the Nominet .UK email based automaton.

This is designed to allow you to handle all of the actions normally associated with registering and managing a .UK domain - ie checking that the proposed name is valid and available, registering it or modifying it.

Note that Nominet's Automaton is an asyncronous process. Requests are sent to it via email (using Net::SMTP) and it replies by email to the nofification email address Nominet hold on record for the tag holder.

Be warned that the error strings returned by the module are not intended to be returned directly to users of your script.

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

=item SMTP

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

=head1 Net::UKDomain::Nominet::Automaton->register($domain, \%details);

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

=head1 Net::UKDomain::Nominet::Automaton->modify($domain, \%details);

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

=head1 SEE ALSO

http://www.jasonclifford.com/
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

	if ( ! defined $self{keyid} ) {
		$errstr = "Please provide the PGP Key ID";
		return;
		}

	$errstr = "Please provide PGP pass phrase",return if ! defined $self{passphrase};
	$errstr = "Please provide Nominet IPS TAG",return if ! $self{tag};
	$errstr = "Please provide SMTP Server",return if ! $self{smtpserver};
	$errstr = "Please provide Email From address",return if ! $self{emailfrom};
	$errstr = "Please provide PGP Secret Ring",return if ! $self{secring};
	$errstr = "Please provide PGP Public Ring",return if ! $self{pubring};

	if ( ! defined $self{compat} ) {
		$self{compat} = 'PGP2';
		}

	return $self;
	}

sub register {
	my $self = shift;
	my $domain = shift;
	my $hr_details = shift;

	if ( ! $domain || ! ref $hr_details ) {
		$errstr = "register_uk called without required arguements";
		return;
		}
	if ( ! $self->valid_domain($domain) ) {
		# $errstr is set in the valid_domain subroutine
		return;
		}

	# We need to check the hash referenced in $hr_details to ensure that
	# all required fields are present and that the data is valid.
	# Once it is confirmed to be valid we construct a message string.
    
	my $message = undef;
	my $flag = undef;

	my $need_co_no = '(.ltd.uk|.plc.uk|.net.uk)';
	my $need_postcode = "(GB|JE|GG|IM)";

	if ( ($domain =~ m/^.*$need_co_no$/i) ) {
		if (! defined $hr_details->{'reg-co-no'}) {
			$errstr = "mandatory field reg-co-no is missing";
			return;
			}
		}

	if ( $hr_details->{'reg-country'} =~ /^$need_postcode$/ ) {
		if ( ! defined $hr_details->{'reg-postcode'} ) {
			$errstr = "mandatory field reg-postcode is missing";
			return;
			}
		}


	foreach my $field (@ukfields) {
		
		if ( (exists $ukmandatory{$field}) && ( ! defined $hr_details->{$field}) ) {
			$errstr = "mandatory field $field is missing " . $hr_details->{$field};
			return;
			}
		
	
		next if ! $hr_details->{$field};

		my $fdata = $hr_details->{$field};	# The actual data in the field


		if ( $fdata !~ m/^$ukrules{$field}$/i ) {
			$errstr = "field $field invalid - data is " . $fdata . " check was " . $ukrules{$field};
			return;
			}

		if ( $field =~ m/^$emailfields$/i && ! check_email($fdata) ) {
			$errstr = "$field is not a valid email address";
			return;
			}
			
		$message .= "$field: " . $fdata . "\n";
		}
    
	my $to = 'applications@nic.uk';
    
	my $data = "operation: request\nkey: $domain\n";
	$data .= $message;
    
	my $signature = &sign($data);
	
	if ( ! $signature ) {
		return;
		}

	if ( ! &send_mail($to, $self{tag} ." Domain Request", $signature) ) {
		$errstr = "Unable to send email request - reason unknown";
		return;
		}

	return 1;
	}

sub modify {
	# Takes a domain name and a hash reference with a list of fields to 
	# change. After checking it emails the automaton with the modify request
    
	my $self = shift;
	my $domain = shift;
	my $hr_details = shift;
    
	return if ! $domain || ! $hr_details;
	return if ! $self->valid_domain($domain);

	# Sanity check modify data
	
	# You cannot change the for field
	if ( $hr_details->{'for'} ) {
		$errstr = "You cannot change the Registrant field - See Nominet website";
		return;
		}

	foreach my $field (@ukfields) {
		next if ! $hr_details->{$field};

		my $fdata = $hr_details->{$field};	# The actual data in the field

		if ( $fdata !~ m/^$ukrules{$field}$/i ) {
			$errstr = "field $field invalid - data is " . $fdata . " check was " . $ukrules{$field};
			return;
			}

		if ( $field =~ m/$emailfields/i && ! check_email($fdata) ) {
			$errstr = "$field is not a valid email address";
			return;
			}

		$message .= "$field: " . $fdata . "\n";
		}
	

	my $to = undef;
	if ( $domain =~ /.*\.(.*)\.uk/i ) {
		$to = 'auto-' . $1 . '@nic.uk';
		}

	my $data = "operation: modify\nkey: $domain\n";
	$data .= $message;
   
	my $signature = &sign($data);
 
	if ( ! $signature ) {
		$errstr = "PGP Signature Failure - " . $pgp->errstr;
		return;
		}
	
	if ( ! &send_mail($to, $self{tag} ." Modify", $signature) ) {
		return;
		}
	return 1;
	}

sub release {
	# Takes a domain name and a hash reference with a list of fields to 
	# change. After checking it emails the automaton with the modify request
    
	my $self = shift;
	my $domain = shift;
	my $tag = shift;
    
	$errstr = "Domain or TAG not passed", return if ! $domain || ! $tag;
	return if ! $self->valid_domain($domain);

	$tag = uc $tag;

	# Check that the TAG exists
	use LWP::UserAgent;
	my $ua = LWP::UserAgent->new(timeout => 20);

	my $response = $ua->get('http://www.nominet.org.uk/tag/becometagholder/taglist/');
	if ( $response->is_success ) {
		$errstr = "$tag is unknown", return if ! $response->content =~ /$tag/im;
		}
	else {
		$errstr = $response->status_line;
		return;
		}

	my $to = undef;
	if ( $domain =~ /.*\.(.*)\.uk/i ) {
		$to = 'auto-' . $1 . '@nic.uk';
		}

	my $data = "operation: release\nkey: $domain\nips-key: $tag";

	my $signature = &sign($data);   
 
	if ( ! $signature ) {
		$errstr = "PGP Signature Failure - " . $pgp->errstr;
		return;
		}
	
	if ( ! &send_mail($to, $self{tag} . " Release", $signature) ) {
		return;
		}
	return 1;
	}


sub renew {
	my $self = shift;
	my $domain = shift;
    
	return if ! $domain;
	return if ! $self->valid_domain($domain);

	my $to = undef;
	if ( $domain =~ /.*\.(.*)\.uk/i ) {
		$to = 'auto-' . $1 . '@nic.uk';
		}

	my $data = "operation: renew\nkey: $domain";
    
	my $signature = &sign($data);
                               
	if ( ! $signature ) {
		$errstr = "PGP Signature Failure - " . $pgp->errstr;
		return;
		}
	
	if ( ! &send_mail($to, $self{tag} . " Renew", $signature) ) {
		$errstr = "Unable to send email request - reason unknown";
		return;
		}
	return 1;
	}

sub delete {
	my $self = shift;
	my $domain = shift;
    
	return if ! $domain;
	return if ! $self->valid_domain($domain);

	my $to = undef;
	if ( $domain =~ /.*\.(.*)\.uk/i ) {
		$to = 'auto-' . $1 . '@nic.uk';
		}

	my $data = "operation: delete\nkey: $domain";
    
	my $signature = &sign($data);
                               
	if ( ! $signature ) {
		$errstr = "PGP Signature Failure - " . $pgp->errstr;
		return;
		}
	
	if ( ! &send_mail($to, $self{tag} ." Delete", $signature) ) {
		$errstr = "Unable to send email request - reason unknown";
		return;
		}
	return 1;
	}

sub query {
	my $self = shift;
	my $domain = shift;
    
	return if ! $domain;
	return if ! $self->valid_domain($domain);

	my $to = undef;
	if ( $domain =~ /.*\.(.*)\.uk/i ) {
		$to = 'auto-' . $1 . '@nic.uk';
		}

	my $data = "operation: query\nkey: $domain";
    
	my $signature = &sign($data);
                               
	if ( ! $signature ) {
		$errstr = "PGP Signature Failure - " . $pgp->errstr;
		return;
		}
	
	if ( ! &send_mail($to, $self{tag} . " Query", $signature) ) {
		$errstr = "Unable to send email request - reason unknown";
		return;
		}
	return 1;
	}

sub valid_domain {
	my $self = shift;
	my $domain = lc shift;

	my $UK_TLDS_REGEX = "(\.co\.uk|\.org\.uk|\.me\.uk|\.ltd\.uk|\.plc\.uk|\.sch\.uk)";
	my $MAX_UK_LENGTH = 63;
	$maxLengthForThisCase = $MAX_UK_LENGTH;

	if (length $domain > $maxLengthForThisCase) {
		$errstr = "Domain name too long - max 61 characters";
		return;
		}
	if ( $domain =~ / / ) {
		$errstr = "Domain cannot contain space character";
		return;
		}
	if ($domain !~ /$UK_TLDS_REGEX$/i) {
		$errstr = "Not a valid .UK domain";
		return;
		}
	if ($domain !~ /^[a-zA-Z0-9][.a-zA-Z0-9\-]*[a-zA-Z0-9]$UK_TLDS_REGEX$/i) {
		$errstr = "Domain contains invalid characters. Use only A-Z 0-9 and -";
		return;
		}
	return 1;
	}

sub domain_available {
	# Takes a domain name and returns true if it is not already registered.
    
	my $self=shift;
	my $domain = shift;
        
	return undef if ! $self->valid_domain($domain);
    
	use Net::XWhois;

	my $whois = Net::XWhois->new( Domain=>$domain );
    
	if ( ! $whois ) {
		$errstr = "Cannot connect to whois server for domain $domain";
		return undef;
		}
	my $response = $whois->response;
	if ( ! $response ) {
		$errstr = "No response from whois server for domain $domain";
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

sub sign {	
	my $data = shift;

	use Crypt::OpenPGP;

	my $pgp = undef;

	$pgp = Crypt::OpenPGP->new( SecRing => $self{secring},
	                            PubRing => $self{pubring},
	                            Compat  => $self{compat},);

	my $signature = undef;

	$signature = $pgp->sign(
	                           Data	 	=> $data,
	                           KeyID 	=> $self{keyid},
	                           Passphrase	=> $self{passphrase},
	                           Armour	=> 1,
	                           Clearsign	=> 1,
				);

	if ( ! $signature ) {
		$errstr = "Unable to sign message - " . $pgp->errstr . " " . $self{keyid};
		return;
		}

	return $signature;
	}

sub send_mail {
	# Takes a message and sends it to specified recpient.
	my $recipient = shift;
	my $subject = shift;
	my $message = shift;

	if ( ! $recipient ) {
		$errstr = "No recipient passed";
		return;
		}

	if ( ! $subject ) {
		$errstr = "No Subject passed";
		return;
		}

	if ( ! $message ) {
		$errstr = "No message passed";
		return;
		}
    
	if ( defined $self{testemail} ) {
		$recipient = $self{testemail};
		return 1 if ! check_email($recipient);	# So we can use in the test suit
		}

	use Net::SMTP;
	my $smtp = Net::SMTP->new($self{smtpserver});
    
	$errstr = "Cannot connect to $smtpserver", return if ! $smtp;
    
	return if ! $smtp->mail($self{emailfrom});
	return if ! $smtp->to($recipient);
    
	return if ! $smtp->data();
	return if ! $smtp->datasend("To: $recipient\n");
	return if ! $smtp->datasend("From: ".$self{emailfrom} ."\n");
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
