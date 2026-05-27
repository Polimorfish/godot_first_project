extends Node

const DEFAULT_PORT = 10567
const MAX_PEERS = 12

var peer = null
var player_name = "lol"

var players = {}
var players_ready = {}

signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)

func _player_connected(id):
	register_player.rpc_id(id, player_name)

func _player_disconnected(id):
	if has_node("/root/Main"):
		if multiplayer.is_server():
			game_error.emit("Player " + players[id] + " disconnected")
			end_game()
	else:
		unregister_player(id)

func _connected_ok():
	connection_succeeded.emit()

func _server_disconnected():
	game_error.emit("Server disconnected")
	end_game()

func _connected_fail():
	multiplayer.set_network_peer(null)
	connection_failed.emit()

@rpc("any_peer")
func register_player(new_player_name):
	var id = multiplayer.get_remote_sender_id()
	players[id] = new_player_name
	player_list_changed.emit()

func unregister_player(id):
	players.erase(id)
	player_list_changed.emit()

#Где будет выполнен метод?
#Как вызвать удаленно
@rpc("authority", "call_local", "reliable", 0)
func load_world():
	#Change Scene
	var world = load("res://scenes/main.tscn").instantiate()
	get_tree().get_root().add_child(world)
	get_tree().get_root().get_node("Main").get_node("HUD").get_node("lobby").hide()
	
	#Set up score
	world.get_node("Score").add_player(multiplayer.get_unique_id(), player_name)
	for pn in players:
		world.get_node("Score").add_player(pn, players[pn])
	get_tree().set_pause(false)
	
func host_game(new_player_name):
	player_name = new_player_name
	peer = ENetMultiplayerPeer.new()
	peer.create_server(DEFAULT_PORT, MAX_PEERS)
	multiplayer.set_multiplayer_peer(peer)

func join_game(ip, new_player_name):
	player_name = new_player_name
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, DEFAULT_PORT)
	multiplayer.set_multiplayer_peer(peer)

func get_player_list():
	return players.values()

func get_player_name():
	return player_name

func begin_game():
	assert(multiplayer.is_server())
	load_world.rpc()
	
	var world = get_tree().get_root().get_node("Main")
	var player_scene = load("res://scenes/Player.tscn")
	
	var spawn_position = world.get_node("StartPosition").position
	
	for pn in players:
		var player = player_scene.instantiate()
		player.synced_position = spawn_position
		player.name = str(players[pn])
		player.set_player_name(player_name if pn == multiplayer.get_unique_id() else players[pn])
		world.get_node("Players").add_child(player)
	
func end_game():
	if has_node("/root/Main"):
		get_node("/root/Main").queue_free()
	game_ended.emit()
	players.clear()
	
func _ready() -> void:
	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.peer_disconnected.connect(_player_disconnected)
	multiplayer.connected_to_server.connect(_connected_ok)
	multiplayer.connection_failed.connect(_connected_fail)
	multiplayer.server_disconnected.connect(_server_disconnected)
