package;
import hxd.Math;

class Gun
{
	var game : Game;
	var m :h3d.scene.Mesh;
	var dmg = 1;
	var owner : Entity;

	public function new( owner : Entity, rot : Float, currGun : Float, boost = false)
	{
		game = Game.inst;
		this.owner = owner;
		if(boost)
			dmg *= 2;

		var c = new h3d.prim.Cube(0.2, 0.025, 0.025);
		c.unindex();
		c.addNormals();
		c.addUVs();
		c.translate( -0.1, -0.0125, -0.0125);

		var model = owner.model;
		m = new h3d.scene.Mesh(c, game.s3d);
		m.x = model.x + 0.2 * Math.cos(rot + Math.PI * 0.5 * (currGun == 1 ? 1 : -1));
		m.y = model.y + 0.2 * Math.sin(rot + Math.PI * 0.5 * (currGun == 1 ? 1 : -1));
		m.z = model.z + 0.4;

		var dz = 0.;
		if(game.mpos == null)
			m.setRotate(0, 0, rot);
		else {
			var dx = Math.distance(game.mpos.x - m.x, game.mpos.y - m.y);
			//dz = Math.min(0.35, Math.atan2(m.z, dx) * 0.5);
			m.setRotate(0, dz, rot);
		}

		var cpt = 0.;
		var sp = 0.3;
		game.event.waitUntil(function(dt) {
			if(cpt > 100 || hit()) {
				m.remove();
				return true;
			}
			m.x += sp * Math.cos(rot) * dt;
			m.y += sp * Math.sin(rot) * dt;
			m.z -= sp * Math.sin(dz) * dt;

			cpt += dt;
			return false;
		});
	}

	function hit() {
		if(game.world.isCollide(m.x, m.y, true))
			return true;

		for(e in game.entities) {
			if(e == owner) continue;
			if(e.collide(m.x, m.y, m.z)) {
				e.hurt(dmg);
				return true;
			}
		}
		return false;
	}

}