#!/usr/bin/env perl

# Simple script to send email with perl
# This was originally created as part of a larger mailer system
# where the recipient, subject, body and optional attachment file
# were fed in as command line arguments.

use strict;
use warnings;
use MIME::Lite::TT;

## SET THIS TO YOUR "FROM" ADDRESS
## Must be encapsulated by single quotes
my $sender = 'email@example.com';

if ((not defined $sender) || ($sender eq "")) {
	print "Edit $0 and define the  \$sender  variable to match your \"From\:\" address\n";
	exit;
}

my ($recipient, $subj, $template, $attachment) = @ARGV;
if ($#ARGV < 2) { 
	print "Usage: $0 recipient\@example.com \"Email Subject Line\" /path/to/body_file /path/to/attachment\n";
	exit;
}

my $msg = MIME::Lite::TT ->new(
	From			=> $sender,
	To				=> $recipient,
	Subject		=> $subj,
	Template	=> $template
);

if (defined $attachment) {
	$msg->attach(
		Path				=> $attachment,
		Filename		=> $attachment,
		Disposition	=> 'attachment'
	);
}

$msg->send;
