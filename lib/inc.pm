package inc;
our $VERSION = '0.02';

use Cwd();
use Config();

my $plugins = {};
my $inc;
BEGIN {
    $inc ||= [@INC];
}

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

#------------------------------------------------------------------------------
# Smart Objects
#------------------------------------------------------------------------------
sub inc_core {
    my ($self, $version) = @_;
    die "inc 'core' object not yet implemented";
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

sub inc_lib {
    return Cwd::cwd . '/lib';
}

sub inc_blib {
    return 'blib/lib', 'blib/arch';
}

sub inc_inc {
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

1;
