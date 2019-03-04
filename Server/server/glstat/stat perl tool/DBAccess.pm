		package DBAccess;

use DBI;

#construct function param(enddate, shiftdays )
sub new
{
	my $class = shift;			#need class name
	my $configfile = shift;	#config file name
	
	#member data
	my $dbtype = "mysql";
	my $dbname = "db_gl_log";
	my $host = "localhost";
	my $user = "root";
	my $passwd = "";
	my $port = 3306;
	
	if( $configfile and -e $configfile and open(CONF_FILE, $configfile) )
	{
		while(my $line= <CONF_FILE>)
		{
			#print "line:$line";
			if( $line =~ /dbtype\s*=\s*(\S+)/i )
			{
				$dbtype = $1;
				#print "dbtype:$dbtype\n";
			}
			elsif( $line =~ /dbname\s*=\s*(\S+)/i )
			{
				$dbname = $1;
				#print "dbname:$dbname\n";
			}
			elsif( $line =~ /host\s*=\s*(\S+)/i )
			{
				$host = $1;
				#print "host:$host\n";
			}
			elsif( $line =~ /user\s*=\s*(\S+)/i )
			{
				$user = $1;
				#print "user:$user\n";
			}
			elsif( $line =~ /port\s*=\s*(\d+)/i )
			{
				$port = $1;
				#print "port:$port\n";
			}
			elsif( $line =~ /passwd\s*=\s*(\S+)/i )
			{
				$passwd = $1;
				#print "passwd:$passwd\n";
			}
		}
		close(CONF_FILE);
	}

	my $this = {
		"dbtype" => $dbtype,
		"dbname" => $dbname,
		"host" => $host,
		"user" => $user,
		"password" => $passwd,
		"port" => $port
		};					#a new hash reference

	bless $this, $class;	
	
	return $this;
}

sub init
{
	my $this = shift;
	unless( $this->{'dbh'} )
	{
		my ($dbtype, $dbname, $host, $user, $password, $port) = (
		$this->{dbtype},
		$this->{dbname},
		$this->{host},
		$this->{user},
		$this->{password},
		$this->{port}
		);
		my $dbh = DBI->connect("DBI:$dbtype:database=$dbname;host=$host;port=$port", $user, $password) or 
							die "Can't connect database:".DBI->errstr;

		#my @arr = DBI->data_sources("mysql");
		#print "databases:@arr\n";
		$dbh->{RaiseError} = 1;
		$dbh->{PrintError} = 1;
		$this->{dbh} = $dbh;
	}
	return 0;
}

sub release
{
	my $this = shift;
	my $dbh = $this->{dbh} or die "dbh not inited";
	$dbh->disconnect if $dbh;
}

sub query
{
	my $this = shift;
	my $sql = shift;
	my $dbh = $this->{dbh} or die "dbh not inited";
	#my $ret = $dbh->do( $sql ) or die "Can't dbh sql ".$dbh->errstr;
	#print "ret:$ret\n";
	my $sth = $dbh->prepare( $sql ) or die "Can't preprare sql ".$dbh->errstr;
	my $rows = $sth->execute() or die "Can't execute sql ".$dbh->errstr;
	#my $rows = $sth->rows();
	
	#my $null_possible = $sth->{NULLABLE};
	#print "null_possible:$null_possible\n";
	#print "num of fileds:" . $sth->{NUM_OF_FIELDS}. "\n";
	#print "sql:\n$sql\n";
	#print "rows:$rows\n";
	print "query filed" if $rows < 0;
	$sth->finish;
	
	return $rows;
}



1;#end of the file