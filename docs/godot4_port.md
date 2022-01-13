Notes on porting to godot 4

# Some nodes changed names

	* Spatial to Node3D
	* PhysicsBody to PhysicsBody3D
	* SpatialMaterial to StandardMaterial3D

# Some classes changed names

	* Quat to Quaternion
	* Transform to Transform3D
	* PoolByteArray to PackedByteArray

# Syntax Changes


`tool` becomes `@tool`

`export` becomes `@export`. General syntax is:

```
@export var var_name : bool = true : get=getter_method set=setter_method
```

# Coroutines

`yield` is gone, replaced by `await`

```
	yield(object, "signal")
```

becomes:

```
	await object.signal
```

When it's a call to another coroutine:

```
	yield(coroutine_call(), "completed")
```

becomes:

```
	await coroutine_call()
```

# Signal connections:

```
connect("signal", object, "method")
```

becomes:

```
connect("signal", Callable(object, "method"))
```

When binding extra parameters, they go outside the Callable constructor:

```
connect("signal", Callable(object, "method"), [extra_values])
```

# Constructors use "super":

```
func _init(param1, param2).(param1, param2):
```

becomes

```
func _init(param1, param2):
	super(param1, parame2)
```

# Super is also used in normal functions

```
func update(data):
	.update(data)
```

becomes:

```
func update(data):
	super.update(data)
```

