		package LogFormat;


sub new
{
	my $class = shift;			#need class name
	my $filename = shift;		#filename
	
	my $this = {};					#a new hash reference
	unless( $filename )
	{
		$filename = "log_stat.h";
	}
	$this->{'mFileName'} = $filename;
	
	bless $this, $class;
	return $this;
}

sub load
{
	my $this = shift;
	my $filename = $this->{'mFileName'};
	unless( open(FILE, "$filename") )
	{
		print("open file $filename failed\n");
		return -1;
	}
	#print("open file $filename successfully.\n");
	my %typemap = ();
	my %namemap = ();
	my %desmap = ();
	my %funcmap = ();
	my ($isgettype, $isrec, $type, $name, $fz);
	while( $line = <FILE> )
	{
		if($line =~ /\/\*\s*TypeBegin/ )
		{
			$isgettype = 1;
			$line =~ /STAT_\w*/;
			$line = $&;
			#printf("line:$line\n");	
		}
		elsif( $line =~ /\/\*\s*TypeEnd/ ) 
		{
			#printf("end:$&\n");
			$isgettype = 0;
		}

		if( defined($isgettype) and $isgettype != 0 )
		{
			if( $line =~ /\/\/(\S+.+\S)/ )
			{
				$fz = $1;
				$line = <FILE>
			}
		
			if( $line =~ /#define STAT/ )
			{
				$line = substr($line, 7);
				$line =~ /\w+/;
				$type = $&;
				$line =~ /"\w+"/;
				$name = $&;
				#printf("type:$type, name:$name fz:$fz\n");
				$typemap{$type} = $name;
				$namemap{$type} = $fz;
			}
			next;
		} 
	
		if($line =~ /\/\*\s*RecBegin/ )
		{
			$isrec = 1;
			#printf("begin:$&\n");
		}
		elsif($line =~ /\/\*\s*RecEnd/ )
		{
			#printf("end:$&\n");
		}	
		if( defined($isrec) and $isrec != 0 )
		{
			if( $line =~ /\/\/(\S+.+\S)/ )
			{
				$fz = $1;
				$line = <FILE>;
			}
			if( $line =~ /#define LOG_STAT/ )
			{
				$line =~ /LOG_STAT_\w+/;
				$line = $&;
				my $type = substr($line, 4);
				#print("type:$type ");
				$desmap{$type} = $fz;
				$line = <FILE>;
				if( $line =~ /LOG_STAT_DATA/ )
				{
					$line =~ /\([\s\S]*\)/;
					$line = $&;
					chop($line);
					$line = substr($line, 1);
					#print("line:$line\n");
					my @arr = split(",", $line);
					@arr[0,1,2] = @arr[1,2,0];
					#print("arr:@arr\n");
					$funcmap{$type} = \@arr;
				} 
			
			} 
		}
	}
	
	$this->{'mTypeMap'} = \%typemap;
	$this->{'mNameMap'} = \%namemap;	
	$this->{'mDesMap'} = \%desmap;	
	$this->{'mFuncMap'} = \%funcmap;
	
	return 0;
}

sub debug()
{
	my $this = shift;
	my $typemap_p = $this->{'mTypeMap'};
	my $namemap_p = $this->{'mNameMap'};
	my $desmap_p = $this->{'mDesMap'};
	my $funcmap_p = $this->{'mFuncMap'};
	printf("TypeMap:\n");
	while( ($type, $name) = each(%$typemap_p) )
	{
		printf("$type => $name \n")
	} 
	printf("NameMap:\n");
	while( ($type, $fz) = each(%$namemap_p) )
	{
		printf("$type => $fz \n");
	} 
	
	printf("DesMap:\n");
	while( ($type, $fz) = each(%$desmap_p) )
	{
	  printf("$type => $fz \n");
	}
	
	printf("FuncMap:\n");
	while( ($type, $fz) = each(%$funcmap_p) )
	{
		print("$type => @$fz \n");
	}
	printf("cpp_sql_case:\n");
	$this->write_cpp_sql_case();
}

sub export
{
	my $this = shift;
	my $typemap_p = $this->{'mTypeMap'};
	my $namemap_p = $this->{'mNameMap'};
	my $desmap_p = $this->{'mDesMap'};
	my $funcmap_p = $this->{'mFuncMap'};
	my $desname;
	printf("-----Export-----\n");

	while( ($type, $name) = each(%$typemap_p) )
	{
		my $desname = $desmap_p->{$type};
	  print("//$desname\n");
		print("LOG_STAT( string.format( ");
		my $arr = $funcmap_p->{$type};
		my $num = scalar(@$arr);
		my $fmat = @$arr[1];
		if($fmat =~ /".*"/ )
		{
			$fmat = substr($&, 1);
		}
		$fmat = "\"%s|%s|" . $fmat;
		print("$fmat, $name");
		for( $i = 2; $i < $num; $i++ )
		{
			my $arg = @$arr[$i];
			if( $i == 2 && !($arg =~ /uid/) )
			{
				$arg = "\"" . $arg . "\"";
			}
			else
			{
				if( $arg =~ /^(\s+)/ )
				{
					$arg = substr($arg, length($1));
				}
				$arg = "\$"."$arg";
			}
			#$arg =~ s/\s/\$/;
			unless( $arg =~ /^\s/ )
			{
				$arg = " ". $arg;
				
			}
			print(",$arg");
		} 
		print(" ) )\n\n");
	}
}

sub get_type_name
{
	my $this = shift;
	my $type = shift;
	my $namemap_p = $this->{'mNameMap'};
	
	$type = "STAT_".$type;
	my $name = $namemap_p->{$type};
	#print("type:$type, name:$name\n");
	
	return $name;
}

sub get_param_des
{
	my $this = shift;
	my $type = shift;
	my $desmap_p = $this->{'mDesMap'};
	$type = "STAT_".$type;
	my $des = $desmap_p->{$type};
	$des =~ /(\S+)\((.+)\)/;
	#print("type:$type des:$des, get:$& 1:$1 2:$2\n");
	#$des = substr($des, length($&));
	#chomp($des); #delete chinese "（"
	#chomp($des);
	$des = $2;
	my @arr = split(",|，", $des);
	#print("arr:@arr\n");
	return @arr;
}

sub get_type_name_map
{
	my $this = shift;
	my $type = shift;
	my $namemap_p = $this->{'mNameMap'};
	
	my %retmap;
	my $key;
	my $offet = length("STAT_");
	while( ($type, $name) = each(%$namemap_p) )
	{
		$key = substr($type, $offet);
		$retmap{$key} = $name;
	}

	return \%retmap;
}

sub write_php_table_col
{
	my $this = shift;
	my $typemap_p = $this->{'mTypeMap'};
	my $namemap_p = $this->{'mNameMap'};
	my $desmap_p = $this->{'mDesMap'};
	my $funcmap_p = $this->{'mFuncMap'};
	my $typeIdx = 4, my $tmpSize = 0, my $startIdx = 2;

	my %filterMap = ();
	{
		my @colarr = qw(real confirm depleft realleft);
		$filterMap{STAT_CAST_YB} = \@colarr;
		$filterMap{STAT_GET_YB} = \@colarr;
	}


	my $colpervar = "\$_LOG_TABLE_COLS";
	my $colpervardes = "\$_LOG_TABLE_COLS_DES";
	
	my $colname = "";
	my $coldes = "";
	my $offet = length("STAT_");
	print "<?php\n/*游戏日志表集*/\n";
	while( ($type, $name) = each(%$typemap_p) )
	{
		my $desname = $desmap_p->{$type};
		my $arr = $funcmap_p->{$type};
		my @desarr = $this->get_param_des(substr($type, $offet));
		$tmpSize = scalar(@$arr);
		my @colarr = @$arr[$startIdx..$tmpSize-1];
		shift @colarr if ($type eq "STAT_ONLINE");
		$tmpSize = scalar(@colarr);
		my $colstr = "";
		my $colpairstr = "";
		for( my $i = 0; $i < $tmpSize; $i++ )
		{
			$colname = @colarr[$i];
			$colname =~ tr/\t //d;
			if( exists($filterMap{$type}) )
			{
				my $filter_colarr = $filterMap{$type};
				#print "$type colname:$colname filter_colarr:@$filter_colarr\n";
				if( grep(/^$colname$/, @$filter_colarr) )
				{
					#print "next\n";
					next;
				}
			}
			if($i > 0 )
			{
				$colstr .= ", ";
				$colpairstr .= ", ";
			}
			$coldes = @desarr[$i];
			$coldes =~ tr/\t //d;
			if( $colname eq "uid" )
			{
				$colstr .= "func_get_roleid(\`$colname\`) as uid";
			}
			else
			{
				$colstr .= "\`$colname\`";
			}
			$colpairstr .= "\'$colname\' => \'$coldes\'";
		}
		my $tablename = $type;
		$tablename =~ s/STAT/LOG/;
		if( $type eq "STAT_USER" )
		{
			$tablename = "SNAP_USER";
			$colstr .= ", `acc`, `ip`, `mmc`, `regist_time`, `last_login_time`, `last_logout_time`";
		}
		$colstr .= ", \`time_stamp\`";
		
		print "/*$desname*/\n";
		print "$colpervar\[\'$tablename\'\] = \'$colstr\';\n";
		print "$colpervardes\[\'$tablename\'\] = array($colpairstr);\n\n";
	}
}

sub write_cpp_sql_case
{
	my $this = shift;
	my $typemap_p = $this->{'mTypeMap'};
	my $namemap_p = $this->{'mNameMap'};
	my $desmap_p = $this->{'mDesMap'};
	my $funcmap_p = $this->{'mFuncMap'};
	my $typeIdx = 4, my $startIdx = 2, my $tmpIdx = 0, my $tmpSize = 0;
	my $fmtsize = 0;
	my $num = 0;
	my $userIdx = $typeIdx + 1;
	printf("void StringHelper::toSql(const StringVector &vec, char *buff, unsigned &size)\n{\n");
	print "\tmemset(buff, 0, size);\n";
	print "\tif( vec.size() < 4 )\n\t{\n\t\treturn;\n\t}\n\n";
	print "\tstd::string statType = vec[$typeIdx];\n";
	while( ($type, $fz) = each(%$funcmap_p) )
	{
		if ( $num == 0 )
		{
			print "\tif ";
		}
		else
		{
			print "\telse if " 
		}
		print("(statType == $type ) \n\t{\n");
		#print("#define CAST_$type(vec, buff, size)\n");
		$tablename = $type;
		$tablename =~ s/STAT/LOG/;
		$tablename = "SNAP_USER" if ($type eq "STAT_USER");
		$tmpSize = scalar(@$fz);
		my @colarr = @$fz[$startIdx..$tmpSize-1];
		shift @colarr if ($type eq "STAT_ONLINE");
		
		my $fmtstr = @$fz[1];
		$fmtstr =~ tr/\t \"//d;
		my @fmt = split(/\|/, $fmtstr);
		unshift(@fmt, "%s") unless ($type eq "STAT_ONLINE");
		
		my ($colstr, $datastr, $colname, $extrastr, $updatestr) = ("`time_stamp`, ", "getStamp(vec[0]), ");
		
		if ($type eq "STAT_USER") #用户表更新
		{
			$updatestr = "`time_stamp` = VALUES(`time_stamp`), `areaid` = VALUES(`areaid`)";
		}
		$fmtstr = "'%s', ";
		unless( $type eq "STAT_ONLINE" )
		{
			$colstr .= "`areaid`, ";
			$datastr .= "getAreaID(vec, $userIdx), ";
			$fmtstr = "'%s', '%s', ";
		}
		$tmpSize = scalar(@fmt);
		for( my $i = 0; $i < $tmpSize; $i++ )
		{
			$tmpIdx = $typeIdx+$i+1;
			$tmpIdx += 1 if ($type eq "STAT_ONLINE");
			if($i > 0 )
			{
				$fmtstr .= ", ";
				$datastr .= ", ";
				$colstr .= ", ";
			}
			if( $fmt[$i] eq "%s" )
			{
				$fmtstr.="'%s'"
			}
			else
			{
				$fmtstr.="%s"
			}	
			$colname = @colarr[$i];
			$colname =~ tr/\t //d;
			$colstr .= "\`$colname\`";
			$datastr .= "str(vec, $tmpIdx)";
			
			if ($type eq "STAT_USER")
			{
				$updatestr .= ", \`$colname\` = VALUES(\`$colname\`)";
			}
		}
		
		if ($type eq "STAT_USER")
		{
			$extrastr = " ON DUPLICATE KEY UPDATE $updatestr"
		}
		print "\t\tsize = snprintf(buff, size, \"INSERT IGNORE INTO $tablename ($colstr) VALUES ($fmtstr)$extrastr;\",\n\t\t\t$datastr);\n";
		print "\t}\n";
		$num++;
	}
	print "}\n\n";
	
	print "const char * StringHelper::getStamp(const std::string &logStamp)\n{\n";
	#2014120811:11:27.000319
	print "\tstatic char buff[128];\n";
	my $datestr = "";
	$datestr .= "logStamp.substr(0, 4).c_str()";
	$datestr .= ", logStamp.substr(4, 2).c_str()";
	$datestr .= ", logStamp.substr(6, 2).c_str()";
	$datestr .= ", logStamp.substr(8, 8).c_str()";
	$datestr .= ", logStamp.substr(17).c_str()";
	print "\tsize_t len = snprintf(buff, sizeof(buff), \"%s-%s-%s %s %s\", $datestr);\n";
	print "\treturn std::string(buff, len).c_str();\n";
	print "}\n\n";
	
	#func str
	print "const char * StringHelper::str(const StringVector &vec, int index)\n{\n";
	print "\tstd::string retStr = \"NULL\";\n";
	print "\tif( !vec.empty() && index < (int)vec.size() )\n\t{\n";
	print "\t\tretStr = vec.at(index);\n\t}\n";
	print "\treturn retStr.c_str();\n";
	print "}\n\n";

	#func getAreaID
	print "const char * StringHelper::getAreaID(const StringVector &vec, int index)\n{\n";
	print "\tstatic std::string retStr;\n";
	print "\tretStr = \"0\";\n";
	print "\tif( !vec.empty() && index < (int)vec.size() )\n\t{\n";
	print "\t\tretStr = vec.at(index);\n";
	print "\t\tstatic const int arealen = 5;\n";
	print "\t\tif( retStr.size() < arealen )\n\t\t{\n\t\t\treturn \"0\";\n\t\t}\n\n";
	print "\t\tretStr = retStr.substr(retStr.size() - arealen);\n";
	print "\t}\n";
	print "\treturn retStr.c_str();\n";
	print "}\n\n";
}

sub write_create_sql
{
	my $this = shift;
	my $typemap_p = $this->{'mTypeMap'};
	my $namemap_p = $this->{'mNameMap'};
	my $desmap_p = $this->{'mDesMap'};
	my $funcmap_p = $this->{'mFuncMap'};
	my $typeIdx = 4, my $startIdx = 2, my $tmpIdx = 0, my $tmpSize = 0;
	my $fmtsize = 0;
	my $colname, my $fmtstr;
	print "CREATE DATABASE IF NOT EXISTS db_gl_log2 DEFAULT CHARACTER SET utf8;\nUSE db_gl_log2;\n\n";
	my $enginestr = " ENGINE=MyISAM DEFAULT CHARSET=utf8";
	while( ($type, $fz) = each(%$funcmap_p) )
	{
		my ($tablename, $tablecons, $extracons) = ("", "", "");
		$tablecons = "\tsid INT AUTO_INCREMENT PRIMARY KEY";
		unless ( $type eq "STAT_USER" )
		{
			$tablecons .= ",\n\tlog_time TIMESTAMP NOT NULL"; #log_time
		}
		unless ( $type eq "STAT_ONLINE" )
		{
			$tablecons .= ",\n\t`areaid` VARCHAR(32) NOT NULL"; #log_time
		}
		$tablename = $type;
		$tablename =~ s/STAT/LOG/;
		$tmpSize = scalar(@$fz);
		my @colarr = @$fz[$startIdx..$tmpSize-1];
		$fmtstr = @$fz[1];
		$fmtstr =~ tr/\t \"//d;
		my @fmt = split(/\|/, $fmtstr);
		unshift(@fmt, "%s") unless( $type eq "STAT_ONLINE" );
		shift(@colarr) if( $type eq "STAT_ONLINE" );
		$tmpSize = scalar(@fmt);
		#print "\nfmt:@fmt colarr:@colarr\n";
		for( my $i = 0; $i < $tmpSize; $i++ )
		{
			$colname = @colarr[$i];
			$colname =~ tr/\t //d;
			$tablecons .= ",\n";
			my ($datatype, $isnull, $comment) = &get_col_cons($colname, @fmt[$i]);
			$tablecons .= "\t\`$colname\` $datatype";
			$tablecons .= " $isnull" if $isnull;
			$tablecons .= " COMMNET '$comment'" if $comment;
		}
		
		if( $type eq "STAT_USER" )
		{
			$tablename = "SNAP_USER";
			$tablecons .= ",\n\t`acc` VARCHAR(65) COMMENT 'user plat account'";
			$tablecons .= ",\n\t`ip` VARCHAR(65) COMMENT 'user login ip'";
			$tablecons .= ",\n\t`mmc` VARCHAR(32) COMMENT 'user login mmc'";
			$tablecons .= ",\n\t`guide_step` INT COMMENT 'new player guide step'";
			$tablecons .= ",\n\t`regist_time` DATETIME COMMENT 'regist time'";
			$tablecons .= ",\n\t`last_login_time` DATETIME COMMENT 'last login time'";
			$tablecons .= ",\n\t`last_logout_time` DATETIME COMMENT 'last logout time'";
			$extracons = ",\n\n\tUNIQUE(`uid`)\n";
		}
		
		$tablecons .= ",\n\t`time_stamp` VARCHAR(32) COMMENT 'time stamp'";
		#$tablecons .= ",\n\ttime_stamp VARCHAR(32)";# COMMENT 'time stamp'";
		print "CREATE TABLE IF NOT EXISTS $tablename(\n$tablecons$extracons\n)$enginestr;\n\n";
	}
	
	my $setstr = "`regist_time` = TIMESTAMP(NEW.time_stamp), `time_stamp` = NEW.time_stamp";
	my $colarrp = $funcmap_p->{"STAT_REGIST"};
	my @arr = @$colarrp;
	shift(@arr);
	shift(@arr);
	my $num = 0;
	foreach my $colname(@arr)
	{
		$colname =~ tr/\t //d;
		$setstr .= ", `$colname` = NEW.$colname";
		$num++;
	}

	print "DELIMITER //\n";
	print "DROP TRIGGER IF EXISTS TRG_USER_REG //\n";
	print "CREATE TRIGGER TRG_USER_REG AFTER INSERT ON LOG_REGIST\n";
	print "FOR EACH ROW\nBEGIN\n\n";
	print "\tINSERT INTO SNAP_USER SET $setstr;\n\n";
	print "END;\n//\n";
	print "DELIMITER ;\n";
	
	#ip, mmc, level, acc
	
	$setstr = "`ip` = NEW.ip, `mmc` = NEW.mmc, `lv` = NEW.level, `acc` = NEW.acc, `last_login_time` = TIMESTAMP(NEW.time_stamp), `time_stamp` = NEW.time_stamp";
	
	print "DELIMITER //\n";
	print "DROP TRIGGER IF EXISTS TRG_USER_LOGIN //\n";
	print "CREATE TRIGGER TRG_USER_LOGIN AFTER INSERT ON LOG_LOGIN\n";
	print "FOR EACH ROW\nBEGIN\n\n";
	print "\tUPDATE SNAP_USER SET $setstr WHERE `uid` = NEW.uid;\n\n";
	print "END;\n//\n";
	print "DELIMITER ;\n";
	
	$setstr = "`last_logout_time` = TIMESTAMP(NEW.time_stamp), `time_stamp` = NEW.time_stamp";
	
	print "DELIMITER //\n";
	print "DROP TRIGGER IF EXISTS TRG_USER_LOGOUT //\n";
	print "CREATE TRIGGER TRG_USER_LOGOUT AFTER INSERT ON LOG_LOGOUT\n";
	print "FOR EACH ROW\nBEGIN\n\n";
	print "\tUPDATE SNAP_USER SET $setstr WHERE `uid` = NEW.uid;\n\n";
	print "END;\n//\n";
	print "DELIMITER ;\n";
	
	$setstr = "`guide_step` = NEW.gid, `time_stamp` = NEW.time_stamp";
	
	print "DELIMITER //\n";
	print "DROP TRIGGER IF EXISTS TRG_USER_GUIDE //\n";
	print "CREATE TRIGGER TRG_USER_GUIDE AFTER INSERT ON LOG_GUIDE\n";
	print "FOR EACH ROW\nBEGIN\n\n";
	print "\tUPDATE SNAP_USER SET $setstr WHERE `uid` = NEW.uid;\n\n";
	print "END;\n//\n";
	print "DELIMITER ;\n";
	
	my $sql_func_name = "func_get_areaid";
	
	my $sql_create_func =
"delimiter //
DROP FUNCTION IF EXISTS $sql_func_name //
CREATE FUNCTION $sql_func_name (_arg_userid VARCHAR(33))
	RETURNS VARCHAR(33)
	DETERMINISTIC
	COMMENT 'return areaid trim the roleid'
	RETURN RIGHT(_arg_userid, 5);
	//
//	
delimiter ;
";
	print "\n$sql_create_func\n";

	$sql_func_name = "func_get_roleid";
	my $sql_create_func =
"delimiter //
DROP FUNCTION IF EXISTS $sql_func_name //
CREATE FUNCTION $sql_func_name (_arg_userid VARCHAR(33))
	RETURNS VARCHAR(33)
	DETERMINISTIC
	COMMENT 'return roleid trim the areaid'
	RETURN LEFT(_arg_userid, LENGTH(_arg_userid)-5);
	//
//	
delimiter ;
";
	print "\n$sql_create_func\n";
	
	$sql_func_name = "func_get_userid";
	my $sql_create_func =
"delimiter //
DROP FUNCTION IF EXISTS $sql_func_name //
CREATE FUNCTION $sql_func_name (_arg_roleid VARCHAR(33), _arg_areaid VARCHAR(33))
	RETURNS VARCHAR(33)
	DETERMINISTIC
	COMMENT 'return roleid trim the areaid'
	RETURN CONCAT(_arg_roleid, _arg_areaid);
	//
//	
delimiter ;
";
	my $dbuser = "ali2";
	my $dbpass = "ali002";
	print "\n$sql_create_func\n\n";
	print "GRANT SELECT ON *.* TO $dbuser IDENTIFIED BY '$dbpass';FLUSH PRIVILEGES;\n";
	print "GRANT UPDATE ON *.* TO $dbuser IDENTIFIED BY '$dbpass';FLUSH PRIVILEGES;\n";
	print "GRANT DELETE ON *.* TO $dbuser IDENTIFIED BY '$dbpass';FLUSH PRIVILEGES;\n";
	print "GRANT INSERT ON *.* TO $dbuser IDENTIFIED BY '$dbpass';FLUSH PRIVILEGES;\n";
	print "GRANT EXECUTE ON *.* TO $dbuser IDENTIFIED BY '$dbpass';FLUSH PRIVILEGES;\n";
	print "GRANT ALL ON *.* TO $dbuser@'127.0.0.1' IDENTIFIED BY '$dbpass';FLUSH PRIVILEGES;\n\n";

}

sub get_col_cons
{
	my $colname = shift;
	my $fmt = shift;
	if( $colname eq "uid" )
	{
		return ("VARCHAR(33)", "NOT NULL");
	}
	if( $colname eq "areaid" )
	{
		return ("VARCHAR(32)", "NOT NULL");
	}
	elsif( $colname eq "acc" || $colname eq "ip")
	{
		return ("VARCHAR(65)");
	}
	else
	{
		if($fmt eq "%d")
		{
			return "INT"
		}
		else
		{
			return "VARCHAR(32)"
		}
	}
}


1; #end of file