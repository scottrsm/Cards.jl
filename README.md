# Cards.jl
A Julia package to play a version of Poker.

## Quick Start
```julia
using Cards

d = Deck()                 # The standard 52 card deck.
shuffle_deck!(d)           # Shuffle in place (pass `rng=` for reproducibility).
h = deal_hand!(d)          # Draw 5 cards and classify them as a `PokerHand`.
h.class                    # e.g. OnePair, Flush, ... (a `PokerType`).
h2 = make_secondary_draw!(h, d)   # Discard/draw up to 2 cards for a better hand.
num_cards_left_in_deck(d)
restore_deck!(d)           # Put all the cards back.

play_poker!(d)             # Play (and print) a two player game.
```

Hands compare with `<`, `==`, and `max` via `Base.isless` on `PokerHand`.
See the Documenter site (or `docs/src/index.md`) for the full API and
`src/CardTest.ipynb` for a worked example.
