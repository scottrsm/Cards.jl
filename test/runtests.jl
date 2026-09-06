using Test
using Random
using Cards

@testset "Cards (Fidelity)                               " begin
    @test length(detect_ambiguities(Cards)) == 0
end

@testset "Cards (PokerHand Creation, Comparison, Dealing)" begin
    Random.seed!(1)
    d = Deck()
    shuffle_deck!(d)

    # Manually construct 6 hands...
    h1 = PokerHand([Card(Four, ♥ ), Card(Jack, ♦ ), Card(Six, ♣ ), Card(King, ♦ ), Card(Six, ♠ )])
    h2 = PokerHand([Card(Two, ♠ ), Card(Jack, ♥ ), Card(Ten, ♠ ), Card(Eight, ♦ ), Card(Ten, ♦ )])
    h3 = PokerHand([Card(Ace, ♣ ), Card(King, ♠ ), Card(Queen, ♦ ), Card(Jack, ♥ ), Card(Ten, ♣ )])
    h4 = PokerHand([Card(Ace, ♣ ), Card(King, ♣ ), Card(Queen, ♣ ), Card(Jack, ♣ ), Card(Ten, ♣ )])
    h5 = PokerHand([Card(Ace, ♦ ), Card(King, ♦ ), Card(Queen, ♦ ), Card(Jack, ♦ ), Card(Ten, ♦ )])
    h6 = PokerHand([Card(King, ♦ ), Card(Queen, ♦ ), Card(Jack, ♦ ), Card(Ten, ♦ ), Card(Nine, ♦ )])
    h7 = PokerHand([Card(King, ♦ ), Card(King, ♣ ), Card(Jack, ♦ ), Card(Jack, ♠ ), Card(Nine, ♦ )])
    h8 = PokerHand([Card(King, ♦ ), Card(King, ♣ ), Card(King, ♠ ), Card(Jack, ♠ ), Card(Nine, ♦ )])
    h9 = PokerHand([Card(King, ♦ ), Card(King, ♣ ), Card(King, ♠ ), Card(Jack, ♠ ), Card(Jack, ♦ )])
    
    h10 = PokerHand([Card(Four, ♥ ), Card(Jack, ♦ ), Card(Six, ♣ ), Card(King, ♦ ), Card(Five, ♠ )])
    h11 = PokerHand([Card(Four, ♥ ), Card(Jack, ♦ ), Card(Six, ♣ ), Card(Ace, ♠ ), Card(Five, ♠ )])
    h12 = PokerHand([Card(Four, ♥ ), Card(King, ♦ ), Card(Six, ♣ ), Card(Ace, ♦ ), Card(Five, ♠ )])
    
    h13 = PokerHand([Card(Four, ♥ ), Card(Jack, ♣), Card(Six, ♥), Card(Jack, ♠ ), Card(Six, ♠ )])
    h14 = PokerHand([Card(Four, ♣ ), Card(Jack, ♥), Card(Six, ♣ ), Card(Jack, ♦), Card(Six, ♦)])

    h15 = PokerHand([Card(Four, ♥ ), Card(Jack, ♣), Card(Six, ♥), Card(Jack, ♠ ), Card(Three, ♦ )])
    h16 = PokerHand([Card(Four, ♣ ), Card(Jack, ♥), Card(Six, ♣ ), Card(Jack, ♦), Card(Three, ♣)])

    dh1 = deal_hand!(d)
    restore_deck!(d)
    dh2 = deal_hand!(d)

    @test h1 == h1
    @test h1 != h2
    @test h1 < h2
    @test h2 < h3
    @test h3 < h4
    @test h5 < h4
    @test h6 < h5
    
    @test h7 < h8
    @test h8 < h9
    @test h9 < h6

    @test h10 < h11
    @test h11 < h12
    @test h14 < h13
    @test h16 < h15

    @test dh1 == dh2

    # Classifications.
    @test h1.class == OnePair
    @test h2.class == OnePair
    @test h3.class == Straight
    @test h4.class == StraightFlush
    @test h6.class == StraightFlush
    @test h7.class == TwoPair
    @test h8.class == ThreeOfKind
    @test h9.class == FullHouse
    @test h10.class == HighCard
    @test h13.class == TwoPair
    @test PokerHand([Card(Two, ♠), Card(Two, ♥), Card(Two, ♦), Card(Two, ♣), Card(Nine, ♦)]).class == FourOfKind
    @test PokerHand([Card(Two, ♠), Card(Nine, ♠), Card(Four, ♠), Card(Jack, ♠), Card(Six, ♠)]).class == Flush

    # Ordering across classes: HighCard < OnePair < TwoPair < ThreeOfKind < Straight < Flush < FullHouse < FourOfKind < StraightFlush
    flush = PokerHand([Card(Two, ♠), Card(Nine, ♠), Card(Four, ♠), Card(Jack, ♠), Card(Six, ♠)])
    quads = PokerHand([Card(Two, ♠), Card(Two, ♥), Card(Two, ♦), Card(Two, ♣), Card(Nine, ♦)])
    @test h10 < h1 < h7 < h8 < h3 < flush < h9 < quads < h6

    # Hash is consistent with ==.
    @test hash(h1) == hash(PokerHand(reverse(h1.cards)))
    @test length(Set([h1, PokerHand(reverse(h1.cards))])) == 1
end

@testset "Cards (Ace-low straight)                       " begin
    wheel  = PokerHand([Card(Ace, ♠), Card(Two, ♦), Card(Three, ♣), Card(Four, ♥), Card(Five, ♠)])
    wheelf = PokerHand([Card(Ace, ♠), Card(Two, ♠), Card(Three, ♠), Card(Four, ♠), Card(Five, ♠)])
    six_hi = PokerHand([Card(Two, ♦), Card(Three, ♣), Card(Four, ♥), Card(Five, ♠), Card(Six, ♠)])
    ace_hi = PokerHand([Card(Ace, ♣), Card(King, ♠), Card(Queen, ♦), Card(Jack, ♥), Card(Ten, ♣)])
    ace_hc = PokerHand([Card(Ace, ♣), Card(King, ♠), Card(Queen, ♦), Card(Jack, ♥), Card(Nine, ♣)])
    @test wheel.class  == Straight
    @test wheelf.class == StraightFlush
    # The wheel is the lowest straight, but beats any high card hand.
    @test wheel < six_hi < ace_hi
    @test ace_hc < wheel
    @test wheelf < PokerHand([Card(Two, ♦), Card(Three, ♦), Card(Four, ♦), Card(Five, ♦), Card(Six, ♦)])
    # Not a straight: A K Q J 9, K Q J 10 8, or A 2 3 4 6.
    @test PokerHand([Card(Ace, ♠), Card(Two, ♦), Card(Three, ♣), Card(Four, ♥), Card(Six, ♠)]).class == HighCard
    @test PokerHand([Card(King, ♠), Card(Queen, ♦), Card(Jack, ♣), Card(Ten, ♥), Card(Eight, ♠)]).class == HighCard
end

@testset "Cards (Deck operations)                        " begin
    d = Deck()
    @test num_cards_left_in_deck(d) == 52
    cs = draw_cards!(d, 5)
    @test length(cs) == 5 && num_cards_left_in_deck(d) == 47
    @test draw_cards!(d, 0) == Card[] && num_cards_left_in_deck(d) == 47
    @test_throws DomainError draw_cards!(d, -3)
    @test num_cards_left_in_deck(d) == 47
    @test_throws DomainError draw_cards!(d, 48)
    draw_cards!(d, 47)
    @test num_cards_left_in_deck(d) == 0
    @test_throws DomainError draw_cards!(d, 1)
    @test_throws DomainError deal_hand!(d)
    restore_deck!(d)
    @test num_cards_left_in_deck(d) == 52
    @test deal_hand!(d) isa PokerHand

    # Reproducible shuffles with an explicit RNG; the dealt part of the deck is untouched.
    d1 = Deck(); d2 = Deck()
    draw_cards!(d1, 3); draw_cards!(d2, 3)
    shuffle_deck!(d1; rng=Random.MersenneTwister(7))
    shuffle_deck!(d2; rng=Random.MersenneTwister(7))
    @test d1.cards == d2.cards
    @test d1.cards[1:3] == Deck().cards[1:3]
    @test sort(d1.cards) == sort(Deck().cards)

    # Manually built decks.
    small = Deck(0, [Card(Ace, ♠), Card(King, ♠), Card(Queen, ♠)])
    @test num_cards_left_in_deck(small) == 3
    @test draw_cards!(small, 2) == [Card(Ace, ♠), Card(King, ♠)]
    @test num_cards_left_in_deck(small) == 1
    @test_throws DomainError Deck(-1, [Card(Ace, ♠)])
    @test_throws DomainError Deck(2, [Card(Ace, ♠)])
    @test_throws DomainError Deck(0, [Card(Ace, ♠), Card(Ace, ♠)])

    # Hand contract.
    @test poker_hand_contract([Card(Ace, ♠), Card(King, ♠), Card(Queen, ♠), Card(Jack, ♠), Card(Ten, ♠)])
    @test !poker_hand_contract([Card(Ace, ♠), Card(King, ♠), Card(Queen, ♠), Card(Jack, ♠)])
    @test !poker_hand_contract([Card(Ace, ♠), Card(Ace, ♠), Card(Queen, ♠), Card(Jack, ♠), Card(Ten, ♠)])
    @test poker_hand_contract([Card(Ace, ♠), Card(King, ♠)]; N=2)
    @test_throws DomainError PokerHand([Card(Ace, ♠), Card(King, ♠)])
    @test_throws DomainError PokerHand([Card(Ace, ♠), Card(Ace, ♠), Card(Queen, ♠), Card(Jack, ♠), Card(Ten, ♠)])

    # grouped_rank_rep works on unsorted input.
    @test grouped_rank_rep([Card(King, ♦), Card(Nine, ♠), Card(King, ♣)]) == [(2, King), (1, Nine)]
    @test grouped_rank_rep(Card[]) == Tuple{Int, Rank}[]
end

# A deck (in standard order) from which the given cards have already been removed.
deck_without(cards) = Deck(0, filter(c -> !(c in cards), Deck().cards))

@testset "Cards (Secondary draw)                         " begin
    # Made hands are kept as they are: no cards are drawn.
    for cards in ([Card(Ace, ♣), Card(King, ♣), Card(Queen, ♣), Card(Jack, ♣), Card(Ten, ♣)],   # royal flush
                  [Card(Nine, ♦), Card(Eight, ♣), Card(Seven, ♠), Card(Six, ♥), Card(Five, ♦)], # straight
                  [Card(Two, ♠), Card(Nine, ♠), Card(Four, ♠), Card(Jack, ♠), Card(Six, ♠)],    # flush
                  [Card(Ace, ♠), Card(Two, ♠), Card(Three, ♠), Card(Four, ♠), Card(Five, ♠)])   # wheel straight flush
        d = deck_without(cards)
        h = PokerHand(cards)
        nh = make_secondary_draw!(h, d)
        @test nh == h
        @test num_cards_left_in_deck(d) == 47
    end

    # A high card hand draws two, keeping its three highest cards.
    h = PokerHand([Card(Ace, ♣), Card(King, ♠), Card(Queen, ♦), Card(Jack, ♥), Card(Nine, ♣)])
    d = deck_without(h.cards)
    nh = make_secondary_draw!(h, d)
    @test num_cards_left_in_deck(d) == 45
    @test all(c in nh.cards for c in (Card(Ace, ♣), Card(King, ♠), Card(Queen, ♦)))

    # One pair draws two, keeping the pair and the highest kicker.
    h = PokerHand([Card(Four, ♥), Card(Jack, ♦), Card(Six, ♣), Card(King, ♦), Card(Six, ♠)])
    d = deck_without(h.cards)
    nh = make_secondary_draw!(h, d)
    @test num_cards_left_in_deck(d) == 45
    @test all(c in nh.cards for c in (Card(Six, ♣), Card(Six, ♠), Card(King, ♦)))

    # A game runs to completion and prints.
    d = Deck()
    out = mktemp() do path, io
        redirect_stdout(io) do
            play_poker!(d; rng=Random.MersenneTwister(3))
        end
        flush(io)
        read(path, String)
    end
    @test occursin("wins!", out) || occursin("tie!", out)
    @test num_cards_left_in_deck(d) <= 42
end
