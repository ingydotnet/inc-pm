use strict;
package inc;
our $VERSION = '0.03';

use Cwd();
use Config();

my $corelists = {};
my $plugins = {};
my $inc = [@INC];

sub import {
    my ($class) = shift;
    return unless @_;
    my $self = bless {}, $class;
    @INC = $self->create_list(@_);
    return;
}

sub list {
    my ($class) = shift;
    die "'inc->list' requires at least one argument"
        unless @_;
    my $self = bless {}, $class;
    return $self->create_list(@_);
}

sub create_list {
    my ($self) = shift;
    $self->{spec} = [@_];
    my $list = $self->{list} = [];
    $self->{inc} = [@INC];
    while (my $next = $self->parse_spec(@_)) {
        my ($name, @args) = @$next;
        if ($name =~ m!/!) {
            push @$list, $name;
        }
        else {
            my $method = "inc_$name";
            die "No inc support found for '$name'"
                unless $self->can($method);
            push @$list, $self->$method(@args);
        }
    }
    return @$list;
}

sub parse_spec {
    my ($self) = @_;
    my $next = $self->get_next_spec or return;
    die "Invalid spec string '$next'"
      unless $next =~ /^(\-?)(\w+)(?:=(.*))?$/;
    my $name = $2;
    $name = "not_$name" if $1;
    my @args = $3 ? split /,/, $3 : ();
    return [$name, @args];
}

sub get_next_spec {
    my ($self) = @_;
    while (@{$self->{spec}}) {
        my $next = shift @{$self->{spec}};
        next unless length $next;
        if ($next =~ /:/) {
            # XXX This parse is flimsy:
            my @rest;
            ($next, @rest) = split /:/, $next;
            unshift @{$self->{spec}}, @rest;
            next unless $next;
        }
        return $next;
    }
    return;
}

sub lookup {
    my ($modpath, @inc) = @_;
    for (@inc) {
        my $path = "$_/$modpath";
        if (-e $path) {
            open my $fh, '<', $path
                or die "Can't open '$path' for input:\n$!";
            return $fh;
        }
    }
    return;
}

#------------------------------------------------------------------------------
# Smart Objects
#------------------------------------------------------------------------------
sub inc_core {
    my ($self, $version) = @_;
    $version ||= $Config::Config{version};
    my $hash = $corelists->{$version} ||= do {
        +{
            split /\s+/, `corelist -v $version //`
        }
    };
    return sub {
        my ($self, $modpath) = @_;
        (my $modname = $modpath) =~ s!/!::!g;
        $modname =~ s!\.pm$!!;
        return unless $hash->{$modname};
        return lookup($modpath, @$inc);
    }
}

sub inc_deps {
    my ($self, @module) = @_;
    die "inc 'deps' object not yet implemented";
}

sub inc_meta {
    my ($self) = @_;
    die "inc 'meta' object not yet implemented";
}

sub inc_dist {
    my ($self) = @_;
    die "inc 'dist' object not yet implemented";
}

sub inc_perl5lib {
    return () unless defined $ENV{PERL5LIB};
    return split /:/, $ENV{PERL5LIB};
}

sub inc_lib {
    return Cwd::abs_path('lib');
}

sub inc_blib {
    return 'blib/lib', 'blib/arch';
}

sub inc_inc {
    my ($self) = @_;
    return @{$self->{inc}};
}

sub inc_INC {
    return @$inc;
}

sub inc_priv {
    die "inc 'priv' object not yet implemented";
}

sub inc_not_priv {
    die "inc '-priv' object not yet implemented";
}

sub inc_site {
    die "inc 'site' object not yet implemented";
}

sub inc_not_site {
    die "inc '-site' object not yet implemented";
}

sub inc_not {
    die "inc 'not' object not yet implemented";
}

sub inc_none {
    return ();
}

sub inc_list {
    my ($self) = @_;
    for (@{$self->{list}}) {
        print "$_\n";
    }
    return ();
}

1;
