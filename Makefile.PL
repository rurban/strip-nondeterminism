use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME		=> 'strip-nondeterminism',
	AUTHOR		=> 'Andrew Ayer <agwa@andrewayer.name>',
	VERSION_FROM	=> 'lib/File/StripNondeterminism.pm',
	ABSTRACT	=> 'tool for stripping non-determinism from files',
	EXE_FILES	=> [qw(bin/dh_strip_nondeterminism bin/strip-nondeterminism)],
	PREREQ_PM => {
		'Archive::Zip'	=> 0,
		'Getopt::Long'	=> 0,
	},
	LICENSE		=> "gpl",
	dist		=> { COMPRESS => 'gzip -9nf', SUFFIX => 'gz', },
	clean		=> { FILES => 'StripNondeterminism-*' },
);
