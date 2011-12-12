#!/usr/bin/perl -w
 
# ttytterwall
#
# A simple twitterwall script.
# v1.0
# Author: @pixel1983
 
# INSTALLATION / REQUIREMENTS (for example Ubuntu):
# sudo apt-get install libwww-mechanize-perl libjson-perl
# for Fedora:
# yum install perl-WWW-Mechanize perl-JSON
# Save this pad to ttytterwall.perl file, run "perl ttytterwall.perl" from console.
 
use strict;
use WWW::Mechanize;
use JSON -support_by_pp;
 
binmode(STDOUT, ":utf8"); #Fixes umlaut troubles
 
# Settings
my $tweetsPerRequest = "15";
my $searchExpression = "%23piraten"; # for now: only letters and numbers, no spaces! (# = %23)
my $interval = 30; # Request interval in seconds, minimum 24 (equals 150 requests per hour)
my $addHours = 1; # Values between 0 and 23, depending on your time zone.
 
print("\n ########## ttytterwall ##########");
print("\n Search expression: $searchExpression");
print("\n Update interval: $interval seconds");
 
fetch_json_page("http://search.twitter.com/search.json");
 
sub fetch_json_page
{
  my ($json_url) = @_;
  my $browser = WWW::Mechanize->new();
 
my $refreshurl = "?q=$searchExpression&result_type=recent&rpp=$tweetsPerRequest";
 
$| = 1;
while (1){
  eval{
        my $url = "$json_url$refreshurl";
 
    # download the json page:
    # print "\n\nGetting $url\n";
    $browser->get( $url );
    my $content = $browser->content();
    my $json = new JSON;
    
    # these are some nice json options to relax restrictions a bit:
    my $json_text = $json->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->decode($content);
 
        $refreshurl = $json_text->{refresh_url};
        #print(" +++++++++++++++++++++++++ $refreshurl ++++++++++++ ");
        if($refreshurl){}else{print"\n\n\nERROR, refresh_url is empty! (Perhaps too frequent requests)\nJSON:\n$content\n<--JSON\nRequest URL: $url\n"; exit;}
 
    # iterate over each episode in the JSON structure:
    foreach my $tweet(reverse @{$json_text->{results}}){
      my %ep_hash = ();
      $ep_hash{from_user} = $tweet->{from_user};
      $ep_hash{from_user_name} = $tweet->{from_user_name};
      $ep_hash{text} = $tweet->{text};
 
        my @dateValues = split(' ', $tweet->{created_at});
        my $fulltime = $dateValues[4];
        my $hours = substr($fulltime, 0, 2);
        my $minutes = substr($fulltime, 3, 2);
        my $seconds = substr($fulltime, 6, 2);
        $hours += $addHours;
        if($hours >= 24){$hours -= 24;}
        $ep_hash{created_at} = "$hours:$minutes:$seconds";
        if(length($ep_hash{created_at}) < 8){$ep_hash{created_at} = "0$ep_hash{created_at}";}
 
        # Replace HTML
        $ep_hash{text} =~ s/\&quot\;/\"/g;
        $ep_hash{text} =~ s/\&gt\;/\>/g;
        $ep_hash{text} =~ s/\&lt\;/\</g;
      
        # print tweet
        print "\n\n\@$ep_hash{from_user}: ";
        print $ep_hash{text};
        print " ($ep_hash{from_user_name}, $ep_hash{created_at})";
    }
        sleep($interval);
  };
  # catch crashes:
  if($@){
    # print "[[JSON ERROR]] JSON parser crashed! $@\n";
  }
 
} # end infinite loop
}

