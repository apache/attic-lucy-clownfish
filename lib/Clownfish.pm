# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
use warnings;

package Clownfish;
our $VERSION = '0.01';

use XSLoader;
BEGIN { XSLoader::load( 'Clownfish', '0.01' ) }

{
    package Clownfish::Base;
}

{
    package Clownfish::CBlock;
    BEGIN { push our @ISA, 'Clownfish::Base' }
    use Clownfish::Util qw( verify_args );
    use Carp;

    our %new_PARAMS = ( contents => undef, );

    sub new {
        my ( $either, %args ) = @_;
        verify_args( \%new_PARAMS, %args ) or confess $@;
        confess("Missing required param 'contents'")
            unless defined $args{contents};
        return $either->_new( $args{contents} );
    }
}

{
    package Clownfish::Class;
    BEGIN { push our @ISA, 'Clownfish::Symbol' }
    use Carp;
    use Config;
    use Clownfish::Util qw(
        verify_args
        a_isa_b
    );

    END { __PACKAGE__->_clear_registry() }

    our %create_PARAMS = (
        source_class      => undef,
        class_name        => undef,
        cnick             => undef,
        parent_class_name => undef,
        docucomment       => undef,
        inert             => undef,
        final             => undef,
        parcel            => undef,
        exposure          => 'parcel',
    );

    our %fetch_singleton_PARAMS = (
        parcel     => undef,
        class_name => undef,
    );

    sub fetch_singleton {
        my ( undef, %args ) = @_;
        verify_args( \%fetch_singleton_PARAMS, %args ) or confess $@;
        # Maybe prepend parcel prefix.
        my $parcel = $args{parcel};
        if ( defined $parcel ) {
            if ( !a_isa_b( $parcel, "Clownfish::Parcel" ) ) {
                $parcel = Clownfish::Parcel->singleton( name => $parcel );
            }
        }
        return _fetch_singleton( $parcel, $args{class_name} );
    }

    sub new { confess("The constructor for Clownfish::Class is create()") }

    sub create {
        my ( $either, %args ) = @_;
        verify_args( \%create_PARAMS, %args ) or confess $@;
        $args{parcel} = Clownfish::Parcel->acquire( $args{parcel} );
        my $package = ref($either) || $either;
        return _create(
            $package,
            @args{
                qw( parcel exposure class_name cnick micro_sym
                    docucomment source_class parent_class_name final inert )
                }
        );
    }
}

{
    package Clownfish::DocuComment;
    BEGIN { push our @ISA, 'Clownfish::Base' }
}

{
    package Clownfish::Dumpable;
    BEGIN { push our @ISA, 'Clownfish::Base' }

    sub new {
        my $either = shift;
        my $package = ref($either) || $either;
        return $either->_new();
    }
}

{
    package Clownfish::File;
    BEGIN { push our @ISA, 'Clownfish::Base' }
    use Clownfish::Util qw( verify_args );
    use Carp;

    our %new_PARAMS = ( source_class => undef, );

    sub new {
        my ( $either, %args ) = @_;
        verify_args( \%new_PARAMS, %args ) or confess $@;
        my $package = ref($either) || $either;
        return $either->_new( $args{source_class} );
    }
}

{
    package Clownfish::Function;
    BEGIN { push our @ISA, 'Clownfish::Symbol' }
    use Carp;
    use Clownfish::Util qw( verify_args a_isa_b );

    my %new_PARAMS = (
        return_type => undef,
        class_name  => undef,
        class_cnick => undef,
        param_list  => undef,
        micro_sym   => undef,
        docucomment => undef,
        parcel      => undef,
        inline      => undef,
        exposure    => undef,
    );

    sub new {
        my ( $either, %args ) = @_;
        verify_args( \%new_PARAMS, %args ) or confess $@;
        $args{inline} ||= 0;
        $args{parcel} = Clownfish::Parcel->acquire( $args{parcel} );
        my $package = ref($either) || $either;
        return $package->_new(
            @args{
                qw( parcel exposure class_name class_cnick micro_sym
                    return_type param_list docucomment inline )
                }
        );
    }
}

{
    package Clownfish::Hierarchy;
    BEGIN { push our @ISA, 'Clownfish::Base' }
    use Carp;
    use Clownfish::Util qw( verify_args );

    our %new_PARAMS = (
        source => undef,
        dest   => undef,
    );

    sub new {
        my ( $either, %args ) = @_;
        verify_args( \%new_PARAMS, %args ) or confess $@;
        my $package = ref($either) || $either;
        my $parser = Clownfish::Parser->new;
        return $package->_new( @args{qw( source dest )}, $parser );
    }

    sub _do_parse_file {
        my ( $parser, $content, $source_class ) = @_;
        $content = $parser->strip_plain_comments($content);
        return $parser->file( $content, 0, source_class => $source_class, );
    }
}

{
    package Clownfish::Method;
    BEGIN { push our @ISA, 'Clownfish::Function' }
    use Clownfish::Util qw( verify_args );
    use Carp;

    my %new_PARAMS = (
        return_type => undef,
        class_name  => undef,
        class_cnick => undef,
        param_list  => undef,
        macro_sym   => undef,
        docucomment => undef,
        parcel      => undef,
        abstract    => undef,
        final       => undef,
        exposure    => 'parcel',
    );

    sub new {
        my ( $either, %args ) = @_;
        verify_args( \%new_PARAMS, %args ) or confess $@;
        $args{abstract} ||= 0;
        $args{parcel} = Clownfish::Parcel->acquire( $args{parcel} );
        $args{final} ||= 0;
        my $package = ref($either) || $either;
        return $package->_new(
            @args{
                qw( parcel exposure class_name class_cnick macro_sym
                    return_type param_list docucomment final abstract )
                }
        );
    }
}

{
    package Clownfish::ParamList;
    BEGIN { push our @ISA, 'Clownfish::Base' }
    use Clownfish::Util qw( verify_args );
    use Carp;

    our %new_PARAMS = ( variadic => undef, );

    sub new {
        my ( $either, %args ) = @_;
        verify_args( \%new_PARAMS, %args ) or confess $@;
        my $class_name = ref($either)           || $either;
        my $variadic   = delete $args{variadic} || 0;
        return $class_name->_new($variadic);
    }
}

{
    package Clownfish::Parcel;
    BEGIN { push our @ISA, 'Clownfish::Base' }
    use Clownfish::Util qw( verify_args );
    use Scalar::Util qw( blessed );
    use Carp;

    END {
        __PACKAGE__->reap_singletons();
    }

    our %singleton_PARAMS = (
        name  => undef,
        cnick => undef,
    );

    sub singleton {
        my ( $either, %args ) = @_;
        verify_args( \%singleton_PARAMS, %args ) or confess $@;
        my $package = ref($either) || $either;
        return $package->_singleton( @args{qw( name cnick )} );
    }

    sub acquire {
        my ( undef, $thing ) = @_;
        if ( !defined $thing ) {
            return Clownfish::Parcel->default_parcel;
        }
        elsif ( blessed($thing) ) {
            confess("Not a Clownfish::Parcel")
                unless $thing->isa('Clownfish::Parcel');
            return $thing;
        }
        else {
            return Clownfish::Parcel->singleton( name => $thing );
        }
    }
}

{
    package Clownfish::Symbol;
    BEGIN { push our @ISA, 'Clownfish::Base' }
    use Clownfish::Util qw( verify_args );
    use Carp;

    my %new_PARAMS = (
        parcel      => undef,
        exposure    => undef,
        class_name  => undef,
        class_cnick => undef,
        micro_sym   => undef,
    );

    sub new {
        my ( $either, %args ) = @_;
        verify_args( \%new_PARAMS, %args ) or confess $@;
        $args{parcel} = Clownfish::Parcel->acquire( $args{parcel} );
        my $class_class = ref($either) || $either;
        return $class_class->_new(
            @args{qw( parcel exposure class_name class_cnick micro_sym )} );
    }
}

{
    package Clownfish::Type;
    BEGIN { push our @ISA, 'Clownfish::Base' }
    use Clownfish::Util qw( verify_args a_isa_b );
    use Scalar::Util qw( blessed );
    use Carp;

    our %new_PARAMS = (
        const       => undef,
        specifier   => undef,
        indirection => undef,
        parcel      => undef,
        c_string    => undef,
        void        => undef,
        object      => undef,
        primitive   => undef,
        integer     => undef,
        floating    => undef,
        string_type => undef,
        va_list     => undef,
        arbitrary   => undef,
        composite   => undef,
    );

    sub new {
        my ( $either, %args ) = @_;
        my $package = ref($either) || $either;
        verify_args( \%new_PARAMS, %args ) or confess $@;

        my $flags = 0;
        $flags |= CONST       if $args{const};
        $flags |= NULLABLE    if $args{nullable};
        $flags |= VOID        if $args{void};
        $flags |= OBJECT      if $args{object};
        $flags |= PRIMITIVE   if $args{primitive};
        $flags |= INTEGER     if $args{integer};
        $flags |= FLOATING    if $args{floating};
        $flags |= STRING_TYPE if $args{string_type};
        $flags |= VA_LIST     if $args{va_list};
        $flags |= ARBITRARY   if $args{arbitrary};
        $flags |= COMPOSITE   if $args{composite};

        my $parcel
            = $args{parcel}
            ? Clownfish::Parcel->acquire( $args{parcel} )
            : $args{parcel};

        my $indirection = $args{indirection} || 0;
        my $specifier   = $args{specifier}   || '';
        my $c_string    = $args{c_string}    || '';

        return $package->_new( $flags, $parcel, $specifier, $indirection,
            $c_string );
    }

    our %new_integer_PARAMS = (
        const     => undef,
        specifier => undef,
    );

    sub new_integer {
        my ( $either, %args ) = @_;
        verify_args( \%new_integer_PARAMS, %args ) or confess $@;
        my $flags = 0;
        $flags |= CONST if $args{const};
        my $package = ref($either) || $either;
        return $package->_new_integer( $flags, $args{specifier} );
    }

    our %new_float_PARAMS = (
        const     => undef,
        specifier => undef,
    );

    sub new_float {
        my ( $either, %args ) = @_;
        verify_args( \%new_float_PARAMS, %args ) or confess $@;
        my $flags = 0;
        $flags |= CONST if $args{const};
        my $package = ref($either) || $either;
        return $package->_new_float( $flags, $args{specifier} );
    }

    our %new_object_PARAMS = (
        const       => undef,
        specifier   => undef,
        indirection => 1,
        parcel      => undef,
        incremented => 0,
        decremented => 0,
        nullable    => 0,
    );

    sub new_object {
        my ( $either, %args ) = @_;
        verify_args( \%new_object_PARAMS, %args ) or confess $@;
        my $flags = 0;
        $flags |= INCREMENTED if $args{incremented};
        $flags |= DECREMENTED if $args{decremented};
        $flags |= NULLABLE    if $args{nullable};
        $flags |= CONST       if $args{const};
        $args{indirection} = 1 unless defined $args{indirection};
        my $parcel = Clownfish::Parcel->acquire( $args{parcel} );
        my $package = ref($either) || $either;
        confess("Missing required param 'specifier'")
            unless defined $args{specifier};
        return $package->_new_object( $flags, $parcel, $args{specifier},
            $args{indirection} );
    }

    our %new_composite_PARAMS = (
        child       => undef,
        indirection => undef,
        array       => undef,
        nullable    => undef,
    );

    sub new_composite {
        my ( $either, %args ) = @_;
        verify_args( \%new_composite_PARAMS, %args ) or confess $@;
        my $flags = 0;
        $flags |= NULLABLE if $args{nullable};
        my $indirection = $args{indirection} || 0;
        my $array = defined $args{array} ? $args{array} : "";
        my $package = ref($either) || $either;
        return $package->_new_composite( $flags, $args{child}, $indirection,
            $array );
    }

    our %new_void_PARAMS = ( const => undef, );

    sub new_void {
        my ( $either, %args ) = @_;
        verify_args( \%new_void_PARAMS, %args ) or confess $@;
        my $package = ref($either) || $either;
        return $package->_new_void( !!$args{const} );
    }

    sub new_va_list {
        my $either = shift;
        verify_args( {}, @_ ) or confess $@;
        my $package = ref($either) || $either;
        return $either->_new_va_list();
    }

    our %new_arbitrary_PARAMS = (
        parcel    => undef,
        specifier => undef,
    );

    sub new_arbitrary {
        my ( $either, %args ) = @_;
        verify_args( \%new_arbitrary_PARAMS, %args ) or confess $@;
        my $package = ref($either) || $either;
        my $parcel = Clownfish::Parcel->acquire( $args{parcel} );
        return $package->_new_arbitrary( $parcel, $args{specifier} );
    }
}

{
    package Clownfish::Variable;
    BEGIN { push our @ISA, 'Clownfish::Symbol' }
    use Clownfish::Util qw( verify_args );
    use Carp;

    our %new_PARAMS = (
        type        => undef,
        micro_sym   => undef,
        parcel      => undef,
        exposure    => 'local',
        class_name  => undef,
        class_cnick => undef,
        inert       => undef,
    );

    sub new {
        my ( $either, %args ) = @_;
        verify_args( \%new_PARAMS, %args ) or confess $@;
        $args{exposure} ||= 'local';
        $args{parcel} = Clownfish::Parcel->acquire( $args{parcel} );
        my $package = ref($either) || $either;
        return $package->_new(
            @args{
                qw( parcel exposure class_name class_cnick micro_sym type inert )
                }
        );
    }
}

1;

=head1 NAME

Clownfish - A small OO language that forms symbiotic relationships with "host"
languages.

=head1 PRIVATE API

Clownfish is an Apache Lucy implementation detail.  This documentation is partial --
enough for the curious hacker, but not a full API.

=head1 DESCRIPTION

=head2 Overview.

Clownfish is a small language for declaring an object oriented interface and a
compiler which allows classes to be implemented either in C, in a "host"
language, or a combination of both. 

=head2 Why use Clownfish?

=over

=item *

Clownfish-based projects give users the ability to write full subclasses
in any "host" language for which a binding has been prepared.

=item *

Pure C Clownfish class implementations are very fast.

=item *

Users can perform rapid prototyping in their language of choice, then port
their classes to C either for speed or to make them available across multiple
language platforms.

=item *

=back

=head2 Object Model

Clownfish is single-inheritance and class based -- a minimalist design which
makes it as compatible as possible with a broad range of hosts.

Subclasses may be created either at compile time or at run time.

=back

=head2 C method invocation syntax.

Methods are differentiated from functions via capitalization:
Boat_capsize() is a function, Boat_Capsize() is a method.

    // Base method.
    void
    Boat_capsize(Boat *self)
    {
        self->upside_down = true;
    }

    // Implementing function, in Boat/Battleship.c
    void
    Battleship_capsize(Battleship *self) 
    {
        // Superclass method invocation.
        Boat_capsize_t capsize = (Boat_capsize_t)SUPER_METHOD(
            BATTLESHIP, Battleship, Capsize);
        capsize((Boat*)self);  

        // Subclass-specific behavior.
        Battleship_Sink(self);
    }

    // Implementing function, in Boat/RubberDinghy.c
    void
    RubDing_capsize(RubberDinghy *self) 
    {
        // Superclass method invocation.
        Boat_capsize_t capsize = (Boat_capsize_t)SUPER_METHOD(
            RUBBERDINGHY, RubDing, Capsize);
        capsize((Boat*)self);  

        // Subclass-specific behavior.
        RubDing_Drift(self);
    }

=head2 Class declaration syntax

    [final] [inert] class CLASSNAME [cnick CNICK] 
        [inherits PARENT] [ : ATTRIBUTE ]* {
    
        [declarations]
    
    }

Example:

    class Boat::RubberDinghy cnick RubDing inherits Boat {
        
        public inert incremented RubberDinghy*
        new();
        
        void 
        Capsize(RubberDinghy *self);
    }

=over

=item * B<CLASSNAME> - The name of this class.  The last string of characters
will be used as the object's C struct name.

=item * B<CNICK> - A recognizable abbreviation of the class name, used as a
prefix for every function and method.

=item * B<PARENT> - The full name of the parent class.

=item * B<ATTRIBUTE> - An arbitrary attribute, e.g. "dumpable", or perhaps
"serializable".  A class may have multiple attributes, each preceded by a
colon.

=back

=head2 Memory management

At present, memory is managed via a reference counting scheme, but this is not
inherently part of Clownfish.

=head2 Namespaces, parcels, prefixes, and "short names"

There are two levels of namespacing in Clownfish: parcels and classes.

Clownfish classes intended to be published as a single unit may be grouped
together using a "parcel".  Parcel directives need to go at the top of each
class file.

    parcel Crustacean cnick Crust;

All symbols generated by Clownfish for classes within a parcel will be
prefixed by varying capitalizations of the parcel's C-nickname or "cnick" in
order to avoid namespace collisions with other projects.

Within a parcel, the last part of each class name must be unique.

    class Crustacean::Lobster::Claw { ... }
    class Crustacean::Crab::Claw    { ... } // Illegal, "Claw" already used

"Short names" -- names minus the parcel prefix -- will be auto-generated for
all class symbols.  When there is no danger of namespace collision, typically
because no third-party non-system libraries are being pound-included, the
short names can be used after a USE_SHORT_NAMES directive:

    #define CRUST_USE_SHORT_NAMES

The USE_SHORT_NAMES directives do not affect class prefixes, only parcel
prefixes.

    // No short names.
    crust_LobsterClaw *claw = crust_LobClaw_new();
    
    // With short names.
    #define CRUST_USE_SHORT_NAMES
    LobsterClaw *claw = LobClaw_new();

=head2 Inclusion

C header code generated by the Clownfish compiler is written to a file with
whose name is the same as the .cfh file, but with an extension of ".h".  C
code should pound-include "Crustacean/Lobster.h" for a class defined in
"Crustacean/Lobster.cfh".

=head1 COPYRIGHT 
 
Clownfish is distributed under the Apache License, Version 2.0, as 
described in the file C<LICENSE> included with the distribution. 

=cut

