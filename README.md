# Mystic Match

A card game I designed to test how much inference players can gain with limited information; here's how you play:

## The Gist
Collect as many cards as you can and try to reach 26 and try to deduce the opponent's moves so you can keep an edge over them


## Rules
1. First, a random card is dealt to you and the other player 
2. Then, given a card: you have either two options: (1) skip a turn and save your current card
(though you may only skip a maximum of three consecutive times; on the fourth turn of a three-consecutive skip, you must play a matching card)
or (2) select a card with either suit or number that matches your current card (your moves are kept secret)
5. If your card has already been selected before, you must remove your most recently obtained card unless you fulfill the "save condition"
6. The Save Condition can be fulfilled when:
(1) you can guess one of the two most recently obtained cards from the other player's deck (in which you receive a bonus of one extra card)
(2) after 5 rounds, you can guess how many cards the other player has (in which one of their cards must be removed and given to you, but it does not count as a "recent card")
9. You lose if you have no cards left
10. You win if the other player has no cards left or they reach 26 cards

## Features
You are playing against a (mostly) brainless AI here, though future updates to this game will allow for multiplayer and more advanced AI models with developed strategies

