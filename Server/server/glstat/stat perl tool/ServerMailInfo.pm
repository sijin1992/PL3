		package ServerMailInfo;

use DateWrap;
use ServerStat;
use Print;
use PrintHtml;

#construct function param(enddate, shiftdays )
sub new
{
	my $class = shift;			#need class name
	my $enddate = shift;		#enddate
	my $shiftdays = shift;	#shiftdays
	my $filter = shift;
	my $this = {};					#a new hash reference
	
	#member data
	
	unless ( $filter )
	{
		$filter = "all";
	}
	
	my @rowlist = ("DATE", "REGIST", "LOGIN", "LIUCUN2", "LIUCUN3", "LIUCUN7", "DEPOSIT", "DEPOMON", "DEPOPERCT", "DEPOARUP", "DEPOUN", "SERVERNUM");
  

	my %nametb = (
               	"DATE" => "日期",
                "REGIST" => "新进",
                "LOGIN" => "活跃",
								"DEPOSIT" => "当日收入",
								"DEPOMON" => "月总收入",
								"DEPOPERCT" => "付费渗透率",
								"DEPOARUP" => "ARUP值",
								"DEPOUN" => "付费人数",
								"LIUCUN2" => "次日留存",
								"LIUCUN3" => "3日留存",
								"LIUCUN7" => "7日留存",
              	"ACU" => "平均在线人数",
								"PCU" => "最高在线人数",
								"SERVERNUM" => "服务器数量",
								"TITLE" => "古龙数据统计",
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

=pod	
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
								"SERVERNUM" => "SERVERNUM",
	);
=cut

	my %statmap = ();
	my @datearray = ();
	my $i = 0;
	for($i = 0; $i < $shiftdays; $i++)
	{
		#my $date = `date -d '$i days ago' +%Y%m%d`;
		my $date = DateWrap::get_date($enddate, -$i);
		#chomp($date);
		push(@datearray, $date);
		my $stat = new ServerStat($date, $filter);
		#printf("date:$date stat:$stat\n");
		$statmap{$date} = $stat;
	}
	@datearray = reverse(@datearray);
	
	my %datamap = ();
	#@datearray = sort(@datearray);
	$this->{'mStatPtrMap'} = \%statmap;
	$this->{'mDateArray'} = \@datearray;
	$this->{'mFilter'} = $filter;
	
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
	my $filter = $this->{'mFilter'};
	
	if( !$this->{'mIsLoaded'} and $this->load_server_config() != 0 )
	{
		print("load_server_config failed.\n");
		return -1;
	}
	
	my $prt = $this->{'mPrint'};
	unless( $prt )
	{
		#print("datamap_p:$datamap_p, $rowlist_p, $nametb_p\n");
		#foreach( ($key, $val) = each(%$datamap_p) )
		#{
			#	print("key:$key, val:$val\n");
		#}
		
		$prt = new PrintHtml();
		$this->{'mPrint'} = $prt;
	}
	
	my $datamap_p = $this->{'mStatDataMap'};
	my $rowlist_p = $this->{'mRowList'};
	my $nametb_p = $this->{'mNameTab'};
	
	my $pretitle = $nametb_p->{'TITLE'};
	my $title = "$pretitle ";
	
	unless( $filter =~ /^server$/ )
	{
		print("FILTER :$filter\n");
		$title .= $filter;
		
		$this->stat_all();

		$prt->do_print_table($datamap_p, $rowlist_p, $nametb_p, $title);
		return;
	}
	pop(@$rowlist_p);
	my $servergroup = $this->{'mServerDirGroup'};
	my $serverid;
	foreach $serverdir( @$servergroup )
	{
		#print("server:$serverdir\n");
		%$datamap_p = ();
		$serverid = $this->stat_single($serverdir);
		$title = "$pretitle ";
		$title .= $serverid ? $serverid : $serverdir;
		$prt->do_print_table($datamap_p, $rowlist_p, $nametb_p, $title);
	}
	

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

sub load_server_config()
{
	my $this = shift;
	my $filename = "serverconf";
	unless( -e $filename )
	{
		print("config file:$filename not exits, default not use cache.\n");
		return 0;
	}
	unless( open(FILE, $filename) )
	{
		print("open file:$filename failed, $!\n");
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
		elsif( $line =~ /serverdir\s*=\s*([\/.\w]+)/i )
		{
			$this->{'mServerDir'} = $1;
		}
	}
	#printf("is cache enbale:%d", $this->{'mCacheEnable'});
	if( $this->{'mCacheEnable'} )
	{
		unless( $this->{'mCacheDir'} )
		{
			$this->{'mCacheDir'} = ".";
		}
		#printf(" , cache dir:%s", $this->{'mCacheDir'});
		unless(-e -d $this->{'mCacheDir'})
		{
			mkdir($this->{'mCacheDir'});
		}
	}
	
	unless( $this->{'mServerDir'} )
	{
		$this->{'mServerDir'} = "servers";
	}
	
	my $serverdir = $this->{'mServerDir'};
	
	unless( -e $serverdir )
	{
		print("no server dir: $serverdir\n");
		return -1;
	}
	
	unless( -d $serverdir )
	{
		print("$serverdir not dir.\n");
		return -1;
	}
	
	unless( opendir(DH, $serverdir) )
	{
		print("open dir:$serverdir failed, $!\n");
		return -1;
	}
	
	my $statcachedir;
	my @dirgroup;
	foreach my $file( readdir DH )
	{
		
		if( $file =~ /(\.{1,2})/ )
		{
			next;
		}
		
		$statcachedir = $serverdir . "/" . $file;
		unless( -d $statcachedir )
		{
			#print("$statcachedir not dir\n");
			next;
		}
		
		unless( grep(/^$statcachedir\Z/g, @dirgroup ) )
		{
			push(@dirgroup, $statcachedir);
		}
	}
	
	$this->{'mServerDirGroup'} = \@dirgroup;
	
	#print("dirgroup:@dirgroup\n");
	$this->{'mIsLoaded'} = 1;
	return 0;
}

sub stat_single
{
	my $this = shift;
	my @serverdir = (shift);
	
	my $statmap = $this->{'mStatPtrMap'};
	
	my $serverid;
	
	while((my $date, my $stat) = each(%$statmap))
	{
		if( $stat->load(\@serverdir) != 0 )
		{
			print("stat:$date load failed\n");
			next;
		}
		
		$serverid = $stat->{'mLastServerID'} unless $serverid;
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
	
	return $serverid;
}

sub stat_all
{
	my $this = shift;
	my $statmap = $this->{'mStatPtrMap'};
	
	while((my $date, my $stat) = each(%$statmap))
	{
		
		if( $this->{'mCacheEnable'} )
		{
			if( $stat->loadfromcache($this->{'mCacheDir'}) != 0 )
			{
				printf("no cache, try to load from log files.\n");
			}
			elsif ( $stat->{'mIsFromCache'} )
			{
				printf("load from cache successfully.\n");
				next;
			}  	
		}
		if( $stat->load($this->{'mServerDirGroup'}) != 0 )
		{
			print("stat:$date load failed\n");
			next;
		}
		
		#$stat->debug();
		#printf("stat:$date load successfully.\n");
		if( $this->{'mCacheEnable'} and $stat->savetocache($this->{'mCacheDir'}) == 0 )
		{
			printf("stat:$date save successfully.\n");
		}
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
	$this->stat_servernum("SERVERNUM");
	
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
	my @deposit_array = ();
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

#sub deposit month
sub stat_depomon
{
	my $this = shift;
	my $type = shift;
	my @mon_array = ();
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
		my $num = $stat->get_deposit_month();
		
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
	my @perct_array = ();
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
	my @arup_array = ();
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
	my @depoun_array = ();
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
	my @liucun_array = ();
	my $datearray = $this->{'mDateArray'};
	my $statmap = $this->{'mStatPtrMap'};
	foreach $date(@$datearray)
	{
		my $stat = $statmap->{$date};
		my $num = $stat->{"mLIUCUN$ndays"};
		push(@liucun_array, $num);
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

sub stat_servernum
{
	my $this = shift;	
	my $type = shift;
	my @array = ();
	my $datearray = $this->{'mDateArray'};
	my $statmap = $this->{'mStatPtrMap'};
	foreach $date(@$datearray)
	{
		my $stat = $statmap->{$date};
		my $num = $stat->get_servernum();
		unless ($num)
		{
			$num = 0;
		}
		push(@array, $num);
	}
	
	$statdatamap = $this->{'mStatDataMap'};
	$statdatamap->{$type} = \@array;
}



1;#end of the file
