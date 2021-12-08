#!/usr/bin/perl
use XML::Simple;
use LWP::UserAgent;
use IO::Socket::SSL;
use POSIX qw(strftime mktime ceil locale_h);
use Net::IDN::Encode ':all';
use Data::Dumper;

my @domeny;
my @domeny_sort;
my $urlHazardXML = "https://hazard.mf.gov.pl/api/Register";
my $pdns_directory = "/var/lib/powerdns/etc/powerdns";
my $pdns_hazard_log_directory = "/var/log/hazard";
my $ua = LWP::UserAgent->new;
$ua->default_header('Accept-Language' => "pl");
$ua->ssl_opts(%{{'verify_hostname' => 0, 'SSL_verify_mode' => SSL_VERIFY_NONE}});

my $response = $ua->get($urlHazardXML);
    if($response->is_success)
   {
        my $xml = new XML::Simple;
        $data = $xml->XMLin($response->content);

        my $date = strftime('%d-%m-%Y %H:%M:%S',localtime(time));
        my $date_file = strftime('%d-%m-%Y_%H:%M:%S',localtime(time));
        my $dumpNew = "";
        my $filePDNSNew;
        my %isAdd;
        my $couter;
       foreach my $domain (@{$data->{'PozycjaRejestru'}})
       {
            my $domena = $domain->{'AdresDomeny'};
           if(!$isAdd{$domena})
           {
               # haszuje jak wykre.lono z listy
               if($domain->{'DataWykreslenia'})
               {
                    $dumpNew .= "\"$domena\|.$domain->{'DataWpisu'}."|".$domain->{'DataWykreslenia'}."|".domain_to_ascii($domena)\n";

               }
               else
               {
                    if ($domain == ${$data->{'PozycjaRejestru'}}[-1])
                    {
                        #$filePDNSNew .= "\"$domena\"";
                         push @domeny, domain_to_ascii($domena);
                    }
                    else
                    {
                        #$filePDNSNew .= "\"$domena\",";
                         push @domeny, domain_to_ascii($domena);
                    }
                    $dumpNew .= "$domena"."|".$domain->{'DataWpisu'}."|".domain_to_ascii($domena)."\n";
               }
               $isAdd{$domena} = $domena;
           }

       }

        my %legal=map{ $_ => 1} qw(.co.uk .foo .com .edu);
        @list=map  { shift @$_ }
        sort { $b->[2] <=> $a->[2] || $a->[1] cmp $b->[1] || $a->[0] cmp
        + $b->[0]}
        map  { my ($ext)=m/(\..*)$/; [ $_, $ext, $legal{$ext}  ] }
         @domeny;

        my $dumpOld = ( -e "$pdns_hazard_log_directory/dump.txt" ? join("\n", fileRead("$pdns_hazard_log_directory/log_$date_file.txt")) : "");
        if(trim($dumpOld) ne trim($dumpNew))
        {
            fileWrite("$pdns_directory/data_aktualizacji.txt", $date);
            fileWrite("$pdns_hazard_log_directory/log_$date_file.txt", $dumpNew);
        }
        my $filePDNSOld = ( -e "$pdns_directory/hazard.dane" ? join("\n", fileRead("$pdns_directory/hazard.dane")) : "");
        foreach (@list) {
            $filePDNSNew .= $_."\n";
        }

        if(trim($filePDNSOld) ne trim($filePDNSNew))
        {
            fileWrite("$pdns_directory/hazard.dane", $filePDNSNew);
        }

        system("rec_control reload-lua-script");
   }
   else
   {
        print STDERR "Error: ".$response->status_line."\n";
   }



sub fileRead {
 my($plik) = @_;
 my @wyjscie;
  open($UCHWYT, $plik);
  while (my $row = <$UCHWYT>) {
    push(@wyjscie, trim($row));
  }
  close ($UCHWYT);
 return @wyjscie;
}


sub fileWrite {
 my($plik, $co) = @_;
  open(UCHWYT, '>', $plik) or die "Nie można otworz.. $plik: $!";
  print UCHWYT $co;
  close UCHWYT;
}

sub trim($) {
 my $string = shift;
 $string =~ s/^\s+//;
 $string =~ s/\s+$//;
 return $string;
}
