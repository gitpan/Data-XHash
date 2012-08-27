package Data::XHash;

use 5.006;
use strict;
use warnings;
use base qw/Exporter/;
use subs qw/clear delete exists fetch first_key next_key
  scalar store xhash xhashref/;
use Carp;
use Scalar::Util qw/blessed/;

our @EXPORT_OK = (qw/&xhash &xhashref &xh &xhn &xhr &xhrn/);

=head1 NAME

Data::XHash - Extended, ordered hash (commonly known as an associative array
or map) with key-path traversal and automatic index keys

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Data::XHash;
    use Data::XHash qw/xhash xhashref/;
    use Data::XHash qw/xh xhn xhr xhrn/;

    $tiedhref = Data::XHash->new(); # A blessed and tied hashref
    # Note: Don't call "tie" yourself!

    # Exports are shortcuts to call Data::XHash->new()->push()
    # or Data::XHash->new()->pushref() for you.
    $tiedhref = xh('auto-indexed', { key => 'value' });
    $tiedhref = xhash('auto-indexed', { key => 'value' });
    $tiedhref = xhashref([ 'auto-indexed', { key => 'value' } ]);
    $tiedhref = xhn('hello', { root => { branch =>
      [ { leaf => 'value' }, 'world' ] } }); # (nested)
    $tiedhref = xhr([ 'auto-indexed', { key => 'value' } ]);
    $tiedhref = xhrn([ 'hello', { root => { branch =>
      [ { leaf => 'value' }, 'world' ] } } ]); # (nested)

    # Note: $xhash means you can use either $tiedhref or the
    # underlying object at tied(%$tiedhref)

    ## Hash-like operations

    # Getting keys or paths
    $value = $tiedhref->{$key};
    $value = $tiedhref->{\@path};
    $value = $xhash->fetch($key);
    $value = $xhash->fetch(\@path);

    # Auto-vivify a Data::XHash at the end of the path
    $tiedhref2 = $tiedhref1->{ [ @path, {} ] };
    $tiedhref->{ [ @path, {} ] }->$some_xh_method(...);
    $tiedhref = $xhash->fetch( [ @path, {} ] );
    $xhash->fetch( [ @path, {} ] )->$some_xh_method(...);

    # Setting keys or paths
    $tiedhref->{$key} = $value;
    $tiedhref->{\@path} = $value;
    $xhash->store($key, $value, %options);
    $xhash->store(\@path, $value, %options);

    # Setting the next auto-index key
    $tiedhref->{[]} = $value; # Recommended syntax
    $tiedhref->{+undef} = $value;
    $tiedhref->{[ undef ]} = $value; # Any path key may be undef
    $xhash->store([], $value, %options);
    $xhash->store(undef, $value, %options);
    $xhash->store([ undef ], $value, %options);

    # Clear the xhash
    %$tiedhref = ();
    $xhash->clear();

    # Delete a key and get its value
    $value = delete $tiedhref->{$key}; # or \@path
    $value = $xhash->delete($key); # or \@path

    # Does a key exist?
    $boolean = exists $tiedhref->{$key}; # or \@path
    $boolean = $xhash->exists($key); # or \@path

    # Keys and lists of keys
    @keys = keys %$tiedhref; # All keys; resets iterator
    @keys = $xhash->keys(%options);
    $key = $xhash->first_key();
    $key2 = $xhash->next_key($key1);
    $key = $xhash->last_key();
    $key = $xhash->next_index(); # The next auto-index key

    # Values
    @all_values = values %$tiedhref;
    @some_values = @{%$tiedhref}{@keys}; # or pathrefs
    @all_values = $xhash->values();
    @some_values = $xhash->values(\@keys); # or pathrefs

    ($key, $value) = each(%$tiedhref); # Key/value iteration

    # Does the hash contain any key/value pairs?
    $boolean = scalar(%$tiedhref);
    $boolean = $xhash->scalar();

    ## Array-like operations

    $value = $xhash->pop(); # last value
    ($key, $value) = $xhash->pop(); # last key/value
    $value = $xhash->shift(); # first value
    ($key, $value) = $xhash->shift(); # first key/value

    # Append values or { keys => values }
    $xhash->push(@elements);
    $xhash->pushref(\@elements, %options);

    # Insert values or { keys => values }
    $xhash->unshift(@elements);
    $xhash->unshiftref(\@elements, %options);

    # Export in array-like fashion
    @list = $xhash->as_array(%options);
    $list = $xhash->as_arrayref(%options);

    # Export in hash-like fasion
    @list = $xhash->as_hash(%options);
    $list = $xhash->as_hashref(%options);

    # Reorder elements
    $xhash->reorder($reference, @keys); # [] = sorted index_only

    # Remap elements
    $xhash->remap(%mapping); # or \%mapping
    $xhash->renumber(%options);

    ## TIEHASH methods - see perltie

    # TIEHASH, FETCH, STORE, CLEAR, FIRSTKEY, NEXTKEY

=head1 DESCRIPTION

Data::XHash provides an object-oriented interface to tied, ordered
hashes. Hash elements may be assigned keys explicitly or automatically
in mix-and-match fashion like arrays in PHP.

It also includes support for trees of nested XHashes, tree traversal,
and conversion to and from native Perl data structures.

Suggested uses include structured configuration information or HTTP query
parameters in which order may at least sometimes be significant, for
passing mixed positional and named parameters, or for porting PHP code.

=head1 EXPORTS

You may export any of the shortcut functions. None are exported by default.


=head1 FUNCTIONS

=head2 $tiedref = xh(@elements)

=head2 $tiedref = xhash(@elements)

=head2 $tiedref = xhashref(\@elements, %options)

=head2 $tiedref = xhn(@elements)

=head2 $tiedref = xhr(\@elements, %options)

=head2 $tiedref = xhrn(\@elements, %options)

These convenience functions call C<< Data::XHash->new() >> and then
C<pushref()> the specified elements. The "r" and "ref" versions take an
arrayref of elements; the others take a list. The "n" versions are
shortcuts for the C<< nested => 1 >> option of C<pushref()>.

    $tiedref = xh('hello', {root=>xh({leaf=>'value'}),
      {list=>xh(1, 2, 3)});
    $tiedref = xhn('hello', {root=>{leaf=>'value'}},
      {list=>[1, 2, 3]});

=cut

sub xh { return __PACKAGE__->new()->pushref(\@_); }

sub xhn { return __PACKAGE__->new()->pushref(\@_, nested => 1); }

sub xhr { return __PACKAGE__->new()->pushref(@_); }

sub xhrn { return __PACKAGE__->new()->pushref(shift, nested => 1, @_); }

*xhash = \&xh;
*xhashref = \&xhr;

=head1 METHODS

=head2 Data::XHash->new( )

=head2 $xhash->new( )

This creates a new Data::XHash object and ties it to a new, empty hash. It
blesses the hash as well and returns a reference to the hash (C<$tiedref>).

Do not use C<< tie %some_hash, 'Data::XHash'; >> - it will croak!

=cut

sub new {
    my $type = shift;
    # Support $xhash->new() for same-class auto-vivification.
    my $class = blessed($type) || $type;
    my $self = bless { }, $class;	# The XHash object
    my %hash;

    $self->clear();
    tie %hash, $class, $self;
    return bless \%hash, $class;	# The XHash tiedref
}

sub TIEHASH {
    my ($class, $self) = @_;

    croak("Use \"${class}->new()\", not \"tie \%hash, '$class'\"") unless $self;
    return $self;
}

=head2 $tiedref->{$key}

=head2 $tiedref->{\@path}

=head2 $xhash->fetch($key)

=head2 $xhash->fetch(\@path)

Returns the value for the specified hash key, or C<undef> if the key does
not exist.

If the key parameter is reference to a non-empty array, its elements are
traversed as a path through nested XHashes.

If the last path element is a hashref, the path will be auto-vivified
(Perl-speak for "created when referenced") and made to be an XHash if
necessary (think "fetch a path to a hash"). Otherwise, any missing
element along the path will cause C<undef> to be returned.

    $xhash->{[]}; # undef

    $xhash->{[qw/some path/, {}]}->isa('Data::XHash'); # always true
    # Similar to native Perl: $hash->{some}{path} ||= {};

=cut

sub FETCH {
    my ($self, $key) = @_;

    if (ref($key) eq 'ARRAY' && @$key) {
	# Fetch with path traversal
	return $self->traverse($key, op => 'fetch')->{value};
    }

    # Local fetch
    $self = tied(%$self) || $self;
    return exists($self->{hash}{$key})? $self->{hash}{$key}[2]: undef;
}

*fetch = \&FETCH;

=head2 $tiedref->{$key} = $value

=head2 $tiedref->{\@path} = $value

=head2 $xhash->store($key, $value, %options)

=head2 $xhash->store(\@path, $value, %options)

Stores the value for the specified key in the XHash. Any existing value for
the key is overwritten. New keys are stored at the end of the XHash.

If the key parameter is a reference to a non-empty array, its elements are
traversed as a path through nested XHashes. Path elements will be
auto-vivified as necessary and intermediate ones will be forced to XHashes.

If the key is an empty path or the C<undef> value, or any path key is the
C<undef> value, the next available non-negative integer index in the
corresponding XHash is used instead.

Returns the XHash tiedref or object (whichever was used).

Options:

=over

=item nested => $boolean

If this option is true, arrayref and hashref values will be converted into
XHashes.

=back

=cut

sub STORE {
    my ($this, $key, $value, %options) = @_;
    my $array_key = ref($key) eq 'ARRAY';

    # XHash values are stored as a doubly-linked, circular hash:
    # {hash}{$key}->[$previous_key, $next_key, $value]

    if ($array_key && @$key) {
	# Store with path traversal.
	my $path = $this->traverse($key, op => 'store');
	$path->{container}->STORE($path->{key}, $value, %options);
    } else {
	# Store locally.
	my $self = tied(%$this) || $this;

	# Get the next index for undef or [].
	$key = $self->next_index() if !defined($key) || $array_key;

	if ($options{nested}) {
	    # Convert nested native structures to XHashes.
	    if (ref($value) eq 'HASH') {
		$value = $self->new()->pushref([$value], %options);
	    } elsif (ref($value) eq 'ARRAY') {
		$value = $self->new()->pushref($value, %options);
	    }
	}

	if (exists($self->{hash}{$key})) {
	    # Replace the value for an existing key.
	    $self->{hash}{$key}[2] = $value;
	} else {
	    if (defined($self->{last_key})) {
		# Link an additional key into a non-empty ring
		my ($first, $last) = ($self->first_key(), $self->{last_key});
		$self->{hash}{$key} = [$last, $first, $value];
		$self->{hash}{$last}[1] = $self->{hash}{$first}[0] = $key;
	    } else {
		# Start a new key ring.
		$self->{hash}{$key} = [$key, $key, $value];
	    }
	    $self->{last_key} = $key;
	    $self->{max_index} = $key
	      if ($key =~ /^\d+$/ && $key >= $self->next_index());
	}
    }

    return $this;
}

=head2 %$tiedref = ()

=head2 $xhash->clear( )

Clears the XHash.

Returns the XHash tiedref or object (whichever was used).

=cut

sub CLEAR {
    my ($this) = @_;
    my $self = tied(%$this) || $this;

    $self->{hash} ||= {};
    %{$self->{hash}} = ();
    $self->{last_key} = undef;
    $self->{max_index} = -1;
    return $this;
}

*clear = \&CLEAR;

=head2 delete $tiedref->{$key} # or \@path

=head2 $xhash->delete($key) # or \@path

=head2 $xhash->delete(\%options?, @keys)

Removes the element with the specified key and returns its value. It quietly
returns C<undef> if the key does not exist.

The method call can also delete (and return) multiple local (not path) keys
at once.

Options:

=over

=item to => $destination

If C<$destination> is an arrayref, hashref, or XHash, each deleted
C<{ $key => $value }> is added to it and the destination is returned
instead of the most recently deleted value.

=back

=cut

sub DELETE : method {
    my $self = shift;
    my %options = ref($_[0]) eq 'HASH'? %{+shift}: ();
    my $key = $_[0];

    if (ref($key) eq 'ARRAY' && @$key) {
	# Delete across the path.
	my $path = $self->traverse($key, op => 'delete');

	return $path->{container}?
	  $path->{container}->DELETE($path->{key}): undef;
    }

    # Delete locally.
    my ($to, $return) = ($options{to});

    $self = tied(%$self) || $self;

    while (@_) {
	$key = shift;

        if (exists($self->{hash}{$key})) {
	    my @entry = @{$self->{hash}{$key}};

	    if ($entry[0] ne $key) {
		# There are other keys, so unlink this one from the ring.
		$self->{hash}{$entry[0]}[1] = $entry[1]; # prev.next = my.next
		$self->{hash}{$entry[1]}[0] = $entry[0]; # next.prev = my.prev
		$self->{max_index} = undef
		  if defined($self->{max_index}) && $self->{max_index} eq $key;
		$self->{next_key} = $entry[0]
		  if (defined($self->{next_key}) && $self->{next_key} eq $key);
		$self->{last_key} = $entry[0] if $self->{last_key} eq $key;
		delete $self->{hash}{$key};
	    } else {
		# We're deleting the last key, so just reset.
		$self->CLEAR();
	    }

	    if (ref($to) eq 'ARRAY') {
		push(@$to, { $key => $entry[2] });
	    } elsif (ref($to) eq 'HASH') {
		$to->{$key} = $entry[2];
	    } elsif (blessed($to) && $to->isa(__PACKAGE__)) {
		$to->STORE($key, $entry[2]);
	    } else {
		$return = $entry[2];
	    }
	}
    }

    return $to? $to: $return;
}

*delete = \&DELETE;

=head2 exists $tiedref->{$key} # or \@path

=head2 $xhash->exists($key) # or \@path

Returns true if the key (or path) exists.

=cut

sub EXISTS {
    my ($self, $key) = @_;

    if (ref($key) eq 'ARRAY' && @$key) {
	# Check existence across the path.
	my $path = $self->traverse($key, op => 'exists');

	return $path->{container} && $path->{container}->EXISTS($path->{key});
    }

    # Check existence locally.
    $self = tied(%$self) || $self;
    return exists($self->{hash}{$key});
}

*exists = \&EXISTS;

=head2 $xhash->first_key( )

Returns the first key (or C<undef> if the XHash is empty).

=cut

sub FIRSTKEY {
    my ($self) = @_;

    $self = tied(%$self) || $self;

    # This is a doubly-linked ring buffer, so the first key is
    # the one after the last key.
    return defined($self->{last_key})?
      $self->{hash}{$self->{last_key}}[1]: undef;
}

*first_key = \&FIRSTKEY;

=head2 $xhash->next_key($key)

Returns the key after C<$key>, or C<undef> if C<$key> is the last key or
doesn't exist.

Path keys are not supported.

=cut

sub NEXTKEY {
    my ($this, $prev) = @_;
    my $self = tied(%$this) || $this;

    return ((!defined($self->{last_key}) || $prev eq $self->{last_key})?
      undef: $self->{hash}{$prev}[1]);
}

*next_key = \&NEXTKEY;

=head2 $xhash->last_key( )

Returns the last key, or C<undef> if the XHash is empty.

=cut

sub last_key {
    my $self = shift;

    $self = tied(%$self) || $self;
    return $self->{last_key};
}

=head2 $xhash->next_index( )

Returns the next numeric insertion index. This is either "0" or one more
than the current largest non-negative integer index.

=cut

sub next_index {
    my ($self) = @_;

    $self = tied(%$self) || $self;
    if (!defined($self->{max_index})) {
	# Recalculate max_index if that key was previously deleted.
	$self->{max_index} = -1;
	foreach (grep(/^\d+$/, keys %{$self->{hash}})) {
	    $self->{max_index} = $_ if $_ > $self->{max_index};
	}
    }

    return $self->{max_index} + 1;
}

=head2 scalar(%$tiedref)

=head2 $xhash->scalar( )

Returns true if the XHash is not empty.

=cut

sub SCALAR : method {
    my ($self) = @_;
    
    return scalar %{$self->{hash}};
}

*scalar = \&SCALAR;

=head2 $xhash->keys(%options)

This method is equivalent to C<keys(%$tiedref)> but may be called on the
object.

Options:

=over

=item index_only => $boolean

If true, only the integer index keys are returned. If false, all keys are
returned,

=item sorted => $boolean

If index_only mode is true, this option determines whether index keys are
returned in ascending order (true) or XHash insertion order (false).

=back

=cut

sub keys : method {
    my ($self, %options) = @_;
    my (@keys, $key);

    $self = tied(%$self) || $self;
    $key = $self->FIRSTKEY();
    while (defined($key)) {
	push(@keys, $key);
	$key = $self->NEXTKEY($key);
    }

    if ($options{index_only}) {
	@keys = grep(/^-?\d+$/, @keys);
	@keys = sort({ $a <=> $b } @keys) if $options{sorted};
    }

    return @keys;
}

=head2 $xhash->values([keys]?)

This method is equivalent to C<values(%$tiedref)> but may be called on the
object.

You may optionally pass a reference to an array of keys whose values should
be returned (equivalent to the slice C<@{$tiedref}{@$keys}>).

=cut

sub values : method {
    my $self = shift;
    my $keys = shift;

    $self = tied(%$self) || $self;
    return map($self->fetch($_), (ref($keys) eq 'ARRAY'?
      @$keys: $self->keys()));
}

sub UNTIE {}
sub DESTROY {}

=head2 $xhash->pop( )

=head2 $xhash->shift( )

Removes the first element (shift) or last element (pop) from the XHash and
returns its value (in scalar context) or its key and value (in list
context). If the XHash was already empty, C<undef> or C<()> is returned
instead.

=cut

sub pop : method {
    my ($self) = @_;

    $self = tied(%$self) || $self;
    return wantarray? (): undef unless defined($self->{last_key});

    my $key = $self->{last_key};
    return wantarray? ($key, $self->DELETE($key)): $self->DELETE($key);
}

sub shift : method {
    my ($self) = @_;

    $self = tied(%$self) || $self;
    return wantarray? (): undef unless defined($self->{last_key});

    my $key = $self->first_key();
    return wantarray? ($key, $self->DELETE($key)): $self->DELETE($key);
}

=head2 $xhash->push(@elements)

=head2 $xhash->pushref(\@elements, %options)

=head2 $xhash->unshift(@elements)

=head2 $xhash->unshiftref(\@elements, %options)

Appends elements at the end of the XHash (C<push()> and C<pushref()>) or
inserts elements at the beginning of the XHash (C<unshift()> and
C<unshiftref()>).

Scalar elements are automatically assigned a numeric index using
C<next_index()>. Hashrefs are added as key/value pairs. References
to references are dereferenced by one level before being added. (To add
a hashref as a hashref rather than key/value pairs, push or unshift a
reference to the hashref instead.)

Returns the XHash tiedref or object (whichever was used).

Options:

=over

=item at_key => $key

This will push after C<$key> instead of at the end of the XHash or unshift
before C<$key> instead of at the beginning of the XHash. This only applies
to the first level of a nested push or unshift.

This must be a local key (not a path), and the operation will croak if
the key is not found.

=item nested => $boolean

If true, values that are arrayrefs (possibly containing hashrefs) or
hashrefs will be recursively converted to XHashes.

=back

=cut

sub push : method { return shift->pushref(\@_); }

sub pushref {
    my ($this, $list, %options) = @_;
    my $self = tied(%$this) || $this;
    my $at_key = delete $options{at_key};
    my $save_last;

    croak "pushref requires an arrayref" unless ref($list) eq 'ARRAY';

    if (defined($at_key)) {
	croak "pushref at_key => key does not exist"
	  unless exists($self->{hash}{$at_key});
	if ($at_key ne $self->{last_key}) {
	    # Temporarily shift the end of the ring
	    $save_last = $self->{last_key};
	    $self->{last_key} = $at_key;
	}
    }

    foreach my $item (@$list) {
	if (ref($item) eq 'HASH') {
	    $self->STORE($_, $item->{$_}, %options) foreach (keys %$item);
	} elsif (ref($item) eq 'REF') {
	    $self->STORE(undef, $$item, %options, nested => 0);
	} else {
	    $self->STORE(undef, $item, %options);
	}
    }

    # Restore the ring after at_key push
    $self->{last_key} = $save_last if defined($save_last);

    return $this;
}

sub unshift : method { return shift->unshiftref(\@_); }

sub unshiftref {
    my ($this, $list, %options) = @_;
    my $self = tied(%$this) || $this;
    my $at_key = delete($options{at_key});
    my $save_last = $self->{last_key};

    croak "unshiftref requires an arrayref" unless ref($list) eq 'ARRAY';

    if (defined($at_key)) {
	croak "unshiftref at_key => key does not exist"
	  unless exists($self->{hash}{$at_key});
	# Temporarily shift the ring
	$self->{last_key} = $self->{hash}{$at_key}[0];
    }

    $self->pushref($list, %options);
    $self->{last_key} = $save_last if defined($save_last);

    return $this;
}

=head2 $xhash->as_array(%options)

=head2 $xhash->as_arrayref(%options)

=head2 $xhash->as_hash(%options)

=head2 $xhash->as_hashref(%options)

These methods export the contents of the XHash as native Perl arrays or
arrayrefs.

The "array" versions return the elements in an "array-like" array or array
reference; elements with numerically indexed keys are returned without their
keys.

The "hash" versions return the elements in an "hash-like" array or array
reference; all elements, including numerically indexed ones, are returned
with keys.

    xh( { foo => 'bar' }, 123, \{ key => 'value' } )->as_arrayref();
    # [ { foo => 'bar' }, 123, \{ key => 'value'} ]

    xh( { foo => 'bar' }, 123, \{ key => 'value' } )->as_hash();
    # ( { foo => 'bar' }, { 0 => 123 }, { 1 => { key => 'value' } } )

    xh(xh({ 3 => 'three' }, { 2 => 'two' })->as_array())->as_hash();
    # ( { 0 => 'three' }, { 1 => 'two' } )

    xh( 'old', { key => 'old' } )->push(
    xh( 'new', { key => 'new' } )->as_array())->as_array();
    # ( 'old', { key => 'new' }, 'new' )

    xh( 'old', { key => 'old' } )->push(
    xh( 'new', { key => 'new' } )->as_hash())->as_hash();
    # ( { 0 => 'new' }, { key => 'new' } )

Options:

=over

=item nested => $boolean

If this option is true, trees of nested XHashes are recursively expanded.

=back

=cut

sub as_array { return @{shift->as_arrayref(@_)}; }

sub as_arrayref {
    my ($self, %options) = @_;
    my @list;

    $self = tied(%$self) || $self;
    foreach ($self->keys()) {
	my $value = $self->{hash}{$_}[2];
	if (/^-?\d+$/) {
	    if ($options{nested} && blessed($value) &&
	      $value->isa(__PACKAGE__)) {
		push(@list, $value->as_arrayref(%options));
	    } else {
		push(@list, ref($value) =~ /HASH|REF/? \$value: $value);
	    }
	} else {
	    if ($options{nested} && blessed($value) &&
	      $value->isa(__PACKAGE__)) {
		push(@list, { $_ => $value->as_arrayref(%options) });
	    } else {
		push(@list, { $_ => $value });
	    }
	}
    }

    return \@list;
}

sub as_hash { return @{shift->as_hashref(@_)}; }

sub as_hashref {
    my ($self, %options) = @_;
    my @list;

    $self = tied(%$self) || $self;
    foreach ($self->keys()) {
	my $value = $self->{hash}{$_}[2];
	if ($options{nested} && blessed($value) && $value->isa(__PACKAGE__)) {
	    push(@list, { $_ => $value->as_hashref(%options) });
	} else {
	    push(@list, { $_ => $value });
	}
    }

    return \@list;
}

=head2 $xhash->reorder($refkey, @keys)

Reorders elements within the XHash relative to the reference element having
key C<$refkey>, which must exist and will not be moved.

If the reference key appears in C<@keys>, the elements with keys preceding
it will be moved immediately before the reference element. All other
elements will be moved immediately following the reference element.

Only the first occurence of any given key in C<@keys> is
considered - duplicates are ignored.

If any key is an arrayref, it is replaced with a sorted list of index keys.

Returns the XHash tiedref or object (whichever was used).

    # Move some keys to the beginning of the XHash.
    $xhash->reorder($xhash->first_key(), @some_keys,
      $xhash->first_key());

    # Move some keys to the end of the XHash.
    $xhash->reorder($xhash->last_key(), @some_keys);

    # Group numeric index keys in ascending order at the lowest one.
    $xhash->reorder([]);

=cut

sub reorder {
    my ($this, @keys) = @_;
    my $self = tied(%$this) || $this;
    my ($refkey, $before, @after);

    @keys = map(ref($_) eq 'ARRAY'?
      $self->keys(index_only => 1, sorted => 1): $_, @keys);
    $refkey = shift(@keys);

    croak("reorder reference key does not exist")
      unless exists($self->{hash}{$refkey});

    while (@keys) {
	my $key = shift(@keys);

	if ($key ne $refkey) {
	    push(@after, { $key => $self->DELETE($key) })
	      if exists($self->{hash}{$key});
	} elsif (!$before) {
	    $before = [ @after ];
	    @after = ();
	}
    }

    $self->unshiftref($before, at_key => $refkey) if $before;
    $self->pushref(\@after, at_key => $refkey) if @after;

    return $this;
}

=head2 $xhash->remap(\%mapping)

=head2 $xhash->remap(%mapping)

Remaps element keys according to the specified mapping (a hash of
C<< $old_key => $new_key >>). The mapping must map old keys to new keys
one-to-one.

The order of elements in the XHash is unchanged.

=cut

sub remap {
    my $this = shift;
    my $self = tied(%$this) || $this;
    my %map = ref($_[0]) eq 'HASH'? %{$_[0]}: @_;
    my $last = $self->{last_key};
    my %hash;

    croak "remap mapping must be unique"
      unless keys(%{{ map(($_ => 1), values(%map)) }}) ==
      values(%map);

    while (my ($key, $entry) = each(%{$self->{hash}})) {
	$entry->[0] = $map{$entry->[0]} if exists($map{$entry->[0]});
	$entry->[1] = $map{$entry->[1]} if exists($map{$entry->[1]});
	$hash{exists($map{$key})? $map{$key}: $key} = $entry;
    }

    $self->{hash} = \%hash;
    $self->{last_key} = $map{$last}
      if defined($last) && exists($map{$last});

    return $this;
}

=head2 $xhash->renumber(%options)

Renumbers all elements with an integer index (those returned by
C<< $xhash->keys(index_only => 1) >>). The order of elements is
unchanged.

Returns the XHash tiedref or object (whichever was used).

Options:

=over

=item from => $starting_index

Renumber from C<$starting_index> instead of the default zero.

=item sorted => $boolean

This option is passed to C<< $xhash->keys() >>.

If set to true, keys will be renumbered in sorted sequence. This results
in a "relative" renumbering (previously higher index keys will still be
higher after renumbering, regardless of order in the XHash).

If false or not set, keys will be renumbered in XHash (or "absolute") order.

=back

=cut

sub renumber {
    my ($self, %options) = @_;
    my $start = $options{from} || 0;

    my @keys = $self->keys(index_only => 1, sorted => $options{sorted});
    if (@keys) {
	my %map;

	@map{@keys} = map($_ + $start, 0 .. $#keys);
	$self->remap(\%map);
    }

    return $self;
}

=head2 $xhash->traverse($path, options?)

This method traverses nested XHash trees. The path may be a simple scalar
key, or it may be an array reference containing multiple keys along the
path.

An C<undef> value along the path will translate to the next available
integer index at that level in the path. A C<{}> at the end of the path
forces auto-vivification of an XHash at the end of the path if one does not
already exist there.

This method returns a reference to a hash containing the elements
"container", "key", and "value". If the path does not exist, the container
value with be C<undef>.

An empty path (C<[]>) is equivalent to a path of C<undef>.

Options:

=over

=item op

Specifies the operation for which the traversal is being performed
(fetch, store, exists, or delete).

=item xhash

Force the path to terminate with an XHash (for "fetch" paths ending in C<{}>).

=item vivify

Auto-vivify missing intermediate path elements.

=back

=cut

sub traverse {
    my ($self, $path, %options) = @_;
    my @path = (ref($path) eq 'ARRAY')? @$path: ($path);
    my $container = $self;
    my $op = $options{op} || '';
    my ($key, $value);

    if (@path && ref($path[-1]) eq 'HASH') {
	# Vivify to terminal XHash on fetch path [ ... {} ].
	$options{vivify} = $options{xhash} = 1 if $op eq 'fetch';
	pop(@path);
    }

    # Default to vivify on store.
    $options{vivify} = 1 if $op eq 'store' && !exists($options{vivify});

    while (@path) {
	$key = shift(@path);
	if (!defined($key) || !$container->EXISTS($key)) {
	    # This part of the path is missing. Stop or vivify.
	    return { container => undef, key => undef, value => undef }
	      unless $options{vivify};

	    # Use the next available index for undef keys.
	    $key = $container->next_index() unless defined($key);

	    if (@path || $options{xhash}) {
		# Vivify an XHash for intermediates or fetch {}.
		$container->STORE($key, $value = $self->new());
	    } else {
		$value = undef;
	    }
	} else {
	    $value = $container->FETCH($key);
	    $container->STORE($key, $value = $self->new())
	      if (@path || $options{xhash}) &&
	      (!blessed($value) || !$value->isa(__PACKAGE__));
	}
	$container = $value if @path;
    }

    $key = $container->next_index() unless defined($key);
    return { container => $container, key => $key, value => $value };
}

=head1 AUTHOR

Brian Katzung, C<< <briank at kappacs.com> >>

=head1 BUG TRACKING

Please report any bugs or feature requests to
C<bug-data-xhash at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-XHash>. I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::XHash

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-XHash>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-XHash>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-XHash>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-XHash/>

=back

=head1 SEE ALSO

=over

=item L<Array::AsHash>

An array wrapper to manage elements as key/value pairs.

=item L<Array::Assign>

Allows you to assign names to array indexes.

=item L<Array::OrdHash>

Like L<Array::Assign>, but with native Perl syntax.

=item L<Data::Omap>

An ordered map implementation, currently implementing an array of single-key
hashes stored in key-sorting order.

=item L<Tie::IxHash>

An ordered hash implementation with a different interface and data
structure and without auto-indexed keys and some of Data::XHash's
other features.

=item L<Tie::Hash::Array>

Hashes stored as arrays in key sorting-order.

=item L<Tie::LLHash>

A linked-list-based hash like L<Data::XHash>, but it doesn't support the
push/pop/shift/unshift array interface and it doesn't have automatic keys.

=item L<Tie::StoredOrderHash>

Hashes with items stored in least-recently-used order.

=back

=for comment
head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Brian Katzung.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Data::XHash
