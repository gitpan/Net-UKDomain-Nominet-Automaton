# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
my $d = undef;
BEGIN { plan tests => 12, onfail => sub { print $d->errstr(); } };
use Net::UKDomain::Nominet::Automaton;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.
use Crypt::OpenPGP;
ok(2); 

my $pgp = Crypt::OpenPGP->new(  -SecRing => './.pgp',
                                -PubRing => './.pgp',
                                -Compat => 'PGP2'
                                );
ok($pgp);

my ($public, $secret) = $pgp->keygen(   Type => 'RSA',
                                        Size => 512,
                                        Identity => 'Test <test@my.isp>',
                                        Passphrase => 'TestOpenPGP',
                                        );
ok($public);

my $psaved = $public->save;
my $ssaved = $secret->save;

open FH, '>', '.pgp/public.pgp' || die $!;
print FH $psaved;
close FH;

open FH, '>', '.pgp/secret.pgp' || die $!;
print FH $ssaved;
close FH;
ok(5);

my $keyID = substr($secret->key->key_id_hex, -8, 8);

$secret = undef;
$public = undef;
$pgp = undef;

$d = Net::UKDomain::Nominet::Automaton->new( keyid     => $keyID,
                                        passphrase      => 'TestOpenPGP',
                                        tag             => 'IPSTAG',
                                        smtpserver      => 'smtp.example.com',
                                        emailfrom       => 'UK Domains <ukdomains@example.com>',
                                        secring         => './.pgp/secret.pgp',
                                        pubring         => './.pgp/public.pgp',
                                        compat          => 'PGP2',
                                        testemail       => 'testemail'
                                        ); 

ok($d);


my $domain = "automaton-test-";
$domain .= join '', (0..9, 'A'..'Z', 'a'..'z')[rand 64, rand 64, rand 64, rand 64, rand 64, rand 64, rand 64, rand 64];
$domain .= ".co.uk";

ok($d->valid_domain($domain));

my $details = { 'for' 		=> 'Test Registrant',
		'reg-contact'	=> 'Test Contact',
		'reg-addr'	=> '1 High Street',
		'reg-city'	=> 'A Town',
		'reg-county'	=> 'County',
		'reg-postcode'	=> 'AN0 0NA',
		'reg-country'	=> 'GB',
		'reg-email'	=> 'test@example.com'
		};

ok( $d->register($domain, $details) );

$domain = 'nominet.org.uk';
my $details = { 'reg-contact'	=> 'Test Contact',
		'reg-addr'	=> '1 High Street',
		'reg-city'	=> 'A Town',
		'reg-county'	=> 'County',
		'reg-postcode'	=> 'AN0 0NA',
		'reg-country'	=> 'GB',
		'reg-email'	=> 'test@example.com'
		};

if ( ! $d->modify($domain, $details) ) {
	print "Cannot modify $domain " . $d->errstr() . "\n";
	}
else { ok(1); }
if ( ! $d->renew($domain) ) {
	print "Cannot renew $domain " . $d->errstr() . "\n";
	}
else { ok(1); }
if ( ! $d->release($domain, "GEEKY") ) { 
	print "Cannot release $domain " . $d->errstr() . "\n";
	}
else { ok(1); }
if ( ! $d->delete($domain) ) { 
	print "Cannot release $domain " . $d->errstr() . "\n";
	}
else { ok(1); }

