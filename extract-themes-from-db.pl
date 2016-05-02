#!/usr/bin/perl -w
use DBI;
use strict;
use warnings;

my $HOME = $ENV{"HOME"};

#my $db_url = glob( "$HOME/.mozilla/firefox/*.default/stylish.sqlite");
my $db_url = glob( "~/.mozilla/firefox/*.default/stylish.sqlite");

my $db = DBI->connect("dbi:SQLite:$db_url", "", "",
{RaiseError => 1, AutoCommit => 1});

#$db->do("CREATE TABLE n (id INTEGER PRIMARY KEY, f TEXT, l TEXT)");
#$db->do("INSERT INTO n VALUES (NULL, 'john', 'smith')");
my $all = $db->selectall_arrayref('SELECT id, name, url, updateUrl, code FROM styles where code like "%domain(_vector.im%" and url not null');

foreach my $row (@$all) {
    my ($id, $name, $url, $updateUrl, $code) = @$row;
    my $filename = $url // '';
    $filename =~ s/.*\///;
    $filename .= '.css';
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
