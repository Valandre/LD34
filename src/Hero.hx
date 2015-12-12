package ;
import hxd.Res;
import hxd.Math;
import hxd.Key in K;

class Hero
{
	var game : Game;
	var model : h3d.scene.Object;
	public var x(get, set) : Float;
	public var y(get, set) : Float;
	public var currentRotation(default, set) : Float = 0;
	var rotation = 0.;
	var maxSpeed = 0.045;
	var speed = 0.;
	var size = 0.5;

	var canMove = true;

	public function new(x, y) {
		game = Game.inst;
		model = getModel();
		this.x = x;
		this.y = y;
		currentRotation = 0;
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
		/*
		var c = new h3d.prim.Cube(size, size * 0.8 , size * 0.6);
		c.unindex();
		c.addNormals();
		c.addUVs();
		c.translate( -size * 0.5, -size * 0.8 * 0.5, 0);
		var m = new h3d.scene.Mesh(c, game.s3d);
		*/
		var m = game.loadModel(Res.bolide.model);
		for( mat in m.getMaterials()) {
			mat.mainPass.enableLights = true;
			mat.shadows = true;

		}
		game.s3d.addChild(m);
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

		if(K.isPressed(K.MOUSE_RIGHT)) {
			canMove = !canMove;
		}
		if(K.isDown(K.MOUSE_LEFT)) {
			if(canMove)
				speed += (maxSpeed - speed) * 0.03 * dt;
		}
		else {
			speed *= Math.pow(0.95, dt);
			if( speed < 0.004)
				speed = 0;
		}

		var mpos = game.getMousePicker();
		if(canMove)
			rotation = Math.atan2(mpos.y - y, mpos.x - x);

		if(canMove || speed != 0) {
			//MOVE
			currentRotation = Math.angleMove(currentRotation, rotation, 0.05 * dt);
			x += speed * Math.cos(currentRotation);
			y += speed * Math.sin(currentRotation);

			var c = game.world.collide(x, y, size * 0.5 * model.scaleX);
			if(c != null) {
				speed *= 0.9 * dt;
				repell(c.x, c.y, 0.5 + size * 0.5 * model.scaleX);
				if(Math.abs(Math.angle(currentRotation - Math.atan2(c.y, c.x))) > Math.PI * 0.7) {
					if(speed > 0) speed = Math.min(-0.01, -speed * 0.6);
					else speed = Math.max( 0.01, -speed * 0.6);
				}
			}
		}
		else {
			//ATTACK

		}
	}
}