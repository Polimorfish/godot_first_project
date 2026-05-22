extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Gamestate.connection_failed.connect(_on_connection_failed)
	Gamestate.connection_succeeded.connect(_on_connection_successes)
	Gamestate.player_list_changed.connect(refresh_lobby)
	Gamestate.game_ended.connect(_on_game_ended)
	Gamestate.game_error.connect(_on_game_error)
	
	if OS.has_environment("USERNAME"):
		$Connect/Name.text = OS.get_environment("USERNAME")
	else:
		var desktop_path = OS.get_system_dir(0).replace("\\", "/").split("/")
		$Connect/Name.text = desktop_path[desktop_path.size()-2]
	
func _on_host_btn_pressed():
	if $Connect/PlayerName.text == "":
		$Connect/ErrorLabel.text = "Invalid name!"
		return
	
	$Connect.hide()
	$Players.show()
	$Connect/ErrorLabel.text = ""
	
	var player_name = $Connect/PlayerName.text
	Gamestate.host_game(player_name)
	refresh_lobby()

func _on_join_btn_pressed() -> void:
	if $Connect/PlayerName.text == "":
		$Connect/ErrorLabel.text = "Invalid name!"
		return
	
	var ip = $Connect/IpAddress.text
	if ip.is_valid_ip_address():
		$Connect/ErrorLabel.text = "Invalid ip address!"
		return
	
	$Connect/ErrorLabel.text = ""
	$Connect/JoinButton.disabled = true
	$Connect/HostButton.disabled = true
	
	var player_name = $Connect/PlayerName.text
	Gamestate.join_game(ip, player_name)

func _on_connection_successes():
	$Connect.hide()
	$Players.show()
	

func _on_connection_failed():
	$Connect/HostButton.disabled = false
	$Connect/JoinButton.disabled = false
	$Connect/ErrorLabel.set_text("Connection failed.")


func _on_game_ended():
	show()
	$Connect.show()
	$Players.hide()
	$Connect/HostButton.disabled = false
	$Connect/JoinButton.disabled = false

func _on_game_error(errtxt):
	$ErrorDialog.dialog_text = errtxt
	$ErrorDialog.popup_centered()
	$Connect/HostButton.disabled = false
	$Connect/JoinButton.disabled = false

func refresh_lobby():
	var players = Gamestate.get_player_list()
	players.sort()
	$Players/PlayerList.clear()
	$Players/PlayerList.add_item(Gamestate.get_player_name())
	for player in players:
		$Players/PlayerList.add_item(player)
	
	$Players/Start.disabled = not multiplayer.is_server()
	

func _on_start_pressed() -> void:
	Gamestate.begin_game()


func _on_find_public_ip_pressed() -> void:
	OS.shell_open("https://icanhazip.com/")
