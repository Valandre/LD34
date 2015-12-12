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

	public function new(x, y) {
		game = Game.inst;
		model = getModel();
		this.x = x;
		this.y = y;
	}

	function get_x() return model.x;
	function set_x(v : Float) return model.x = v;
	function get_y() return model.y;
	function set_y(v : Float) return model.y = v;
	function set_currentRotation(v : Float) {
		model.setRotate(0, 0, v);
		return currentRotation = v;
	}


	function getModel() {
		var w = 0.6;
		var c = new h3d.prim.Cube(w, w, w);
		c.unindex();
		c.addNormals();
		c.addUVs();
		c.translate( -w * 0.5, -w * 0.5, 0);
		var m = new h3d.scene.Mesh(c, game.s3d);
		m.material.mainPass.enableLights = true;
		m.material.shadows = true;
		return m;
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
	}
}