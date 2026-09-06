"""
    Module Cards:
    Functions to define cards, a card deck, shuffle the deck, deal from 
    the deck, poker card comparison, and poker hand representations.
    Can reset the deck, so that all cards dealt in a previous game are available again.
    Additionally, can play a round of vanilla poker with two players.
"""

module Cards

# -------- FOR EXPORT -------------
# Enums.
export Suit, Rank, PokerType 
export ♣, ♠, ♦, ♥
export Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten, Jack, Queen, King, Ace
export HighCard, OnePair, TwoPair, ThreeOfKind, FullHouse, FourOfKind, Flush, Straight, StraightFlush

# Structs.
export Card, PokerHand, Deck

# Deck Manipulation.
export shuffle_deck!, restore_deck!, num_cards_left_in_deck

# Drawing Cards from Deck.
export draw_cards!, deal_hand!, make_secondary_draw! 

# Play Poker.
export play_poker!

# Lower level functions
export classify_hand, grouped_rank_rep, poker_hand_contract

# Imports.
import Random


#---------------------------------------------------------------------------
# ---------------------  CONSTS, ENUMS  ------------------------------------
#---------------------------------------------------------------------------
const NO_CARDS_IN_DECK=52

# Enums for poker card ranking, `Rank`, `Suits`, `PokerType`.

"""
    Rank (Enum)

Card ranks in poker; ordered by strength from lowest to highest.

# Fields
- `Two` `Three` `Four` `Five` `Six` `Seven` `Eight` `Nine` `Ten`
- `Jack`
- `Queen`
- `King`
- `Ace`
"""
@enum Rank Two Three Four Five Six Seven Eight Nine Ten Jack Queen King Ace


"""
    Suit (Enum)

Allowable suits in poker; ordered by strength from lowest to highest.

# Fields
- ♠
- ♦  
- ♣  
- ♥ 
"""
@enum Suit  ♠ ♦ ♣ ♥



"""
    PokerType (Enum)

Enumeration describing a classification of hands for poker; ordered by strength
from lowest to highest.

# Fields
- HighCard
- OnePair
- TwoPair
- ThreeOfKind
- Straight
- Flush
- FullHouse
- FourOfKind
- StraightFlush
"""
@enum PokerType HighCard OnePair TwoPair ThreeOfKind Straight Flush FullHouse FourOfKind StraightFlush


#---------------------------------------------------------------------------
# ---------------------  STRUCTS   -----------------------------------------
#---------------------------------------------------------------------------
"""
    Card

DATA STRUCTURE: Representation of a Card.

# Fields 
- rank :: Rank
- suit :: Suit

# Constructors
- Card(::Rank, ::Suit)
"""
struct Card
    rank::Rank
    suit::Suit
end


"""
    PokerHand

DATA STRUCTURE: Representation of a (5 card) poker hand.
    
This inner constructor takes a vector of cards:
- Checks the input contract:
    - Checks that the number of cards is correct;
    - Checks that there are no duplicates.
- Sorts the cards (`isless` is defined for `Card`).
- Creates an internal representation grouping cards by `Rank`.
- Classifies the hand into one of the poker types: `PokerType`.
  These are the familiar names of poker hands: `TwoPair`, `FullHouse`, etc.

# Fields 
- `cards  :: Vector{Card}`
- `gr_rep :: Vector{Tuple{Int, Rank}}`
- `class  :: PokerType`

# Constructor
- `PokerHand(::Vector{Card})` -- exactly 5 distinct cards.
"""
struct PokerHand
    cards  :: Vector{Card}
    gr_rep :: Vector{Tuple{Int, Rank}}
    class  :: PokerType 

    # Constructor
    function PokerHand(cds::Vector{Card})
        scds   = poker_hand_contract(cds) ? sort(cds, rev=true) : throw(DomainError(cds, "Not a valid poker hand.\nEither duplicate cards or not the right number (5).\n"))
        gr_rep = grouped_rank_rep(scds)
        class  = classify_hand(gr_rep, scds)
        return(new(scds, gr_rep, class))
    end
end


"""
    Deck

MUTABLE DATA STRUCTURE: Representation of a deck of cards.

# Fields 
- place :: Int          -- The place in the deck beyond which we may draw.
- cds   :: Vector{Card} -- A vector of cards.

# Constructors
- Deck() -- Creates the standard 52 card deck using the standard Card ordering.
- Deck(place::Int, cards::Vector{Card}) -- Create a deck of cards manually; `0 <= place <= length(cards)`.
"""
mutable struct Deck
    place::Int
    cards::Vector{Card}

    # Constructors
    Deck() = new(0, [Card(r, s) for s in instances(Suit) for r in instances(Rank)])
    function Deck(p::Int, cds::Vector{Card}) 
        if length(cds) != length(Set(cds))
            throw(DomainError(cds, "There are duplicate cards in this prospective deck!"))
        end
        if !(0 <= p <= length(cds))
            throw(DomainError(p, "The deck place must be in the range [0, $(length(cds))]."))
        end
        new(p, cds)
    end
end



#=---------------------------------------------------------------------------
---------------------  AUGMENT BASE: isless, show   ----------------------
---------------------------------------------------------------------------
=#

# Define `isless` for `Card`. 
Base.isless(c1::Card, c2::Card) = c1.rank < c2.rank ? true : (c1.rank == c2.rank) ? (c1.suit < c2.suit) : false


function get_single_cards(ph::PokerHand)
    cds = ph.cards
    rep = ph.gr_rep
    single_rnks = [r for (n, r) in rep if n == 1]
    singles = Card[]
    for c in cds
       if c.rank in single_rnks
           push!(singles, c)
       end
    end

    return(singles)
end

# Is this (sorted, high to low) rank sequence the Ace-low straight ("wheel"): A 5 4 3 2?
is_wheel(gr_rep::Vector{Tuple{Int, Rank}}) = length(gr_rep) == 5 && gr_rep[1][2] == Ace && gr_rep[2][2] == Five

# The high card of a straight: `Five` for the wheel, otherwise the top rank.
straight_high(ph::PokerHand) = is_wheel(ph.gr_rep) ? Five : ph.gr_rep[1][2]

# Define `isless` for `PokerHand` 
function Base.isless(p1::PokerHand, p2::PokerHand)  
    if p1.class != p2.class
        return(p1.class < p2.class)
    end

    # Same class: compare the grouped ranks; a straight is ranked by its high card
    # (the Ace-low straight is the lowest straight).
    if p1.class == Straight || p1.class == StraightFlush
        h1 = straight_high(p1)
        h2 = straight_high(p2)
        h1 != h2 && return(h1 < h2)
    elseif p1.gr_rep != p2.gr_rep
        return(p1.gr_rep < p2.gr_rep)
    end

    #= This means that even the single cards have the same rank.
       We now decide who is higher by suit 
       (actually done by comparing Cards as Suit is a secondary comparator.)
	=#
    return(get_single_cards(p1) < get_single_cards(p2))
end

# Show methods for `Card` and `PokerHand`.
Base.show(io::IO, c::Card)       = print(io, "$(c.suit) $(c.rank)")
Base.show(io::IO, ph::PokerHand) = print(io, "Cards = $(ph.cards)\nGrouped_Rank_Rep = $(ph.gr_rep)\nClassification = $(ph.class)")

# Define `(==)` and a matching `hash` for PokerHand
Base.:(==)(ph1::PokerHand, ph2::PokerHand) = (ph1.cards == ph2.cards) && (ph1.gr_rep == ph2.gr_rep) && (ph1.class == ph2.class)
Base.hash(ph::PokerHand, h::UInt) = hash(ph.cards, hash(ph.gr_rep, hash(ph.class, hash(:PokerHand, h))))


#=------------------------------------------------------------------------
---------------------  FUNCTIONS   ---------------------------------------
--------------------------------------------------------------------------
=#
"""
    poker_hand_contract(cds; N=5)

Checks that a poker hand is valid.

Checks the following are true for `cds`:
- They are unique.
- Their number is `N`. 

# Arguments
- `cds :: Vector{Card}` -- A vector of cards.

# Optional Arguments
- `N=5 :: Int` -- The number of cards that the hand should have.

# Return
`::Bool` -- `true` if `cds` are valid.
"""
function poker_hand_contract(cds :: Vector{Card}; N::Int=5)
    n = length(Set(cds))
    n != length(cds) && return(false)
    n != N           && return(false)
    return(true)
end


"""
    shuffle_deck!(d[; rng=Random.default_rng()])

Shuffles the Deck, `d`, destructively; that is, the deck is changed as 
a result of this function.

This function only shuffles "what's left" of the deck. It will not
interfere with the function `restore_deck!`, in the sense
that all of the cards will put back, but the "restore" does
not interfere with current and previous `shuffle_deck!`.

# Arguments
- `d :: Deck` -- The deck to shuffle.

# Keyword Arguments
- `rng :: Random.AbstractRNG` -- The random number generator to use (default: the global one).

# Return
`nothing`
"""
function shuffle_deck!(d::Deck; rng::Random.AbstractRNG=Random.default_rng()) :: Nothing
    Random.shuffle!(rng, @view d.cards[(1+d.place):end])
    return(nothing)
end



"""
    deal_hand!(d)

Deals a (5 card) hand from a deck, `d`, creating a PokerHand.

In the process, removes 5 cards from the deck, `d`.

# Arguments
- `d :: Deck` -- A Deck from which to deal.

# Return
`::PokerHand` -- A poker hand
"""
function deal_hand!(d::Deck) :: PokerHand
    return(PokerHand(draw_cards!(d, 5)))
end


"""
    draw_cards!(d, N)

Draws `N` cards from a deck, `d`.
In the process, removes `N` cards from the deck, `d`.

# Arguments
- `d :: Deck`  -- A Deck from which to draw.
- `N :: Int` -- The number of cards to draw (`N >= 0`).

# Return
`::Vector{Card}` -- A vector of Cards.
"""
function draw_cards!(d::Deck, N::Int) :: Vector{Card}
    if N < 0
        throw(DomainError(N, "The number of cards to draw must be non-negative."))
    end
    if (d.place + N) > length(d.cards)
        throw(DomainError(N, "Deck does not have enough cards left to draw $N cards (only $(num_cards_left_in_deck(d)) left)."))
    end
    cds = [d.cards[d.place + i] for i in 1:N]  
    d.place += N
    return(cds)
end


"""
    restore_deck!(d)

Reset the Deck, `d`, to have all of the cards placed back into the deck.

# Assumptions
- The deck `d` has not been directly manipulated; that is,
  only the functions in this module should be used to manipulate
  a Deck.

# Note
- The cards that have been previously dealt will be replaced; however,
previous calls to shuffle_deck! will remain in effect.

# Arguments
- `d :: Deck` -- The Deck to operate on.

# Return
`::Nothing`
"""
function restore_deck!(d::Deck) :: Nothing
    d.place = 0
    return(nothing)
end


"""
    num_cards_left_in_deck(d)

Computes the number of cards left in deck, `d`.

# Arguments
- `d :: Deck` -- The deck to query.

# Return
The number of cards left in the deck.
"""
num_cards_left_in_deck(d::Deck) :: Int = length(d.cards) - d.place



"""
    grouped_rank_rep(cds)

Creates a representation of a Poker hand.

The representation is a vector of two-tuples of the form:
`(N, Card-Rank)` -- Here, `N` is the number of times a card with Card-Rank appears in the hand.
The tuple representation is ordered from highest to lowest.

**NOTE:** When `N==1` the corresponding rank *uniquely* determines the card in the hand.

# Note
- The cards are sorted (high to low, via `Base.isless(Card, Card)`) before grouping,
  so the input may be in any order.

# Arguments
- `cds :: Vector{Card}` -- A Vector of Card.

# Examples: The poker hand `(♣ King, ♦ Jack, ♥ Nine, ♠ Nine, ♣ Three)`
becomes: `[(2, Nine), (1, King), (1, Jack), (1, Three)]`

# Return
`::Vector{Tuple{Int, Rank}}` -- A Vector of two-tuples. 
"""
function grouped_rank_rep(cds::Vector{Card}) :: Vector{Tuple{Int, Rank}}
    gr_rep = Tuple{Int, Rank}[]
    isempty(cds) && return(gr_rep)

    scds     = issorted(cds, rev=true) ? cds : sort(cds, rev=true)
    lastRank = scds[1].rank
    sameCnt  = 0
    for c in scds
        if c.rank == lastRank
            sameCnt += 1
        else 
            push!(gr_rep, (sameCnt, lastRank))
            sameCnt  = 1
            lastRank = c.rank
        end
    end
    push!(gr_rep, (sameCnt, lastRank))

    return(sort(gr_rep, rev=true))
end


"""
    classify_hand(gr_rep, cds)

Classifies a poker hand into one of the standard classes given by the enumeration: `PokerType`.
The Ace-low straight (A 5 4 3 2, the "wheel") is recognised as a `Straight` (or `StraightFlush`).

This is done by first examining the length of the grouped rank representation, `gr_rep`.

We know the following:
- `|gr_rep| == 2` ``\\implies`` `FourOfKind  | FullHouse`
- `|gr_rep| == 3` ``\\implies`` `ThreeOfKind | TwoPair`
- `|gr_rep| == 4` ``\\implies`` `OnePair`
- `|gr_rep| == 5` ``\\implies`` `HighCard     | Flush  | Straight | StraightFlush` 

# Arguments
- `gr_rep :: Vector{Tuple{Int, Rank}}`  -- The internal representation of the hand. (See `grouped_rank_rep`).
- `cds    :: Vector{Card}`                -- Cards sorted by rank then suit.

# Returns
`::PokerType`
"""
function classify_hand(gr_rep::Vector{Tuple{Int, Rank}}, cds::Vector{Card}) :: PokerType
    # FourOfKind | FullHouse
    if length(gr_rep) == 2
        if gr_rep[1][1] == 4
            return(FourOfKind)
        else
            return(FullHouse )
        end

    # TwoPair | ThreeOfKind
    elseif length(gr_rep) == 3
        if gr_rep[1][1] == 3
            return(ThreeOfKind)
        else
            return(TwoPair    )
        end

    # OnePair
    elseif length(gr_rep) == 4
        return(OnePair)

    # HighCard | Flush | Straight | StraightFlush
    elseif length(gr_rep) == 5
        isFlush    = false
        isStraight = false

        # Test for Flush -- should only have 1 suit.
        if length(Set([cd.suit for cd in cds])) == 1
            isFlush = true
        end

        # Test for Straight (cds cards are ordered from high to low, with 5 distinct ranks)
        # Therefore, each rank should be one less than the previous one; or, the hand is the
        # Ace-low straight: A 5 4 3 2.
        ranks = [Int(cd.rank) for cd in cds]
        if all(ranks[i] - ranks[i+1] == 1 for i in 1:4) || ranks == [Int(Ace), Int(Five), Int(Four), Int(Three), Int(Two)]
            isStraight = true
        end

        # Continue to classify...
        if isFlush && isStraight
            return(StraightFlush)
        elseif isFlush
            return(Flush        )
        elseif isStraight
            return(Straight     )
        else
            return(HighCard      )
        end
    else
        throw(DomainError(gr_rep, "Unexpected grouped rank representation length: $(length(gr_rep))"))
    end

end


"""
    make_secondary_draw!(h, d)

This function examines a poker hand, `h`, and decides
(given that we can draw up to two cards from the deck)
what cards (if any) to eliminate and then draw from the deck, `d`.

Although one may stick with the current hand, and consequently, 
not draw from the deck, we mark this function as mutable as 
it has the potential to mutate the deck, `d`. 

# Arguments
- `h :: PokerHand` -- The current poker hand to examine.
- `d :: Deck`      -- The deck to work with.

# Return
`::PokerHand` -- A new poker hand. Potentially a copy of the original hand.
"""
function make_secondary_draw!(h::PokerHand, d::Deck) :: PokerHand
    # Will be new cards for hand after the potential draw. 
    nh = Card[]

    #= This will be the list of cards to eliminate.
       The cards will be represented by their rank as this
       uniquely defines (as the doc for grouped_rank_rep makes clear)
       cards that are not grouped. As these are the cards
       that we will look to for elimination the rank representation
       is a good one.
	=#
    eliminate_cards_by_rank = Rank[]

    # FourOfKind
    if (length(h.gr_rep) == 2) && (h.gr_rep[1][1] == 4)
        if h.gr_rep[2][2] < Seven
            # Eliminate 1 card.
            push!(eliminate_cards_by_rank, h.gr_rep[2][2]) 
        end

    # TwoPair | ThreeOfKind
    elseif length(h.gr_rep) == 3
        if h.gr_rep[1][1] == 3 
            # Eliminate 2 cards. ThreeOfKind
            push!(eliminate_cards_by_rank, h.gr_rep[2][2]) 
            push!(eliminate_cards_by_rank, h.gr_rep[3][2]) 
        else
            # Eliminate 1 card. TwoPair.
            push!(eliminate_cards_by_rank, h.gr_rep[3][2]) 
        end

    # OnePair
    elseif length(h.gr_rep) == 4
        # Eliminate 2 cards. OnePair.
        push!(eliminate_cards_by_rank, h.gr_rep[3][2]) 
        push!(eliminate_cards_by_rank, h.gr_rep[4][2]) 

    # HighCard -- (a Straight, Flush, or StraightFlush also has 5 distinct ranks; keep those as they are.)
    elseif h.class == HighCard
        # Eliminate 2 cards (the two lowest).
        push!(eliminate_cards_by_rank, h.gr_rep[4][2]) 
        push!(eliminate_cards_by_rank, h.gr_rep[5][2]) 
    end

    # Now gather all cards in the current hand that are NOT in the elimination set.
    # Push them onto the new list of cards.
    for c in h.cards
        if !(c.rank in eliminate_cards_by_rank)
            push!(nh, c)
         end
    end

    # Augment this new list of cards with draws from the deck.
    append!(nh, draw_cards!(d, length(eliminate_cards_by_rank)))

    # Return the new poker hand.
    return(PokerHand(nh))
end


"""
    play_poker!(d[; rng=Random.default_rng()])

Play a game of poker with two players.

Process:
- Deal each player two 5 card hands.
- Compare two hands to see who would win.
- Each player can then ask for up to 2 cards.
- The two players are compared again to see who wins.

**Note:** This function mutates the deck by dealing cards 
          to the players.

# Arguments
`d :: Deck` -- A deck of cards.

# Keyword Arguments
- `rng :: Random.AbstractRNG` -- The random number generator used to shuffle (default: the global one).

# Return
`::Nothing`
"""
function play_poker!(d::Deck; rng::Random.AbstractRNG=Random.default_rng()) :: Nothing
    # Reset the deck -- put back all the cards from previous games.
    restore_deck!(d)

    # Shuffle the deck.
    shuffle_deck!(d; rng)

    # Deal poker hands for two players.
    h1 = deal_hand!(d)
    h2 = deal_hand!(d)
    println("hand 1 = $h1")
    println("hand 2 = $h2")

    println("")

    # Compare the hands.
    println("BEFORE Players are given a chance at card replacement:")
    if h1 < h2
        println("Player 2 wins!")
    elseif h2 < h1
        println("Player 1 wins!")
    else
        println("It's a tie!")
    end

    # Allow each player a chance at replacing up to two cards.
    nh1 = make_secondary_draw!(h1, d) 
    nh2 = make_secondary_draw!(h2, d) 

    println("\nAFTER Players are given a chance at card replacement:")
    println("Updated hand 1 = $nh1")
    println("Updated hand 2 = $nh2")

    println("")
    # Now compare the new hands.
    if nh1 < nh2
        println("Player 2 wins!")
    elseif nh2 < nh1
        println("Player 1 wins!")
    else
        println("It's a tie!")
    end
    
    return(nothing)
end

end # module Cards


