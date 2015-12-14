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
	public var headlight : h3d.scene.Object;
	public var rifle : h3d.scene.Object;
	var fxs : Array<h3d.scene.Object>;

	var light : h3d.scene.PointLight;

	public function new(x, y) {
		game = Game.inst;
		model = new h3d.scene.Object(game.s3d);
		model.addChild(getBolide());
		this.x = x;
		this.y = y;
		currentRotation = 0;

		fxs = [];
		light = new h3d.scene.PointLight(model);
		light.color.setColor(0xFFD000);
		light.params = new h3d.Vector(0.5, 0.7, 0.9);
		light.z += 0.1;
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

		light.remove();
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

	function explode() {
		Sounds.play("Explode");
		model.visible = false;
		rifle.visible = false;

		var fx = game.loadModel(Res.fx.xplosion.model);
		fx.x = x;
		fx.y = y;
		for( mat in fx.getMaterials()) {
			mat.mainPass.enableLights = true;
			mat.shadows = false;
			mat.mainPass.setPassName("noSAO");
			cast(mat, h3d.mat.MeshMaterial).blendMode = Add;
		}
		fx.getObjectByName("Box013").toMesh().material.texture = Res.fx.xplosion.flame_ADD_.toTexture();

		fx.playAnimation(game.anims.get(Res.fx.xplosion.model.entry.path));
		fx.currentAnimation.onAnimEnd = function() {
			fx.remove();
			remove();
			if(game.fighters.length == 0 && game.hero != null)
				game.victory();
		}
		game.s3d.addChild(fx);

		for(i in 0...16)
			addExplodeSmoke(i / 16 * Math.PI * 2);
	}

	function addExplodeSmoke(a : Float) {
		trace("addExplodeSmoke");
		var fx = game.loadModel(Res.fx.smoke.model);
		fx.x = x;
		fx.y = y;
		fx.z = 0.3 + Math.srand() * 0.1;
		for( mat in fx.getMaterials()) {
			mat.mainPass.enableLights = true;
			mat.shadows = false;
			mat.mainPass.setPassName("noSAO");
		}

		var sc = 0.;
		fx.setScale(sc);
		fx.setRotate(0, 0, Math.srand(Math.PI));
		var d = 0.08 + 0.01 * Math.srand();
		var sp = 0.05 + Math.srand() * 0.01;
		var cos = Math.cos(a);
		var sin = Math.sin(a);
		game.event.waitUntil(function(dt) {
			sc += d * dt;
			fx.setScale(sc);
			fx.x += sp * cos * dt;
			fx.y += sp * sin * dt;
			if(sc > 1) {
				d = 0.04 + 0.01 * Math.srand();
				game.event.waitUntil(function(dt) {
					sc = Math.max(0, sc - 0.05 * dt);
					fx.setScale(sc);
					if(sc == 0) {
						fx.remove();
						return true;
					}
					fx.x += sp * cos;
					fx.y += sp * sin;
					sp = Math.max(0, sp - 0.002 * dt);
					return false;
				});
				return true;
			}
			sp = Math.max(0, sp - 0.002 * dt);

			return false;
		});
		game.fxs.push(fx);
		game.s3d.addChild(fx);
	}

	public function hurt(dmg : Int) {
		if(isDead()) return;
		life = Math.imax(0, life - dmg);
		blink();
		if(life <= 0)
			explode();
	}

	function addSmoke() {
		var fx = game.loadModel(Res.fx.smoke.model);
		fx.x = x + 0.05 * Math.srand() - 0.15 * Math.cos(currentRotation);
		fx.y = y + 0.05 * Math.srand() - 0.15 * Math.sin(currentRotation);
		fx.z = 0.15 + 0.05 * Math.srand();
		for( mat in fx.getMaterials()) {
			mat.mainPass.enableLights = true;
			mat.shadows = false;
			mat.mainPass.setPassName("noSAO");
		}

		var sc = 0.;
		fx.setScale(sc);
		fx.setRotate(0, 0, Math.srand(Math.PI));
		var d = 0.08 + 0.03 * Math.srand();
		var max = 0.6 + 0.1 * Math.srand();
		game.event.waitUntil(function(dt) {
			sc = Math.min(1, sc + d * dt);
			fx.setScale(sc);
			if(sc > max) {
				d = 0.04 + 0.02 * Math.srand();
				game.event.waitUntil(function(dt) {
					sc = Math.max(0, sc - 0.05 * dt);
					fx.setScale(sc);
					if(sc == 0) {
						fx.remove();
						return true;
					}
					return false;
				});
				return true;
			}

			return false;
		});
		game.fxs.push(fx);
		game.s3d.addChild(fx);
	}

	public function collide(tx : Float, ty : Float, tz : Float, forceRay : Float = null) {
		var r = forceRay == null ? ray : forceRay;
		if(Math.distance(tx - x, ty - y) < r)
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

		if(Math.random() < 0.2 && speed > 0.02)
			addSmoke();
	}

}