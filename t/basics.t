use strict;
use warnings;
use Test2::V0;

use App::Tailor;
use Term::ANSIColor qw(color RESET);

sub paip {
  my $str = '';
  open my $in,  '<', \$str or die $!;
  open my $out, '>', \$str or die $!;
  return ($in, $out);
}

subtest itail => sub{
  reset_rules;

  my ($in, $out) = paip;
  my $iter = itail $in;

  print $out "$_\n" for qw(foo bar baz bat);
  is $iter->(), "$_\n", "out: $_" for qw(foo bar baz bat);
  is $iter->(), U, 'out: undef';
};

subtest ignore => sub{
  reset_rules;

  ignore qr/foo/;
  ignore qr/bar/;

  my ($in, $out) = paip;
  my $iter = itail $in;

  print $out "foo should be ignored\n";
  print $out "baz should be printed\n";
  print $out "bar should be ignored\n";
  print $out "bat should be printed\n";

  is $iter->(), "baz should be printed\n", 'foo ignored';
  is $iter->(), "bat should be printed\n", 'bar ignored';
  is $iter->(), U, 'closed: undef';
};

subtest modify => sub{
  reset_rules;

  modify qr/foo/    => sub{ uc $_ };
  modify qr/bar/    => 'barbar';
  modify qr/barbar/ => 'barbarbar';

  my ($in, $out) = paip;
  my $iter = itail $in;

  print $out "foo\n";
  print $out "bar\n";
  print $out "baz\n";

  is $iter->(), "FOO\n", 'modify foo';
  is $iter->(), "barbarbar\n", 'multiple rules match bar';
  is $iter->(), "baz\n", 'do not modify baz';
  is $iter->(), U, 'closed: undef';
};

subtest colorize => sub{
  reset_rules;

  colorize 'foo'      => qw(red);
  colorize 'bar'      => qw(black on_white);
  colorize 'baz'      => qw(red);
  colorize 'az'       => qw(blue);
  colorize qr/a(?=b)/ => qw(red);

  my ($in, $out) = paip;
  my $iter = itail $in;

  print $out "foo\n";
  print $out "bar\n";
  print $out "baz\n";
  print $out "bat\n";
  print $out "ab ba\n";

  is $iter->(), color('red').'foo'.RESET."\n", 'single color';
  is $iter->(), color('black', 'on_white').'bar'.RESET."\n", 'multiple colors';
  is $iter->(), color('red').'b'.color('blue').'az'.RESET.RESET."\n", 'multiple matching rules';
  is $iter->(), "bat\n", 'unmatched';
  is $iter->(), color('red').'a'.RESET."b ba\n", 'match with zero-length component';
  is $iter->(), U, 'closed: undef';
};

done_testing;
