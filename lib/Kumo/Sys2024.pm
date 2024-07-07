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

use Data::Dumper;
use JSON;

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
      cred    => {},
      conf    => {},
   };
   
   bless($self, $class);
   
   $self->startup();
   
   $self->update();
   
   return $self;
};

# ----------------------------------------------------------------- #
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
sub update {
   my $self = shift;
   
   foreach my $wdata ( @{ $self->{conf}->{webdata} } ) {
      my $source = $wdata->{name};
      $self->log("msg", "fetch $source");
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
   $self->log("load", "$fkey / $fil");
   
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
   
   if ( $lvl =~ /warn|log|msg|error|load/i ) {
      print "[$class] <$lvl> $msg\n";
   }
   
   return 1;
};

my $k = Kumo::Sys2024->new();



1;