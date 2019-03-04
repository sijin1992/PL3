		package LevelsInfo;

use DateWrap;
use LogStat;
use Print;


#construct function param( stat, print, enddate, shiftdays )
sub new
{
	my $class = shift;			#need class name
	my $enddate = shift;		#enddate
	my $shiftdays = shift;	#shiftdays
	my $levelsector = shift;	#levelsector

	my $this = {};					#a new hash reference
	
	#member data
	#printf("enddate:$enddate\n");
	my @stattypes = qw(LOGIN LOGOUT REGIST DEPOSIT ONLINE LEVELUP);
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
		$stat->{mStatTypes} =  \@stattypes;
		#printf("date:$date stat:$stat\n");
		$statmap{$date} = $stat;
	}
	@datearray = reverse(@datearray);
	
	my %datamap = ();
	#@datearray = sort(@datearray);
	$this->{'mStatPtrMap'} = \%statmap;
	$this->{'mDateArray'} = \@datearray;
	
	$this->{'mStatDataMap'} = \%datamap;
	
	$this->{'mEndDate'} = $enddate;
	$this->{'mDays'} = $shiftdays;
	$this->{'mNowDate'} = `date '+%Y%m%d'`;
	$this->{'mLevelSector'} = $levelsector;

	bless $this, $class;	
	
	return $this;
}

sub show()
{
	my $this = shift;
	my $need_filter = shift;
	printf("need_filter:$need_filter\n");
	if( $need_filter > 0 )
	{
		$this->stat_filter($need_filter - 1, $need_filter > 2, $need_filter > 3)
	}
	elsif( $need_filter < 0 )
	{
		$this->stat_reg();
	}
	else
	{
		$this->stat_all();
	}
	
	my $datamap_p = $this->{'mStatDataMap'};
	my %bar_array;
	my $total = $this->{'mUserNum'};
	#my @sectors = keys %$datamap_p;
	foreach $sector (sort { $a <=> $b } keys %$datamap_p)
	{
			my $num = $datamap_p->{$sector};
			my $prect = $num / $total * 100.0;
			my $endstr = sprintf("%d(%2.02f%%)", $num, $prect);
			my $len = int($prect);
			my @arr = ();
			@arr[0..2] = ($len, $sector, $endstr);
			push(@bar_array, \@arr);
	}
	my $prt = $this->{'mPrint'};
	unless( $prt )
	{
		$prt = new Print();
		$this->{'mPrint'} = $prt;
		$prt->{'mTitle'} = "玩家等级分布 人数：" . $total;
		if( $need_filter < 0 )
		{
			my $date = $this->{'mEndDate'};
			$prt->{'mTitle'} =  "日期:$date 人数：" . $total;
		}
	}

	$prt->do_print_bar(\@bar_array);	
}

sub stat_all
{
	$this = shift;
	$statmap = $this->{'mStatPtrMap'};
	while((my $date, my $stat) = each(%$statmap))
	{
		
		if( $stat->load(1) != 0 )
		{
			#die("stat:$date load failed\n");
		}
		#printf("stat:$date load successfully.\n");
		$stat->stat();
		#printf("stat:$date stat suceessfully.\n");
	}

	$this->stat_all_levels();
}


sub stat_reg
{
	$this = shift;
	my $date = $this->{'mEndDate'};
	my $statmap = $this->{'mStatPtrMap'};
	my $stat = $statmap->{$date};
	die("date:$date not in statmap\n") unless ($stat);
	if( $stat->load(1) != 0 )
	{
		#die("stat:$date load failed\n");
	}
	#printf("stat:$date load successfully.\n");
	$stat->stat();

	my $regusers = $stat->get_regist_users();
	$this->stat_all_levels($regusers);
}

sub stat_filter
{
	my $this = shift;
	my $liucun = shift;
	my $allreg = shift;
	$statmap = $this->{'mStatPtrMap'};
	while((my $date, my $stat) = each(%$statmap))
	{
		
		if( $stat->load(1) != 0 )
		{
			#die("stat:$date load failed\n");
		}
		#printf("stat:$date load successfully.\n");
		$stat->stat();
		#printf("stat:$date stat suceessfully.\n");
	}
	
	my $date = $this->{'mEndDate'};
	my @liushi_users = ();
	my $isin;
		my $regdate = DateWrap::get_date($date, -1);
		my $logindate = DateWrap::get_date($date);
		my $loginstat =  $statmap->{$logindate};
		my $regstat =  $statmap->{$regdate};
		unless( $regstat )
		{
			return;
		}
		unless( $loginstat )
		{
			return;
		}
		my $regusers = $regstat->get_regist_users();
		my $loginusers = $loginstat->get_login_users();
		my $regnum = scalar(@$regusers);
		unless( $regnum )
		{
			return;
		}
		my $loginnum = scalar(@$loginusers);
		#print("regnum:$regnum loginnum:$loginnum\n");
		#print("@$loginusers\n");
		my $count = 0;
		foreach $user (@$regusers)
		{
			$isin = grep(/^$user$/, @$loginusers);
			if( $allreg or ($liucun ? $isin: not $isin) )
			{
				#print("linshi_user:$user\n");
			  push(@liushi_users, $user);
			  $count++;
			}
		}
		my $perct = 0;
		if( $regnum )
		{
			$perct = $count / $regnum * 100;
		}
	printf("date:$date regdate:$regdate regnum:$regnum loginnum:$loginnum count:$count, pecrt:$perct\n");
	my $liushi_usernum = scalar(@liushi_users);
	#printf("liushi_usernum:$liushi_usernum, @liushi_users\n");
	$this->stat_all_levels(\@liushi_users);
}

sub stat_all_levels
{
		my $this = shift;
		my $filter_users = shift;
		my %level_map = ();
		my $datearray = $this->{'mDateArray'};
		my $statmap = $this->{'mStatPtrMap'};
		foreach $date (@$datearray)
		{
			unless( exists($statmap->{$date}) )
			{
				printf("date:$date logstat not found\n");
				next;
			}
			my $stat = $statmap->{$date};
			my $user_levels = $stat->get_all_user_levels();
			#my $nums = keys %$user_levels;
			#print("nums:$nums, $user_levels\n");
			while( ($user, $level) = each(%$user_levels) )
			{
				#printf("user:$user, level:$level\n");
				if( $filter_users and not grep(/^$user$/, @$filter_users) )
				{
					next;
				}
				unless( $level )
				{
					printf("user:$user level:$level not exists.\n");
					$level = 1;
				}
				if( exists($level_map{$user}) )
				{
						if( $level > $level_map{$user} )
						{
							$level_map{$user} = $level;
						}
				}
				else
				{
						$level_map{$user} = $level;
				}
			}
		}

		my $usernum = keys %level_map; #return key nums
		my %statmap;
		while( ($user, $level) = each(%level_map) )
		{
			#print("linshi_user:$user level:$level\n");
			my $sector = $this->get_level_sector($level);
			$statmap{$sector} += 1;
		}
		
		$this->{'mStatDataMap'} = \%statmap;
		$this->{'mUserNum'} = $usernum;
}

sub stat_levels
{
		my $this = shift;
		my %level_map;
		my $datearray = $this->{'mDateArray'};
		my $statmap = $this->{'mStatPtrMap'};
		foreach $date (@$datearray)
		{
			unless( exists($statmap->{$date}) )
			{
				printf("date:$date logstat not found\n");
				next;
			}
			my $stat = $statmap->{$date};
			my $user_levels = $stat->get_login_user_levels();
			my $nums = keys %$user_levels;
			#print("nums:$nums, $user_levels\n");
			while( ($user, $level) = each(%$user_levels) )
			{
				unless( $level )
				{
					$level = 1;
				}
				#printf("user:$user, level:$level\n");
				if( exists($level_map{$user}) )
				{
						if( $level > $level_map{$user} )
						{
								$level_map{$user} = $level;
						}
				}
				else
				{
						$level_map{$user} = $level;
				}
			}
		}
		
		my $usernum = keys %level_map; #return key nums
		my %statmap;
		while( ($user, $level) = each(%level_map) )
		{
				my $sector = $this->get_level_sector($level);
				$statmap{$sector} += 1;
		}
		
		$this->{'mStatDataMap'} = \%statmap;
		$this->{'mUserNum'} = $usernum;
}


sub get_level_sector
{
		my $this = shift;
		my $level = shift;
		chomp($level);
		if( $level == 1 )
		{
			return 1;
		}
		elsif( $level == 2 )
		{
			return 2;
		}
		my $sector = $this->{'mLevelSector'};
		unless( $sector and $sector != 0 )
		{
				$sector = 1;
		} 
		if( $sector == 1 )
		{
			return $level;
		}
		my $n = int($level / $sector) + 1;
		my $begin = ($n-1) * $sector;
		unless( $begin )
		{
			$begin = 3;
		}
		my $end = $n * $sector -1;
		#printf("level:$level, n:$n begin:$begin, end:$end\n");
		return $begin . "~" . $end;
}


1;#end of the file
