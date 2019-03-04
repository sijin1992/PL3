		package MainInfo;

use DateWrap;
use LogStat;
use Print;


#construct function param(enddate, shiftdays )
sub new
{
	my $class = shift;			#need class name
	my $enddate = shift;		#enddate
	my $shiftdays = shift;	#shiftdays
	my $this = {};					#a new hash reference
	
	#member data
	

	
	my @rowlist = ("DATE", "REGIST", "LOGIN", "LIUCUN2", "LIUCUN3", "LIUCUN7", "DEPOSIT", "DEPOMON", "DEPOPERCT", "DEPOARUP", "DEPOUN", "ACU", "PCU");
        
	my %nametb = (
               	"DATE" => "DATE",
                "REGIST" => "REGIST",
                "LOGIN" => "LOGIN",
								"DEPOSIT" => "DEPOSIT",
								"DEPOMON" => "DEPOMON",
								"DEPOPERCT" => "DEPOPERCT",
								"DEPOARUP" => "DEPOARUP",
								"DEPOUN" => "DEPOUN",
								"LIUCUN2" => "LIUCUN2",
								"LIUCUN3" => "LIUCUN3",
								"LIUCUN7" => "LIUCUN7",
              	"ACU" => "ACU",
								"PCU" => "PCU",
	);


	if( exists($ENV{'NAME_CONF_FILE'}) )
	{
		my $filename = $ENV{'NAME_CONF_FILE'};
		if( -e $filename and open(CONF_FILE, $filename) )
		{
			%nametb =();
			my $line;
			while($line=<CONF_FILE>)
			{
				if( $line =~ /"(\S+)"\s*=>\s*"(\S+)"/i )
				{
					$nametb{$1} = $2;
				}
			}
			close(CONF_FILE);
		}
		
	}

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
	$this->{'mRowList'} = \@rowlist;
	$this->{'mNameTab'} = \%nametb;

	$this->{'mEndDate'} = $enddate;
	$this->{'mDays'} = $shiftdays;
	$this->{'mNowDate'} = `date '+%Y%m%d'`;

	bless $this, $class;	
	
	return $this;
}

sub show
{
	my $this = shift;
	$this->stat_all();
	my $datamap_p = $this->{'mStatDataMap'};
	my $rowlist_p = $this->{'mRowList'};
	my $nametb_p = $this->{'mNameTab'};
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
	my $title = $nametb_p->{'TITLE'};
	$prt->do_print_table($datamap_p, $rowlist_p, $nametb_p, $title);

}

sub clean
{
	my $this = shift;
	my $statmap = $this->{'mStatPtrMap'};
	while((my $date, my $stat) = each(%$statmap))
	{
		$stat->clean();
		printf("stat:$date clean stat file successfully.\n");
	}
}

sub stat_all
{
	my $this = shift;
	my $statmap = $this->{'mStatPtrMap'};
	while((my $date, my $stat) = each(%$statmap))
	{
		
		if( $stat->load() != 0 )
		{
			#die("stat:$date load failed\n");
		}
		#printf("stat:$date load successfully.\n");
		$stat->stat();
		#printf("stat:$date stat suceessfully.\n");
	}
	
	$this->stat_date("DATE");
	$this->stat_regist("REGIST");
	$this->stat_login("LOGIN");
	$this->stat_deposit("DEPOSIT");
	$this->stat_depomon("DEPOMON");
	$this->stat_depopert("DEPOPERCT");
	$this->stat_depoarup("DEPOARUP");
	$this->stat_depoun("DEPOUN");
	$this->stat_liucun(2, "LIUCUN2");
	$this->stat_liucun(3, "LIUCUN3");
	$this->stat_liucun(7, "LIUCUN7");
	$this->stat_acu("ACU");
	$this->stat_pcu("PCU");
	
	
	while((my $date, my $stat) = each(%$statmap))
	{
		if( $stat->save() == 0 )
		{
			printf("stat:$date save suceessfully.\n");
		}
	}
	
}

sub stat_date
{
	my $this = shift;
	my $type = shift;
	my @date_array = ();
	my $darray = $this->{'mDateArray'};
	$i = 0;
	my $datestr;
	foreach $date (@$darray)
	{
		if( $date == $this->{'mNowDate'} )
		{
			$datestr = `date -d $date +%m-%d*`;
		}
		else
		{
			$datestr = `date -d $date +%m-%d`;
		}
		chomp($datestr);
		push(@date_array, $datestr);
	}
	$statdatamap = $this->{'mStatDataMap'};
	$statdatamap->{$type} = \@date_array;
}

sub stat_regist
{
	my $this = shift;
	my $type = shift;
	my @reg_array = ();
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
		my $regnum = $stat->get_regist_usernum();
		unless( $regnum )
		{
			$regnum = 0;	
		}
		push(@reg_array, $regnum);
	}
	
	$statdatamap = $this->{'mStatDataMap'};
	$statdatamap->{$type} = \@reg_array;
}

sub stat_login
{
	my $this = shift;
	my $type = shift;
	my @login_array = ();
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
	  my $loginnum = $stat->get_login_usernum();
	  unless( $loginnum )
	  {
	  	$loginnum = 0;
	  }
		push(@login_array, $loginnum);
	} 
	$statdatamap = $this->{'mStatDataMap'};
	$statdatamap->{$type} = \@login_array;
}

#sub deposit today
sub stat_deposit
{
	my $this = shift;
	my $type = shift;
	my $deposit_array = ();
	my $datearray = $this->{'mDateArray'};
	my $statmap = $this->{'mStatPtrMap'};
	foreach $date(@$datearray)
	{
		unless( exists($statmap->{$date}) )
		{
			printf("date:$date logstat not found\n");
			next;
		} 
		
		my $stat = $statmap->{$date};
		my $total = $stat->get_deposit_total();
		unless( $total )
		{
			$total = 0;
		}
		push(@deposit_array, $total);
	}
	
	$statdatamap = $this->{'mStatDataMap'};
	$statdatamap->{$type} = \@deposit_array;
}

#sub stat all 
sub stat_depomon_recursive
{
	my $this = shift;
	my $stat = shift;
	my $date = shift;
	my $statmap = $this->{'mStatPtrMap'};
	my $num = 0;
	my $total = $stat->get_deposit_total();
	$total = 0 unless defined($total);
	my $day = substr($date, 6, 2);
	#print("$date, day:$day, total: $total\n");
	if( $day > 1 )
	{
		$date = $date - 1;
		unless( exists($statmap->{$date}) )
		{
			#print("return $date not fund\n");
			return $total;
		}
		$stat = $statmap->{$date};
		unless( exists($stat->{'mDepositMonth'}) )
		{
			$num = $total + $this->stat_depomon_recursive($stat, $date);
		}
		else
		{
			$num = $total + $stat->{'mDepositMonth'};
			#print("$date, day:$day, get exists: $num\n");
		}
		return $num;
	}
	else
	{
		#print("return total: $total\n");
		return $total;
	}
}

#sub deposit month
sub stat_depomon
{
	my $this = shift;
	my $type = shift;
	my $mon_array = ();
	my $datearray = $this->{'mDateArray'};
	my $statmap = $this->{'mStatPtrMap'};
	foreach $date(@$datearray)
	{
		unless( exists($statmap->{$date}) )
		{
			printf("date:$date logstat not found\n");
			next;
		} 
		
		my $stat = $statmap->{$date};
		my $num = $stat->{'mDepositMonth'};
		unless( $num )
		{
			#print("pmon $date not exists\n");
			$num = $this->stat_depomon_recursive($stat, $date);
			$stat->{'mDepositMonth'} = $num;
		}
		else
		{
			#print("pmon $date exists\n");
			$num = $stat->{'mDepositMonth'};
		}
		#print("push $date num:$num\n");
		push(@mon_array, $num);
	}
	
	$statdatamap = $this->{'mStatDataMap'};
	$statdatamap->{$type} = \@mon_array;
}

#sub deposit percent
sub stat_depopert
{
	my $this = shift;
	my $type = shift;
	my $perct_array = ();
	my $datearray = $this->{'mDateArray'};
	my $statmap = $this->{'mStatPtrMap'};
	foreach $date(@$datearray)
	{
		unless( exists($statmap->{$date}) )
		{
			printf("date:$date logstat not found\n");
			next;
		} 
		
		my $stat = $statmap->{$date};
		my $num = $stat->get_deposit_perct();
		push(@perct_array, $num);
	}
	
	$statdatamap = $this->{'mStatDataMap'};
	$statdatamap->{$type} = \@perct_array;
}

#sub deposit percent
sub stat_depoarup
{
	my $this = shift;
	my $type = shift;
	my $arup_array = ();
	my $datearray = $this->{'mDateArray'};
	my $statmap = $this->{'mStatPtrMap'};
	foreach $date(@$datearray)
	{
		unless( exists($statmap->{$date}) )
		{
			printf("date:$date logstat not found\n");
			next;
		} 
		
		my $stat = $statmap->{$date};
		my $num = $stat->get_deposit_arup();
		push(@arup_array, $num);
	}
	
	$statdatamap = $this->{'mStatDataMap'};
	$statdatamap->{$type} = \@arup_array;
}

#sub deposit user num
sub stat_depoun
{
	my $this = shift;
	my $type = shift;
	my $depoun_array = ();
	my $datearray = $this->{'mDateArray'};
	my $statmap = $this->{'mStatPtrMap'};
	foreach $date(@$datearray)
	{
		unless( exists($statmap->{$date}) )
		{
			printf("date:$date logstat not found\n");
			next;
		} 
		
		my $stat = $statmap->{$date};
		my $num = $stat->get_deposit_usernum();
		push(@depoun_array, $num);
	}
	
	$statdatamap = $this->{'mStatDataMap'};
	$statdatamap->{$type} = \@depoun_array;
}

sub stat_liucun
{
	my $this = shift;
	my $ndays = shift;
	my $type = shift;
	
	my $name = "mLIUCUN".$ndays;
	my @liucun_array = ();
	my $datearray = $this->{'mDateArray'};
	my $statmap = $this->{'mStatPtrMap'};
	foreach my $date(@$datearray)
	{
		my $regdate = DateWrap::get_date($date);
		my $logindate = DateWrap::get_date($date, $ndays - 1);
		my $loginstat =  $statmap->{$logindate};
		my $regstat =  $statmap->{$regdate};
		my $stat = $statmap->{$date};
		if( $stat->{$name} )
		{
			#push(@liucun_array, $stat->{$name});
			#next;
		}
		printf("liucun name:$name\n"); 
		printf("date:$date ndays:$ndays logindate:$logindate regdate:$regdate\n");
		unless( $regstat )
		{
			printf("registstat not found regdate:$regdate\n"); 
			push(@liucun_array, "NoRegData");
			next;
		}
		unless( $loginstat )
		{
			printf("loginstat not found logindate:$logindate\n"); 
			push(@liucun_array, "NoLoginData");
			next;
		}
		my $regusers = $regstat->get_regist_users();
		my $loginusers = $loginstat->get_login_users();
		#my $toregusers = $loginstat->get_regist_users();
		my $regnum = scalar(@$regusers);
		unless( $regnum )
		{
			printf("no regusers num regdate:$regdate arr:@$regusers\n"); 
			push(@liucun_array, "NoRegData");
			next;
		}
		my $loginnum = scalar(@$loginusers);
		print("statdate:$date regnum:$regnum loginnum:$loginnum\n");
		#print("logindate:$logindate @$loginusers\n");
		my $count = 0, $liushinum = 0;
		foreach my $user (@$regusers)
		{
			#print("user:$user\n");
			if( grep(/^$user$/,  @$loginusers) )
			{
			  #print("liucun_user:$user login\n");
			  $count++;
			}
			else
			{
				#print("linshi_user:$user\n");
			  $liushinum++;
			}
		}
		my $perct = 0;
		if( $regnum )
		{
			$perct = $count / $regnum * 100;
		}
		printf("regdate :$regdate regnum:$regnum count:$count,liushinum:$liushinum pecrt:$perct\n");
		my $fn = sprintf("%2.02f", $perct);
		
		$stat->{$name} = $fn;
		my $liucun = $stat->{'mLIUCUN2'};
		#print("date:$date liucun2:$liucun2\n");
		#print("$name = $fn\n");
		
		push(@liucun_array, $fn);
	}
	$statdatamap = $this->{'mStatDataMap'};
	$statdatamap->{$type} = \@liucun_array;
}

sub stat_acu
{
	my $this = shift;
	my $type = shift;
	my @array = ();
	my $datearray = $this->{'mDateArray'};
	my $statmap = $this->{'mStatPtrMap'};
	foreach $date(@$datearray)
	{
		my $stat = $statmap->{$date};
		my $acu = $stat->get_acu();
		push(@array, $acu);
	}
	
	$statdatamap = $this->{'mStatDataMap'};
	$statdatamap->{$type} = \@array;
}

sub stat_pcu
{
	my $this = shift;	
	my $type = shift;
	my @array = ();
	my $datearray = $this->{'mDateArray'};
	my $statmap = $this->{'mStatPtrMap'};
	foreach $date(@$datearray)
	{
		my $stat = $statmap->{$date};
		my $pcu = $stat->get_pcu();
		unless ($pcu)
		{
			$pcu = 0;
		}
		push(@array, $pcu);
	}
	
	$statdatamap = $this->{'mStatDataMap'};
	$statdatamap->{$type} = \@array;
}


1;#end of the file