use v6;
use Algorithm::AhoCorasick::Node;
unit class Algorithm::AhoCorasick:ver<0.0.9>;

has Algorithm::AhoCorasick::Node $!root;
has @.keywords is required;

method !build-automata() {
    $!root .= new;
    for @!keywords -> $keyword {
        my $current-node = $!root;
        for ^$keyword.chars -> $i {
            my $edge-character = $keyword.substr($i,1);
            if not $current-node.transitions{$edge-character}:exists {
                $current-node.transitions{$edge-character} .= new;
            }
            $current-node = $current-node.transitions{$edge-character};
        }
        $current-node.matched-string = set($keyword);
    }
    my @queue;
    @queue.push: $!root;
    while @queue.elems > 0 {
        my $current-node = @queue.shift;
        for $current-node.transitions.keys -> $edge-character {
            my $next-node = $current-node.transitions{$edge-character};
            @queue.push($next-node);

            my $r = $current-node.failure;
            while $r.defined && not $r.transitions{$edge-character}:exists {
                $r = $r.failure;
            }

            if not $r.defined {
                $next-node.failure = $!root;
            }
            else {
                $next-node.failure = $r.transitions{$edge-character};
                $next-node.matched-string = $next-node.matched-string (|) $next-node.failure.matched-string;
            }
        }
    }
    $!root.failure = $!root;
}

method match($text) {
    my $all = self.locate($text);
    my Set $matched = set();
    for $all.keys -> $keyword {
        $matched = $matched (|) $keyword;
    }
    return $matched;
}

method locate($text) {
    my $matched;
    my $trans = $!root;
    for ^$text.chars -> $i {
        my $edge-character = $text.substr($i,1);
        until ($trans.defined and $trans.transitions{$edge-character}:exists) or ($trans === $!root) {
            $trans = $trans.failure;
        }

        $trans = do if $trans.transitions{$edge-character}:exists {
            $trans.transitions{$edge-character};
        } else {
            $!root;
        }
        for $trans.matched-string.keys -> $string {
            $matched{$string}.push($i - $string.chars + 1);
        }
    }
    return $matched;
}

submethod BUILD (:@keywords) {
    @!keywords := @keywords;
    self!build-automata();
}

=begin pod

=head1 NAME

Algorithm::AhoCorasick - efficient search for multiple strings

=head1 SYNOPSIS

       use Algorithm::AhoCorasick;
       my Algorithm::AhoCorasick $aho-corasick .= new(keywords => ['corasick','sick','algorithm','happy']);
       my $matched = $aho-corasick.match('aho-corasick was invented in 1975'); # set("corasick","sick")
       my $located = $aho-corasick.locate('aho-corasick was invented in 1975'); # {"corasick" => [4], "sick" => [8]}

=head1 DESCRIPTION

Algorithm::AhoCorasick is a implmentation of the Aho-Corasick algorithm (1975).
It constructs a finite state machine from a list of keywords in the offline process.
After the above preparation, it locate elements of a finite set of strings within an input text in the online process.

=head2 CONSTRUCTOR

=head3 new

      my Algorithm::AhoCorasick $aho-corasick .= new(keywords => @keyword-list);

Constructs a new finite state machine from a list of keywords.

=head2 METHODS

=head3 match

      my $matched = $aho-corasick.match($text);

Returns elements of a finite set of strings within an input text.

=head3 locate

      my $located = $aho-corasick.locate($text);

Returns elements of a finite set of strings with location within an input text.

=head1 AUTHOR

titsuki <titsuki@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2016 titsuki

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

The algorithm is from Alfred V. Aho and Margaret J. Corasick, Efficient string matching: an aid to bibliographic search, CACM, 18(6):333-340, June 1975.

=end pod
