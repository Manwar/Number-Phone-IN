package Number::Phone::IN;

$Number::Phone::IN::VERSION = '0.01';

=head1 NAME

Number::Phone::IN - Indian phone number system.

=head1 VERSION

Version 0.01

=cut

use 5.006;
use Data::Dumper;
use JSON;
use File::Share ':all';

use Number::Phone::IN::Operator;
use Number::Phone::IN::Zone;
use Number::Phone::IN::Chart;
use Number::Phone::IN::STD;

use Moo;
use namespace::clean;

has config     => (is => 'ro', default => sub { return dist_file('Number-Phone-IN', 'config.json') });
has operators  => (is => 'rw');
has zones      => (is => 'rw');
has charts     => (is => 'rw');
has std        => (is => 'rw');
has landline_o => (is => 'rw');

sub BUILD {
    my ($self) = @_;

    $self->_init;
}

=head1 DESCRIPTION

The Department of Telecommunications has divided India into various cellular zones.
At present, there  are  22  telecom circles or service areas. They are classified
into 4 categories: Metro,A,B,C. Delhi, Mumbai, Kolkata fall under Metro category.
All mobile numbers in  India  have the prefix 9, 8 or 7. Each  zone is allowed to
have multiple private operators (earlier it was 2 private+BSNL/MTNL, subsequently
it was  changed to 3 private + BSNL / MTNL in GSM, now each zone has more than 10
operators including  BSNL/MTNL. All mobile  phone numbers are 10 digits long. The
way to split the numbers is defined in the National Numbering Plan 2003 as XXXX-NNNNNN
where XXXX is the Network operator,NNNNNN is the subscriber numbers.

Subscriber Trunk Dialling (STD) codes are assigned to each city/town/village,with
the larger Metro cities having shorter area codes (STD codes), the shortest being
2 digits.

Land line  numbers are at most 8 digits long (usually in major metros). The total
length of all phone numbers (STD code and the phone number) in India  is constant
at 10 digits, for example 7513200000 signifies a STD code  i.e. 751 Gwalior & the
phone number 3200000.

Thus, a number formatted as  020-30303030 means  a fixed-line  Reliance number in
Pune,  while 011-20000198  is an MTNL fixed  line in Delhi and 033-45229320 is an
Airtel number in Kolkata, and 07582-221434 is a BSNL number from Sagar.

No prefix is required to call from one  landline to another in the same STD area.
A prefix of "0+STD code" is required to dial from landline phone in one STD  code
area to another. A prefix of "0+STD code" is required to dial from a mobile phone
in India to any landline number, irrespective of STD area.

Source: L<wikipedia|https://en.wikipedia.org/wiki/Telephone_numbers_in_India>

=head1 METHODS

=head2 parse($phone_number)

=cut

sub parse {
    my ($self, $phone_number) = @_;

    die "ERROR: Invalid phone number [$phone_number].\n"
        unless ($phone_number =~ /^\d{3}\-\d{8}$/);

    my ($std, $number) = split /\-/,$phone_number,2;
}


#
#
# PRIVATE METHODS

sub _init {
    my ($self) = @_;

    my $data = do {
        open (my $fh, "<:encoding(utf-8)", $self->config);
        local $/;
        <$fh>
    };

    my $config = JSON->new->decode($data);
    my ($operators);
    foreach my $operator (@{$config->{'operators'}}) {
        my $operator_id = $operator->{id};
        $operators->{$operator_id} = Number::Phone::IN::Operator->new($operator);
    }

    my ($zones);
    foreach my $zone (@{$config->{'zones'}}) {
        my $zone_id = $zone->{id};
        $zones->{$zone_id} = Number::Phone::IN::Zone->new($zone);
    }

    foreach (@{$config->{'charts'}}) {
        my $chart = {
            operator      => $operators->{$_->{operator}},
            number_series => $_->{number_series},
        };
        foreach my $zone_id (@{$_->{zones}}) {
            push @{$chart->{zones}}, $zones->{$zone_id};
        }

        push @{$self->{charts}}, Number::Phone::IN::Chart->new($chart);
    }

    foreach my $std (@{$config->{'std'}}) {
        my $code = $std->{code};
        $self->{std}->{$code} = Number::Phone::IN::STD->new($std);
    }

    foreach my $op_code (keys %{$config->{'landline'}->{'operator'}}) {
        $self->{landline_o}->{$op_code} = $config->{'landline'}->{'operator'}->{$op_code};
    }
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Number-Phone-IN>

=head1 BUGS

Please report any bugs/feature requests to C<bug-number-phone-in  at rt.cpan.org>
or through the web interface at  L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Number-Phone-IN>.
I will be notified & then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Number::Phone::IN

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Number-Phone-IN>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Number-Phone-IN>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Number-Phone-IN>

=item * Search CPAN

L<http://search.cpan.org/dist/Number-Phone-IN/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 Mohammad S Anwar.

This  program  is  free software; you can redistribute it and/or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Number::Phone::IN
