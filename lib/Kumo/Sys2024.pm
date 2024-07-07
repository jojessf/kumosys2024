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
         'log'  >  'kumosys.log'
      },
      inFiles   => {
         'cred' => 'kumosys.cred',
         'conf' => 'kumosys.conf',
      },
      data      => {

      },
      cred    => {},
      conf    => {},
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
   my $table = $self->{cred}->{table};
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
   $self->log( "DB", $DBq );
   $self->{insert_webdata} = $dbh->prepare($DBq);
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

sub getTenki {
   my $self = shift;
   my $WD = $self->{data}->{webdata};
   my $raw;
   my $hash; 
   
   $self->log("msg", "tenki? " . ref( $WD->{weather}) ."" );

   if ( ref($WD->{weather}) =~ /HASH/ ) {
      if ( $WD->{weather}->{res} ) {
         $raw = $WD->{weather}->{res};
         $hash = $self->{json}->decode( $raw );
         $self->log("msg", "tenki ~ " . length($raw) . "bytes..." );

         my $temps;
         if ( ref($hash->{properties}) =~ /HASH/ ) {
            if ( ref($hash->{properties}->{periods}) =~ /ARRAY/ ) {
               foreach my $period ( @{ $hash->{properties}->{periods} } ) {
                  push(@{$temps}, $period->{temperature});
               }
            }
         }
         my $str;
         for (my $i=0; $i<=4; $i++) {
            $str .= $temps->[$i] . ", ";
         }
         $str =~ s/,\s*$//g;

         return( $str );

      }
   }
   return "mystery weather o.o;";
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
               return $hash->{data}->{aqi};
            }
         }
      }
   }
   return "idk ;w;";
}


# ----------------------------------------------------------------- #
sub update {
   my $self = shift;
   my $dbh = $self->{dbh};
   my $STHi = $self->{insert_webdata};
   $self->{now} = time();
   my $dtR = strftime "%Y-%m-%d %H:%M:%S", localtime;

   foreach my $wdata ( @{ $self->{conf}->{webdata} } ) {
      my $name   = $wdata->{name};
      my $table  = $wdata->{table};
      my $url    = $wdata->{url};
      my $maxage = $wdata->{maxage};
         $maxage ||= 120;
      my $timefrom = $self->{now} - $maxage;
      my $resq = 0;


      if ( $self->{data}->{webdata}->{$name}->{utime} >= $timefrom ) {
         $self->log("msg", "Current: $name");

      } else {
         my $tdiff = $self->{now} - $self->{data}->{webdata}->{$name}->{utime};
         $self->log("msg", "Stale, DB fetch $name :: "
            . "rtime[" . $self->{data}->{webdata}->{$name}->{utime} . "],"
            . "now[". $self->{now} . "] ~" .  $timefrom . " :: " . $tdiff
         );

         my $sQuery = "SELECT * from $table WHERE name=? AND utime > ? ORDER BY utime DESC";
         my $sth = $dbh->prepare($sQuery);
         my $values = [$name, $timefrom];
         $self->log("DB", "DB: " . $sQuery . ":: " . join(",", @{$values}) );
         $sth->execute(@{$values});

         while (my $ref = $sth->fetchrow_hashref()) {
            $self->log("msg", "Found current DB entry: id = $ref->{'name'}, $ref->{'utime'}" );

            #print Dumper([ $ref->{utime} ]) . "\n";

            $self->{data}->{webdata}->{ $ref->{name} } = {
               name => $ref->{name},
               url => $ref->{url},
               utime => $ref->{utime},
               res => $ref->{res},
               ts => $ref->{ts}
            };
         
            print Dumper([
               $ref->{name},
               $self->{data}->{webdata}->{ $ref->{name} }->{utime}
            ]) . "\n";

            $resq++;
         }

      }

      if ( $self->{data}->{webdata}->{$name}->{utime} <= $timefrom ) {
         $self->log("msg", "Fetching: $name, $url");
         my $fdata = get($url);
         $self->log("msg", "Fetch got " . length($fdata) . " bytes...!");
         
         $self->{data}->{webdata}->{$name} = {
            name => $name,
            url => $url,
            utime => $self->{now},
            res => $fdata,
            ts => $dtR
         };

         $STHi->execute($name, $url, $self->{now}, $fdata, $dtR);
      }

   }
   
   
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
   
   if ( $lvl =~ /warn|log|msg|error|load|info/i ) {
      print "[$class] <$lvl> $msg\n";
   }
   
   return 1;
};

my $k = Kumo::Sys2024->new();
$k->update();


1;