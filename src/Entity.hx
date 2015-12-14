package ;
import hxd.Res;
import hxd.Math;

class Entity
{
	var game : Game;
	public var model : h3d.scene.Object;
	public var x(default, set) : Float;
	public var y(default, set) : Float;
	public var currentRotation(default, set) : Float = 0;
	public var ray = 0.25;
	public var life = 100;
	var maxSpeed = 0.05;
	var speed = 0.;
	var size = 0.35;

	var canMove = true;
	var isMeca = false;
	var delay = 0.;
	var currGun = 0;
	var oldRot = 0.;
	var rotation = 0.;
	public var impact : h2d.col.Point;
	var headlight : h3d.scene.Object;
	var rifle : h3d.scene.Object;
	var fxs : Array<h3d.scene.Object>;

	public function new(x, y) {
		game = Game.inst;
		model = new h3d.scene.Object(game.s3d);
		model.addChild(getBolide());
		this.x = x;
		this.y = y;
		currentRotation = 0;

		fxs = [];

		game.entities.push(this);
	}
	function set_x(v : Float) {
		model.x = v;
		return x = v;
	}
	function set_y(v : Float) {
		model.y = v;
		return y = v;
	}
	function set_currentRotation(v : Float) {
		model.setRotate(0, 0, v);
		return currentRotation = v;
	}

	public function isDead() {
		return life <= 0;
	}

	public function remove() {
		if(model == null) return;
		game.entities.remove(this);
		model.remove();
		model.dispose();
		model = null;
		headlight.remove();
		headlight.dispose();
		headlight = null;
		rifle.remove();
		rifle.dispose();
		rifle = null;

		for(fx in fxs)
			fx.remove();
	}

	function getBolide() {
		var m = game.loadModel(Res.bolide.model);
		for( mat in m.getMaterials()) {
			mat.mainPass.enableLights = true;
			mat.shadows = true;
			mat.addPass(new h3d.mat.Pass("depth", mat.mainPass));
			mat.addPass(new h3d.mat.Pass("normal", mat.mainPass));
		}
		model.setScale(0.8);

		headlight = game.loadModel(Res.fx.headlight.model);
		for( mat in headlight.getMaterials()) {
			mat.mainPass.enableLights = true;
			cast(mat, h3d.mat.MeshMaterial).blendMode = Add;
		}
		headlight.x = model.x;
		headlight.y = model.y;
		headlight.setRotate(0, 0, currentRotation);
		headlight.setScale(model.scaleX);
		game.s3d.addChild(headlight);

		rifle = game.loadModel(Res.rifle.model);
		for( mat in rifle.getMaterials()) {
			mat.mainPass.enableLights = true;
			mat.shadows = true;
			mat.addPass(new h3d.mat.Pass("depth", mat.mainPass));
			mat.addPass(new h3d.mat.Pass("normal", mat.mainPass));
		}

		rifle.x = model.x;
		rifle.y = model.y;
		rifle.setRotate(0, 0, currentRotation);
		rifle.setScale(model.scaleX);
		rifle.playAnimation(game.anims.get(Res.rifle.model.entry.path));
		game.s3d.addChild(rifle);

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

	public function blink() {
		for(m in model.getMaterials())
			m.mainPass.addShader(game.renderer.globalColorAdd);
		game.event.wait(0.05, function() {
			if(model == null) return;
			for(m in model.getMaterials())
				m.mainPass.removeShader(game.renderer.globalColorAdd);
		});
	}

	public function hurt(dmg : Int) {
		life = Math.imax(0, life - dmg);
		blink();
		if(life <= 0)
			remove();
	}

	public function collide(tx : Float, ty : Float, tz : Float) {
		if(Math.distance(tx - x, ty - y) < ray)
			return true;
		return false;
	}

	public function update(dt:Float) {
		delay -= dt;

		if(impact != null) {
			x += impact.x * (isMeca ? 0.5 : 1);
			y += impact.y * (isMeca ? 0.5 : 1);
			impact.x *= Math.pow(0.9, dt);
			impact.y *= Math.pow(0.9, dt);
		}
	}

}