$usage = "Usage: hexconv.pl <hexfile> <hex start address> <hex table size>";

$file = shift(ARGV);
if($file eq ''){die $usage};

$start_addr = shift(ARGV);
if($start_addr eq ''){die $usage};
$start_addr = hex $start_addr;

$table_size = shift(ARGV);
if($table_size eq ''){die $usage};
$table_size = hex $table_size;


open(INFO, $file);
@lines = <INFO>;
close(INFO);

$min_address = 65536;
$max_address = 0;
$bytes_read = 0;

@data_array = ();
for($i=0;$i<65536;$i++){ $data_array[$i] = 0; };

$line_no = 0;
foreach $line (@lines){
  
  chomp($line);
  $line_no++;
  
  if(length($line)>=11 and substr($line, 0, 1) eq ':'){
    $total_length = length($line);
    $len =  substr($line, 1,2);
    $addr = substr($line, 3,4);
    $type = substr($line, 7,2);
    $csum = substr($line, $total_length-3,2);
    $data = substr($line, 9,$total_length-11);
    
    # Process data records and utterly ignore all others
    # Note that the checksum field is ignored too; we rely on the correctness
    # of the hex file.
    if($type eq '00'){
      $len = hex $len;
      $first_addr = hex $addr;
      $last_addr = $first_addr + $len - 1;
      
      if($first_addr < $min_address){
        $min_address = $first_addr;
      };
      if($last_addr > $max_address){
        $max_address = $last_addr;
      };
      
      $chksum = 0;
      for($i=0;$i<$len;$i++){
        $data_byte = substr($line, 9+$i*2, 2);
        $data_byte = hex $data_byte;
        $chksum += $data_byte;
        $data_array[$first_addr+$i] = $data_byte;
        $bytes_read++;
      }
    }
    
  }
  else{
    die "Wrong format in line $line_no\n";
  }
}


printf "Done. %d (%0xh) data bytes read.\n", $bytes_read, $bytes_read;

if($min_address < $start_addr or $max_address < $start_addr){
  die "Hex data out of bounds";
}

$upper_bound = $start_addr + $table_size;

if($min_address > $upper_bound or 
        $max_address > $upper_bound){
  die "Hex data out of bounds: ".$upper_bound;
}

printf "Data address span [%04x : %04x]\n", $min_address, $max_address;
$bytes_defaulted = ($max_address-$min_address+1)-$bytes_read;
if($bytes_defaulted > 0){
  printf "(%d bytes defaulted to 0)\n", $bytes_defaulted;
}

# TODO argv
$col = 0;
for($i=0;$i<$table_size;$i++){
  $q = $data_array[$start_addr+$i];
  #$qb = to_bin($q, 8);
  printf "X\"%02x\"", $q;
  if($i<$table_size-1){
    printf ",";
  }
  $col++;
  if($col eq 8){
    print "\n";
    $col = 0;
  }
}



sub to_bin {
  my $number = shift(@_) * 1;
  my $length = shift(@_);
  
  $n = $number;
  $r = '';
  for( my $i=$length-1;$i>=0;$i--){
    $d = 2 ** $i;
    
    if($n >= $d){
      $r = $r.'1';
      $n = $n - $d;
    }
    else{
      $r = $r.'0';
    }
  }
  
  return $r;
}
