#
# Copyright (c) 2013-2023 Todd Kover
# All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package JazzHands::Common;

use strict;
use warnings;
use JazzHands::Common::Util qw(:all);
use JazzHands::Common::Error qw(:internal);
use JazzHands::Common::Logging qw(:all);
use Data::Dumper;

use vars qw(@ISA %EXPORT_TAGS @EXPORT);

use Exporter;    # 'import';

our $VERSION = '1.0';

our @ISA = qw(
  Exporter
  JazzHands::Common::Util
  JazzHands::Common::Error
);

our @EXPORT;
our @EXPORT_OK;
our %EXPORT_TAGS = (
	'all' => [],

	# note that :db is special, see my import function
	'internal' => [],
);

#foreach my $c (@ISA) {
#	print "C is $c\n";
#	my @x = @{$c::EXPORT};
#	foreach my $name (@x) {
#		print "NAME in $c is $name\n";
#	}
#}

# pull up all the stuff from JazzHands::Common::Util
push( @EXPORT,    @JazzHands::Common::Util::EXPORT );
push( @EXPORT_OK, @JazzHands::Common::Util::EXPORT_OK );
foreach my $name ( keys %JazzHands::Common::Util::EXPORT_TAGS ) {
	push(
		@{ $EXPORT_TAGS{$name} },
		@{ $JazzHands::Common::Util::EXPORT_TAGS{$name} } );
}

# pull up all the stuff from JazzHands::Common::Error
push( @EXPORT,    @JazzHands::Common::Error::EXPORT );
push( @EXPORT_OK, @JazzHands::Common::Error::EXPORT_OK );
foreach my $name ( keys %JazzHands::Common::Error::EXPORT_TAGS ) {
	push(
		@{ $EXPORT_TAGS{$name} },
		@{ $JazzHands::Common::Error::EXPORT_TAGS{$name} } );
}

# pull up all the stuff from JazzHands::Common::Logging
push( @EXPORT,    @JazzHands::Common::Logging::EXPORT );
push( @EXPORT_OK, @JazzHands::Common::Logging::EXPORT_OK );
foreach my $name ( keys %JazzHands::Common::Logging::EXPORT_TAGS ) {
	push(
		@{ $EXPORT_TAGS{$name} },
		@{ $JazzHands::Common::Logging::EXPORT_TAGS{$name} } );
}

sub import {
	if ( grep( $_ =~ /^\:(db|all)$/, @_ ) ) {
		require JazzHands::Common::GenericDB;
		JazzHands::Common::GenericDB->import(qw(:all));
		JazzHands::Common::GenericDB->import(qw(:legacy));

		# pull up all the stuff from JazzHands::Common::GenericDB
		push( @EXPORT,    @JazzHands::Common::GenericDB::EXPORT );
		push( @EXPORT_OK, @JazzHands::Common::GenericDB::EXPORT_OK );
		foreach my $name ( keys %JazzHands::Common::GenericDB::EXPORT_TAGS ) {
			push(
				@{ $EXPORT_TAGS{$name} },
				@{ $JazzHands::Common::GenericDB::EXPORT_TAGS{$name} } );
		}
		push(
			@{ $EXPORT_TAGS{'db'} },
			@{ $JazzHands::Common::GenericDB::EXPORT_TAGS{'all'} } );
	}

	my $save = $Exporter::ExportLevel;
	$Exporter::ExportLevel = 1;
	Exporter::import(@_);
	$Exporter::ExportLevel = $save;

}

#
# can be called from a child classs, sets everything up that may be used by
# the routines under this hierarchy
#
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $opt   = &_options;

	my $self = {};
	bless $self, $class;

	if ( $opt->{debug_callback} ) {
		$self->{_debug_callback} = $opt->{debug_callback};
	}

	if ( $opt->{logging} ) {
		$self->initialize_logging(%{$opt->{logging}});
	}

	$self->{_debug}  = 0 if ( !$self->{_debug} );
	$self->{_errors} = [];
	$self;
}

1;

=head1 NAME

JazzHands::Common - Perl extensions that are used throughout JazzHands

=head1 SYNOPSIS

use parent 'JazzHands::Common';

use JazzHands::Common;
use JazzHands::Common qw(:internal :log :all :db :error);

The :internal tag includes functions from JazzHands::Common::Util.

The :db tag imports routines for interating with the db in a perlish interface.

The :log behaves as described in JazzHands::Common::Logging

The :all does everything, as well as JazzHands::Common::Error

This class imports (and makes available for export) things in other 
subclasses.  

=head1 DESCRIPTION

This is really just a placeholder  for other subclasses and is meant to be
a parent class to provide a bunch of baseline functionality out of the box.

Various JazzHands utilities and modules use these to make their lives easier
although there are also standalone modules that are not part of this.

head1 SEE ALSO

JazzHands::Common::Util, JazzHands::Common::GenericDB, 
	JazzHands::Common::Error, JazzHands::Common::Logging

=head1 AUTHOR

Todd Kover, Matthew Ragan

=head1 COPYRIGHT AND LICENSE

