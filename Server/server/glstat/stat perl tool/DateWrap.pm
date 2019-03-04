	package DateWrap;

use Date::Calc qw(Date_to_Time Time_to_Date Add_Delta_Days Add_Delta_DHMS Mktime);

#get the date shift ndays from startday
#get_date(statrday, ndays),e.g. £¨20141011£¬ 4£©
sub get_date
{
	my $startday = shift;
	my $ndays = shift;
	my $y = substr($startday, 0, 4);
	my $m = substr($startday, 4, 2);
	my $d = substr($startday, 6, 2);	
	$ndays = 0 unless defined($ndays);
	($y, $m, $d) = Add_Delta_Days($y, $m, $d, $ndays);
	my $nt = Date_to_Time($y, $m, $d, 0, 0, 0);
	my $date = sprintf("%4d%02d%02d", $y, $m, $d);
	return $date;
}

sub get_date_time
{
	my ($datetime, $ndays, $nhours, $nmins, $nsecs) = @_;
	
	$ndays = 0 unless defined($ndays);
	$nhours = 0 unless defined($nhours);
	$nmins = 0 unless defined($nmins);
	$nsecs = 0 unless defined($nsecs);
	#20141223 19:47:28
	my $y = substr($datetime, 0, 4);
	my $m = substr($datetime, 4, 2);
	my $d = substr($datetime, 6, 2);
	my $h = substr($datetime, 9, 2);
	my $M = substr($datetime, 12, 2);
	my $s = substr($datetime, 15, 2);
	#print "$datetime\n";
	#print "$y, $m, $d, $h, $M, $s, $ndays, $nhours, $nmins, $nsecs\n";
	
	$ndays = 0 unless defined($ndays);
	($y, $m, $d, $h, $M, $s) = Add_Delta_DHMS($y, $m, $d, $h, $M, $s, $ndays, $nhours, $nmins, $nsecs);
	my $nt = Date_to_Time($y, $m, $d, $h, $M, $s);
	my $date = sprintf("%4d%02d%02d", $y, $m, $d);
	#print "($date, $h, $M, $s)\n";
	return ($date, $h, $M, $s);
}

1;#end of the file