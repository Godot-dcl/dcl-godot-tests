extends Node

const proto = preload("res://engineinterface.gd")

const PORT = 9080
var _server = WebSocketServer.new()

var global_scenes = {}
var parcel_scenes = {}

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

func _connected(id, _protocol):
	print("Client connected!")
	
	var peer = _server.get_peer(id)
	peer.set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
	peers[id] = peer

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

func create_scene(msg, peer, p_global):
	var scene = preload("res://scene.tscn").instance()
	scene.set_name(msg.payload.id)
	if p_global:
		global_scenes[msg.payload.id] = [scene, peer]
	else:
		parcel_scenes[msg.payload.id] = [scene, peer]
	get_tree().get_root().add_child(scene)
	scene.create(msg, peer, true)
	

func _message(msg, peer):
	
	printt("Server message ", msg.type, msg)
	
	if msg.type == "CreateGlobalScene":
		create_scene(msg, peer, true)

	elif msg.type == "LoadParcelScenes":
		create_scene(msg, peer, false)
		
	elif msg.type == "SendSceneMessage":
		for buf in msg.payload:
			var scene_msg = proto.PB_SendSceneMessage.new()
			var err = scene_msg.from_bytes(buf)
			if err == proto.PB_ERR.NO_ERRORS:
				var id = scene_msg.get_sceneId()
				var scene
				if id in global_scenes:
					scene = global_scenes[id][0]
				elif id in parcel_scenes:
					scene = parcel_scenes[id][0]
				else:
					print("error: unknown scene id %s for SendSceneMessage %s", [id, scene_msg.to_string()])
					break
				scene.message(scene_msg)
			else:
				printt("****** Protobuf error is ", err)
				printt("msg is ", scene_msg.to_string())
	else:
		printt("Unhandled message", msg.type)

func _data_received(id):
	var data = peers[id].get_packet().get_string_from_utf8() as String
	if data.left(1) in ["[", "{"]:
		var json = JSON.parse(data.strip_edges().strip_escapes()) as JSONParseResult
		if typeof(json.result) == TYPE_DICTIONARY:
			if "payload" in json.result and !json.result.payload.empty():
				if json.result.payload.left(1) in ["[", "{"]:
					var payload = JSON.parse(json.result.payload.strip_edges().strip_escapes()) as JSONParseResult
					json.result.payload = payload.result
				else:
					if !json.result.payload.strip_edges().strip_escapes().empty():
						var payload = []
						for line in json.result.payload.split("\n"):
							if !line.empty():
								if line.right(line.length() - 1) != "=":
									line += "="
								payload.push_back(Marshalls.base64_to_raw(line.trim_prefix("b64-")))
						json.result.payload = payload
			
		_message(json.result, peers[id])
	else:
		print("unsupported data: ", data)

func send(msg, peer = null):
	if peers.size() == 0:
		return

	if peer == null:
		peer = peers[peers.keys()[0]]

	var txt = JSON.print(msg)
	peer.put_packet(txt.to_utf8())
