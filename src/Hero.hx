package ;
import hxd.Math;
import hxd.Key in K;

class Hero
{
	var game : Game;
	var model : h3d.scene.Mesh;
	public var x(get, set) : Float;
	public var y(get, set) : Float;
	public var currentRotation(default, set) : Float = 0;
	var maxSpeed = 0.04;
	var speed = 0.;
	var size = 0.5;

	var moveAdd: h2d.col.Point;

	public function new(x, y) {
		game = Game.inst;
		model = getModel();
		this.x = x;
		this.y = y;
		currentRotation = 0;
		moveAdd = new h2d.col.Point();
	}

	function get_x() return model.x;
	function set_x(v : Float) return model.x = v;
	function get_y() return model.y;
	function set_y(v : Float) return model.y = v;
	function set_currentRotation(v : Float) {
		model.setRotate(0, 0, v);
		return currentRotation = v;
	}

	public function remove() {
		model.remove();
		model.dispose();
		model = null;
	}

	function getModel() {
		var c = new h3d.prim.Cube(size, size * 0.8 , size * 0.6);
		c.unindex();
		c.addNormals();
		c.addUVs();
		c.translate( -size * 0.5, -size * 0.8 * 0.5, 0);
		var m = new h3d.scene.Mesh(c, game.s3d);
		m.material.mainPass.enableLights = true;
		m.material.shadows = true;
		return m;
	}

	function repell(dx : Float, dy : Float, r : Float) {
		var d = dx * dx + dy * dy;
		if ( d < r * r * 0.99 ) {
			var r = -(r - Math.sqrt(d));
			dx *= r;
			dy *= r;
			x -= dx;
			y -= dy;
		}
	}

	public function update(dt : Float) {

		if(K.isDown(K.MOUSE_LEFT)) {
			speed += (maxSpeed - speed) * 0.025 * dt;
			x += speed * Math.cos(currentRotation);
			y += speed * Math.sin(currentRotation);
		}
		else {
			speed *= Math.pow(0.9, dt);
			x += speed * Math.cos(currentRotation);
			y += speed * Math.sin(currentRotation);
		}
		if(K.isPressed(K.MOUSE_RIGHT)) {

		}

		var mpos = game.getMousePicker();
		var rotation = Math.atan2(mpos.y - y, mpos.x - x);
		currentRotation = Math.angleMove(currentRotation, rotation, 0.05 * dt);

		var c = game.world.collide(x, y, size * 0.5 * model.scaleX);
		if(c != null) {
			speed *= 0.9 * dt;
			repell(c.x, c.y, 0.5 + size * 0.5 * model.scaleX);
			if(Math.abs(Math.angle(currentRotation - Math.atan2(c.y, c.x))) > Math.PI * 0.7) {
				if(speed > 0) speed = Math.min(-0.01, -speed * 0.5);
				else speed = Math.max( 0.01, -speed * 0.5);
			}
		}
	}
}