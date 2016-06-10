#!/usr/bin/perl -w
use DBI;
use strict;
use warnings;

my $HOME = $ENV{"HOME"};
my $db_url_stylish = '';

#my $db_url = glob( "$HOME/.mozilla/firefox/*.default/stylish.sqlite");
my $db_chrome_url = glob( "~/.config/chromium/Default/databases/Databases.db");
my $db_chrome = DBI->connect("dbi:SQLite:$db_chrome_url", "", "",
{RaiseError => 1, AutoCommit => 1});
my $extn_dir = $db_chrome->selectall_arrayref('SELECT id, origin FROM Databases where name like "stylish"');

print '
======================================================================
==     This script is experimental and may not work as expected.    ==
==     ----------------- you have been warned! -----------------    ==
======================================================================
';


print "These are the locations of stylish Database's that chrome will use\n";
foreach my $row (@$extn_dir) {
    my ($id, $origin) = @$row;
    $db_url_stylish= glob( "~/.config/chromium/Default/databases/$origin/$id");
    print "\t$db_url_stylish\n";
}

if ( @$extn_dir != 1 ) {
    print "there are " . scalar @$extn_dir . " possible stylish Databases available for Chrome.\n";
    print "Unfortunately we require there to be exactly one.\n\n";
    print "\n\nexiting....\n\n";
    exit
}

print "\n";


#my $db_url_stylish = glob( "~/.config/chromium/Default/databases/$extn_dir/");

my $db = DBI->connect("dbi:SQLite:$db_url_stylish", "", "", {RaiseError => 1, AutoCommit => 1}) || die;

#$db->do("CREATE TABLE n (id INTEGER PRIMARY KEY, f TEXT, l TEXT)");
#$db->do("INSERT INTO n VALUES (NULL, 'john', 'smith')");
my $all = $db->selectall_arrayref('SELECT id, name, url, updateUrl, code FROM styles where code like "%domain(_vector.im%" and url not null');
my $ChangesCommitted=0;

foreach my $row (@$all) {
    my ($id, $name, $url, $updateUrl, $code) = @$row;
    my $filename = $url // '';
    $filename =~ s/.*\///;
    $filename .= '-chrome.css';
    print "$id | $name  =>  $filename \t\t: ";
    open( my $file, '>', $filename);
    print $file "$code";
    close $file;
    chomp( my $diff = `git diff --color $filename`);
    if ($diff) {
        print "CHANGED\n";
        print "\n===========================================================================\n";
        print "Diff Results from git diff --color $filename are\n";
        print "===========================================================================\n";
        print "$diff\n";
        print "===========================================================================\n";
        print "Please enter a commit message for the above changes: ";
        my $input = <STDIN>;
        chomp $input;
        if ($input) {
            $ChangesCommitted=1;
            print "\nrunning: git commit $filename -m \"$input\"\n\n";
            chomp( my $commit = `git commit $filename -m "$input"`);
            print "\n$commit\n";
        } else {
            print "Skipping Commit as no commit message was entered\n";
            print "===========================================================================\n";
        }
    } else {
        print "same\n";
    };

}

if ($ChangesCommitted) {
    print "\n\n===========================================================================\n";
    print "You committed some changes please don't forget to push to github with\n";
    print "===========================================================================\n";
    print "git push\n";
    print "===========================================================================\n";
}