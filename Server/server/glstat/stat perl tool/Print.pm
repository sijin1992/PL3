			package Print;
#use utf8;
###################################################
##	a print module for glstat
##	
##	need member data
##	mDataTime;	#now datetime string
##	mTitle;		#title string
##	mDataTab;	#stated data table, a hash table ptr
##	mNameTab;	#name table
##	mRowList;	#rowlist;
##
###################################################	

#need arg (data_table_ptr, [title]);
sub new
{	
	my $class = shift;
	my $title = shift;
	
	unless( $title )
	{
		$title = "古龙数据统计";
	}
	
	my $this = {};
	
	$this->{'mTitle'} = $title;
	$this->{'mDateTime'} = `date`;
	
	bless $this, $class;
	
	return $this;
}

#print stat info(dataptr, rowlist_ptr, namelist_ptr);
sub do_print_table
{
	my $this = shift;
	$this->{'mDataTab'} = shift;
	$this->{'mRowList'} = shift;
	$this->{'mNameTab'} = shift;
	if( @_ >= 1 )
	{
		$this->{'mTitle'} = shift;
	}

	$this->write_header();
	$this->write_body();
	$this->write_foot();
}

#need a bar_data_arr pointer
sub do_print_bar
{
	my $this = shift;
	my $bar_data_arr = shift;
	$this->write_header();
	&write_bars($bar_data_arr);
	$this->write_foot();
}

#need a datalist pointer, header array pointer
sub do_print_list
{
	my $this = shift;
	my $type = shift;
	my $datalist = shift;
	my $headerarr = shift;
	$this->write_header();
	print "listheader:@$headerarr\n";
	&write_list_header($type, $headerarr);
	&write_lists($datalist);
	$this->write_foot();
}

#need a titler, datamap pointer
sub do_print_help
{
	my $this = shift;
	my $title = shift;
	my $datamap = shift;
	#$this->write_header();
	&write_help_title($title);
	&write_help_body($datamap);
	#$this->write_foot();
}

sub write_header
{
	my $this = shift;
	local $title = $this->{'mTitle'};
	local $datetime = `date`;
	&write_format("FORMAT_HEADER");
}

sub write_format
{
	my $format = shift;
	
	my $OUTFILE = $ENV{'PRINT_OUT_FILE'} ? $ENV{'PRINT_OUT_FILE'} : \*STDOUT;
	local ($savefile, $saveformat);
        $savefile = select($OUTFILE);
        #binmode(OUTFILE, "utf-8");
        $saveformat = $~;
        $~ = $format;
        write;
        $~ = $saveformat;
        select($savefile);
	
}


sub write_body
{
	my $this = shift; 
	my $name_tb_p = $this->{'mNameTab'};
	my $data_tb_p = $this->{'mDataTab'};
	my $row_p = $this->{'mRowList'};
	&write_format("FORMAT_TOP_LINE");
	foreach $type (@$row_p)
	{
		my $name = $name_tb_p->{$type};
		unless( $name )
		{
			$name = $type;
		}
		my $arr = $data_tb_p->{$type};
		#printf("name:$name arr:@$arr\n");
		&write_row($name, @$arr);
	}

}

#a bar_data_arr pointer
sub write_bars
{
	my $bar_data_arr_p = shift;
	
	foreach $bar( @$bar_data_arr_p )
	{
		my $len = @$bar[0];
		my $prestr = @$bar[1];
		my $endstr= @$bar[2];
		&write_one_bar($len, $prestr, $endstr);
	}
}

#need (bar_len, prestr, endstr)'
sub write_one_bar
{
	my $len = shift;
	my $prestr = shift;
	my $endstr = shift;
	local $bar = "";
	local $w = "";
	for($i=0; $i < $len; $i++)
	{
		$bar .= "_";
		$w .= " ";
	}
	local $pr = $prestr;
	local $str = $endstr;
	&write_format("FORMAT_ROW_BAR");
}

#write lists header(header_arr_ptr)
sub write_list_header
{
		local $type = shift;
		my $header_p = shift;
		#print("header_p:$header_p, @$header_p\n");
		local $headerstr = join(" | ", @$header_p);
		#print("headerstr:$headerstr\n");
		&write_format("FORMAT_LIST_HEADER");
}

#write lists need(datalist_ptr)
sub write_lists
{
		my $lists_p = shift;
		my $data_p;
		local $rownum = 0;
		local $leftstr;
		local $datastr;
		foreach $left (sort {$b<=>$a} keys (%$lists_p))
		#while( ($left, $data_p) = each(%$lists_p) )
		{
			$leftstr = $left;
			$data_p = $lists_p->{$left};
			#printf("leftstr:$leftstr, data_p:$data_p @$data_p\n");
			&write_format("FORMAT_LIST_LEFT");
			foreach $item (@$data_p)
			{
				$rownum++;
				$datastr = join( "|", @$item);
				#printf("item:$item, @$item\n datastr:$datastr\n");
				&write_format("FORMAT_LIST_ROW");
			}
		}
}

#write help_title(title)
sub write_help_title
{
		local $helptitle = shift;
		&write_format("FORMAT_HELP_TITLE");
}

#write lists need(body_data_map)
sub write_help_body
{
		my $datamap_p = shift;
		my $num = keys %$datamap_p;
		#printf("lists_p:$lists_p num:$num space:$space\n");
		local $keystr;
		local $valstr;
		foreach $key (sort keys (%$datamap_p))
		{
			$keystr = $key;
			$valstr = $datamap_p->{$key};
			&write_format("FORMAT_HELP_ROW");
		}
}


#write one row,(name, data.....)
sub write_row
{
	local $row_name = shift;
	local ($data1, $data2, $data3, $data4, $data5, $data6, $data7) = @_;
	$data1 = "" unless $data1;
	$data2 = "" unless $data2;
	$data3 = "" unless $data3;
	$data4 = "" unless $data4;
	$data5 = "" unless $data5;
	$data6 = "" unless $data6;
	$data7 = "" unless $data7;
	#printf("$row_name, $data1, $data2, $data3, $data4, $data5, $data6\n");
	&write_format("FORMAT_ROW");
}

#write foot
sub write_foot
{
	&write_format("FORMAT_FOOT");	
}


format STDOUT_TOP = 
Star Report.
Page @<<
$%


.


format FORMAT_HEADER =
				                        =========================================
				                        =                                       =
				                               @||||||||||||||||||||||||||       
					$title
				                        =                                       =
				                        =========================================
						
				                        @||||||||||||||||||||||||||||||||||||||||
				$datetime
.

format FORMAT_TOP_LINE =


				 ________________________________________________________________________________________________
.

format FORMAT_ROW =
				|                    |          |          |          |          |          |          |          |
				  @||||||||||||||||| | @|||||||   @|||||||   @|||||||   @|||||||   @|||||||   @|||||||   @||||||| 			
	         $row_name,$data1,$data2,$data3,$data4,$data5,$data6,$data7	
				|____________________|__________|__________|__________|__________|__________|__________|__________|
.

format FORMAT_ROW_BAR =
       | @*
            $bar
       ||@*| 
            $w
 @<<<< ||@*| @*
 $pr,       $w, $str
       ||@*|    
            $bar
       |
.

format FORMAT_LIST_HEADER =


Stat:@<<<<<<< 
 $type
              ...| @* |
						  $headerstr 
						 
.

format FORMAT_LIST_LEFT =
@>>>>>>>>>>> ->__________________
$leftstr
					
.

format FORMAT_LIST_ROW =
         @>>>>|@*
             $rownum, $datastr
.

format FORMAT_HELP_TITLE =
  @*
  $helptitle
					
.

format FORMAT_HELP_ROW =
        @<<<<<<<<<<<< => @*
        $keystr, $valstr	
.

format FORMAT_FOOT =

				                        ____________________END__________________


.

1;