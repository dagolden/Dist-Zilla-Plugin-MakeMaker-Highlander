use v5.10;
use strict;
use warnings;

package Dist::Zilla::Plugin::MakeMaker::Highlander;
# ABSTRACT: There can be only one
# VERSION

use Moose 2;
use List::AllUtils 'first';
use namespace::autoclean;

with 'Dist::Zilla::Role::InstallTool';

sub setup_installer {
    my ($self) = @_;

    my $build_script = first { $_->name eq 'Makefile.PL' } @{ $self->zilla->files }
      or $self->log_fatal('No Makefile.PL found. Using [MakeMaker] is required');

    my $insert = <<'HERE';
if ( $] < 5.012
    && $ENV{PERL_MM_OPT} !~ /(?:INSTALL_BASE|PREFIX)/
    && ! grep { /INSTALL_BASE/ || /PREFIX/ } @ARGV
) {
    $WriteMakefileArgs{UNINST} = 1;
}

HERE

    my $content = $build_script->content;

    $content =~ s/(?=WriteMakefile\s*\()/$insert/
      or $self->log_fatal("Failed to insert UNINST provision into Makefile.PL");

    return $build_script->content($content);
}

__PACKAGE__->meta->make_immutable;

1;

=for Pod::Coverage setup_installer

=head1 SYNOPSIS

    # in dist.ini, *after* other MakeMaker plugins
    [MakeMaker::Highlander]

=head1 DESCRIPTION

The vast majority of distributions B<do not need this> and B<should not use
it>.  It is intended for distributions that are bundled with
L<ExtUtils::MakeMaker> in order to bootstrap it.

This plugin sets the C<UNINST> attribute to 1, to ensure that any other copies
of the module files are removed from C<@INC>.  It only runs on Perls before
v5.12 when C<@INC> was reordered, and only if there appears to be no use of
C<INSTALL_BASE> or C<PREFIX>.

This will result in warnings from old ExtUtils::MakeMaker, but appears to
work nonetheless.

=cut

# vim: ts=4 sts=4 sw=4 et:
