extends "res://interfaces/component.gd"
class_name DCL_AttachToAvatar


const _classid = 206

enum AnchorPointId {
	Position,
	NameTag,
}


static func update_component_in_entity(data, entity, _scene):
	var parser = JSON.new()
	var err = parser.parse(data)
	if err != OK:
		return

	var json = parser.get_data()
	if json.has("avatarId"):
		var remote_transform = RemoteTransform3D.new()
		entity.set_meta("AttachToAvatar", remote_transform)
		remote_transform.remote_path = entity.get_path()

		var avatar = Server.player.mesh
		avatar.add_child(remote_transform)
		# Stick it to the avatar's origin.
		remote_transform.position.y -= avatar.position.y

		if json.has("anchorPointId") and\
				json.anchorPointId == AnchorPointId.NameTag:
			remote_transform.position.y = avatar.height


func detach_from(entity):
	entity.get_meta("AttachToAvatar").queue_free()
	entity.remove_meta("AttachToAvatar")

	super.detach_from(entity)
