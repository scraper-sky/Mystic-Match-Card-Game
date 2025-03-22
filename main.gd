extends Node2D

var card_scene = preload("res://card.tscn")
var deck = []
var player_hand = []
var ai_hand = []
var player_current_card = null
var ai_current_card = null
var player_skip_count = 0
var is_player_turn = true
var selection_cards = []
var ai_recent_cards = []
var round_count = 0
var save_guess_active = false
var guess_buttons = []
var is_processing_turn = false
var guess_input = null

func _ready():
	create_deck()
	shuffle_deck()
	deal_initial_cards()

func create_deck():
	var suits = ["Spades", "Hearts", "Clubs", "Diamonds"]
	var numbers = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
	for suit in suits:
		for number in numbers:
			deck.append({"suit": suit, "number": number})

func shuffle_deck():
	deck.shuffle()

func deal_initial_cards():
	player_current_card = create_card(deck.pop_front())
	add_child(player_current_card)
	player_current_card.position = Vector2(100, 500)
	ai_current_card = create_card(deck.pop_front())
	add_child(ai_current_card)
	ai_current_card.position = Vector2(100, 100)
	show_selection_cards()

func create_card(card_data):
	var card = card_scene.instantiate()
	card.suit = card_data["suit"]
	card.number = card_data["number"]
	var error = card.connect("card_selected", Callable(self, "_on_card_selected"))
	if error == OK:
		print("Signal connected for: ", card_data["number"], " of ", card_data["suit"])
	else:
		print("Signal connection failed: ", error)
	return card

func _on_card_selected(card):
	print("Received card_selected: ", card.number, " of ", card.suit)
	if is_player_turn and not is_processing_turn and card in selection_cards and not save_guess_active:
		is_processing_turn = true
		var card_key = card.number + " of " + card.suit
		
		# Check if card is in player’s hand first
		var in_player_hand = false
		for hand_card in player_hand:
			if hand_card.number + " of " + hand_card.suit == card_key:
				in_player_hand = true
				break
		if in_player_hand:
			print("Invalid! Card already in your hand: ", card_key)
			is_processing_turn = false
			return
		
		# Now check AI hand and validity
		if player_skip_count == 3:
			if is_valid_move(card_key):
				play_card(card, card_key)
			else:
				print("Invalid! Must match and not be in AI’s hand unless saved.")
		else:
			if is_valid_move(card_key):
				play_card(card, card_key)
			else:
				handle_save_condition(card, card_key)
		is_processing_turn = false

func is_valid_move(card_key):
	var in_ai_hand = false
	for hand_card in ai_hand:
		if hand_card.number + " of " + hand_card.suit == card_key:
			in_ai_hand = true
			break
	if in_ai_hand and not save_guess_active:
		return false
	return true

func handle_save_condition(card, card_key):
	save_guess_active = true
	get_node("/root").set_meta("pending_card", card)
	get_node("/root").set_meta("pending_card_key", card_key)
	if round_count >= 5:
		print("Guess AI hand size (0-25):")
		show_number_guess_input()
	elif ai_recent_cards.size() > 0:
		print("Guess one of AI’s recent cards:")
		show_recent_card_guess_ui()

func play_card(card, card_key):
	if card == null or card_key == null:
		print("Error: Attempted to play null card!")
		return
	print("Match! Played: ", card_key)
	if player_current_card and player_current_card.get_parent() == self:
		remove_child(player_current_card)
	player_current_card = card
	if card.get_parent() != self:
		add_child(card)
	player_current_card.position = Vector2(100, 500)
	player_hand.append(card)
	update_hand_display("player")
	player_skip_count = 0
	clear_selection_cards()
	save_guess_active = false
	end_turn()

func can_save():
	return save_guess_active

func show_number_guess_input():
	if guess_input and guess_input.is_inside_tree():
		guess_input.queue_free()
	guess_input = LineEdit.new()
	guess_input.position = Vector2(200, 600)
	guess_input.placeholder_text = "Enter 0-25"
	guess_input.connect("text_submitted", Callable(self, "_on_guess_number_input"))
	add_child(guess_input)
	guess_input.grab_focus()

func show_recent_card_guess_ui():
	clear_guess_buttons()
	var options = ai_recent_cards.duplicate()
	var used_cards = []
	for hand_card in player_hand:
		used_cards.append(hand_card.number + " of " + hand_card.suit)
	for hand_card in ai_hand:
		used_cards.append(hand_card.number + " of " + hand_card.suit)
	for recent_card in ai_recent_cards:
		used_cards.append(recent_card)
	while options.size() < 4 and deck.size() > 0:
		var card_data = deck[randi() % deck.size()]
		var card_key = card_data["number"] + " of " + card_data["suit"]
		if card_key not in used_cards and card_key not in options:
			options.append(card_key)
	options.shuffle()
	for i in options.size():
		var card_key = options[i]
		var btn = Button.new()
		btn.text = card_key
		btn.position = Vector2(200 + i * 200, 600)
		btn.connect("pressed", Callable(self, "_on_guess_recent_card").bind(card_key))
		add_child(btn)
		guess_buttons.append(btn)

func clear_guess_buttons():
	for btn in guess_buttons:
		if btn.is_inside_tree():
			btn.queue_free()
	guess_buttons.clear()
	if guess_input and guess_input.is_inside_tree():
		guess_input.queue_free()
		guess_input = null

func _on_guess_number_input(text):
	if not get_node("/root").has_meta("pending_card"):
		print("Error: No pending card for guess!")
		save_guess_active = false
		clear_guess_buttons()
		end_turn()
		return
	var guess = text.to_int()
	var card = get_node("/root").get_meta("pending_card")
	var card_key = get_node("/root").get_meta("pending_card_key")
	if guess >= 0 and guess <= 25 and guess == ai_hand.size():
		print("Correct hand size guess! Stealing a card.")
		if ai_hand.size() > 0:
			var stolen = ai_hand.pop_back()
			player_hand.append(stolen)
			update_hand_display("player")
			update_hand_display("ai")
		play_card(card, card_key)
	else:
		print("Wrong guess! Removing last card.")
		if player_hand.size() > 0:
			var lost_card = player_hand.pop_back()
			if lost_card.get_parent() == self:
				remove_child(lost_card)
			update_hand_display("player")
		save_guess_active = false
		clear_guess_buttons()
		end_turn()
	get_node("/root").remove_meta("pending_card")
	get_node("/root").remove_meta("pending_card_key")

func _on_guess_recent_card(guess):
	if not get_node("/root").has_meta("pending_card"):
		print("Error: No pending card for guess!")
		save_guess_active = false
		clear_guess_buttons()
		end_turn()
		return
	var card = get_node("/root").get_meta("pending_card")
	var card_key = get_node("/root").get_meta("pending_card_key")
	if guess in ai_recent_cards:
		print("Correct recent card guess! Bonus card added.")
		var bonus_card_data = deck.pop_front() if deck.size() > 0 else {"suit": "Hearts", "number": "2"}
		var bonus_card = create_card(bonus_card_data)
		player_hand.append(bonus_card)
		update_hand_display("player")
		play_card(card, card_key)
	else:
		print("Wrong guess! Removing last card.")
		if player_hand.size() > 0:
			var lost_card = player_hand.pop_back()
			if lost_card.get_parent() == self:
				remove_child(lost_card)
			update_hand_display("player")
		save_guess_active = false
		clear_guess_buttons()
		end_turn()
	get_node("/root").remove_meta("pending_card")
	get_node("/root").remove_meta("pending_card_key")

func _on_skip_button_pressed() -> void:
	if is_player_turn and not is_processing_turn and player_skip_count < 3:
		is_processing_turn = true
		player_skip_count += 1
		print("Skipped! Skip count: ", player_skip_count)
		end_turn()
		is_processing_turn = false
	elif player_skip_count >= 3:
		print("Max skips reached! You must play a matching card.")

func end_turn():
	is_player_turn = false
	ai_turn()
	is_player_turn = true
	if player_skip_count == 3:
		print("Must play a matching card this turn!")
	if not save_guess_active:
		show_selection_cards()
	print("Player hand size: ", player_hand.size(), " | AI hand size: ", ai_hand.size())
	if player_hand.size() == 0:
		print("You lose! Your hand is empty.")
		get_tree().quit()
	elif ai_hand.size() == 0:
		print("You win! AI hand is empty.")
		get_tree().quit()
	elif player_hand.size() >= 26:
		print("You win! Collected 26 cards.")
		get_tree().quit()
	elif ai_hand.size() >= 26:
		print("You lose! AI collected 26 cards.")
		get_tree().quit()

func ai_turn():
	if randf() < 0.2:
		print("AI Skipped!")
		round_count += 1
		return
	var options = get_matching_options(ai_current_card)
	var option = options[randi() % options.size()]
	var card_key = option["number"] + " of " + option["suit"]
	var card = create_card(option)
	
	var in_player_hand = false
	for hand_card in player_hand:
		if hand_card.number + " of " + hand_card.suit == card_key:
			in_player_hand = true
			break
	if in_player_hand:
		print("AI Mismatch! Played: ", card_key, " - Removing last card.")
		if ai_hand.size() > 0:
			var lost_card = ai_hand.pop_back()
			if lost_card.get_parent() == self:
				remove_child(lost_card)
			update_hand_display("ai")
		round_count += 1
		return
	
	var in_ai_hand = false
	for hand_card in ai_hand:
		if hand_card.number + " of " + hand_card.suit == card_key:
			in_ai_hand = true
			break
	if in_ai_hand:
		if randf() < 0.5:
			print("AI Duplicate Saved! Played: ", card_key)
		else:
			print("AI Duplicate Failed! Played: ", card_key, " - Removing last card.")
			if ai_hand.size() > 0:
				var lost_card = ai_hand.pop_back()
				if lost_card.get_parent() == self:
					remove_child(lost_card)
				update_hand_display("ai")
		round_count += 1
		return
	
	print("AI Match! Played: ", card_key)
	ai_hand.append(card)
	ai_recent_cards.append(card_key)
	if ai_recent_cards.size() > 2:
		ai_recent_cards.pop_front()
	if ai_current_card and ai_current_card.get_parent() == self:
		remove_child(ai_current_card)
	ai_current_card = card
	if ai_current_card.get_parent() != self:
		add_child(ai_current_card)
	ai_current_card.position = Vector2(100, 100)
	update_hand_display("ai")
	round_count += 1

func show_selection_cards():
	clear_selection_cards()
	var matches = get_matching_options(player_current_card)
	print("Showing ", matches.size(), " options")
	for i in matches.size():
		var card = create_card(matches[i])
		selection_cards.append(card)
		add_child(card)
		if i < 8:
			card.position = Vector2(200 + i * 100, 300)
		else:
			card.position = Vector2(200 + (i - 8) * 100, 400)

func get_matching_options(current_card):
	var matches = []
	var suits = ["Spades", "Hearts", "Clubs", "Diamonds"]
	var numbers = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
	for number in numbers:
		if number != current_card.number:
			matches.append({"suit": current_card.suit, "number": number})
	for suit in suits:
		if suit != current_card.suit:
			matches.append({"suit": suit, "number": current_card.number})
	return matches

func clear_selection_cards():
	for card in selection_cards:
		if card.get_parent() == self:
			remove_child(card)
	selection_cards.clear()

func update_hand_display(player_type):
	var hand = player_hand if player_type == "player" else ai_hand
	var y_pos = 600 if player_type == "player" else 200
	for i in hand.size():
		var card = hand[i]
		if card.get_parent() != self:
			add_child(card)
		card.position = Vector2(100 + i * 50, y_pos)
