		package LogStat;
#require Exporter;
#@ISA = qw (ExPorter);
#@EXPORT = qw (load);
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
	my $date = shift;	#date
	my $this = {};		#a new hash reference
	
	#member data
	my @logtable = ();
	my %loghash = ();
	my @miss = ();
	$this->{'mDate'} = $date;
	$this->{'mLogTable'} = \@logtable;
	$this->{'mIsLoaded'} = 0;
	$this->{'mLogHash'} = \%loghash;
	$this->{'mMissFileHour'} = \@miss;
	$this->{'mTypeIndex'} = 4;
	$this->{'mUserIndex'} = $this->{'mTypeIndex'} + 1;
	bless $this, $class;	
	
	
	#printf("new stat mFileName:$this->{'mFileName'}, 
	#	mLogTable:$this->{'mLogTable'}, 
	#	mIsLoaded:$this->{'mIsLoaded'}
	#	mLogHash:$this->{'mLogHash'}\n");
	
	return $this;
}

#load funciton init the log entrys
sub load
{
	my $this = shift;
	my $ingorecache = shift;
	
	if( $this->isenablecache() )
	{
		if( not $ingorecache and $this->loadfromcache($this->{'mCacheDir'}) != 0 )
		{
			printf("no cache, try to load from log files.\n");
		}
		elsif ( $this->{'mIsFromCache'} )
		{
			printf("load from cache successfully.\n");
			return 0;
		}  	
	}
	
	my $nowdir = `pwd`;
	chomp($nowdir);
	if( exists($this->{'mLogDir'}) )
	{
		my $logdir = $this->{'mLogDir'};
		#printf("logdir:$logdir\n");
		chdir($logdir);
	}
	
	my $i = 0;
	my $missarr = $this->{'mMissFileHour'};
	printf("--------loading:$this->{'mDate'}-----------\n");
	my $readcount = 0;
	for( $i = 0; $i < 24; $i++ )
	{
		if( exists($this->{'mReferHour'}) and $this->{'mReferHour'} != $i )
		{
			next;
		}
		my $filename = $this->get_log_filename($i);
		unless( -e $filename )
		{
			#printf("file:$filename not exist. next\n");
			push(@$missarr, $i);
			next;
		}	
		if( $this->loadfile($filename) != 0 )
		{
			chdir($nowdir);
			printf("loadfile:$filename error\n");
			return -1;
		}
		$readcount++;
	}
	
	if( scalar(@$missarr) > 0 )
	{
		printf("MissFileHours:@$missarr\n");
	}
	else
	{
		printf("Read $readcount Hours.\n");
	}
	

	chdir($nowdir);

	return 0;
}

#load clean the cache entrys
sub clean
{
	my $this = shift;
	
	unless( $this->isenablecache() )
	{
		return;
	}
	my $cachedir = $this->{'mCacheDir'};
	unless($cachedir)
	{
		print("cachedir $cachedir is null.\n");
		return;
	}

	my $date = $this->{'mDate'};
	my $nowdate = `date +%Y%m%d`;
	unless( $date < $nowdate )
	{
		print("date:$date is today:$nowdate, don't load from cache.\n");
		return 0;
	}
	
	my $statfile = $date . ".stat"; #all stat item
	my $regfile = $date . ".regist_u"; #_u means users
	my $loginfile = $date . ".login_u"; # _u means users
	my $depositfile = $date . ".deposit_u"; # _u means usrs
	
	my $nowdir = `pwd`;
	chomp($nowdir);
	chdir($cachedir);
	if( -e $statfile )
	{
		unlink($statfile);
	}
	if( -e $regfile )
	{
		unlink($regfile);
	}
	if( -e $loginfile )
	{
		unlink($loginfile);
	}
	if( -e $depositfile )
	{
		unlink($depositfile);
	}
	chdir($nowdir);

	return 0;
}


sub loadfile()
{
	my $this = shift;
	my $filename = shift;
	
  unless( open(FILE, $filename) )
  {
  	#printf("open file:%s failed $!.\n", $filename);
    return -1;        
	}
	
	#unless( open(MIROFILE, ">$filename.miro") )
  #{
  	#printf("open filename:%s failed $!.\n", $filename.".miro");
    #return -1;
	#}
	
	#printf("logtable:$this->{'mLogTable'}\n");
	
	my $stattypes = $this->{'mStatTypes'};
	my $typeidx = $this->{'mTypeIndex'};
	my $type;
  my $logtable_ptr = $this->{'mLogTable'};
  my $count = 0;
  while( $line = <FILE> )
 	{
    my @arr = split(/\|/, $line);
  	#printf("@arr");
  	$type = $arr[$typeidx];
  
  	unless( !defined($stattypes) || grep(/^$type$/, @$stattypes) )
  	{
  		next;
  	}
  	
		push(@$logtable_ptr, \@arr);
		#print MIROFILE ("@arr");
		$count++;
  }

  #printf("table:$this->{'mLogTable'}, arr:$arr arr:*$arr\n");
  my $i = scalar(@$logtable_ptr);
  printf("file:$filename readcount:$count totalcount:$i\n");

  $this->{'mIsLoaded'} = 1;

  close(FILE);

  return 0;
}

sub save()
{
	my $this = shift;
	my $cachedir = $this->{'mCacheDir'};
	unless( -d -e $cachedir )
	{
		mkdir($cachedir);
	}
	$this->savestatfile($cachedir);
	if( $this->{'mIsFromCache'} )
	{
		printf("save to cache exists.\n");
		return 0;
	}
	unless( $this->{'mCacheEnable'} )
	{
		printf("not enable cache.\n");
		return -1;
	}
	
	if( $this->savetocache($cachedir) != 0 )
	{
		printf("save to cache failed\n");
		return -1;
	}
	return 0;
}

sub isenablecache
{
	my $this = shift;
	my $filename = "statconf";
	unless( -e $filename )
	{
		print("config file:$filename not exits, default not use cache.\n");
		return 0;
	}
	unless( open(FILE, $filename) )
	{
		print("open conf file:$filename failed, $!\n");
		return 0;
	} 
	my $line;
	while( $line = <FILE> )
	{
		if( $line =~ /enablecache\s*=\s*(\w+)/i )
		{
			$this->{'mCacheEnable'} = $1;
		}
		elsif( $line =~ /cachedir\s*=\s*([\/.\w]+)/i )
		{
			$this->{'mCacheDir'} = $1;
		}
		elsif($line =~ /logdir\s*=\s*([\/.\w]+)/i)
		{
			$this->{'mLogDir'} = $1;
		}
	}
	#printf("is cache enbale:%d", $this->{'mCacheEnable'});
	if( $this->{'mCacheEnable'} )
	{
		unless( $this->{'mCacheDir'} )
		{
			$this->{'mCacheDir'} = "./cache";
		}
		#printf(" , cache dir:%s", $this->{'mCacheDir'});
	}
	
	#print("\n");
	return $this->{'mCacheEnable'};
}

sub loadfromcache
{
	my $this = shift;
	my $cachedir = shift;
	
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
	
	my $success = 1;
	my $statfile = $cachedir . "/" . $date . ".stat"; #all stat item
	
	unless( -e $statfile )
	{
		return -1;
	}
	elsif( $this->loadstatfile($statfile) != 0 )
	{
		print("loadstatfile :$statfile failed.\n");
		$success = 0;
	} 
	
	my $regfile = $date . ".regist_u"; #_u means users
	my $loginfile = $date . ".login_u"; # _u means users
	my $depositfile = $date . ".deposit_u"; # _u means usrs
	
	my $nowdir = `pwd`;
	chomp($nowdir);
	chdir($cachedir);
	
	#load regist table info
	if( -e $regfile )
	{
		unless( open(FILE, "$regfile") )
		{
			print("load open regfile:$regfile failed. $!\n");
			chdir($nowdir);
			return -1;
		}
		my $line;
		my @entry_arr;
		while( $line = <FILE> )
		{
			unless($line)
			{
				next;
			}
			chomp($line);
			push(@entry_arr, $line) if $line;
		}
		$this->{'mRegistUsers'} = \@entry_arr;
		close(FILE);
		printf("date:$date load from cache exists.\n");
	}
	else
	{
		printf("regfile:$regfile not exists.\n");
		$success = 0;
	}
	
	#write login_users info
	if( -e $loginfile )
	{
		unless( open(FILE, "$loginfile") )
		{
			print("load open loginfile:$loginfile failed. $!\n");
			chdir($nowdir);
			return -1;
		}
		my $line;
		my @entry_arr;
		while( $line = <FILE> )
		{
			unless($line)
			{
				next;
			}
			chomp($line);
			push(@entry_arr, $line) if $line;
		}
		$this->{'mLoginUsers'} = \@entry_arr;
		close(FILE);
	}
	else
	{
		printf("loginfile:$loginfile not exists.\n");
		$success = 0;
	}
	
	#write login_users info
	if( -e $depositfile )
	{
		unless( open(FILE, "$depositfile") )
		{
			print("load open depositfile:$depositfile failed. $!\n");
			chdir($nowdir);
			return -1;
		}
		my $line;
		my @entry_arr;
		while( $line = <FILE> )
		{
			unless($line)
			{
				next;
			}
			chomp($line);
			push(@entry_arr, $line) if $line;
		}
		$this->{'mDepositUsers'} = \@entry_arr;
		close(FILE);
	}
	else
	{
		printf("depositfile:$depositfile not exists.\n");
		$success = 0;
	}
	
	if( $success )
	{ 
		$this->{'mIsFromCache'} = 1;
	}
	chdir($nowdir);
	
	return 0;
}

sub loadstatfile
{
	my $this = shift;
	my $statfile = shift;
	
	unless( open(FILE, "$statfile") )
	{
		print("load open statfile:$statfile failed $!.\n");
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
	return 0;
}
##cache the stat entry to cache
sub savetocache
{
	my $this = shift;
	my $cachedir = shift;
	
	my $date = $this->{'mDate'};
	my $nowdate = `date +%Y%m%d`;
	unless( $date < $nowdate )
	{
		print("date:$date is today:$nowdate, don't save to cache.\n");
		return 0;
	}
	unless($cachedir)
	{
		print("cachedir:$cachedir not exist.\n");
		return -1;
	}
	
	my $regfile = $date . ".regist_u";
	my $loginfile = $date . ".login_u"; # means filter
	my $depositfile = $date . ".deposit_u"; # means filter

	my $nowdir = `pwd`;
	chomp($nowdir);
	#printf("cachedir:$cachedir\n");
	chdir($cachedir);
	
	#write regist table info
	unless( -e $regfile )
	{
		unless( open(FILE, ">$regfile") )
		{
			print("open regfile:$regfile failed. $!\n");
			chdir($nowdir);
			return -1;
		}
		my $reg_users = $this->get_regist_users();
		#print "reg_users:@$reg_users";
		foreach my $user(@$reg_users)
		{
			print FILE ("$user\n");
		}
		close(FILE);
	}
	else
	{
		#printf("regfile:$regfile has exists.\n");
	}
	
	#write login_users info
	unless( -e $loginfile )
	{
		unless( open(FILE, ">$loginfile") )
		{
			print("open loginfile:$loginfile failed. $!\n");
			chdir($nowdir);
			return -1;
		}
		my $login_users = $this->get_login_users();
		foreach $user(@$login_users)
		{
			print FILE ("$user\n");
		}
		close(FILE);
	}
	else
	{
		#printf("loginfile:$loginfile has exists.\n");
	}
	
	#write login_users info
	unless( -e $depositfile )
	{
		unless( open(FILE, ">$depositfile") )
		{
			print("open depositfile:$depositfile failed. $!\n");
			chdir($nowdir);
			return -1;
		}
		my $deposit_users = $this->get_deposit_users();
		foreach $user(@$deposit_users)
		{
			print FILE ("$user\n");
		}
		close(FILE);
	}
	else
	{
		#printf("depositfile:$depositfile has exists.\n");
	}
	
	chdir($nowdir);
		
	return 0;
}

sub savestatfile
{
	#write stat if it not exist
	my $this = shift;
	my $cachedir = shift;
	
	my $date = $this->{'mDate'};
	my $nowdate = `date +%Y%m%d`;
	#unless( $date < $nowdate )
	#{
		#print("date:$date is today:$nowdate, don't save to cache.\n");
		#return 0;
	#}
	unless($cachedir)
	{
		print("cachedir:$cachedir not exist.\n");
		return -1;
	}

	my $statfile = $date . ".stat"; #all stat item

	my $nowdir = `pwd`;
	chomp($nowdir);
	#printf("cachedir:$cachedir\n");
	chdir($cachedir);
	
	unless( 0 )
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
		
		my $deposit_total = $this->get_deposit_total();
		my $deposit_month = $this->get_deposit_month();
		my $deposit_perct = $this->get_deposit_perct();
		my $deposit_arup = $this->get_deposit_arup();
		my $deposit_usernum = $this->get_deposit_usernum();
		my $deposit_count = $this->get_deposit_count();
		
		my $acu = $this->get_acu();
		my $pcu = $this->get_pcu();
		
		my $liucun_2 = $this->{'mLIUCUN2'} ? $this->{'mLIUCUN2'}: 0;
		my $liucun_3 = $this->{'mLIUCUN3'} ? $this->{'mLIUCUN3'}: 0;
		my $liucun_7 = $this->{'mLIUCUN7'} ? $this->{'mLIUCUN7'}: 0;
		#print("date:$date liucun_2:$liucun_2\n");
		
		printf FILE ("RegistUserNum = %d\n", $regist_usernum);
		printf FILE ("LoginUserNum = %d\n", $login_usernum);
		printf FILE ("Liucun2 = %.02f\n", $liucun_2);
		printf FILE ("Liucun3 = %.02f\n", $liucun_3);
		printf FILE ("Liucun7 = %.02f\n", $liucun_7);
		printf FILE ("DepositTotal = %d\n", $deposit_total);
		printf FILE ("DepositMonth = %d\n", $deposit_month);
		printf FILE ("DepositPerct = %2.02f\n", $deposit_perct);
		printf FILE ("DepositArup = %d\n", $deposit_arup);
		printf FILE ("DepositUserNum = %d\n", $deposit_usernum);
		printf FILE ("DepositCount = %d\n", $deposit_count);
		printf FILE ("ACU = %d\n", $acu);
		printf FILE ("PCU = %d\n", $pcu);
		close(FILE);
		
		#printf("save statfile:$statfile successful.\n");
	}
	else
	{
		printf("save statfile:$statfile failed.\n");
	}
	
	chdir($nowdir);
}

#show debug info of the stat log
sub debug
{
	my $this = shift;
	printf("Hi, this is LogStat for Gu Long\n");
	printf("**LogTable**\n");
	my $arr = $this->{'mLogTable'};
	#printf("@$arr\n");
	my $i = 0;
	foreach (@$arr)
	{
		my $subt = @$arr[$i++];
		#print("@$subt");
	}

	printf("**LogHash**\n");
	my $hashp = $this->{'mLogHash'};
	while ( ($type, $arrp) = each(%$hashp) )
	{
		$i = 0;
		foreach(@$arrp)
		{
			my $ss = @$arrp[$i++];
			printf("$type => @$ss");
		}
		#printf("$type => @$arrp\n");
	}
}	

#stat the entrys
sub stat
{
	my $this = shift;
	my $arr = $this->{'mLogTable'};
	my $typeidx = $this->{'mTypeIndex'};
	my $hasharray = $this->{'mLogHash'};
	#print("hasharry:$hasharray\n");
	my $subt, my $tb, my $type;
	foreach $subt (@$arr)
	{
		$type = @$subt[$typeidx];
		unless( exists($hasharray->{$type}) ) #not exist create typed array
		{
			my @newarr = ();
			$hasharray->{$type} = \@newarr; #array pointer
			#my $temp = \$hasharray->{$type};
			#printf("hasharray->type:$hasharray->{$type} addr:$temp\n");
			$tb = \@newarr;
		}
		else
		{
			$tb = $hasharray->{$type};
		}
		push(@$tb, $subt); #add entry to typed array
		#printf("tb:$tb subt:$subt, type:$type result:$result\n");
	}
}

#show typed table (type:string)
sub show_typed_table
{
	my $this = shift;
	my $type = shift;
	my $hashtb = $this->{'mLogHash'};
	if( !exists($hashtb->{$type}) )
	{
		printf("no type:$type table\n");
		return;
	}
	
	printf("---[$type] table---\n");
	my $arrp = $hashtb->{$type};
	my $i = 0;
	foreach(@$arrp)
	{
		my $ss = @$arrp[$i++];
		print("@$ss");
	}	

}

#get log filename
sub get_log_filename
{
	my $this = shift;
	my $hour = shift;

	my $time = sprintf("%s%02d.log", $this->{'mDate'}, $hour);
	return $time;
}


#a lot of function to stat data

#get typed table, in array[(record entry) point][...]
sub get_typed_table
{
	my $this = shift;
	my $type = shift;
	my $hashtb = $this->{'mLogHash'};
	unless( exists($hashtb->{$type}) )
	{
		my @arr = ();
		$hashtb->{$type} = \@arrmap;
	}
	return $hashtb->{$type};
}

#get regist table, in array[(record entry) point][...]
sub get_regist_table
{
	my $this = shift;
	my $regtb = $this->get_typed_table("REGIST");
	
	unless( $regtb )
	{
		return;	
	}
	return $regtb;
}

#sub get_regist_users int array(user1,user2...)
sub get_regist_users
{
	my $this = shift;
	my $date = $this->{'mDate'};
	my $users =  $this->{'mRegistUsers'};
	#printf("date:$date $users users:@$users\n");
	unless( $this->{'mRegistUsers'} )
	{
		my $regtb = $this->get_regist_table();
		my @array = ();
		my $user;
		foreach $item(@$regtb)
		{
			$user = @$item[$this->{'mUserIndex'}];
			if( &is_user_name($user) )
			{
				push(@array, $user);
			}
			else
			{
				print("invalid user:$user\n");
			}
		}
		$this->{'mRegistUsers'} = \@array;
	}
	return $this->{'mRegistUsers'};
}

#sub get_regist_usermap, in map:user -> array(record entry) point
sub get_regist_usermap
{
	my $this = shift;
	unless ( $this->{'mRegistUserMap'} )
	{
		my $regtb = $this->get_regist_table();
		my $nameidx = $this->{'mUserIndex'};
		my $dt = &distinct_table($regtb, $nameidx);
		$this->{'mRegistUserMap'} = $dt;
	}
	return $this->{'mRegistUserMap'};
}

#sub get_regist_user_num int
sub get_regist_usernum
{
	my $this = shift;
	unless( exists($this->{'mRegistUserNum'}) )
	{
		my $users_ptr = $this->get_regist_users();
		$this->{'mRegistUserNum'} = scalar(@$users_ptr);
	}
	return $this->{'mRegistUserNum'};
}

#get login table(need filter), in array[(record entry) point][...]
sub get_login_table
{
	my $this = shift;
	my $needfilter;
	if( @_ >= 1 )
	{
		$needfilter = shift;	
	} 
	my $logintb;
	#filter
	if( $needfilter )
	{	
		$logintb = $this->get_login_usermap();
		my @arr = values %$logintb;
		#printf("my @arr\n");
		$logintb = \@arr;
	}
	else
	{
		$logintb = $this->get_typed_table("LOGIN"); 
	}

	return $logintb;
}

#get login users in map:user -> array(record entry) point
sub get_login_usermap
{
	my $this = shift;
	unless ( $this->{'mLoginUserMap'} )
	{
		my $logintb = $this->get_typed_table("LOGIN");
		my $nameidx = $this->{'mUserIndex'};
		my $dt = &distinct_table($logintb, $nameidx);
		#while( ($key,$val) = each(%$dt) )
		#{
				#print("$key -> $val\n");
		#}
		$this->{'mLoginUserMap'} = $dt;
	}
	return $this->{'mLoginUserMap'};
}

#get login users in array(user1,user2...)
sub get_login_users
{
	my $this = shift;
	unless( $this->{'mLoginUsers'} )
	{
		my @array = ();
		my $user;
		my $logintb = $this->get_login_table(1);
		foreach $item(@$logintb)
		{
			$user = @$item[$this->{'mUserIndex'}];
			if( &is_user_name($user) )
			{
				push(@array, $user);
			}
			else
			{
				print("invalid user:$user\n");
			}
		}
	
		$this->{'mLoginUsers'} = \@array;
	}
	return $this->{'mLoginUsers'};
}

#sub get_login_user_num int
sub get_login_usernum
{
	my $this = shift;
	unless( exists($this->{'mLoginUserNum'}) )
	{
		my %tempmap = ();
		my $users_ptr = $this->get_login_users();
		my $regists_ptr = $this->get_regist_users();
		#my $loginnum = scalar(@$users_ptr);
		#my $regnum = scalar(@$regists_ptr);
		foreach my $user( @$users_ptr )
		{
			$tempmap{$user} = 1;
		}
		
		foreach my $user( @$regists_ptr )
		{
				$tempmap{$user} = 1;	
		}
		
		my $usernum = keys %tempmap;
		#print("usernum:$usernum loginnum:$loginnum regnum:$regnum\n");
		$this->{'mLoginUserNum'} = scalar($usernum);
		#$this->{'mLoginUserNum'} = scalar(@$users_ptr);
	}
	return $this->{'mLoginUserNum'};
}


#get login users in map:user->$level
sub get_login_user_levels
{
	my $this = shift;
	unless( $this->{'mLoginUserLevels'} )
	{
		my %usermap;
		my $logintb = $this->get_login_table(1);
		my $user, my $level;
		foreach $item(@$logintb)
		{
			$user = @$item[$this->{'mUserIndex'}];
			unless( &is_user_name($user) )
			{
				next;
			}
			$level = @$item[$this->{'mUserIndex'} + 3];
			chomp($level);
			#print("get user:$user level:$level\n");
			$usermap{$user} = $level;
		}
		$this->{'mLoginUserLevels'} = \%usermap;
	}
	return $this->{'mLoginUserLevels'};
}

#get login users in map:user->$level
sub get_all_user_levels
{
	my $this = shift;
	
	unless( $this->{'mAllUserLevels'} )
	{
		my $usermap = $this->get_login_user_levels();
		my %newmap = %$usermap;
		my $user, my $level;
		
		my $registmap = $this->get_regist_users();
		foreach my $user(@$registmap)
		{
			unless( exists($newmap{$user}) )
			{
				#print("resg user:$user to $level\n");
				$newmap{$user} = 1;
			}
		}
		
		my $leveluptb = $this->get_typed_table("LEVEL_UP");
		foreach $item(@$leveluptb)
		{
			$user = @$item[$this->{'mUserIndex'}];
			unless( &is_user_name($user) )
			{
				next;
			}
			$level = @$item[$this->{'mUserIndex'} + 2];
			chomp($level);
			#print("get user:$user level:$level\n");
			if( exists($newmap{$user}) )
			{
				if( $newmap{$user} < $level )
				{
					#print("set user:$user to $level\n");
					$newmap{$user} = $level;
				}
			}
			else
			{
				$newmap{$user} = $level;
				#print("not  user:$user to $level\n");
			}
		}
		
		$this->{'mAllUserLevels'} = \%newmap;
	}
	return $this->{'mAllUserLevels'};
}	

#get deposit table, in array[(record entry) point][...]
sub get_deposit_table
{
	my $this = shift;
	my $regtb = $this->get_typed_table("DEPOSIT");
	
	unless( $regtb )
	{
		return;	
	}
	return $regtb;
}

#get deposit usersmap users -> point to array[total, count, max, viplevel, vipscore];
sub get_deposit_usermap
{
	my $this = shift;
	unless( $this->{'mDepositUserMap'} )
	{
		my $deposit = $this->get_deposit_table();
		my $depidx = $this->{'mUserIndex'} + 1;
		my $user, my $num, my $level, my $score;
		my %usermap = ();
		my $arrp;
		foreach $item(@$deposit)
		{
			$user = @$item[$this->{'mUserIndex'}];
			unless( &is_user_name($user) )
			{
				next;
			}
			$num = @$item[$depidx];
			$level = @$item[$depidx+3];
			$level = 0 unless defined($level);
			$score = @$item[$depidx+4];
			$score = 0 unless defined($score);
			unless( exists($usermap{$user}) )
			{
					my @array = ($num, 1, $num, 0, 0);
					$usermap{$user} = \@array;
			}
			else
			{
				$arrp = $usermap{$user};
				@$arrp[0] += $num;
				@$arrp[1] += 1;
				if( @$arrp[2] < $num )
				{
					@$arrp[2] = $num;
				}
				if( @$arrp[3] < $level )
				{
					@$arrp[3] = $level;
				}
				if( @$arrp[4] < $score )
				{
					@$arrp[4] = $score;
				}
			}
		}
		$this->{'mDepositUserMap'} = \%usermap;
	}
	return $this->{'mDepositUserMap'};
}

##时间，交易总量，真元宝数总数，财务确认金额总数，留存充值元宝，剩余总真元宝，剩余总元宝
#get yuan bao usersmap users -> point to array[transtime, transall, transreal, transconfirm, depositleft, realleft, totalleft];
sub get_yuanbao_usermap
{
	my $this = shift;
	unless( $this->{'mYuanBaoUserMap'} )
	{
		my $get_yb_tb = $this->get_typed_table("GET_YB");
		my $cast_yb_tb = $this->get_typed_table("CAST_YB");
		my %usermap = ();
		$this->stat_trans_yuanbao($get_yb_tb, \%usermap, 1);
		$this->stat_trans_yuanbao($cast_yb_tb, \%usermap, 0);

		$this->{'mYuanBaoUserMap'} = \%usermap;
	}
	return $this->{'mYuanBaoUserMap'};
}

sub stat_trans_yuanbao
{
	my $this = shift;
	my $tb_ptr = shift;
	my $usermap_p = shift;
	my $isget = shift;
	
	my $useridx = $this->{'mUserIndex'};
	my $transtime, my $transall, my $transreal, my $transconfirm, my $depositleft, my $realleft, my $totalleft;
	my $user, my $stamp, my $arrp;
	my $item;
	foreach $item(@$tb_ptr)
	{
		$user = @$item[$useridx];
		unless( &is_user_name($user) )
		{
			next;
		}
		#printf "@$item \n";
		#$transtime = @$item[0];
		($transtime, $transall, $transreal, $transconfirm, $depositleft, $realleft, $totalleft) = @$item[0, $useridx + 2..$useridx + 7];
		#print("list:@$item[0, $useridx + 2..$useridx + 7]\n");
		#print("transtime:$transtime transall:$transall transreal:$transreal transconfirm:$transconfirm depositleft:$depositleft realleft:$realleft totalleft:$totalleft\n");
		unless( exists( $usermap_p->{$user} ) )
		{
			my @array = ($transtime, $transall, $transreal, $transconfirm, $depositleft, $realleft, $totalleft);
			$usermap_p->{$user} = \@array;
		}
		else
		{
			$arrp = $usermap_p->{$user};
			$stamp = @$arrp[0];
			@$arrp[0] = $transtime;
			@$arrp[1] += $transall;
			@$arrp[2] += $transreal;
			@$arrp[3] += $transconfirm;
			if( $transtime gt $stamp )
			{
				@$arrp[4] = $depositleft;
				@$arrp[5] = $realleft;
				@$arrp[5] = $totalleft;
			}
		}
	}
}

#get deposit users in array(user1,user2...)
sub get_deposit_users
{
		my $this = shift;
		unless( $this->{'mDepositUsers'} )
		{
			my $tb = $this->get_deposit_usermap();
			my @arr = sort keys %$tb;
			$this->{'mDepositUsers'} = \@arr;
		}
		return $this->{'mDepositUsers'};
}

#get deposit users in int
sub get_deposit_usernum
{
		my $this = shift;
		unless( exists($this->{'mDepositUserNum'}) )
		{
			my $user_ptr = $this->get_deposit_users();
			my $num = scalar(@$user_ptr);
			$this->{'mDepositUserNum'} = $num;
		}
		return $this->{'mDepositUserNum'};
}

#get deposit total amount in int 
sub get_deposit_total
{
	my $this = shift;
	my $date = $this->{'mDate'};
	unless( exists($this->{'mDepositTotal'}) )
	{
		my $deposit = $this->get_deposit_table();
		my $depidx = $this->{'mUserIndex'} + 1;
		my ($total, $num) = (0, 0);
		foreach my $item(@$deposit)
		{
			$num =  @$item[$depidx];
			$total += $num;
		}
		#print("date:$date total: $total\n");
		$this->{'mDepositTotal'} = $total;
	}
	return $this->{'mDepositTotal'};
}

#get deposit times in int 
sub get_deposit_count
{
		my $this = shift;
		unless( exists($this->{'mDepositCount'}) )
		{
			my $deposit = $this->get_deposit_table();
			$this->{'mDepositCount'} = scalar(@$deposit);
		}
		return $this->{'mDepositCount'};
}

#get deposit total in one month in int
sub get_deposit_month
{
		my $this = shift;
		#print("get_deposit_month\n");
		if( exists($this->{'mDepositMonth'}) )
		{
			return $this->{'mDepositMonth'};
		}
}

#set deposit total in one month in int
sub set_deposit_month
{
		my $this = shift;
		my $num = shift;
		$this->{'mDepositMonth'} = $num;
		#print("set Deposit month: $num\n");
}


#get deposit user perct in in int
sub get_deposit_perct
{
		my $this = shift;
		unless( exists($this->{'mDepositPerct'}) )
		{
			my $depoun = $this->get_deposit_usernum();
			my $loginun = $this->get_login_usernum();
			my $perct = 0;
			if( $loginun )
			{
				$perct = $depoun / $loginun * 100;
			}
			my $fn = sprintf("%2.02f", $perct);
			$this->{'mDepositPerct'} = $fn;
		}
		return $this->{'mDepositPerct'};
}

#get deposit arup (amount per user) in in int
sub get_deposit_arup
{
		my $this = shift;
		unless( exists($this->{'mDepositArup'}) )
		{
			my $deptotal =$this->get_deposit_total(); 
			my $depoun = $this->get_deposit_usernum();
			my $perct = 0;
			if( $depoun )
			{
				$perct = int($deptotal / $depoun);
			}
			my $fn = sprintf("%.f", $perct);
			$this->{'mDepositArup'} = $fn;
		}
		return $this->{'mDepositArup'};
}

#get online average user num
sub get_acu
{
	my $this = shift;
	unless( exists($this->{'mAcu'}) )
	{
		my $acu = 0;
		my $olidx = $this->{'mUserIndex'}+1;
		my $num = 0;
		my $arr = $this->get_typed_table("ONLINE");
		foreach $item(@$arr)
		{
			$num += @$item[$olidx];
		}
		$count = scalar(@$arr);
		if( $count )
		{
			$acu = $num / $count;
		}
		#print("num:$num, count:$count, acu:$acu\n");
		$this->{'mAcu'} = sprintf("%d", $acu);
	}
	return $this->{'mAcu'};
}	

#get online top user num
sub get_pcu
{
	my $this = shift;
	unless( exists($this->{'mPcu'}) )
	{
		my $pcu = 0;
		my $olidx = $this->{'mUserIndex'}+1;
		my $num = 0;
		my $arr = $this->get_typed_table("ONLINE");
		foreach $item(@$arr)
		{
			if( $pcu < @$item[$olidx] )
			{
				$pcu = @$item[$olidx];
			}
		}
		#print("pcu:$pcu\n");
		$this->{'mPcu'} = $pcu;
	}
	return $this->{'mPcu'};
}	

#sub distinct table 
#param (tp,didx,cidx)
#tp => a pointer to table
#didx => index of distinct, e.g. username
#cidx => compare index, when duplicate idx occus, compare the cidx
sub distinct_table
{
	my $tp = shift;
	my $didx = shift;
	my $cidx = shift;
	my %retmap = ();	#a map to save the ([didx]'s value) => array point of value
	my $retp = \%retmap;
	#print("retp:$retp\n");
	my $temp;		#temp is a pointer to record array
	my $key;
	foreach $item (@$tp)	#item is the pointer to record array
	{
		$key = @$item[$didx]; #key is the sector of record
		
		if( exists($retp->{$key}) )
		{
			$temp = $retp->{$key}; #temp is the pointer to record array
			#print("$key exist :@$temp\n");
			if( !$cidx or @$temp[$cdix] <=> @$item[$cidx] )
			{
				#print("replace key:$key item:$item: @$item\n");
				$retp->{$key} = $item;
			}
			
		}
		else
		{
			#print("insert key:$key item:$item @$item\n");
			$retp->{$key} = $item;
		} 
		#print("result: $retmap->{$key}\n");
	}
	return $retp;
}

sub is_user_name
{
	my $user = shift;
	#return $user =~ /^\d+$/;
	return $user =~ /^\S+$/;
}


1;#end of the file