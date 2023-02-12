extends Node

@export_range(1025, 65536) var network_port := 1909
@export_range(2, 4095) var max_clients := 2


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
                )
        network.peer_disconnected.connect(
            func(client_id: int) -> void:
                print("Client %d disconnected" % client_id)
                )
    else:
        print("Error while starting server: %d" % ret)
        get_tree().quit(ret)
