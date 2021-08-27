extends Node

const PORT = 9080
var _server = WebSocketServer.new()

var peers = []

func _ready():
	# Start server.
	_server.connect("client_connected", self, "_connected")
	_server.listen(PORT)


func _process(delta):
	_server.poll()

	var i = peers.size()
	while i > 0:
		i -= 1
		check_peer(peers[i])
		if !peers[i].is_connected_to_host():
			printt("peer disconnected!")
			peers.remove(i)

func _connected(id, protocol):
	var peer = _server.get_peer(id)
	peers.push_back(peer)
	peer.set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
	print("Client connected!")


func check_peer(p):
	for i in range(p.get_available_packet_count()):
		#printt("data from socket", JSON.parse(p.get_packet().get_string_from_utf8()).result)
		var pct = p.get_packet().get_string_from_utf8()
		printt("data from socket", pct)
		var msg = JSON.parse(pct).result
		var payload
		if "payload" in msg:
			payload = JSON.parse(msg.payload).result
		get_node("..").message(msg.type, payload)
		

func send(msg):
	if peers.size() == 0:
		return

	var txt = JSON.print(msg)
	printt("sending to peer", txt)
	peers[0].put_packet(txt.to_utf8())
