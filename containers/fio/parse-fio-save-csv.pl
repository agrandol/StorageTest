#!/usr/bin/perl
#
# Parse fio test output
#
# Will parse multiple fio output files converting the results to CWV.
#
# Call as follows: perl parse-fio-save-csv.pl <file1> <file2> ... <filen>
#
use Time::Local;

# to convert abbreviated month to a number
my %monthNumber = (
	'Jan'  =>  1,
	'Feb'  =>  2,
	'Mar'  =>  3,
	'Apr'  =>  4,
	'May'  =>  5,
	'Jun'  =>  6,
	'Jul'  =>  7,
	'Aug'  =>  8,
	'Sep'  =>  9,
	'Oct'  => 10,
	'Nov'  => 11,
	'Dec'  => 12,
);

# Scan the input file for results, output the desired results as JSON
sub scan($) {
    my $filename = shift;
    my $lineNum = 0;
    my $testName = '';
    my $blockSize = '';
    my $testType = '';
    my $ioengine = '';
    my $iodepth = 0;
    my $testDayOfWeek = '';
    my $month = '';
    my $day = 0;
    my $hourMinuteSecond = '';
    my $year = 0;
    my $ioResult = 0;
    my $ioUnits = '';
    my $bwResult = 0;
    my $bwUnits = '';
    my $iopsResult = 0;
    my $runtime = 0;
    my $runtimeUnits = '';

    # open the file for processing
    open(F,$filename);

    # while not end of file
    while($_ = <F>) {
        $lineNum++;

        m#(\w+): \(.*\): rw=(\w+), bs=([\w\d\-\/]+), ioengine=(\w+), iodepth=(\d+)# and do {
            $testName = $1;
            $testType = $2;
            $blockSize = $3;
            $ioengine = $4;
            $iodepth = $5;
#            print "Line: " . $lineNum . "\n"; #" (" . $1 . ")\n";
        };

        # Test name and date
        m#(\w+\-?\w*\-?\w*): \(.*\): err= \d+: pid=\d+: (\w+) (\w+)\s+(\d+) (\d+:\d+:\d+) (\d+)# and do {
            $testName = $1;
            $testDayOfWeek = $2;
            $month = $monthNumber{$3};
            $day = $4;
            $hourMinuteSecond = $5;
            $year = $6;
 #           print "Line: " . $lineNum . "\n"; #" (" . $1 . ")\n";
        };

        # Test results
        m#\s* write: io=(\d+\.?\d*)(\w+), bw=(\d+\.?\d*)(\w+/\w+), iops=(\d+), runt=\s*(\d+)(\w+)# and do { # iops=(\d+), runt=(\d+)(\w+)# and do {
            $ioResult = $1;
            $ioUnits = $2;
            $bwResult = $3;
            $bwUnits = $4;
            $iopsResult = $5;
            $runtime = $6;
            $runtimeUnits = $7;
  #          print "Line: " . $lineNum . "\n"; #" (" . $1 . ")\n";
        };
    }

    # format extracted data
    # set doc primary key
    my $endTime = sprintf("%04d-%02d-%02d %s", $year, $month, $day, $hourMinuteSecond);
    #print "endTime = " . $endTime . "\n";
    my ($yyyy,$mm,$dd,$hour,$min,$sec) = split(/[\s-:]+/, $endTime);
    #2017-10-03T19:24:04.321Z
    my $timestamp = sprintf("%04d-%02d-%02dT%sZ", $year, $month, $day, $hourMinuteSecond);
    #print "yyyy,mm,dd,hour,min,sec = " . $yyyy . "-" . $mm . "-" . $dd . "-" . $hour . "-" . $min . "-" . $sec . "\n";
    #my $timestamp = timelocal($sec,$min,$hour,$dd,$mm-1,$yyyy);
    #print $timestamp,"\n",scalar localtime $endTime;

    # gather metadata
    my $persistentStorageName = $ENV{PERSISTENT_STORAGE_NAME};
    my $persistentStorageVersion = $ENV{PERSISTENT_STORAGE_VERSION};
    my $jobname = $ENV{JOB_NAME};
    my $podname = $ENV{HOSTNAME};
    my $testDirectory = $ENV{DATA_DIR};
    chomp($fileSystemType=`stat --file-system --format=%T $testDirectory`);
    
    (my $id = $filename) =~ /(pm-fio-ss-\d+)/g;

    #
    # Header line
    #
    my $csvOutput = "metric, persistentStorageName, persistentStorageVersion, jobname, podname, testDirectory, fileSystemType, type, ";
    $csvOutput .= "testName, blockSize, testType, endTime, ioengine, iodepth, result, resultUnits, runtime, timestamp, runtimeUnits\n";

    #
    # io results
    #
    $resultType = "io";
    $csvOutput .= "fio, $persistentStorageName, $persistentStorageVersion, $jobname, $podname, $testDirectory, $fileSystemType, $resultType, ";
    $csvOutput .= "$testName, $blockSize, $testType, $endTime, $ioengine, $iodepth, $ioResult, $ioUnits, $runtime, $timestamp, $runtimeUnits\n";

    #
    # bw results
    #
    $resultType = "bw";
    $csvOutput .= "fio, $persistentStorageName, $persistentStorageVersion, $jobname, $podname, $testDirectory, $fileSystemType, $resultType, ";
    $csvOutput .= "$testName, $blockSize, $testType, $endTime, $ioengine, $iodepth, $bwResult, $bwUnits, $runtime, $timestamp, $runtimeUnits\n";
  
    #
    # iops results
    #
    $resultType = "iops";
    $csvOutput .= "fio, $persistentStorageName, $persistentStorageVersion, $jobname, $podname, $testDirectory, $fileSystemType, $resultType, ";
    $csvOutput .= "$testName, $blockSize, $testType, $endTime, $ioengine, $iodepth, $iopsResult, IOPS, $runtime, $timestamp, $runtimeUnits\n";

    print $csvOutput;
}

# for each file passed in
foreach my $file ( @ARGV ) {
    # process the individual file
	scan($file);
}
