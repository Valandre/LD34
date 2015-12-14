package ;
import hxd.Res;
import hxd.Math;

enum BonusKind {
	Ammo;
	Mine;
	Rocket;
	Fuel;
	Repair;
	Speed;
}

class Bonus
{
	public var kind : BonusKind;
	var game : Game;
	var looted = false;
	public var model : h3d.scene.Object;
	var lifeTime = 1000.;

	public function new() {
		game = Game.inst;
		kind = bonusSelect();

		lifeTime = 1000 + Math.srand(500);

		var res = switch(kind) {
			case Ammo : Res.bonus.ammo.model;
			case Mine : Res.bonus.mine.model;
			case Rocket : Res.bonus.rocket.model;
			case Fuel : Res.bonus.fuel.model;
			case Repair : Res.bonus.repair.model;
			case Speed : Res.bonus.speed.model;
		}

		model = game.loadModel(res);
		var pos = game.world.getFreePos();
		if(game.world.hasZebra[Std.int(pos.x + pos.y * game.width)] == 1)
			return;
		for( b in game.bonus)
			if(Std.int(b.model.x) == pos.x && Std.int(b.model.y) == pos.y)
				return;

		model.x = pos.x + 0.5;
		model.y = pos.y + 0.5;
		model.playAnimation(game.anims.get(res.entry.path));
		model.setScale(0.9);

		for( mat in model.getMaterials()) {
			mat.mainPass.enableLights = true;
			mat.shadows = true;
			mat.mainPass.setPassName("noSAO");

			switch(mat.name) {
				case "Ammo": cast(mat, h3d.mat.MeshMaterial).texture = Res.bonus.ammo.texture.toTexture();
				case "Repair": cast(mat, h3d.mat.MeshMaterial).texture = Res.bonus.repair.texture.toTexture();
				case "Mine": cast(mat, h3d.mat.MeshMaterial).texture = Res.bonus.mine.texture.toTexture();
				case "Rocket": cast(mat, h3d.mat.MeshMaterial).texture = Res.bonus.rocket.texture.toTexture();
				case "Fuel": cast(mat, h3d.mat.MeshMaterial).texture = Res.bonus.fuel.texture.toTexture();
				case "Speed": cast(mat, h3d.mat.MeshMaterial).texture = Res.bonus.speed.texture.toTexture();
			}
		}

		var obj = switch(kind) {
			case Ammo : model.getObjectByName("Ammo");
			case Mine : model.getObjectByName("Mine");
			case Rocket : model.getObjectByName("Rocket");
			case Fuel : model.getObjectByName("Fuel");
			case Repair : model.getObjectByName("Repair");
			case Speed : model.getObjectByName("Speed");
		}

		game.s3d.addChild(model);
		game.bonus.push(this);

		var cpt = 0.;
		var rot = Math.srand(Math.PI);
		game.event.waitUntil(function(dt) {
			if(looted) return true;
			lifeTime -= dt;
			if(lifeTime < 0) {
				remove();
				return true;
			}

			if(lifeTime < 120) {
				if(cpt < 0) {
					cpt = 2;
					model.visible = !model.visible;
				}
				cpt -= dt;
			}


			if(obj != null) {
				obj.setRotate(0, 0, rot);
				rot += 0.01 * dt;
			}
			return false;
		});
	}

	public function loot() {
		if(looted) return;
		looted = true;

		var x = model.x;
		var y = model.y;
		model.remove();
		var res = null;
		switch(kind) {
			case Ammo :
				game.hero.ammo = Math.imin(game.hero.ammoMax, game.hero.ammo + 100);
				res = Res.fx.ammo.model;
			case Mine :
				game.hero.setMine();
				res = Res.fx.mine.model;
			case Rocket :
				game.hero.setRocket();
				res = Res.fx.rocket.model;
			case Fuel :
				game.hero.fuel = Math.min(game.hero.fuelMax, game.hero.fuel + 100);
				res = Res.fx.fuel.model;
			case Repair :
				game.hero.life = Math.imin(game.hero.lifeMax, game.hero.life + 100);
				res = Res.fx.repair.model;
			case Speed :
				game.hero.boost = 60 * 10;
				res = Res.fx.speed.model;
		}

		model = game.loadModel(res);
		model.x = x;
		model.y = y;
		for( mat in model.getMaterials()) {
			mat.mainPass.enableLights = true;
			mat.shadows = true;
			mat.mainPass.setPassName("noSAO");
		}
		model.playAnimation(game.anims.get(res.entry.path));
		model.currentAnimation.onAnimEnd = remove;
		game.s3d.addChild(model);
	}

	function bonusSelect() {
		var a = 0;
		var m = 0;
		var f = 0;
		var r = 0;
		var s = 0;
		var rk = 0;


		for(b in game.bonus) {
			switch(b.kind) {
				case Ammo: a++;
				case Mine: m++;
				case Fuel: f++;
				case Repair: r++;
				case Speed: s++;
				case Rocket: rk++;
			}
		}

		var choice = [];
		if(a == 0) choice.push(Ammo);
		if(m == 0) choice.push(Mine);
		if(f == 0) choice.push(Fuel);
		if(r == 0) choice.push(Repair);
		if(s == 0) choice.push(Speed);
		if(rk == 0) choice.push(Rocket);

		if(choice.length == 0)
			choice = [Mine, Rocket, Fuel, Repair, Speed];

		choice.push(Fuel); //add one more
		choice.push(Ammo); //add one more
		choice.push(Repair); //add one more

		return choice[Std.random(choice.length)];
	}

	public function remove() {
		game.bonus.remove(this);
		model.remove();
		model.dispose();
		model = null;
	}

}