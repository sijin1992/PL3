		package DBTransport;

use DateWrap;
use LogStat;
use DBAccess;

#construct function param(enddate, shiftdays )
sub new
{
	my $class = shift;			#need class name
	my $enddate = shift;		#enddate
	my $referhour = shift;	#referhour
	my $this = {};					#a new hash reference
	
	#member data
	my @stattypes = qw(LOGIN LOGOUT REGIST DEPOSIT ONLINE LEVELUP GET_YB CAST_YB);
	
	my %statmap = ();
	my @datearray = ();
	my $i = 0;
	for($i = 0; $i < 1; $i++)
	{
		#my $date = `date -d '$i days ago' +%Y%m%d`;
		#my $date = DateWrap::get_date($enddate, -$i);
		my $date = $enddate;
		#chomp($date);
		push(@datearray, $date);
		my $stat = new LogStat($date);
		$stat->{mStatTypes} =  \@stattypes;
		$stat->{'mReferHour'} = $referhour if defined($referhour);
		print "referhour:$referhour\n" if defined($referhour);
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

sub stat_all
{
	my $this = shift;
	my $tablename = shift;
	my $lasthour = shift;
	my $dbacc = new DBAccess("dbconf") or die "new db failed";
	if( $dbacc->init() != 0 )
	{
		die "db init failed";
	}
	
	my $statmap = $this->{'mStatPtrMap'};
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

	
	$this->stat_users_table() if( $tablename eq "all" || $tablename eq "users" );
	$this->stat_login_table() if( $tablename eq "all" || $tablename eq "login" );
	my $gold_sql = $this->stat_gold_table() if( $tablename eq "all" || $tablename eq "gold" );
	my $pcu_sql = $this->stat_pcu_table() if( $tablename eq "all" || $tablename eq "pcu" );

	$this->db_query($dbacc);
	
	$dbacc->release;	
}

sub db_query
{
	my ($this, $dbacc)  = @_;
	
	my $row_num_arr = $this->{rownumarr};
	my $row_num_map = $this->{rownummap};
	my $sql_str_map = $this->{sqlstrmap};
	
	local ($prtname, $entrynum, $retrownum);
	my $sqlstr;
	foreach my $tablename( @$row_num_arr )
	{
		$entrynum = $row_num_map->{$tablename};
		if( $entrynum == 0 )
		{
			$retrownum = "no entry";
		} 
		else
		{
			$sqlstr = $sql_str_map->{$tablename};
			#print "table:$tablename \n sql:$sqlstr\n";
			$retrownum = $dbacc->query($sqlstr);
		}
		$prtname = $tablename;
		#print "query $tablename \t\trownum:$rownum \t ret:$retrownum\n";
		$~="QUERY_RESULT";
		write;
	}
}

format QUERY_RESULT = 
query @<<<<<<<<<<<<<<<<<<<<< entrynum:@<<<<<<<<  ret_rownum:@<<<<<<<<
$prtname, $entrynum, $retrownum
.

sub stat_users_table
{
	my $this = shift;
	my $date = $this->{'mEndDate'};
	my $statmap = $this->{'mStatPtrMap'};
	my $stat = $statmap->{$date};
	die "stat $date not found:$stat" unless ($stat);
	
	#my $areaid, my $uid, my $roleid, my $create_time, my $vip, my $ip, my $imei, my $lv, my $gold, my $last_time;
	my ($areaid, $uid, $roleid, $create_time, $vip, $ip, $imei, $lv, $gold, $last_time);

	my $regmap = $stat->get_regist_usermap();
	my $loginmap = $stat->get_login_usermap();
	my $depomap = $stat->get_deposit_usermap();
	my $ybmap = $stat->get_yuanbao_usermap();
	my $levelmap = $stat->get_all_user_levels();
	
	my @newuser_arr = ();
	
	#my $user, my $stamp, my $arr_reg, my $arr_login, my $arr_depo, my $arr_yuanbao;
	my ($stamp, $arr_reg, $arr_login, $arr_depo, $arr_yuanbao);
	my $len;
	my $arealen = 5;
	my $useridx = $stat->{'mUserIndex'};
	#stat new users
	while( my ($user, $arr_reg) = each (%$regmap) )
	{
		
		#print("user:$user\n");
		$roleid = $user;
		$areaid = &get_areaid_by_roleid($roleid);
		$stamp = @$arr_reg[0];
		($create_time, $stamp) = &adjust_stamp($stamp);
		
		$ip = @$arr_reg[$useridx + 1];
		$imei = @$arr_reg[$useridx + 2];
		$uid = @$arr_reg[$useridx + 3];
		
		#init unkown info
		$vip = 0;
		$lv = 1;
		$gold = 0;
		$last_time = $create_time;
		
		#check login map
		if( exists($loginmap->{$user}) )
		{
			$arr_login = $loginmap->{$user};
			$stamp = @$arr_login[0];
			($last_time, $stamp) = &adjust_stamp($stamp);
			$lv = @$arr_login[$useridx + 3];
			$ip = @$arr_login[$useridx + 1];
			$imei = @$arr_login[$useridx + 2];
		}
		
		#check deposit map
		if( exists($depomap->{$user}) )
		{
			$arr_depo = $depomap->{$user};
			$vip = @$arr_depo[3];
			#print("vip:$vip\n");
		}
		
		#check yuanbao map
		if( exists($ybmap->{$user}) )
		{
			$arr_yuanbao = $ybmap->{$user};
			$gold = @$arr_yuanbao[5];
		}
		
		#check level map
		if( exists($levelmap->{$user}) )
		{
			$lv = $levelmap->{$user};
		}
		
		my @new_entry = ($areaid, $uid, $roleid, $create_time, $vip, $ip, $imei, $lv, $gold, $last_time);
		#print("entry:@new_entry\n");
		push(@newuser_arr, \@new_entry);
	}
	#print("newuser_arr:@newuser_arr\n");
	my $new_users_sql = $this->create_new_users_sql(\@newuser_arr);
	
	#stat old users
	my @olduser_arr = ();
	my $has_yb, my $has_vip;
	while( my ($user, $arr_login) = each (%$loginmap) )
	{
		if( exists($regmap->{$user}) )
		{
			next;
		}
		
		# $has_yb, $has_vip, $roleid, $ip, $imei, $lv, $last_time, $vip, $gold
		
		$stamp = @$arr_login[0];
		$roleid = $user;
		$areaid = &get_areaid_by_roleid($roleid);
		($last_time, $stamp) = &adjust_stamp($stamp);
		($ip, $imei, $lv, $uid) = @$arr_login[$useridx+1 .. $useridx+4];
		if( exists($levelmap->{$user}) )
		{
			$lv = $levelmap->{$user};
		}
		
		#check yuanbao map
		if( exists($ybmap->{$user}) )
		{
			$arr_yuanbao = $ybmap->{$user};
			$gold = @$arr_yuanbao[5];
			$has_yb = 1;
		}
		else
		{
			$has_yb = 0;
			$gold = 0;
		}
		
		#check deposit map
		if( exists($depomap->{$user}) )
		{
			$arr_depo = $depomap->{$user};
			$vip = @$arr_depo[3];
			$has_vip = 1;
		}
		else
		{
			$vip = 0;
			$has_vip = 0;
		}
		my @entry = ($has_yb, $has_vip, $areaid, $uid, $roleid, $ip, $imei, $lv, $last_time, $vip, $gold);
		push(@olduser_arr, \@entry);
	}
	if( scalar(@olduser_arr) > 0 )
	{
		$this->create_old_users_sql(\@olduser_arr);
	}
	
	return $new_users_sql;
}

sub stat_login_table
{
	my $this = shift;
	my $date = $this->{'mEndDate'};
	my $statmap = $this->{'mStatPtrMap'};
	my $stat = $statmap->{$date};
	die "stat $date not found" unless $stat;
	
	#my $areaid, my $uid, my $roleid, my $log_time, my $tag, my $ip, my $imei, my $lv, my $ts, my $time_stamp;
	my ($areaid, $uid, $roleid, $log_time, $tag, $ip, $imei, $lv, $ts, $time_stamp);
	
	my $logintb = $stat->get_typed_table("LOGIN");
	my $logouttb = $stat->get_typed_table("LOGOUT");
	my $useridx = $stat->{'mUserIndex'};
	
	my @logarr = ();
	foreach	my $item (@$logintb)
	{
		$time_stamp = @$item[0];
		#登录(用户ID，IP地址， MCC移动设备国家码，等级，账号)
		($roleid, $ip, $imei, $lv, $uid) = @$item[$useridx..$useridx+4];
		$areaid = &get_areaid_by_roleid($roleid);
		($log_time, $time_stamp) = &adjust_stamp($time_stamp); 
		my @entry = ($areaid, $uid, $roleid, $log_time, $ip, $imei, $lv, $time_stamp);
		my @arr = ($time_stamp, \@entry);
		push( @logarr, \@arr );
	}
	
	foreach	my $item (@$logouttb)
	{
		$time_stamp = @$item[0];
		#离线(用户ID，在线时间(秒)，账号)
		($roleid, $ts, $uid) = @$item[$useridx..$useridx+2];
		$areaid = &get_areaid_by_roleid($roleid);
		($log_time, $time_stamp) = &adjust_stamp($time_stamp);
		my @entry = ($areaid, $uid, $roleid, $log_time, $ts, $time_stamp);
		my @arr = ($time_stamp, \@entry, 1);
		push( @logarr, \@arr );
	}
	
	@logarr = sort { @$a[0] cmp @$b[0] } ( @logarr );
	return $this->create_login_logout_sql(\@logarr);
}

sub stat_gold_table
{
	my $this = shift;
	my $date = $this->{'mEndDate'};
	my $statmap = $this->{'mStatPtrMap'};
	my $stat = $statmap->{$date};
	die "stat $date not found" unless $stat;
	
	
	#my $areaid, my $uid, my $roleid, my $log_time, my $tag, my $item, my $remark, my $qty, my $confirm, 
	#my $deposit_left, my $total_left, my $cur_yb, my $ip, my $imei, my $time_stamp;
	
	my ($areaid, $uid, $roleid, $log_time, $tag, $remark, $trans_qty, $qty, $confirm, 
				$deposit_left, $total_left, $cur_yb, $ip, $imei, $time_stamp);
	
	my $gettb = $stat->get_typed_table("GET_YB");
	my $costtb = $stat->get_typed_table("CAST_YB");

	my $useridx = $stat->{'mUserIndex'};
	my @logarr = ();
	foreach	my $it_p (@$gettb)
	{
		$time_stamp = @$it_p[0];
		#//元宝获得(用户ID，获得渠道，获得数量，真元宝数，财务确认金额，留存充值元宝，剩余总真元宝，剩余总元宝，账号，IP，MMC)
		($roleid, $remark, $trans_qty, $qty, $confirm, $deposit_left, $total_left, $cur_yb, $uid, $ip, $imei) = 
		@$it_p[$useridx..$useridx+10];
		unless( $qty > 0 )
		{
			next;
		}
		($log_time, $time_stamp) = &adjust_stamp($time_stamp);
		$areaid = &get_areaid_by_roleid($roleid);

		if ( $remark == 0 ) #gm where
		{
			$tag = 0;
		}
		elsif( $remark == 50 ) #deposit where
		{
			$tag = 1;
		}
		else
		{
			$tag = 2;
		}
		
		my @entry = ($areaid, $uid, $roleid, $log_time, $tag, $remark, $trans_qty, $qty, $confirm,
			$deposit_left, $total_left, $cur_yb, $ip, $imei, $time_stamp);
		
		my @arr = ($time_stamp, \@entry);
		push( @logarr, \@arr );
	}
	
	$tag = 3;
	foreach	my $it_p (@$costtb)
	{
		$time_stamp = @$it_p[0];
		#//元宝消耗(用户ID，获得渠道，获得数量，真元宝数，财务确认金额，留存充值元宝，剩余总真元宝，剩余总元宝，账号，IP，MMC)
		($roleid, $remark, $trans_qty, $qty, $confirm, $deposit_left, $total_left, $cur_yb, $uid, $ip, $imei) = 
		@$it_p[$useridx..$useridx+10];
		unless( $qty > 0 )
		{
			next;
		}
		($log_time, $time_stamp) = &adjust_stamp($time_stamp);
		$areaid = &get_areaid_by_roleid($roleid);
		
		my @entry = ($areaid, $uid, $roleid, $log_time, $tag, $remark, -$trans_qty, -$qty, $confirm,
			$deposit_left, $total_left, $cur_yb, $ip, $imei, $time_stamp);
		my @arr = ($time_stamp, \@entry);
		push( @logarr, \@arr );
	}
	
	@logarr = sort { @$a[0] cmp @$b[0] } ( @logarr );

	return $this->create_gold_sql(\@logarr);
}

sub stat_pcu_table
{
	my $this = shift;
	my $date = $this->{'mEndDate'};
	my $statmap = $this->{'mStatPtrMap'};
	my $stat = $statmap->{$date};
	die "stat $date not found" unless $stat;
	
	my $areaid, my $log_time, my $qty, my $time_stamp;
	my $olidx = $stat->{'mUserIndex'}+1;
	my $onlinetb = $stat->get_typed_table("ONLINE");
	my @logarr = ();
	foreach	my $item (@$onlinetb)
	{
		$time_stamp = @$item[0];
		#在线统计(在线人数，区服ID)
		($qty, $areaid) = @$item[$olidx..$olidx+1];
		($log_time, $time_stamp) = &adjust_stamp($time_stamp);
		my @entry = ($areaid, $log_time, $qty);
		push( @logarr, \@entry );
	}
	
	return $this->create_pcu_sql(\@logarr);
}

sub create_new_users_sql
{
	my $this = shift;
	my $entry_arr_p = shift;
	my $sql_table_name = "users";
	my $colstr = "areaid, uid, roleid, create_time, vip, ip, imei, lv, gold, last_time";
	my $sql_insert = "INSERT IGNORE $sql_table_name ($colstr) VALUES \n";

	my $allnum = scalar(@$entry_arr_p);
	my $curnum = 0;
	my $flag = ",";
	foreach my $entry ( @$entry_arr_p )
	{
		$curnum ++;
		unless( $curnum < $allnum )
		{
			$flag = "";
		}
		$sql_insert .= sprintf("('%s', '%s', '%s', '%s', %d, '%s', '%s', %d, %d, '%s')$flag\n", @$entry);
	}
	$sql_insert .= ";\n";
	#print("new user sql_insert:\n$sql_insert");
	$this->add_table_sql("new_users", $allnum, $sql_insert);
}

sub create_old_users_sql
{
	my $this = shift;
	my $entry_arr_p = shift;
	my $sql_table_name = "users";
	my $colstr_all = "areaid, uid, roleid, ip, imei, lv, last_time, vip, gold";
	my $colstr_no_gold = "areaid, uid, roleid, ip, imei, lv, last_time, vip";
	my $colstr_no_vip = "areaid, uid, roleid, ip, imei, lv, last_time, gold";
	my $colstr_no_both = "areaid, uid, roleid, ip, imei, lv, last_time";

	my $sql_insert_all = "INSERT IGNORE INTO $sql_table_name ($colstr_all) VALUES \n";
	my $sql_insert_no_gold = "INSERT IGNORE INTO $sql_table_name ($colstr_no_gold) VALUES \n";
	my $sql_insert_no_vip = "INSERT IGNORE INTO $sql_table_name ($colstr_no_vip) VALUES \n";
	my $sql_insert_no_both = "INSERT IGNORE INTO $sql_table_name ($colstr_no_both) VALUES \n";
	
	#my @entry = ($has_yb, $has_vip, $areaid, $uid, $roleid, $ip, $imei, $lv, $last_time, $vip, $gold);
	my ($allnum, $no_gold_num, $no_vip_num, $no_both_num);
	$allnum = $no_gold_num = $no_vip_num = $no_both_num = 0;
	foreach my $entry ( @$entry_arr_p )
	{
		if( @$entry[0] and @$entry[1] )
		{
			$allnum++;
		}
		elsif( @$entry[0] )
		{
			$no_vip_num ++;
		}
		elsif( @$entry[1] )
		{
			$no_gold_num++;
		}
		else
		{
			$no_both_num++;
		}
	}
	
	#print("allnum:$allnum no_vip_num:$no_vip_num no_gold_num:$no_gold_num no_both_num:$no_both_num\n" );
	my ($allnum_bak, $no_gold_num_bak, $no_vip_num_bak, $no_both_num_bak) = ($allnum, $no_gold_num, $no_vip_num, $no_both_num);
	my $flag = "";
	foreach my $entry ( @$entry_arr_p )
	{
		$flag = "";
		if( @$entry[0] and @$entry[1] )
		{
			$allnum--;
			if( $allnum > 0 )
			{
				$flag = ",";
			}
			
			#do insert
			#my $colstr_all = "areaid, uid, roleid, ip, imei, lv, last_time, vip, gold";
			$sql_insert_all .= sprintf("('%s', '%s', '%s', '%s', '%s', %d, '%s', %d, %d)$flag\n", @$entry[2...10]);
		}
		elsif( @$entry[0] )
		{
			$no_vip_num--;
			if( $no_vip_num > 0 )
			{
				$flag = ",";
			}
			
			#do insert
			#my $colstr_no_vip = "areaid, uid, roleid, ip, imei, lv, last_time, vip";
			$sql_insert_no_vip .= sprintf("('%s', '%s', '%s', '%s', '%s', %d, '%s', %d)$flag\n", @$entry[2..8, 10]);
		}
		elsif( @$entry[1] )
		{
			$no_gold_num--;
			if( $no_gold_num > 0 )
			{
				$flag = ",";
			}
			
			#do insert
			#my $colstr_no_gold = "areaid, uid, roleid, ip, imei, lv, last_time, gold";
			$sql_insert_no_gold .= sprintf("('%s', '%s', '%s', '%s', '%s', %d, '%s', %d)$flag\n", @$entry[2..9]);
		}
		else
		{
			$no_both_num--;
			if( $no_both_num > 0 )
			{
				$flag = ",";
			}
			#do insert
			#my $colstr_no_both = "areaid, uid, roleid, ip, imei, lv, last_time";
			$sql_insert_no_both .= sprintf("('%s', '%s', '%s', '%s', '%s', %d, '%s')$flag\n", @$entry[2..8]);
		}
	}
	
	$sql_insert_all .= "ON DUPLICATE KEY UPDATE ";
	$sql_insert_no_gold .= "ON DUPLICATE KEY UPDATE ";
	$sql_insert_no_vip .= "ON DUPLICATE KEY UPDATE ";
	$sql_insert_no_both .= "ON DUPLICATE KEY UPDATE ";
	
	my @colarr = split(",", $colstr_all);
	shift(@colarr);
	# = "ip, imei, lv, last_time, vip, gold";
	my $col;
	
	my $size = scalar(@colarr);
	print "size:$size\n";
	for (my $i = 0; $i < $size; $i++) 
	{
		$col = $colarr[$i];
		$sql_insert_all .= "$col = VALUES($col)" if $i < 6;
		$sql_insert_all .= ", " if $i < 5;
		
		$sql_insert_no_gold .= "$col = VALUES($col)" if $i < 5;
		$sql_insert_no_gold .= ", " if $i < 4;
		
		$sql_insert_no_vip .= "$col = VALUES($col)" if $i < 4 || $i == 5;
		$sql_insert_no_vip .= ", " if $i < 4;
		
		$sql_insert_no_both .= "$col = VALUES($col)" if $i < 4;
		$sql_insert_no_both .= ", " if $i < 3;
	}
	
	$sql_insert_all .= ";\n";
	$sql_insert_no_gold .= ";\n";
	$sql_insert_no_vip .= ";\n";
	$sql_insert_no_both .= ";\n";
	
	#my ($allnum_bak, $no_gold_num_bak, $no_vip_num_bak, $no_both_num_bak);
	

	#print("old user sql_insert_all:\n$sql_insert_all");
	#print("old user sql_insert_no_vip:\n$sql_insert_no_vip");
	#print("old user sql_insert_no_gold:\n$sql_insert_no_gold");
	#print("old user sql_insert_no_both:\n$sql_insert_no_both");

	$this->add_table_sql("old_users_all", $allnum_bak, $sql_insert_all) if $allnum_bak > 0;
	$this->add_table_sql("old_users_no_gold", $no_gold_num_bak, $sql_insert_no_gold) if $no_gold_num_bak > 0;
	$this->add_table_sql("old_users_no_vip", $no_vip_num_bak, $sql_insert_no_vip) if $no_vip_num_bak > 0;
	$this->add_table_sql("old_users_no_both", $no_both_num_bak, $sql_insert_no_both) if $no_both_num_bak > 0;
}


sub create_login_logout_sql
{
	my $this = shift;
	my $entry_arr_p = shift;
	my $sql_table_name = "login";
	my $colstr = "areaid, uid, roleid, log_time, tag, ip, imei, lv, ts, time_stamp";
	my $sql_insert = "INSERT IGNORE INTO $sql_table_name ($colstr) VALUES \n";
	
	
	#my @entry = ($areaid, $uid, $roleid, $log_time, $ip, $imei, $lv, $time_stamp);
	#my @entry = ($areaid, $uid, $roleid, $log_time, $ts, $time_stamp);
	
	my $allnum = scalar(@$entry_arr_p);
	my $curnum = 0;
	my $flag = ",";
	my $arr_p;
	foreach my $entry ( @$entry_arr_p )
	{
		$curnum ++;
		unless( $curnum < $allnum )
		{
			$flag = "";
		}
		$arr_p = @$entry[1];
		if( @$entry[2] ) #logout
		{
			$sql_insert .= sprintf("('%s', '%s', '%s', '%s', 'logout', NULL, NULL, NULL, '%d', '%s')$flag\n", @$arr_p);
		}
		else #login
		{
			$sql_insert .= sprintf("('%s', '%s', '%s', '%s', 'login', '%s', '%s', %d, NULL, '%s')$flag\n", @$arr_p);
		}
	}
	$sql_insert .= ";\n";
	#print("login & logout sql_insert:\n$sql_insert");
	$this->add_table_sql("login_logout", $allnum, $sql_insert);
}

sub create_gold_sql
{
	my $this = shift;
	my $entry_arr_p = shift;
	my $sql_table_name = "gold";
	my $colstr = "areaid, uid, roleid, log_time, tag, remark, trans_qty, qty, confirm, deposit_left, total_left, cur_yb, ip, imei, time_stamp";
	             #(areaid, uid, roleid, log_time, tag, remark, trans_qty, qty, confirm, deposit_left, total_left, cur_yb, ip, imei, time_stamp);
	my $sql_insert = "INSERT IGNORE INTO $sql_table_name ($colstr) VALUES \n";
	my $allnum = scalar(@$entry_arr_p);
	my $curnum = 0;
	my $flag = ",";
	my $arr_p;
	foreach my $entry ( @$entry_arr_p )
	{
		$curnum ++;
		unless( $curnum < $allnum )
		{
			$flag = "";
		}
		$arr_p = @$entry[1];
		$sql_insert .= sprintf("('%s', '%s', '%s', '%s', '%s', %d, %d, %d, %d, %d, %d, %d, '%s', '%s', '%s')$flag\n", @$arr_p);
	}
	$sql_insert .= ";\n";
	#print("gold sql_insert:\n$sql_insert");
	$this->add_table_sql("gold", $allnum, $sql_insert);
}

sub create_pcu_sql
{
	my $this = shift;
	my $entry_arr_p = shift;
	my $sql_table_name = "pcu";
	my $colstr = "areaid, log_time, qty";
	my $sql_insert = "INSERT IGNORE $sql_table_name ($colstr) VALUES \n";

	my $allnum = scalar(@$entry_arr_p);
	my $curnum = 0;
	my $flag = ",";
	my $entry;
	foreach $entry ( @$entry_arr_p )
	{
		$curnum ++;
		unless( $curnum < $allnum )
		{
			$flag = "";
		}
		$sql_insert .= sprintf("('%s', '%s', %d)$flag\n", @$entry);
	}
	$sql_insert .= ";\n";
	#print("pcu sql_insert:\n$sql_insert");
	$this->add_table_sql("pcu", $allnum, $sql_insert);
}

sub create_gold_month_sql
{
	my $this = shift;
	my $entry_arr_p = shift;
	my $sql_table_name = "gold_month";
	my $sql_table_name_user = "gold_month";
	my $colstr = "areaid, uid, roleid, qty";
	my $usercolstr = "areaid, uid, roleid, gold";
	my $sql_insert = "INSERT INTO IGNORE $sql_table_name ($colstr) SELECT $usercolstr from $sql_table_name_user;\n";
	
	print("gold_month sql_insert:\n$sql_insert");
}

sub add_table_sql
{
	my ($this, $name, $rownum, $sql) = @_;
	my $sql_str_map_p = $this->{'sqlstrmap'};
	unless( $sql_str_map_p )
	{
		%sqlstrmap = ();
		$sql_str_map_p = \%sqlstrmap;
		$this->{'sqlstrmap'} = $sql_str_map_p;
	}
	$sql_str_map_p->{$name} = $sql;
	
	my $row_num_map_p = $this->{'rownummap'};
	unless( $row_num_map_p )
	{
		%rownummap = ();
		$row_num_map_p = \%rownummap;
		$this->{'rownummap'} = $row_num_map_p;
	}
	$row_num_map_p->{$name} = $rownum;
	
	my $row_num_arr_p = $this->{'rownumarr'};
	unless( $row_num_arr_p )
	{
		@rownumarr = ();
		$row_num_arr_p = \@rownumarr;
		$this->{'rownumarr'} = $row_num_arr_p;
	}
	push(@$row_num_arr_p, $name);
}

sub get_time_by_stamp
{
	my $stamp = shift;
	#my ($datestr, $timestr) = (substr($stamp, 0, 8), substr($stamp, 8, 8));
	#return sprintf("%d-%d-%d %s", $datestr, $timestr);
	return (sprintf("%s", substr($stamp, 0, 19)), $stamp);
}

sub adjust_stamp
{
	my $stamp = shift;
	#return (sprintf("%s", substr($stamp, 0, 19)), $stamp);
	#2014120811:11:27.000319
	$stamp =~ /^(\d{4})(\d{2})(\d{2})(\d{2}:\d{2}:\d{2})\.(\d+)$/;
	#print "stamp:$stamp ". $& ."\n";
	my $datetime = "$1-$2-$3 $4";
	#my $datetime = $1."-".$2."-".$3." ".$4;
	#print "datetime:$datetime\n";
	$stamp = "$datetime $5";
	#print "stamp:$stamp\n";
	return ($datetime, $stamp);
}

#need roleid
sub get_areaid_by_roleid
{
	my $roleid = shift;
	my $len = length($roleid);
	local $arealen = 5;
	if( $len > $arealen )
	{
		$areaid = substr($roleid, $len - $arealen);
	}
	else
	{
		$areaid = $roleid;
	}
}


1;#end of the file