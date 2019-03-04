		package ServerStat;

use LogStat;
#	stat the data from log file

#	===========	#need member data
#	mDate		#the log date
#	mLogTable	#a array that save other entrys(table address)
#	mIsLoaded	#has loaded
#	mLogHash	#a hash table that saved typed entrys by key=type, value = address of entrys 

#construct function
sub new
{
	my $class = shift;	#need class name
	my $date = shift;		#date
	my $filter = shift;
	
	my $this = {};			#a new hash reference
	
	#member data
	
	unless ( $filter )
	{
		$filter = "all";
	}
	
	$this->{'mDate'} = $date;
	$this->{'mFilter'} = $filter;
	
	bless $this, $class;
	
	return $this;
}

#load funciton init
sub load
{
	my $this = shift;
	my $serverdirgroup = shift;
	my $totalnum = scalar(@$serverdirgroup);
	my $date = $this->{'mDate'};
	my $filter = $this->{'mFilter'};
	my $serverid = "serverid";
	my $servernum = 0;
	
		my $regist_usernum = 0;
		my $login_usernum = 0;
		my $liucun_2 = 0;
		my $liucun_3 = 0;
		my $liucun_7 = 0;
		
		my $deposit_total = 0;
		my $deposit_month = 0;
		my $deposit_perct = 0;
		my $deposit_arup = 0;
		my $deposit_usernum = 0;
		my $deposit_count = 0;
		
		my $acu = 0;
		my $pcu = 0;
	
	my $statfilename;
	my $idstr;
	my $isserver = $filter =~ /server/i;
	$this->{'mLastServerID'} = "";
	#printf("stat date:$date\n");
	foreach my $serverdir( @$serverdirgroup )
	{
		unless( -d $serverdir )
		{
			next;
		}
		#printf("loadserverdir:$serverdir\n");
		my $stat = new LogStat($date);
		$statfilename = $serverdir . "/" . $date . ".stat"; #all stat item
		
		unless( $filter =~ /^all$/ )
		{
			$serveridfile = $serverdir . "/" . $serverid; 			#all serveridfile
			$idstr = "";
			if( -e $serveridfile )
			{
				$idstr = `cat $serveridfile`;
				if( $idstr =~ /serverid\s*=\s*(\S+)/i )
				{
					$idstr = $1;
				}
			}
			$this->{'mLastServerID'} = $idstr;
			#printf("filter:$filter idstr:$idstr\n");
			unless( $isserver or $idstr =~ /^$filter/i )
			{
				next;
			}
			#printf("get:$filter\n");
		}
		
		unless( -e $statfilename )
		{
			#print(" $statfilename not exists.\n");
			next;
		}
		if( $stat->loadstatfile($statfilename) != 0 )
		{
			print("stat->loadstatfile $statfilename failed\n");
			return -1;
		}
		
		$servernum++;
		$regist_usernum += $stat->get_regist_usernum();
		$login_usernum += $stat->get_login_usernum();
		
		$liucun_2 += $stat->{'mLIUCUN2'};
		$liucun_3 += $stat->{'mLIUCUN3'};
		$liucun_7 += $stat->{'mLIUCUN7'};
		
		$deposit_total += $stat->get_deposit_total();
		$deposit_month += $stat->get_deposit_month();
		$deposit_perct += $stat->get_deposit_perct();
		$deposit_arup += $stat->get_deposit_arup();
		$deposit_usernum += $stat->get_deposit_usernum();
		$deposit_count += $stat->get_deposit_count();
		
		$acu += $stat->get_acu();
		$pcu += $stat->get_pcu();
	}
	
	#printf("servernum:$servernum deposit:$deposit_total\n");
	if( $servernum == 0 )
	{
		$liucun_2 = 0;
		$liucun_3 = 0;
		$liucun_7 = 0;
		$deposit_perct = 0;
		$deposit_arup = 0;
	}
	else
	{
		$liucun_2 = sprintf("%.2f", $liucun_2 / $servernum);
		$liucun_3 = sprintf("%.2f", $liucun_3 / $servernum);
		$liucun_7 = sprintf("%.2f", $liucun_7 / $servernum);
		$deposit_perct = sprintf("%.2f", $deposit_perct / $servernum);
		$deposit_arup = sprintf("%d", $deposit_arup / $servernum);
	}
	
	if( $deposit_usernum )
	{
		$deposit_arup = sprintf("%d", $deposit_total / $deposit_usernum);	
	}
	
	if( $login_usernum )
	{
		$deposit_perct = sprintf("%.2f", $deposit_usernum / $login_usernum * 100.0);
	} 
	
	$this->{'mServerNum'} = $servernum;
	$this->{'mRegistUserNum'} = $regist_usernum;
	$this->{'mLoginUserNum'} = $login_usernum;
	$this->{'mLIUCUN2'} = $liucun_2;
	$this->{'mLIUCUN3'} = $liucun_3;
	$this->{'mLIUCUN7'} = $liucun_7;
	$this->{'mDepositTotal'} = $deposit_total;
	$this->{'mDepositMonth'} = $deposit_month;
	$this->{'mDepositPerct'} = $deposit_perct;
	$this->{'mDepositArup'} = $deposit_arup;
	$this->{'mDepositUserNum'} = $deposit_usernum;
	$this->{'mDepositCount'} = $deposit_count;
	
	$this->{'mAcu'} = $acu;
	$this->{'mPcu'} = $pcu;
	
	return 0;
}

sub loadfromcache
{
	my $this = shift;
	my $cachedir = shift;
	my $filter = $this->{'mFilter'};
	unless($cachedir)
	{
		print("cachedir $cachedir is null.\n");
		return -1;
	}
	
	#printf("cachedir:$cachedir\n");
	
	my $date = $this->{'mDate'};
	my $nowdate = `date +%Y%m%d`;
	unless( $date < $nowdate )
	{
		print("date:$date is today:$nowdate, don't load from cache.\n");
		return 0;
	}
	
	my $statfile = $date . ".stat"; #all stat item

	if( $filter )
	{
		$statfile .= "_$filter";
	}
	

	my $success = 1;
	
	my $nowdir = `pwd`;
	chomp($nowdir);
	chdir($cachedir);
	if( -e $statfile )
	{
		unless( open(FILE, "$statfile") )
		{
			print("load open statfile:$statfile failed $!.\n");
			chdir($nowdir);
			return -1;
		}
		
		# stat regist_usernum|login_usernum|deposit_usernum|deposit_total|deposit_count|acu|pcu
		my $line;
		while( $line = <FILE> )
		{
			if( $line =~ /RegistUserNum\s*=\s*(\S+)/i )
			{
				$this->{'mRegistUserNum'} = $1;
			}
			elsif($line =~ /LoginUserNum\s*=\s*(\S+)/i)
			{
				$this->{'mLoginUserNum'} = $1;
			}
			elsif($line =~ /DepositUserNum\s*=\s*(\S+)/i)
			{
				$this->{'mDepositUserNum'} = $1;
			}
			elsif($line =~ /DepositTotal\s*=\s*(\S+)/i)
			{
				$this->{'mDepositTotal'} = $1;
			}
			elsif($line =~ /DepositMonth\s*=\s*(\S+)/i)
			{
				$this->{'mDepositMonth'} = $1;
			}
			elsif($line =~ /DepositPerct\s*=\s*(\S+)/i)
			{
				$this->{'mDepositPerct'} = $1;
			}
			elsif($line =~ /DepositArup\s*=\s*(\S+)/i)
			{
				$this->{'mDepositArup'} = $1;
			}
			elsif($line =~ /DepositUserNum\s*=\s*(\S+)/i)
			{
				$this->{'mDepositUserNum'} = $1;
			}
			elsif($line =~ /DepositCount\s*=\s*(\S+)/i)
			{
				$this->{'mDepositCount'} = $1;
			}
			elsif($line =~ /ACU\s*=\s*(\S+)/i)
			{
				$this->{'mAcu'} = $1;
			}
			elsif($line =~ /PCU\s*=\s*(\S+)/i)
			{
				$this->{'mPcu'} = $1;
			}
			elsif($line =~ /Liucun2\s*=\s*(\S+)/i)
			{
				$this->{'mLIUCUN2'} = $1;
			}
			elsif($line =~ /Liucun3\s*=\s*(\S+)/i)
			{
				$this->{'mLIUCUN3'} = $1;
			}
			elsif($line =~ /Liucun7\s*=\s*(\S+)/i)
			{
				$this->{'mLIUCUN7'} = $1;
			}
		}
		close(FILE);
	}
	else
	{
		printf("load statfile:$statfile not exists.\n");
		$success = 0;
	}
	
	if( $success )
	{ 
		$this->{'mIsFromCache'} = 1;
	}
	
	chdir($nowdir);
	
	return 0;
}

##cache the stat entry to cache
sub savetocache
{
	my $this = shift;
	my $cachedir = shift;
	my $filter = $this->{'mFilter'};
	my $date = $this->{'mDate'};
	my $nowdate = `date +%Y%m%d`;
	unless( $date < $nowdate )
	{
		print("date:$date is today:$nowdate, don't save to cache.\n");
		return 0;
	}
	
	unless( -d -e $cachedir)
	{
		print("cachedir:$cachedir not exist.\n");
		return -1;
	}

	my $statfile = $date . ".stat"; #all stat item
	if( $filter )
	{
		$statfile .= "_$filter";
	}
	
	my $nowdir = `pwd`;
	chomp($nowdir);
	#printf("cachedir:$cachedir\n");
	chdir($cachedir);
	
	
	#write stat if it not exist
	unless( -e $statfile )
	{
		unless( open(FILE, ">$statfile") )
		{
			print("open statfile:$statfile failed. $!\n");
			chdir($nowdir);
			return -1;
		}
		
		# stat regist_usernum|login_usernum|deposit_usernum|deposit_total|deposit_count|acu|pcu
		
		my $regist_usernum = $this->get_regist_usernum();
		my $login_usernum = $this->get_login_usernum();
		my $liucun_2 = $this->{'mLIUCUN2'};
		my $liucun_3 = $this->{'mLIUCUN3'};
		my $liucun_7 = $this->{'mLIUCUN7'};
		
		my $deposit_total = $this->get_deposit_total();
		my $deposit_month = $this->get_deposit_month();
		my $deposit_perct = $this->get_deposit_perct();
		my $deposit_arup = $this->get_deposit_arup();
		my $deposit_usernum = $this->get_deposit_usernum();
		my $deposit_count = $this->get_deposit_count();
		
		my $acu = $this->get_acu();
		my $pcu = $this->get_pcu();
		my $pcu = $this->get_pcu();
		
		printf FILE ("RegistUserNum = %d\n", $regist_usernum);
		printf FILE ("LoginUserNum = %d\n", $login_usernum);
		printf FILE ("Liucun2 = %d\n", $liucun_2);
		printf FILE ("Liucun3 = %d\n", $liucun_3);
		printf FILE ("Liucun7 = %d\n", $liucun_7);
		printf FILE ("DepositTotal = %d\n", $deposit_total);
		printf FILE ("DepositMonth = %d\n", $deposit_month);
		printf FILE ("DepositPerct = %d\n", $deposit_perct);
		printf FILE ("DepositArup = %d\n", $deposit_arup);
		printf FILE ("DepositUserNum = %d\n", $deposit_usernum);
		printf FILE ("DepositCount = %d\n", $deposit_count);
		printf FILE ("ACU = %d\n", $acu);
		printf FILE ("PCU = %d\n", $pcu);
		close(FILE);
	}
	else
	{
		#printf("statfile:$statfile has exists.\n");
	}
	
	chdir($nowdir);
		
	return 0;
}


#show debug info of the stat log
sub debug
{
	my $this = shift;
	printf("Hi, this is ServerStat for Gu Long, Server Num:%d\n", $this->{'mServerNum'});
	printf("**ServerStat**\n");
		my $regist_usernum = $this->get_regist_usernum();
		my $login_usernum = $this->get_login_usernum();
		my $liucun_2 = $this->{'mLIUCUN2'};
		my $liucun_3 = $this->{'mLIUCUN3'};
		my $liucun_7 = $this->{'mLIUCUN7'};
		
		my $deposit_total = $this->get_deposit_total();
		my $deposit_month = $this->get_deposit_month();
		my $deposit_perct = $this->get_deposit_perct();
		my $deposit_arup = $this->get_deposit_arup();
		my $deposit_usernum = $this->get_deposit_usernum();
		my $deposit_count = $this->get_deposit_count();
		
		my $acu = $this->get_acu();
		my $pcu = $this->get_pcu();
		my $pcu = $this->get_pcu();
		
		printf ("RegistUserNum = %d\n", $regist_usernum);
		printf ("LoginUserNum = %d\n", $login_usernum);
		printf ("Liucun2 = %d\n", $liucun_2);
		printf ("Liucun3 = %d\n", $liucun_3);
		printf ("Liucun7 = %d\n", $liucun_7);
		printf ("DepositTotal = %d\n", $deposit_total);
		printf ("DepositMonth = %d\n", $deposit_month);
		printf ("DepositPerct = %d\n", $deposit_perct);
		printf ("DepositArup = %d\n", $deposit_arup);
		printf ("DepositUserNum = %d\n", $deposit_usernum);
		printf ("DepositCount = %d\n", $deposit_count);
		printf ("ACU = %d\n", $acu);
		printf ("PCU = %d\n", $pcu);
		
}


#sub get_servernum int
sub get_servernum
{
	my $this = shift;
	return $this->{'mServerNum'};
}

#sub get_regist_user_num int
sub get_regist_usernum
{
	my $this = shift;
	return $this->{'mRegistUserNum'};
}

#sub get_login_user_num int
sub get_login_usernum
{
	my $this = shift;
	return $this->{'mLoginUserNum'};
}

#get deposit users in int
sub get_deposit_usernum
{
		my $this = shift;
		return $this->{'mDepositUserNum'};
}

#get deposit total amount in int 
sub get_deposit_total
{
		my $this = shift;
		return $this->{'mDepositTotal'};
}

#get deposit times in int 
sub get_deposit_count
{
		my $this = shift;
		return $this->{'mDepositCount'};
}

#get deposit total in one month in int
sub get_deposit_month
{
		my $this = shift;
		return $this->{'mDepositMonth'};
}

#get deposit user perct in in int
sub get_deposit_perct
{
		my $this = shift;
		return $this->{'mDepositPerct'};
}

#get deposit arup (amount per user) in in int
sub get_deposit_arup
{
		my $this = shift;
		return $this->{'mDepositArup'};
}

#get online average user num
sub get_acu
{
	my $this = shift;
	return $this->{'mAcu'};
}	

#get online top user num
sub get_pcu
{
	my $this = shift;
	return $this->{'mPcu'};
}


1;#end of the file
