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
			var ext = content.file.get_extension()
			if ext in ["glb", "png"]:
				var http = HTTPRequest.new()
				http.use_threads = true
				add_child(http)
				http.connect("request_completed", self, "load_" + ext, [content, http])
				
				var file : String = msg.payload.baseUrl + content.hash
				var res = http.request(file)
				if res != OK:
					printt("****** error creating the glb request", res)
					http.queue_free()
	
	if msg.payload.contents.size() > 0:
		transform.origin = Vector3(msg.payload.basePosition.x, 0, msg.payload.basePosition.y) * parcel_size

	var response = {"eventType":"SceneReady", "payload": {"sceneId": msg.payload.id}}
	Server.send({"type": "ControlEvent", "payload": JSON.print(response)}, peer)
	#print("scene ready! ", scene_id)

func load_png(_result, response_code, _headers, body, content, connection):
	if response_code >= 200 && response_code < 300:
		var f = File.new()
		var file_name = "user://%s" % content.file.right(content.file.rfind("/") + 1)
		f.open(file_name, File.WRITE)
		f.store_buffer(body)
		f.close()
		connection.queue_free()

func load_glb(_result, response_code, _headers, body, content, connection):
	if response_code >= 200 && response_code < 300:
		var f = File.new()
		var file_name = "user://%s.glb" % content.hash
		f.open(file_name, File.WRITE)
		f.store_buffer(body)
		f.close()
		
		var l = DynamicGLTFLoader.new()
		var model = l.import_scene(file_name, 1, 1)
		add_child(model)
		
		# remove 'collider' mesh (creates z-fighting with the floor mesh)
		for c in model.get_children():
			if c.name.ends_with("_collider") \
			or c.name.begins_with("FloorBaseGrass_01"):
				c.queue_free()
		
		connection.queue_free()

func message(scene_msg):
	print(scene_msg.to_string())

	if scene_msg.has_createEntity():
		pass#print("create entity ", scene_msg.get_createEntity().get_id())
	
	if scene_msg.has_removeEntity():
		pass#print("remove entity ", scene_msg.get_removeEntity().get_id())
	
	if scene_msg.has_setEntityParent():
		pass#print("setEntityParent %s -> %s" % [
#			scene_msg.get_setEntityParent().get_parentId(),
#			scene_msg.get_setEntityParent().get_entityId() ])
	
	if scene_msg.has_componentCreated():
		pass#print("component created ", scene_msg.get_componentCreated().get_name())
	
	if scene_msg.has_componentDisposed():
		pass#print("component disposed ", scene_msg.get_componentDisposed().get_id())
	
	if scene_msg.has_componentRemoved():
		pass#print("component removed ", scene_msg.get_componentRemoved().get_name())
	
	if scene_msg.has_componentUpdated():
		pass#print("component updated %s -> %s" % [
#			scene_msg.get_componentUpdated().get_id(),
#			scene_msg.get_componentUpdated().get_json() ])
	
	if scene_msg.has_attachEntityComponent():
		pass#print("attach component to entity %s -> %s" % [
#			scene_msg.get_attachEntityComponent().get_entityId(),
#			scene_msg.get_attachEntityComponent().get_name() ])
	
	if scene_msg.has_updateEntityComponent():

		var data = scene_msg.get_updateEntityComponent().get_data()
		if data.left(1) in ["[", "{"]:

			var comp = JSON.parse(data)
			print("update component in entity %s -> %s" % [
				scene_msg.get_updateEntityComponent().get_entityId(),
				scene_msg.get_updateEntityComponent().get_data() ])
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
		pass#print("scene started ", id)
	
	if scene_msg.has_openNFTDialog():
		pass#print("open NFT dialog %s %s" % [
#			scene_msg.get_openNFTDialog().get_assetContractAddress(),
#			scene_msg.get_openNFTDialog().get_tokenId()
#		])
	
	if scene_msg.has_query():
		pass#print("query ", scene_msg.get_query().get_payload())

func _ready():
	pass
