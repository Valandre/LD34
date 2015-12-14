package;
import hxd.Math;
import hxd.Res;

class Mine
{
	var game : Game;
	var m :h3d.scene.Object;
	var dmg = 50;
	var owner : Entity;
	public var explode = false;
	var canHit = false;

	public function new( owner : Entity, rot : Float)
	{
		game = Game.inst;
		this.owner = owner;

		m = game.loadModel(Res.mine.model);
		m.x = owner.x - 0.1 * Math.cos(rot);
		m.y = owner.y - 0.1 * Math.sin(rot);
		m.z = 0.3 * owner.model.scaleX;
		m.setScale(0.9 * owner.model.scaleX);
		for( mat in m.getMaterials()) {
			mat.mainPass.enableLights = true;
			mat.shadows = true;
			if(mat.name == "Mine2") cast(mat, h3d.mat.MeshMaterial).texture = Res.mine.texture.toTexture();
			if(mat.name == "minelight") cast(mat, h3d.mat.MeshMaterial).mainPass.culling = Both;
		}
		m.playAnimation(game.anims.get(Res.mine.model.entry.path));

		game.s3d.addChild(m);

		rot += Math.PI;
		m.setRotate(0, 0, rot);

		var cpt = 0.;
		var sp = 0.02;
		var zAcc = 0.08;
		var a = 0.;
		game.event.waitUntil(function(dt) {
			if(explode) return true;
			if(m.z < 0) {
				Sounds.play("Mines");
				m.z = 0;
				m.setRotate(0, 0, rot);
				for( mat in m.getMaterials()) {
					if(mat.name == "minelight") cast(mat, h3d.mat.MeshMaterial).mainPass.culling = None;
				}
				return true;
			}
			m.x += sp * Math.cos(rot) * dt;
			m.y += sp * Math.sin(rot) * dt;
			m.z += zAcc * dt;
			m.setRotate(0, a, rot);

			a += 0.5 * dt;
			zAcc -= 0.01 * dt;
			cpt += dt;
			return false;
		});

		game.event.wait(0.25, function() {
			canHit = true;
		});

		game.fxs.push(m);
	}

	public function remove() {
		m.remove();
	}

	function hit() {
		for(e in game.entities) {
			if(e.collide(m.x, m.y, m.z, 0.3)) {
				e.hurt(dmg);
				explode = true;
				return true;
			}
		}
		return false;
	}

	public function update(dt : Float) {
		if(explode) return;
		if(canHit && hit())
			m.remove();
	}

}