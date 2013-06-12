# -*- perl -*-
use strict;
use warnings;
use Test::More tests => 118 * 2 + 1;

BEGIN { use_ok( 'DBIx::Array' ); }

my $connection={
                 "DBD::SQLite" => "dbi:SQLite:dbname=:memory",
                 "DBD::CSV"    => "dbi:CSV:f_dir=.",
                 "DBD::XBase"  => "dbi:XBase:.",
               };

foreach my $driver ("DBD::CSV", "DBD::XBase") { 
  #I can't get "DBD::SQLite" to pass tests on many platforms.
  my $dba=DBIx::Array->new;
  isa_ok($dba, 'DBIx::Array');

  SKIP: {
    eval "require $driver";
    skip "Database driver $driver not installed", 113 if $@;
    diag("Found database driver $driver");
  
    die("connection not defined for $driver") unless $connection->{$driver};
    $dba->connect($connection->{$driver}, "", "", {RaiseError=>0, AutoCommit=>1});
    my $table="dbixarray";
  
   #$dba->dbh->do("DROP TABLE $table");
    $dba->dbh->do("CREATE TABLE $table (F1 INTEGER,F2 CHAR(1),F3 VARCHAR(10))");
    is($dba->update("INSERT INTO $table (F1,F2,F3) VALUES (?,?,?)", 0,1,2), 1, 'insert');
    is($dba->update("INSERT INTO $table (F1,F2,F3) VALUES (?,?,?)", 1,2,3), 1, 'insert');
    is($dba->update("INSERT INTO $table (F1,F2,F3) VALUES (?,?,?)", 2,3,4), 1, 'insert');
    
    isa_ok($dba->sqlcursor("SELECT * FROM $table"), 'DBI::st', 'sqlcursor');
    
    my $array=$dba->sqlarray("SELECT F1,F2,F3 FROM $table WHERE F1 = ?", 0);
    isa_ok($array, "ARRAY", '$dba->sqlarray scalar context');
    is(scalar(@$array), 3, 'scalar(@$array)');
    is($array->[0], 0, '$dba->sqlarray->[0]');
    is($array->[1], 1, '$dba->sqlarray->[1]');
    is($array->[2], 2, '$dba->sqlarray->[2]');
    
    my @array=$dba->sqlarray("SELECT F1,F2,F3 FROM $table WHERE F1 = ?", 0);
    is(scalar(@array), 3, 'scalar(@$array)');
    is($array[0], 0, '$dba->sqlarray[0]');
    is($array[1], 1, '$dba->sqlarray[1]');
    is($array[2], 2, '$dba->sqlarray[2]');
    
   SKIP: {
     skip "Database driver $driver does not support named parameters", 4 if $driver eq "DBD::CSV";
     my @array=$dba->sqlarray("SELECT F1,F2,F3 FROM $table WHERE F1 = :zero", {zero=>0});
     is(scalar(@array), 3, 'named bind scalar(@$array)');
     is($array[0], 0, 'named bind $dba->sqlarray[0]');
     is($array[1], 1, 'named bind $dba->sqlarray[1]');
     is($array[2], 2, 'named bind $dba->sqlarray[2]');
   }
    
    my $hash=$dba->sqlhash("SELECT F1,F2 FROM $table");
    isa_ok($hash, "HASH", 'sqlarray scalar context');
    is($hash->{'0'}, 1, 'sqlhash');
    is($hash->{'1'}, 2, 'sqlhash');
    is($hash->{'2'}, 3, 'sqlhash');
    
    my %hash=$dba->sqlhash("SELECT F1,F2 FROM $table");
    is($hash{'0'}, 1, 'sqlhash');
    is($hash{'1'}, 2, 'sqlhash');
    is($hash{'2'}, 3, 'sqlhash');
    
    $array=$dba->sqlarrayarray("SELECT F1,F2,F3 FROM $table ORDER BY F1");
    isa_ok($array, "ARRAY", 'sqlarrayarray scalar context');
    isa_ok($array->[0], "ARRAY", 'sqlarrayarray row 1');
    isa_ok($array->[1], "ARRAY", 'sqlarrayarray row 2');
    isa_ok($array->[2], "ARRAY", 'sqlarrayarray row 3');
    is($array->[0]->[0], 0, 'data');
    is($array->[0]->[1], 1, 'data');
    is($array->[0]->[2], 2, 'data');
    is($array->[1]->[0], 1, 'data');
    is($array->[1]->[1], 2, 'data');
    is($array->[1]->[2], 3, 'data');
    is($array->[2]->[0], 2, 'data');
    is($array->[2]->[1], 3, 'data');
    is($array->[2]->[2], 4, 'data');
    
    @array=$dba->sqlarrayarray("SELECT F1,F2,F3 FROM $table ORDER BY F1");
    isa_ok($array[0], "ARRAY", 'sqlarrayarray row 1');
    isa_ok($array[1], "ARRAY", 'sqlarrayarray row 2');
    isa_ok($array[2], "ARRAY", 'sqlarrayarray row 3');
    is($array[0]->[0], 0, 'data');
    is($array[0]->[1], 1, 'data');
    is($array[0]->[2], 2, 'data');
    is($array[1]->[0], 1, 'data');
    is($array[1]->[1], 2, 'data');
    is($array[1]->[2], 3, 'data');
    is($array[2]->[0], 2, 'data');
    is($array[2]->[1], 3, 'data');
    is($array[2]->[2], 4, 'data');
    
    $array=$dba->sqlarrayarrayname("SELECT F1,F2,F3 FROM $table ORDER BY F1");
    isa_ok($array, "ARRAY", 'sqlarrayarrayname scalar context');
    isa_ok($array->[0], "ARRAY", 'sqlarrayarrayname header');
    isa_ok($array->[1], "ARRAY", 'sqlarrayarrayname row 1');
    isa_ok($array->[2], "ARRAY", 'sqlarrayarrayname row 2');
    isa_ok($array->[3], "ARRAY", 'sqlarrayarrayname row 3');
    is($array->[0]->[0], 'F1', 'data');
    is($array->[0]->[1], 'F2', 'data');
    is($array->[0]->[2], 'F3', 'data');
    is($array->[1]->[0], 0, 'data');
    is($array->[1]->[1], 1, 'data');
    is($array->[1]->[2], 2, 'data');
    is($array->[2]->[0], 1, 'data');
    is($array->[2]->[1], 2, 'data');
    is($array->[2]->[2], 3, 'data');
    is($array->[3]->[0], 2, 'data');
    is($array->[3]->[1], 3, 'data');
    is($array->[3]->[2], 4, 'data');
    
    @array=$dba->sqlarrayarrayname("SELECT F1,F2,F3 FROM $table ORDER BY F1");
    isa_ok($array[0], "ARRAY", 'sqlarrayarrayname header');
    isa_ok($array[1], "ARRAY", 'sqlarrayarrayname row 1');
    isa_ok($array[2], "ARRAY", 'sqlarrayarrayname row 2');
    isa_ok($array[3], "ARRAY", 'sqlarrayarrayname row 3');
    is($array[0]->[0], 'F1', 'data');
    is($array[0]->[1], 'F2', 'data');
    is($array[0]->[2], 'F3', 'data');
    is($array[1]->[0], 0, 'data');
    is($array[1]->[1], 1, 'data');
    is($array[1]->[2], 2, 'data');
    is($array[2]->[0], 1, 'data');
    is($array[2]->[1], 2, 'data');
    is($array[2]->[2], 3, 'data');
    is($array[3]->[0], 2, 'data');
    is($array[3]->[1], 3, 'data');
    is($array[3]->[2], 4, 'data');
    
    $array=$dba->sqlarrayhashname("SELECT F1,F2,F3 FROM $table ORDER BY F1");
    isa_ok($array, "ARRAY", 'sqlarrayhashname scalar context');
    isa_ok($array->[0], "ARRAY", 'sqlarrayhashname header');
    isa_ok($array->[1], "HASH", 'sqlarrayhashname row 1');
    isa_ok($array->[2], "HASH", 'sqlarrayhashname row 2');
    isa_ok($array->[3], "HASH", 'sqlarrayhashname row 3');
    is($array->[0]->[0], 'F1', 'data');
    is($array->[0]->[1], 'F2', 'data');
    is($array->[0]->[2], 'F3', 'data');
    is($array->[1]->{'F1'}, 0, 'data');
    is($array->[1]->{'F2'}, 1, 'data');
    is($array->[1]->{'F3'}, 2, 'data');
    is($array->[2]->{'F1'}, 1, 'data');
    is($array->[2]->{'F2'}, 2, 'data');
    is($array->[2]->{'F3'}, 3, 'data');
    is($array->[3]->{'F1'}, 2, 'data');
    is($array->[3]->{'F2'}, 3, 'data');
    is($array->[3]->{'F3'}, 4, 'data');
    
    @array=$dba->sqlarrayhashname("SELECT F1,F2,F3 FROM $table ORDER BY F1");
    isa_ok($array[0], "ARRAY", 'sqlarrayhashname header');
    isa_ok($array[1], "HASH", 'sqlarrayhashname row 1');
    isa_ok($array[2], "HASH", 'sqlarrayhashname row 2');
    isa_ok($array[3], "HASH", 'sqlarrayhashname row 3');
    is($array[0]->[0], 'F1', 'data');
    is($array[0]->[1], 'F2', 'data');
    is($array[0]->[2], 'F3', 'data');
    is($array[1]->{'F1'}, 0, 'data');
    is($array[1]->{'F2'}, 1, 'data');
    is($array[1]->{'F3'}, 2, 'data');
    is($array[2]->{'F1'}, 1, 'data');
    is($array[2]->{'F2'}, 2, 'data');
    is($array[2]->{'F3'}, 3, 'data');
    is($array[3]->{'F1'}, 2, 'data');
    is($array[3]->{'F2'}, 3, 'data');
    is($array[3]->{'F3'}, 4, 'data');
    
    my $sql="SELECT F1,F2,F3 FROM $table";
    is($dba->sqlsort($sql,1), "$sql ORDER BY 1 ASC", 'sqlsort');
    is($dba->sqlsort($sql,-1), "$sql ORDER BY 1 DESC", 'sqlsort');
    
    $dba->dbh->do("DROP TABLE $table");
  }
}
