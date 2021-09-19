extends Spatial

const proto = preload("res://engineinterface.gd")
const parcel_size = 16

var peer = null
var global_scene
var id

var current_index = -1

func create(msg, p_peer, is_global):
	id = msg.payload.id
	global_scene = is_global
	
	peer = p_peer
	
	if msg.payload.name != "DCL Scene":
		for content in msg.payload.contents:
			if content.file.right(content.file.length() - 4) == ".glb":
				var http = HTTPRequest.new()
				add_child(http)
				http.connect("request_completed", self, "load_glb", [content.hash, http])
				
				var file : String = msg.payload.baseUrl + content.hash
				var res = http.request(file)
				if res != OK:
					printt("****** error creating the glb request", res)
					http.queue_free()
	
	if msg.payload.contents.size() > 0:
		transform.origin = Vector3(msg.payload.basePosition.x, 0, msg.payload.basePosition.y) * parcel_size

	var response = {"eventType":"SceneReady", "payload": {"sceneId": msg.payload.id}}
	Server.send({"type": "ControlEvent", "payload": JSON.print(response)}, peer)
	print("scene ready! ", msg.payload.id)

func load_glb(result, response_code, headers, body, file_hash, connection):
	if response_code >= 200 && response_code < 300:
		var f = File.new()
		var file_name = "user://%s.glb" % file_hash
		f.open(file_name, File.WRITE)
		f.store_buffer(body)
		f.close()
		
		var l = DynamicGLTFLoader.new()
		var model = l.import_scene(file_name, 1, 1)
		add_child(model)
		connection.queue_free()

func message(scene_msg):
	print(scene_msg.to_string())

	if scene_msg.has_createEntity():
		print("create entity ", scene_msg.get_createEntity().get_id())
	
	if scene_msg.has_removeEntity():
		print("remove entity ", scene_msg.get_removeEntity().get_id())
	
	if scene_msg.has_setEntityParent():
		print("setEntityParent %s -> %s" % [
			scene_msg.get_setEntityParent().get_parentId(),
			scene_msg.get_setEntityParent().get_entityId() ])
	
	if scene_msg.has_componentCreated():
		print("component created ", scene_msg.get_componentCreated().get_name())
	
	if scene_msg.has_componentDisposed():
		print("component disposed ", scene_msg.get_componentDisposed().get_id())
	
	if scene_msg.has_componentRemoved():
		print("component removed ", scene_msg.get_componentRemoved().get_name())
	
	if scene_msg.has_componentUpdated():
		print("component updated %s -> %s" % [
			scene_msg.get_componentUpdated().get_id(),
			scene_msg.get_componentUpdated().get_json() ])
	
	if scene_msg.has_attachEntityComponent():
		print("attach component to entity %s -> %s" % [
			scene_msg.get_attachEntityComponent().get_entityId(),
			scene_msg.get_attachEntityComponent().get_name() ])
	
	if scene_msg.has_updateEntityComponent():
		print("update component in entity %s -> %s" % [
			scene_msg.get_updateEntityComponent().get_entityId(),
			scene_msg.get_updateEntityComponent().get_data() ])

		var data = scene_msg.get_updateEntityComponent().get_data()
		if data.left(1) in ["[", "{"]:

			var comp = JSON.parse(data)
			print(JSON.print(comp.result))

		else:
			var buf = Marshalls.base64_to_raw(data)
			
			var comp = proto.PB_Transform.new()
			var err = comp.from_bytes(buf)
			if err == proto.PB_ERR.NO_ERRORS:
				print(comp.to_string())
			else:
				print("****** error decoding payload ", err)
		
	
	if scene_msg.has_sceneStarted():
		print("scene started ", id)
	
	if scene_msg.has_openNFTDialog():
		print("open NFT dialog %s %s" % [
			scene_msg.get_openNFTDialog().get_assetContractAddress(),
			scene_msg.get_openNFTDialog().get_tokenId()
		])
	
	if scene_msg.has_query():
		print("query ", scene_msg.get_query().get_payload())

func _ready():
	pass
