#!/usr/bin/bash

https://github.com/ingydotnet/test-yaml-pm/blob/master/bin/test-yaml

>>>  YAML::Syck

USAGE=<<...
Usage:

  test-yaml <test> <options>

Tests:

  load                  # Load YAML input and write data output
  dump                  # Load data input and write YAML output
  yny                   # Load→Dump→Load roundtrip
  nyn                   # Dump→Load→Dump roundtrip
  parse                 # Parse YAML input and write YAML events
  emit                  # Emit YAML events and write YAML output

Options:

  --in=<file>           # Input file
  --out=<file>          # Output file
  --from=<format>       # Input format
  --to=<format>         # Output format
  --yaml=<framework>    # Which YAML implementations to use
  --test=<tag-spec>     # Tags of test cases to use

Formats:
  json                  # JSON input or output
  perl                  # Perl code producing or representing data

Examples:

  test-yaml load --in=file.yaml --to=json --yaml=perl
  test-yaml dump --in=prog.pl --tag=dump --yaml=perl

See:

  For more complete doc, run:

    > man test-yaml

...
