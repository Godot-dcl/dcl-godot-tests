extends Node

const PORT = 9080
var _server = WebSocketServer.new()

var peers = {}

func _ready():
	_server.connect("client_connected", self, "_connected")
	_server.connect("client_disconnected", self, "_disconnected")
	_server.connect("client_close_request", self, "_close_request")
	_server.connect("data_received", self, "_data_received")
	
	# Start server.
	var res = _server.listen(PORT)
	if res != OK:
		printerr("failed to listen to port ", PORT)

func _process(_delta):
	if _server.is_listening():
		_server.poll()

func _disconnected(id, was_clean_close):
	print("Client disconnected! was_clean_close: ", was_clean_close)
	if id in peers:
		peers.erase(id)

func _close_request(id, code, reason):
	print("client close request - %d %d: %s" % [
		id,
		code,
		"No Reason" if reason.empty() else reason
	])

func _data_received(id):
	var pct = JSON.parse(peers[id].get_packet().get_string_from_utf8())
	if pct.error == OK:
		var msg = pct.result
		if "payload" in msg and !msg.payload.empty():
			var payload = JSON.parse(msg.payload)
			if payload.error == OK:
				get_node("..").message(msg.type, payload.result)
	else:
		printerr(peers[id].get_packet().get_string_from_utf8())

func _connected(id, _protocol):
	print("Client connected!")
	
	var peer = _server.get_peer(id)
	peer.set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
	peers[id] = peer

func send(msg):
	if peers.size() == 0:
		return

	var txt = JSON.print(msg)
	for p in peers:
		peers[p].put_packet(txt.to_utf8())
