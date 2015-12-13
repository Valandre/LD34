package ;
import hxd.Res;
import hxd.Math;

class Entity
{
	var game : Game;
	public var model : h3d.scene.Object;
	public var x(get, set) : Float;
	public var y(get, set) : Float;
	public var currentRotation(default, set) : Float = 0;
	var ray = 0.35;
	var life = 100;

	public function new(x, y) {
		game = Game.inst;
		model = new h3d.scene.Object(game.s3d);
		model.addChild(getBolide());
		this.x = x;
		this.y = y;
		currentRotation = 0;

		game.entities.push(this);
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
		game.entities.remove(this);
		model.remove();
		model.dispose();
		model = null;
	}

	function getBolide() {
		var m = game.loadModel(Res.bolide.model);
		for( mat in m.getMaterials()) {
			mat.mainPass.enableLights = true;
			mat.shadows = true;
			mat.addPass(new h3d.mat.Pass("depth", mat.mainPass));
			mat.addPass(new h3d.mat.Pass("normal", mat.mainPass));
		}
		return m;
	}

	function getMeca() {
		var m = game.loadModel(Res.meca.model);
		for( mat in m.getMaterials()) {
			mat.addPass(new h3d.mat.Pass("depth", mat.mainPass));
			mat.addPass(new h3d.mat.Pass("normal", mat.mainPass));
			mat.mainPass.enableLights = true;
			mat.shadows = true;
		}
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

	public function hurt(dmg : Int) {
		life -= dmg;
		if(life <= 0)
			remove();
	}

	public function collide(tx : Float, ty : Float, tz : Float) {
		if(Math.distance(tx - x, ty - y) < ray && tz < 0.4)
			return true;
		return false;
	}

	public function update(dt:Float) {
	}

}