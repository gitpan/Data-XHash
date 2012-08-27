#!perl -T

### This file tests primarily tree-related functionality

use Test::More tests => 12;
use Data::XHash qw/xh xhr/;

my $xh;

## Test basic fetch

$xh = xh({ one => xh({ two => 'value' }) });

is($xh->{[]}, undef, '{[]} is undef');
isa_ok($xh->{one}, 'Data::XHash', '{one=>{two=>value}} => {one}');
is($xh->{[qw/one two/]}, 'value',
  '{one=>{two=>value}} => {[one two]} is value');
is($xh->{[qw/one tow/]}, undef, '{one=>{two=>value}} => {[one tow]} is undef');
is_deeply($xh->{['one', {}]}->as_hashref(), [{two=>'value'}],
   '{one=>{two=>value}} => {[one {}]} is {two=>value}');

# Tests: 5

# Test recursive as_hashref now so we can check other stuff easily

is_deeply($xh->as_hashref(nested=>1), [{one=>[{two=>'value'}]}],
  '{one=>{two=>value}} as_hashref(nested=>1) is OK');
$xh = xhr([{one=>{two=>'value'}}], nested => 1);
is_deeply($xh->as_hashref(nested=>1), [{one=>[{two=>'value'}]}],
  'xhr([{one=>{two=>value}}], nested => 1) as_hashref(nested=>1) is OK');
$xh = xhr([{one=>[{two=>'value'}]}], nested => 1);
is_deeply($xh->as_hashref(nested=>1), [{one=>[{two=>'value'}]}],
  'xhr([{one=>[{two=>value}]}], nested => 1) as_hashref(nested=>1) is OK');

# Tests: 3

## Test basic store

$xh->{[qw/one change/]} = 'is good';
is_deeply($xh->as_hashref(nested=>1),
  [{one=>[{two=>'value'},{change=>'is good'}]}],
  '{one=>{two=>value,change=>is good}} is OK');
$xh->{['one', undef]} = '#0';
$xh->{['one', undef]} = '#1';
is_deeply($xh->as_hashref(nested=>1),
  [{one=>[{two=>'value'},{change=>'is good'},{0=>'#0'},{1=>'#1'}]}],
  '{one=>{two=>value,change=>is good,0=>#0,1=>#1}} is OK');

# Tests: 2

## Test as_arrayref(nested=>1)

is_deeply($xh->as_arrayref(nested=>1),
  [{one=>[{two=>'value'},{change=>'is good'},'#0','#1']}],
  '{one=>{two=>value,change=>is good,#0,#1}} is OK');

# Tests: 1

## Test XHash vivification

$xh = xh();
$xh->{['one', {}]}->push(1, 2, 3);
is_deeply($xh->as_hashref(nested=>1), [{one=>[{0=>1},{1=>2},{2=>3}]}],
  '[one {}]->push(1, 2, 3) is OK');

# Tests: 1

# END
