		package SingleInfo;

use DateWrap;
use LogStat;
use Print;
use LogFormat;


#construct function param(enddate, shiftdays )
sub new
{
	my $class = shift;			#need class name
	my $enddate = shift;		#enddate
	my $shiftdays = shift;	#shiftdays
	my $this = {};					#a new hash reference
	
	#member data

	my %statmap = ();
	my @datearray = ();
	my $i = 0;
	for($i = 0; $i < $shiftdays; $i++)
	{
		#my $date = `date -d '$i days ago' +%Y%m%d`;
		my $date = DateWrap::get_date($enddate, -$i);
		#chomp($date);
		push(@datearray, $date);
		my $stat = new LogStat($date);
		#printf("date:$date stat:$stat\n");
		$statmap{$date} = $stat;
	}
	#@datearray = reverse(@datearray);
	
	my %datamap = ();
	#@datearray = sort(@datearray);
	$this->{'mStatPtrMap'} = \%statmap;
	$this->{'mDateArray'} = \@datearray;
	
	$this->{'mStatDataMap'} = \%datamap;

	$this->{'mEndDate'} = $enddate;
	$this->{'mDays'} = $shiftdays;
	$this->{'mNowDate'} = `date '+%Y%m%d'`;

	bless $this, $class;	
	
	return $this;
}

sub show()
{
	my $this = shift;
	my $type = shift;	
	my $user = shift;
	
	my $fmt = $this->{'mLogFmt'};
	unless( $fmt )
	{
		$fmt = new LogFormat;
		if( $fmt->load() != 0 )
		{
			print("fmt load failed\n");
		}
		#$fmt->debug();
		$this->{'mLogFmt'} = $fmt;
	}
	
	
	my $prt = $this->{'mPrint'};
	unless( $prt )
	{
		#print("datamap_p:$datamap_p, $rowlist_p, $nametb_p\n");
		#foreach( ($key, $val) = each(%$datamap_p) )
		#{
			#	print("key:$key, val:$val\n");
		#}
		$prt = new Print();
		$this->{'mPrint'} = $prt;
	}
	
	unless($type)
	{
		my $title = "need specify the log type such as 'LOGIN', there are type list:";
		my $typemap = $fmt->get_type_name_map();
		$prt->do_print_help($title, $typemap);
		return;
	}

	$type = uc($type);

	$this->stat_all($type, $user);
	my $datamap_p = $this->{'mStatDataMap'};
	my $header_p = $this->{'mHeaderTab'};

	
	my $typestr = $fmt->get_type_name($type);
	#printf("data:$datamap_p, header_p:$header_p\n");
	$prt->do_print_list($typestr, $datamap_p, $header_p);	
}

sub stat_all
{
	my $this = shift;
	my $type = shift;	
	my $user = shift;
	$this->stat_header($type);
	$this->stat_data($type, $user);
}

sub stat_header
{
	my $this = shift;
	my $type = shift;	
	my $fmt = $this->{'mLogFmt'};
	my @arr = $fmt->get_param_des($type);
	unshift(@arr, $type);
	$this->{'mHeaderTab'} = \@arr;
}

sub stat_data
{
	my $this = shift;
	my $type = shift;	
	my $user = shift;
	my $statmap = $this->{'mStatPtrMap'};
	while((my $date, my $stat) = each(%$statmap))
	{
		my @stattypes = $type;
		$stat->{mStatTypes} = \@stattypes;
		if( $stat->load(1) != 0 )
		{
			#die("stat:$date load failed\n");
		}
		#printf("stat:$date load successfully.\n");
		$stat->stat();
		#printf("stat:$date stat suceessfully.\n");
	}
	
	#printf("type:$type\n");
	#stat_data
	my $datamap = $this->{'mStatDataMap'};
	my $datearray = $this->{'mDateArray'};
	foreach $date (@$datearray)
	{
		unless( exists($statmap->{$date}) )
		{
			printf("date:$date logstat not found\n");
			next;
		}
		my $stat = $statmap->{$date};
		my $tb = $stat->get_typed_table($type);
		my $num = scalar(@$tb);
		#print("tb:$tb, tbnum:$num user:$user\n");
		my @arr;
		if( $user )
		{
			foreach $item(@$tb)
			{
				if( grep(/$user/, @$item) )
				{
					push(@arr, $item);
				}
			}
		}
		else
		{
			@arr = @$tb;
		}
		$datamap->{$date} = \@arr;
	}
	
}


1;#end of the file
