#
# Copyright 2014 Andrew Ayer
#
# This file is part of strip-nondeterminism.
#
# strip-nondeterminism is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# strip-nondeterminism is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with strip-nondeterminism.  If not, see <http://www.gnu.org/licenses/>.
#
package File::StripNondeterminism;

use strict;
our($VERSION, $canonical_time);
$VERSION = '0.017'; # 0.017

sub _get_file_type {
    my $file=shift;
    open (FILE, '-|') # handle all filenames safely
      || exec('file', $file)
      || die "can't exec file: $!";
    my $type=<FILE>;
    close FILE;
    return $type;
}

sub get_normalizer_for_file {
    $_ = shift;
    return undef if -d $_; # Skip directories
    my $map = [
        sub {
            $_ = shift;
            m/\.a$/ && _get_file_type($_) =~ m/ar archive/
        } => 'ar',
        sub {
            $_ = shift;
            m/\.g?mo$/ && _get_file_type($_) =~ m/GNU message catalog/
        } => 'gettext',
        sub {
            $_ = shift;
            m/\.(gz|dz)$/ && _get_file_type($_) =~ m/gzip compressed data/;
        } => 'gzip',
        sub { 
            $_ = shift;
            m/\.(jar|war|hpi)$/ && _get_file_type($_) =~ m/(Java|Zip) archive data/;
        } => 'jar',
        sub {
            $_ = shift;
            if (m/\.html$/) {
                require File::StripNondeterminism::handlers::javadoc;
                return File::StripNondeterminism::handlers::javadoc::is_javadoc_file($_) : 1 : 0;
            } else {
                0
            };
        } => 'javadoc',
        sub {
            $_ = shift;
            if (m/\.reg$/) {
                require File::StripNondeterminism::handlers::pearregistry;
                return File::StripNondeterminism::handlers::pearregistry::is_registry_file($_) ? 1 : 0;
            } else {
                0
            };
        } => 'pearregistry',
        sub {
            $_ = shift;
            m/\.png$/ && _get_file_type($_) =~ m/PNG image data/;
        } => 'png',
        sub {
            $_ = shift;
            # pom.properties, version.properties
            if (m/(pom|version)\.properties$/) {
		require File::StripNondeterminism::handlers::javaproperties;
                return File::StripNondeterminism::handlers::javaproperties::is_java_properties_file($_);
                }
	} => 'javaproperties',
        sub {
            $_ = shift;
            m/\.(zip|pk3|whl|xpi)$/ && _get_file_type($_) =~ m/Zip archive data/;
        } => 'zip',
      ];
    
    for my $m (@$map) {
        if ($m->[0]($_)) {
            no strict 'refs';
            my $p = $m->[1]; 
            eval { eval "require File::StripNondeterminism::handlers::".$p; };
            return undef if $@;
            return \&{"File::StripNondeterminism::handlers::".$p."::normalize"};
        }
    }
    return undef;
}

sub get_normalizer_by_name {
    no strict 'refs';
    $_ = shift;
    eval { eval "require File::StripNondeterminism::handlers::".$_; };
    return undef if $@;
    return \&{"File::StripNondeterminism::handlers::".$_."::normalize"};
}

1;
