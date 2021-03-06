package bullet;

@:hlNative("bullet")
class Body {

	var state : Native.MotionState;
	var inst : Native.RigidBody;
	var _pos = new h3d.col.Point();
	var _vel = new h3d.col.Point();
	var _q = new h3d.Quat();
	var _tmp = new Array<Float>();

	public var world(default,null) : World;

	public var shape(default,null) : Shape;
	public var mass(default,null) : Float;
	public var position(get,never) : h3d.col.Point;
	public var velocity(get,set) : h3d.col.Point;
	public var rotation(get,never) : h3d.Quat;
	public var object(default,set) : h3d.scene.Object;

	public function new( shape : Shape, mass : Float, ?world : World ) {
		var inertia = new Native.Vector3(shape.inertia.x * mass, shape.inertia.y * mass, shape.inertia.x * mass);
		state = new Native.DefaultMotionState();
		var inf = new Native.RigidBodyConstructionInfo(mass, state, @:privateAccess shape.getInstance(), inertia);
		inst = new Native.RigidBody(inf);
		inertia.delete();
		inf.delete();
		this.shape = shape;
		this.mass = mass;
		_tmp[6] = 0.;
		if( world != null ) addTo(world);
	}

	function set_object(o) {
		if( object != null ) object.remove();
		object = o;
		if( object != null && object.parent == null && world != null && world.parent != null ) world.parent.addChild(object);
		return o;
	}

	public function addTo( world : World ) {
		if( this.world != null ) remove();
		@:privateAccess world.addRigidBody(this);
	}

	public function remove() {
		if( world == null ) return;
		@:privateAccess world.removeRigidBody(this);
	}

	public function setTransform( p : h3d.col.Point, ?q : h3d.Quat ) {
		var t = inst.getCenterOfMassTransform();
		var v = new Native.Vector3(p.x, p.y, p.z);
		t.setOrigin(v);
		v.delete();
		if( q != null ) {
			var qv = new Native.Quaternion(q.x, q.y, q.z, q.w);
			t.setRotation(qv);
			qv.delete();
		}
		inst.setCenterOfMassTransform(t);
	}

	public function initObject() {
		if( object != null ) return object.toMesh();
		var o = new h3d.scene.Mesh(shape.getPrimitive());
		object = o;
		return o;
	}

	public function delete() {
		inst.delete();
		state.delete();
	}

	public function loadPosFromObject() {
		setTransform(new h3d.col.Point(object.x, object.y, object.z), object.getRotationQuat());
	}

	function get_position() {
		var t = inst.getCenterOfMassTransform();
		var p = t.getOrigin();
		_pos.set(p.x(), p.y(), p.z());
		p.delete();
		return _pos;
	}

	function get_rotation() {
		var t = inst.getCenterOfMassTransform();
		var q = t.getRotation();
		var qw : Native.QuadWord = q;
		_q.set(qw.x(), qw.y(), qw.z(), qw.w());
		q.delete();
		return _q;
	}

	function get_velocity() {
		var v = inst.getLinearVelocity();
		_vel.set(v.x(),v.y(),v.z());
		return _vel;
	}

	function set_velocity(v) {
		if( v != _vel ) _vel.load(v);
		var p = new Native.Vector3(v.x, v.y, v.z);
		inst.setLinearVelocity(p);
		p.delete();
		return v;
	}

	public function resetVelocity() {
		inst.setAngularVelocity(zero);
		inst.setLinearVelocity(zero);
	}

	static var zero = new Native.Vector3();

	/**
		Updated the linked object position and rotation based on physical simulation
	**/
	public function sync() {
		if( object == null ) return;
		var pos = position;
		object.x = pos.x;
		object.y = pos.y;
		object.z = pos.z;
		var q = rotation;
		object.getRotationQuat().load(q); // don't share reference
	}

}
