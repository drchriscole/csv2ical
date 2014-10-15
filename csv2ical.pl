#!/usr/bin/perl

=head1 NAME

csv2ical.pl - Script to convert CSV to iCal format

=cut

use strict;
use warnings;

use Getopt::Long qw(:config auto_version);
use Pod::Usage;
use Data::ICal;
use Data::ICal::Entry::Event;
use Date::ICal;
use Date::Calc qw(:all);


my $csv;
my $venue = 'SLT';
my $start = '14:00';
my $end = '15:00';
my $checkDow = 0;
my $out = 'out.ics';
my $VERBOSE = 1;
my $DEBUG = 0;
my $help;
my $man;
our $VERSION = '0.9';

GetOptions (
   'csv=s'      => \$csv,
   'venue=s'   => \$venue,
   'start=s'   => \$start,
   'end=s'     => \$end,
   'out=s'     => \$out,
   'verbose!'  => \$VERBOSE,
   'debug!'    => \$DEBUG,
   'man'       => \$man,
   'help|?'    => \$help,
) or pod2usage();

pod2usage(-verbose => 2) if ($man);
pod2usage(-verbose => 1) if ($help);
pod2usage(-msg => 'Please supply a valid filename.') unless ($csv && -s $csv);

die "ERROR - start time is not valid.\n" unless ($start =~ /:/);
die "ERROR - end time is not valid.\n" unless ($end =~ /:/);

# converter for days of week

my %dowCnv = (
   mon => 1,
   tue => 2,
   wed => 3,
   thu => 4,
   fri => 5,
   sat => 6,
   sun => 7
);

## create new iCalendar object and populate it with events
my $calendar = Data::ICal->new(offset => "UTC") or die "ERROR - failed to create calendar object.\nDied";
open(my $fh, "<", $csv) or die "ERROR - unable to open '$csv': ${!}\nDied";
while(<$fh>) {
   ## assumes input file is comma-delimited and first column is date e.g.
   ##
   ##  Date,Speaker ,Universtiy ,Host,note,
   ##  15/09/2014,Tim Newman,Dundee,Newman,30 min talk.,
   next if (/^Date/i); #skip header line 
   my @F = split(/,/);
   next if ($F[0] eq ""); # skip rows with no date
   my @date;
   unless (@date = Decode_Date_EU($F[0])) {
      die "ERROR - start string '$F[0]' is not a valid date\nDied"
   }
   # check start date is valid
   die "ERROR - start date ".join("-",@date)." is not valid\nDied" unless (check_date(@date));

   # check start date is expected day
   if ($checkDow) {
     my $dow = Day_of_Week(@date);
     
     my $check = substr($checkDow,0,3); # get first 3 chars of day
     $check =~ tr/A-Z/a-z/; # convert lowercase
     die "ERROR - the start date specified is not a $checkDow!\n" unless ($dow == $dowCnv{$check});
   }

   # placeholder for empty summary data
   if ($F[1] eq "") {
      $F[1] = 'TBC';
   }
   
   # split start/end times into hours and minutes
   my ($startHr,$startMin) = split(/:/, $start);
   my ($endHr,$endMin) = split(/:/, $end);
   
   # create the event and populate the calendar
   my $event = Data::ICal::Entry::Event->new();
   my $offset = "+0000";
   $offset = "+0100"if (isDST(@date) > 0);
   $event->add_properties(
      summary => $F[1],
      description => join(":",@F[2..4]),
      location => "SLT",
      dtstart => Date::ICal->new(
         year => $date[0],
         month => $date[1],
         min => $startMin,
         offset => $offset
      )->ical,
      dtend => Date::ICal->new(
         year => $date[0],
         month => $date[1],
         day => $date[2],
         hour => $endHr,
         min => $endMin,
         offset => $offset
      )->ical
      
   );
   $calendar->add_entry($event);
      
   printf "%2s %.3s %d\t$F[2]\n", English_Ordinal($date[2]), Month_to_Text($date[1]), $date[0];
}
close($fh);
open(my $OUT, ">", $out) or die "ERROR - unable to open '$out' for write: ${!}\nDied";
print $OUT $calendar->as_string;
close($OUT);
exit;

# check if date is DST or not
sub isDST {
   my @date = @_;
   
   my $time = Date_to_Time(@date,0,0,0);
   my @fullTime = localtime($time);
   return(pop @fullTime); # last element in the array is the DST flag. Pop and return it.
}


=head1 SYNOPSIS

csv2ical.pl --csv <file> [--venue <string>] [--start <time>] [--end <time>] [--out <file>] [--verbose|--no-verbose] [--version] [--debug|--no-debug] [--man] [--help]

=head1 DESCRIPTION

Script to take a CSV file with rows of dates and some additional information and converts it into an iCal file.

It's very quick and dirty so many assumption are made. The main ones being:

  - 1st column is a date in European format (day, month, year)
  - 2nd column is the subject of the event
  
There are likely to be a few bugs.

=head1 OPTIONS

=over 5

=item B<--csv>

Input file CSV format with first column as dates.

=item B<--venue>

Venue for events. [default: SLT]

=item B<--start>

Start time for events (24hr clock). [default: 14:00]

=item B<--end>

End time for events (24hr clock). [default: 15:00]

=item B<--out>

Output filename in iCal format. [default: 'out.ics']

=item B<--version>

Report version information and exit

=item B<--verbose|--no-verbose>

Toggle verbosity. [default:none]

=item B<--debug|--no-debug>

Toggle debugging output. [default:none]

=item B<--help>

Brief help.

=item B<--man>

Full manpage of program.

=back

=head1 AUTHOR

Chris Cole <christian@cole.name>

=head1 COPYRIGHT

Copyright 2012, Chris Cole. All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
