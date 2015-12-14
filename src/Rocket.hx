package;
import hxd.Math;
import hxd.Res;

class Rocket
{
	var game : Game;
	public var m :h3d.scene.Object;
	var dmg = 50;
	var owner : Entity;
	public var exploded = false;
	public var launched = false;


	public function new(owner : Entity)
	{
		game = Game.inst;
		this.owner = owner;

		m = game.loadModel(Res.rocket.model);
		for( mat in m.getMaterials()) {
			mat.mainPass.enableLights = true;
			mat.shadows = true;
			if(mat.name == "FXFlameRocket") {
				cast(mat, h3d.mat.MeshMaterial).texture = Res.rocket.flame_ADD_.toTexture();
			}
		}
		game.fxs.push(m);
		game.s3d.addChild(m);
	}

	public function launch(rot : Float) {
		Sounds.play("Rockets");
		game.event.wait(0.1, function() {
			Sounds.play("Rockets2");
		});
		launched = true;
		m.playAnimation(game.anims.get(Res.rocket.model.entry.path));
		m.currentAnimation.speed = 1.5;

		var light = new h3d.scene.PointLight(m);
		light.color.setColor(0xFFD000);
		light.params = new h3d.Vector(0.2, 0.5, 0.7);
		game.fxs.push(light);

		var speed = 0.;
		var cos = Math.cos(rot);
		var sin = Math.sin(rot);
		var tz = m.z + 0.1;
		var cpt = 0.;
		var time = 120.;
		game.event.waitUntil(function(dt) {
			if(time < 0) return true;
			m.x += speed * cos * dt;
			m.y += speed * sin * dt;
			m.z += (tz - m.z) * 0.1 * dt;
			speed = Math.min(0.16, speed + 0.005 * dt);

			if(speed > 0.04 && cpt < 0) {
				addSmoke();
				cpt += 2;
			}
			cpt -= dt;
			time -= dt;
			if(hit())
				return true;
			return false;
		});
	}

	function addSmoke() {
		var fx = game.loadModel(Res.fx.smoke.model);
		fx.x = m.x;
		fx.y = m.y;
		fx.z = m.z;
		for( mat in fx.getMaterials()) {
			mat.mainPass.enableLights = true;
			mat.shadows = false;
			mat.mainPass.setPassName("noSAO");
		}

		var sc = 0.;
		fx.setScale(sc);
		fx.setRotate(0, 0, Math.srand(Math.PI));
		var d = 0.08 + 0.03 * Math.srand();
		game.event.waitUntil(function(dt) {
			sc = Math.min(1, sc + d * dt);
			fx.setScale(sc);
			if(sc > 0.8) {
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

	public function remove() {
		m.remove();
	}

	function explode() {
		Sounds.stop("Rockets2");
		Sounds.play("Explode");
		exploded = true;
		m.remove();
	}

	function hit() {
		if(game.world.isCollide(m.x, m.y, true)) {
			explode();
			return true;
		}

		for(f in game.fighters) {
			if(f.collide(m.x, m.y, m.z, 0.3)) {
				f.hurt(dmg);
				explode();
				return true;
			}
		}
		return false;
	}

}