csv2ical
========

People love spreadsheets even for things which they are not suited, 
like meeting schedules.

This script takes a schedule created in a spreadsheet, saved to CSV
and converts it to an iCal document for easy sharing and importing
into calendaring applications.

Dependencies
------------

This is a perl script and uses several date and calendaring libraries
for ease of use:

 - Getopt::Long
 - Pod::Usage
 - Data::ICal
 - Data::ICal::Entry::Event
 - Data::ICal::Entry::Alarm::Display
 - Date::ICal
 - Date::Calc

All are available in CPAN.

Help
----

Run the script with the --man switch for detailed help

  perl csv2ical.pl --man

Bugs
----

This is an early version of the script. There will be bugs. Pull 
requests are welcome.

