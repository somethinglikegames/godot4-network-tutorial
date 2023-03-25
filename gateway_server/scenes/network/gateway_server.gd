extends Node

@export_range(1025, 65536) var network_port := 1910
@export_range(2, 4095) var max_clients := 2

var shutdown_hook : Callable
var authentication_server : Node
var peers := []

func startup() -> void:
	var network := ENetMultiplayerPeer.new()
	var ret := network.create_server(network_port, max_clients)
	if ret == OK:
		get_multiplayer().set_multiplayer_peer(network)
		print("Server started on port %d, allowing max %d connections"
				% [network_port, max_clients])

		network.peer_connected.connect(
			func(client_id: int) -> void:
				print("Client %d connected" % client_id)
				peers.append(client_id)
				)
		network.peer_disconnected.connect(
			func(client_id: int) -> void:
				print("Client %d disconnected" % client_id)
				peers.erase(client_id)
				)
	else:
		print("Error while starting server: %d" % ret)
		shutdown_hook.call(ret)


func shutdown() -> void:
	if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED:
		multiplayer.multiplayer_peer.refuse_new_connections = true
		for client in peers:
			multiplayer.multiplayer_peer.disconnect_peer(client, true)
		multiplayer.multiplayer_peer.close()


func return_login_request(result: bool, token: String, player_id: int) -> void:
	c_login_response.rpc_id(player_id, result, token)
	var peer: ENetPacketPeer = multiplayer.multiplayer_peer.get_peer(player_id)
	if peer != null:
		peer.peer_disconnect_later()


@rpc("call_remote", "authority", "reliable")
func c_login_response(_result: bool, _token: String) -> void:
	pass # on game client


@rpc("call_remote", "any_peer", "reliable")
func s_login_request(username: String, password: String) -> void:
	var player_id := multiplayer.get_remote_sender_id()
	print("login request received by %d" % player_id)
	authentication_server.authenticate_player(username, password, player_id)
