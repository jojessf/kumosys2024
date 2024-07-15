#!/usr/bin/env perl
# =========================================================================== #
# (c) Jojess Fournier 20240706                                                #
# --------------------------------------------------------------------------- #
#                                                                             #
# there's proly no reason for anybody else to use this haha                   #
#                                                                             #
# --------------------------------------------------------------------------- #
# Copyright (C) 2024 Jojess Nyxa                                              #
#                                                                             #
# This program is free software: you can redistribute it and/or modify it     #
# under the terms of the GNU General Public License as published by the Free  #
# Software Foundation, either version 3 of the License, or (at your option)   #
# any later version.                                                          #
#                                                                             #
# This program is distributed in the hope that it will be useful, but         #
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY  #
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License     #
# for more details.                                                           #
#                                                                             #
# You should have received a copy of the GNU General Public License along     #
# with this program. If not, see https://www.gnu.org/licenses/.               #
#                                                                             #
# LICENSE described in project "/LICENSE" file.                               #
#                                                                             #
# --------------------------------------------------------------------------- #
#                                                                             #
# morbo kumosys2024 daemon -m production -l http://*:8095
#                                                                             #
# =========================================================================== #
package Kumo::Sys2024;

use strict;
use Data::Dumper;
use POSIX qw(strftime);
use LWP::Simple;
use JSON;
use DBI;

# ----------------------------------------------------------------- #
sub new {
   my ($class, $opt) = (@_);
   
   my $self = {
      class   => $class,
      json    => JSON->new->allow_nonref,
      outFiles   => {
         'log'  =>  'kumosys.log'
      },
      inFiles   => {
         'cred' => 'kumosys.cred',
         'conf' => 'kumosys.conf',
      },
      data      => {

      },
      cred    => {},
      conf    => {},
      lognow  => 0,  # toggle to trigger recording to secondary table
      lastlog => 0,
      dbh     => undef,
      now     => time,
   };
   
   bless($self, $class);

   $self->startup();
   $self->dbinit();
   #$self->update();
   
   return $self;
};

# ----------------------------------------------------------------- #

# ----------------------------------------------------------------- #

sub dbinit { 
   my $self = shift;
   
   my $hostname = $self->{cred}->{hostname};
   my $database = $self->{cred}->{database};
   my $username = $self->{cred}->{username};
   my $password = $self->{cred}->{password};
   my $table    = $self->{conf}->{table};
   my $tableLog = $self->{conf}->{tableLog};
   my $port = $self->{cred}->{port};
   
   my $dsn = "DBI:mysql:database=$database;host=$hostname;port=$port";
   my $dbh = DBI->connect($dsn, $username, $password);
   $self->{dbh} = $dbh;

   # ----------------------------------------------------------------------#
   my $DBFields = "name,url,utime,res,ts";
   my $ReValues;
   my $DBValues = "VALUES";
   my $DBIVal = 'VALUES (';
   my $DBFieldsI = ("(");

   foreach my $fi (split(",", $DBFields )) {
      $DBIVal     .= "?,";
      $ReValues  .= "`$fi`=VALUES(`$fi`),";
      $DBFieldsI .= "`$fi`,";
   }
   chop($DBFieldsI);
   chop($DBIVal);
   chop($ReValues);
   $DBIVal.= ")";
   $DBFieldsI .= ")";
   my $DBq = "INSERT INTO $table $DBFieldsI $DBIVal ON DUPLICATE KEY UPDATE $ReValues;";
   my $DBqLog = "INSERT INTO $tableLog $DBFieldsI $DBIVal;";
   $self->log( "DB", $DBq );
   $self->{insert_webdata} = $dbh->prepare($DBq);
   $self->{insert_webdatalog} = $dbh->prepare($DBqLog);
   # ----------------------------------------------------------------------#

   return $dbh;
} 

sub startup {
   my $self = shift;
   # load $self->{cred}, ->{conf}; 
   FIL: foreach my $fkey ( sort keys %{ $self->{inFiles} } ) {
      my $fil = $self->{inFiles}->{$fkey};
      $self->{$fkey} = $self->jSlurp($fil);
   };   
   
   return 1;
};

# ----------------------------------------------------------------- #

sub getX {
   my $self = shift;
   my $key  = shift;
   my $WD   = $self->{data}->{webdata};
   
   my $val;
   if ( ref($self->{data}->{webdata}->{$key}) =~ /HASH/ ) {
      $val = $self->{data}->{webdata}->{$key}->{res};
   }
   
   return($val) if defined($val);
   
   return "UwU";
}

sub getDB {
   my $self = shift;
   my $dbh  = $self->{dbh};
   
   my $opt = {};
   if ( ! ref( $_[0] ) ) {
      if ( scalar(@_) == 1 ) {
         $opt->{name} = shift;
      } elsif ( scalar(@_) == 2 ) {
         $opt->{realm}  = shift;
         $opt->{key}    = shift;
      } elsif ( scalar(@_) == 3 ) {
         $opt->{table}    = shift;
         $opt->{realm}  = shift;
         $opt->{key}    = shift;
      }
   } elsif ( ref( $_[0] ) =~ /HASH/ ) {
      $opt = shift;
   }

   $opt->{name}  ||= $opt->{key};
   $opt->{table} ||= "postlog";
   $opt->{limit} ||= 1;
   $opt->{url}   ||= $opt->{realm};
   $opt->{url}   ||= "kumosys";
   $opt->{ts};
   $opt->{utime};
   $opt->{res};
   $opt->{cachestr};
   $opt->{dtR} = strftime "%Y-%m-%d %H:%M:%S", localtime;
   
   my $query = "SELECT * from ".$opt->{table}. " WHERE name=?";
   if ( $opt->{url} ) {
      $query .= " AND url=?";
   }
   $query .= " ORDER BY ts DESC"; 
   if ( $opt->{limit} ) {
      $query .= " LIMIT ".$opt->{limit};
   }
   my $values = [];
   if ( $opt->{url} ) {
      $values = [ $opt->{name}, $opt->{url} ];
   } elsif ( $opt->{name} ) {
      $values = [ $opt->{name} ];
   }
   
   my $STHi = $dbh->prepare($query);
   $self->log("msg", "DB: " . $query . ":: " . join(",", @{$values}) ) if $ENV{DEBUG};
   $STHi->execute(@{$values});
   
   my $res;
   while (my $ref = $STHi->fetchrow_hashref()) {
      $res = $ref->{res};
   }

   return $res;
}

sub postDB {
   my $self = shift;
   # my $opt  = shift;
   my $dbh  = $self->{dbh};
   
   my $opt = {};
   if ( ! ref( $_[0] ) ) {
      if ( scalar(@_) == 2 ) {
         $opt->{key}  = shift;
         $opt->{val}  = shift;
      } elsif ( scalar(@_) == 3 ) {
         $opt->{realm}  = shift;
         $opt->{key}    = shift;
         $opt->{val}    = shift;
      } elsif ( scalar(@_) == 4 ) {
         $opt->{table}  = shift;
         $opt->{realm}  = shift;
         $opt->{key}    = shift;
         $opt->{val}    = shift;
      }
   } elsif ( ref( $_[0] ) =~ /HASH/ ) {
      $opt = shift;
   }
   
   return 0 if ref($opt) !~ /HASH/;
   
   $opt->{name}  ||= $opt->{key};
   $opt->{res}   ||= $opt->{val};
   $opt->{url}   ||= $opt->{realm};
   
   $opt->{table} ||= "postlog";
   $opt->{name}  ||= "testyjunk";
   $opt->{url}   ||= "mystery";
   $opt->{utime} ||= time;
   
   return 0 if ! $opt->{res};
   
   
   my $DBFields;
   my $InsertVals;
   OKEY: foreach my $key ( sort keys %{ $opt }) {
      next OKEY if $key =~ /table|key|val|realm/;
      $DBFields .= "$key,";
      push @{$InsertVals}, $opt->{$key};
   }
   chop($DBFields);
   
   my $ReValues;
   my $DBValues = "VALUES";
   my $DBIVal = 'VALUES (';
   my $DBFieldsI = ("(");

   foreach my $fi (split(",", $DBFields )) {
      $DBIVal     .= "?,";
      $ReValues  .= "`$fi`=VALUES(`$fi`),";
      $DBFieldsI .= "`$fi`,";
   }
   chop($DBFieldsI);
   chop($DBIVal);
   chop($ReValues);
   $DBIVal.= ")";
   $DBFieldsI .= ")";
   
   
   my $query = "INSERT INTO ". $opt->{table} . " $DBFieldsI $DBIVal ON DUPLICATE KEY UPDATE $ReValues;";
   $self->log( "msg", $query . "::" . join(",", @{$InsertVals}));
   my $STHi = $dbh->prepare($query);
   
   $STHi->execute(@{$InsertVals});
   
   
   
   
   return 1;
}


sub getTenki {
   my $self = shift;
   my $WD = $self->{data}->{webdata};
   my $raw;
   my $hash; 
   $self->{now} = time;
   $self->{dtR} = strftime "%Y-%m-%d %H:%M:%S", localtime;
   
   $self->log("msg", "tenki? " . ref( $WD->{weather}) ."" );

   my $weathernow;
   if ( ref($WD->{weathernow}) =~ /HASH/ ) {
      if ( $WD->{weathernow}->{res} ) {
         $raw = $WD->{weathernow}->{res};
         $hash = $self->{json}->decode( $raw );
         if ( ref($hash->{properties}->{temperature}) =~ /HASH/ ) {
            
            # tempnow 
            $weathernow->{tempnow} = $hash->{properties}->{temperature}->{value};
            if ( $hash->{properties}->{temperature}->{unitCode} =~ /degC/i ) {
               $weathernow->{tempnow} = ( $weathernow->{tempnow} * 9 / 5 ) + 32;
               $weathernow->{tempnow} = int($weathernow->{tempnow});
            }
            # windnow
            $weathernow->{windnow} = $hash->{properties}->{windSpeed}->{value};
            if ( $hash->{properties}->{windSpeed}->{unitCode} =~ /km_h/i ) {
               $weathernow->{windnow} *= 0.621371;
               $weathernow->{windnow} = int($weathernow->{windnow});
            }
            
            # dewpoint
            $weathernow->{dewpoint} = $hash->{properties}->{dewpoint}->{value};
            if ( $hash->{properties}->{dewpoint}->{unitCode} =~ /degC/i ) {
               $weathernow->{dewpoint} = int( ( $weathernow->{dewpoint} * 9 / 5 ) + 32 );
            }
            # pressure
            $weathernow->{pressure} = $hash->{properties}->{barometricPressure}->{value};
            if ( $hash->{properties}->{barometricPressure}->{unitCode} =~ /Unit:Pa/i ) {
               $weathernow->{pressure} /= 1000;
            }
            # visibility
            $weathernow->{visibility} = $hash->{properties}->{visibility}->{value};
            if ( $hash->{properties}->{visibility}->{unitCode} =~ /Unit:m$/i ) {
               $weathernow->{visibility} /= 1000;
               $weathernow->{visibility} *= 0.621371;
               $weathernow->{visibility} = int($weathernow->{visibility});
            }
            
            # humidity             
            $weathernow->{humidity} = int($hash->{properties}->{relativeHumidity}->{value});
          
            # forecastShort
            $weathernow->{conditions} = $hash->{properties}->{textDescription}; 
            # $weathernow->{forecastShort} = $hash->{properties}->{textDescription}; 
          
         }
      }
   }
   
   foreach my $key (keys %{$weathernow}) {
      print ">OwO>" . $key . "\t" . $weathernow->{$key} . "\n" if $ENV{DEBUG} =~ /weathernow/i;
      
      
      $WD->{$key}->{utime} ||= 0;
      # $self->log("msg", "UT2 ~ " . $key ." ~ "  . $WD->{$key}->{utime}); # 
      #if ( $WD->{$key}->{utime} < $WD->{'weathernow'}->{utime} ) {
         $self->insertDB("weather", $key, $weathernow->{$key}) if $weathernow->{$key};
         # $self->log("msg", "UT2 ~ " . $key ." I " ); # 
      #}
      $self->insertTb("weather", $key, $weathernow->{$key}) if $weathernow->{$key};
      # $self->log("msg", "UT2 ~ " . $key ." ~ "  . $WD->{$key}->{utime}); #
   }
   
   
   if ( ref($WD->{weather}) =~ /HASH/ ) {
      if ( $WD->{weather}->{res} ) {
         $raw = $WD->{weather}->{res};
         $hash = $self->{json}->decode( $raw );
         $self->log("msg", "tenki ~ " . length($raw) . "bytes..." );

         open OF, ">weatherdebug.txt";
         print OF Dumper([ $hash ]);
         close OF;

         my ( $temp, $temps, $precip, $precips, $winds, $forecast, $forecastShort, $winds, $wind );
         if ( ref($hash->{properties}) =~ /HASH/ ) {
            
            
            if ( ref($hash->{properties}->{periods}) =~ /ARRAY/ ) {
               
               $temp      = $hash->{properties}->{periods}->[0]->{temperature}; # 89
               $forecastShort = $hash->{properties}->{periods}->[0]->{shortForecast}; # "Sunny"
               $forecast  = $hash->{properties}->{periods}->[0]->{name}; # "This Afternoon"
               $forecast .= ": ";
               $forecast .= $hash->{properties}->{periods}->[0]->{detailedForecast}; # "Sunny, with a high near ..."
               $wind      = $hash->{properties}->{periods}->[0]->{windDirection};
               $wind     .= " ";
               $wind     .= $hash->{properties}->{periods}->[0]->{windSpeed};

               if ( ref($hash->{properties}->{periods}->[0]->{probabilityOfPrecipitation}) =~ /HASH/ ) {
                  my $precipChance = $hash->{properties}->{periods}->[0]->{probabilityOfPrecipitation}->{value};
                  $precipChance ||= 0;
                  $precip = $precipChance;
               }
               
               foreach my $period ( @{ $hash->{properties}->{periods} } ) {
                  push(@{$temps}, $period->{temperature});
                  $winds .= $hash->{properties}->{periods}->[0]->{windDirection};
                  $winds .= $hash->{properties}->{periods}->[0]->{windSpeed};
                  $winds .= ", ";
                  if ( ref($period->{probabilityOfPrecipitation}) =~ /HASH/ ) {
                     my $precipChance = $period->{probabilityOfPrecipitation}->{value};
                        $precipChance ||= 0;
                     push(@{$precips}, $precipChance);
                  } else {
                     push(@{$precips}, "N");
                  }
               }
            }
         }
         my $tmpstr;
         my $precipstr;
         for (my $i=0; $i<=4; $i++) {
            $tmpstr .= $temps->[$i] . ", ";
            $precipstr .= $precips->[$i] . ", ";
         }
         $tmpstr    =~ s/,\s*$//g;
         $precipstr =~ s/,\s*$//g;
         $winds     =~ s/,\s*$//g;

         $self->insertTb("weather", "winds", $winds);
         $self->insertTb("weather", "wind", $wind);
         $self->insertTb("weather", "forecastShort", $forecastShort);
         $self->insertTb("weather", "forecast", $forecast);
         $self->insertTb("weather", "temp", $temp);
         $self->insertTb("weather", "temps", $tmpstr);
         $self->insertTb("weather", "precips", $precipstr);
         $self->insertTb("weather", "precip", $precip);

         $WD->{precip}->{utime} ||= 0;
         
         
         #$self->log("msg", "precip/weather utime " . 
         #   $WD->{precip}->{utime} .  "\t" . $WD->{'weather'}->{utime} .
         #"" );
         
         # if ( $WD->{precip}->{utime} < $WD->{'weather'}->{utime} ) {
            $self->insertDB("weather", "winds", $winds);
            $self->insertDB("weather", "wind", $wind);
            $self->insertDB("weather", "forecastShort", $forecastShort);
            $self->insertDB("weather", "forecast", $forecast);
            $self->insertDB("weather", "temp", $temp);
            $self->insertDB("weather", "temps", $tmpstr);
            $self->insertDB("weather", "precips", $precipstr);
            $self->insertDB("weather", "precip", $precip);
         # }

         return( $tmpstr );

      }
   }
   return "mystery weather o.o;";
}

sub insertTb {
   my $self = shift;
   my ( $url, $name, $res ) = @_;
   my $WD = $self->{data}->{webdata};
   my $STHi = $self->{insert_webdata};
   my $STHiLog = $self->{insert_webdatalog};
   $self->{now} = time();
   $self->{dtR} = strftime "%Y-%m-%d %H:%M:%S", localtime;

   $WD->{$name} = {
      name  => $name,
      url   => $url,
      utime => $self->{now},
      res   => $res,
      ts    => $self->{dtR}
   };

   return 1;
}


sub insertDB {
   my $self = shift;
   my ( $url, $name, $res ) = @_;
   my $WD = $self->{data}->{webdata};
   my $STHi = $self->{insert_webdata};
   my $STHiLog = $self->{insert_webdatalog};
   $self->{now} = time();
   $self->{dtR} = strftime "%Y-%m-%d %H:%M:%S", localtime;
   
   $STHi->execute(
      $name, 
      $url, 
      $self->{now}, 
      $res, 
      $self->{dtR}
   );

   if ( $self->{lognow} == 1 ) {
      $STHiLog->execute(
         $name, 
         $url, 
         $self->{now}, 
         $res, 
         $self->{dtR}
      );
   };
   
   return 1;
}

sub getAQI {
   my $self = shift;
   my $WD = $self->{data}->{webdata};
   my $raw;
   my $hash; 
   
   $self->log("msg", "aqi ? " . ref( $WD->{aqi}) ."" );

   if ( ref($WD->{aqi}) =~ /HASH/ ) {
      if ( $WD->{aqi}->{res} ) {
         $raw = $WD->{aqi}->{res};
         $hash = $self->{json}->decode( $raw );
         $self->log("msg", "aqi ~ " . length($raw) . "bytes..." );

         if ( ref($hash->{data}) =~ /HASH/ ) {
            if ( $hash->{data}->{aqi} ) {
               $self->log("msg", "aqi ~ " . $hash->{data}->{aqi} . "bytes..." );
               
               $self->insertDB("weather", "aqipm25", $hash->{data}->{aqi});
               $self->insertTb("weather", "aqipm25", $hash->{data}->{aqi});
               return $hash->{data}->{aqi};
            }
         }
      }
   }
   return "idk ;w;";
}

sub lastlog { 
   my $self = shift;
   my $dbh = $self->{dbh};
   my $STHi = $self->{insert_webdata};
   $self->{now} = time;
   my $dtR = strftime "%Y-%m-%d %H:%M:%S", localtime;
   my $WD   = $self->{data}->{webdata};
   my $lastlogage = $self->{now} - $self->{lastlog};
   
   if (scalar(keys %{$WD}) >=1) {
      if ( $lastlogage > $self->{conf}->{loginterval} ) {
         $self->log("dblog", "triggering log routine...  " . $self->{now} .",\t". $self->{lastlog} );
         $self->{lastlog}  = time;
         $self->{lognow} = 1;
         $self->insertDB("weather", "lastlog", $self->{lastlog});
         foreach my $key (keys %{$WD}) {
            my $val = $WD->{$key}->{res};
            if ( length($val) <= $self->{conf}->{logstrmaxlen} ) {
               $self->log("dblog", "hewwo $key ~ $val\n");
               $self->log("self", Dumper([ $self ]) );
               $self->insertDB("weatherlog", $key, $val);
            }
         }
         $self->{lognow} = 0;
      } else {
         $self->log("dblog", "skippin' log routine...  " . $self->{now} .",\t". $self->{lastlog} );
         $self->{lognow} = 0;
      }
   }
}


# ----------------------------------------------------------------- #
sub update {
   my $self = shift;
   my $dbh = $self->{dbh};
   my $STHi = $self->{insert_webdata};
   $self->{now} = time;
   my $dtR = strftime "%Y-%m-%d %H:%M:%S", localtime;

   $self->lastlog();

   # data->webdata =================================================
   foreach my $wdata ( @{ $self->{conf}->{webdata} } ) {
      my $name   = $wdata->{name};
      my $table  = $wdata->{table};
      my $url    = $wdata->{url};
      my $maxage = $wdata->{maxage};
         $maxage ||= 120;
      my $timefrom = $self->{now} - $maxage;
      my $resq = 0;

      # Cache Check 0 ---------------------------------------------------
      if ( 
         ( $self->{data}->{webdata}->{$name}->{utime} >= $timefrom ) &&
         ( $self->{data}->{webdata}->{$name}->{res} )
      ) {
         $self->log("msg", "Current: $name");

      } else {
         # DB get ---------------------------------------------------
         my $tdiff = $self->{now} - $self->{data}->{webdata}->{$name}->{utime};
         $self->log("msg", "Stale, DB fetch $name :: "
            . "rtime[" . $self->{data}->{webdata}->{$name}->{utime} . "],"
            . "now[". $self->{now} . "] ~" .  $timefrom . " :: " . $tdiff
         );

         my $sQuery = "SELECT * from $table WHERE name=? AND utime > ? ORDER BY utime DESC";
         my $sth = $dbh->prepare($sQuery);
         my $values = [$name, $timefrom];
         $self->log("DB", "DB: " . $sQuery . ":: " . join(",", @{$values}) ) if $ENV{DEBUG};
         $sth->execute(@{$values});

         while (my $ref = $sth->fetchrow_hashref()) {
            $self->log("msg", "Found current DB entry: id = $ref->{'name'}, $ref->{'utime'}" );

            $self->{data}->{webdata}->{ $ref->{name} } = {
               name => $ref->{name},
               url => $ref->{url},
               utime => $ref->{utime},
               res => $ref->{res},
               ts => $ref->{ts}
            };
       

            $resq++;
         }

      } # DB get ---------------------------------------------------

      # LWP get / Cache Check 1 ------------------------------------
      if ( $self->{data}->{webdata}->{$name}->{utime} >= $timefrom ) {
         $self->log("msg", "Fetching: $name, $url");
         my $fdata = get($url);
         
         # use Data::Dumper; print Dumper([ $fdata ]) . "\n";
         $self->log("msg", "Fetch got " . length($fdata) . " bytes...!");
         
         $self->{data}->{webdata}->{$name} = {
            name => $name,
            url => $url,
            utime => $self->{now},
            res => $fdata,
            ts => $dtR
         };

         $STHi->execute($name, $url, $self->{now}, $fdata, $dtR);
      } # LWP get / Cache Check 1 ------------------------------------

   } # data->webdata =================================================
   
   
   return 1;
};

# ----------------------------------------------------------------- #
sub jSlurp {
   my $self  = shift;
   my $fil   = shift;
   my $fdata = undef;
   if ( ! -e $fil )  {
      $self->log("warn", "File not found: $fil");
      return 0;
   }
   my $fistr = '';
   open IF, "<" . $fil or do {
      $self->log("warn", "File Slurpaderp failure $fil . . .");
   };
   $self->log("load", "$fil");
   
   while (<IF>) { $fistr .= $_ };
   close IF;
   
   $fdata = $self->{json}->decode( $fistr );

   if ( ! $fdata ) {
      $self->log("warn", "File JSON decode error $fil");
      return 0;
   }
   return $fdata;
};

# ----------------------------------------------------------------- #
sub log {
   my ( $self, $lvl, $msg ) = ( @_ );
   my $class = $self->{class};
   $lvl ||= "warn";
   
   my $logit = "[$class] <$lvl> $msg";
   if ( $lvl =~ /warn|log|msg|error|load|info/i ) {
      print $logit . "\n";
   }
   
   open OF, ">>" . $self->{outFiles}->{log};
      print OF localtime . "$logit\n";   
   close OF;
   
   
   return 1;
};

if ( $ENV{DEBUG} ) {
   my $k = Kumo::Sys2024->new();
   $k->startup(); # maybe move this to part of the constructor ...
   $k->update(); # maybe add this to constructor, too?  needs to run before getAQI and getTenki
   $k->getAQI();
   $k->getTenki();
   # my $WD   = $k->{data}->{webdata};
   # 
   # use Data::Dumper; print Dumper([ 
   #    "A = ".$k->getX("aqipm25")  # depends on startup/update/getAQI being run first ...
   # ]) . "\n";
   # 
   # use Data::Dumper; print Dumper([ "Wnow", $k->getX("weathernow") ]) . "\n";
   use Data::Dumper; print Dumper([ "getDB_simpleName:" , $k->getDB("meow") ]) . "\n";
   use Data::Dumper; print Dumper([ "getDB_byParms:" , $k->getDB({"name" =>"meow"}) ]) . "\n";
   
   use Data::Dumper; print Dumper([  $k->postDB({}) ]) . "\n";
   use Data::Dumper; print Dumper([  $k->postDB({name=>'', 'res'=>"stuff"}) ]) . "\n";
   use Data::Dumper; print Dumper([  $k->postDB({name=>0, 'res'=>"cacawww"}) ]) . "\n";
   use Data::Dumper; print Dumper([  $k->postDB({name=>"bettertest", 'res'=>"somevaluwu"}) ]) . "\n";
   use Data::Dumper; print Dumper([  $k->postDB({key=>"dognoises", 'res'=>"awawawa"}) ]) . "\n";
   use Data::Dumper; print Dumper([  $k->postDB("nya", "ha") ]) . "\n";
   use Data::Dumper; print Dumper([  $k->postDB("praxis", "nya", "ha") ]) . "\n";
   
};


1;