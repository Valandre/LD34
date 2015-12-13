package ;
import hxd.Res;
import hxd.Math;

enum BonusKind {
	Ammo;
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

	public function new() {
		game = Game.inst;
		kind = bonusSelect();

		var res = switch(kind) {
			case Ammo : Res.bonus.ammo.model;
			case Fuel : Res.bonus.fuel.model;
			case Repair : Res.bonus.repair.model;
			case Speed : Res.bonus.speed.model;
		}

		model = game.loadModel(res);
		var pos = game.world.getFreePos();
		model.x = pos.x + 0.5;
		model.y = pos.y + 0.5;
		model.playAnimation(game.anims.get(res.entry.path));

		for( mat in model.getMaterials()) {
			mat.mainPass.enableLights = true;
			mat.shadows = true;
			mat.mainPass.setPassName("noSAO");

			switch(mat.name) {
				case "Repair": cast(mat, h3d.mat.MeshMaterial).texture = Res.bonus.repair.texture.toTexture();
				case "Ammo": cast(mat, h3d.mat.MeshMaterial).texture = Res.bonus.ammo.texture.toTexture();
				case "Fuel": cast(mat, h3d.mat.MeshMaterial).texture = Res.bonus.fuel.texture.toTexture();
				case "Speed": cast(mat, h3d.mat.MeshMaterial).texture = Res.bonus.speed.texture.toTexture();
			}
		}
		game.s3d.addChild(model);
		game.bonus.push(this);
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
				game.hero.ammo = Math.imin(game.hero.ammoMax, game.hero.ammo + 150);
				res = Res.fx.speed.model;
			case Fuel :
				game.hero.fuel = Math.min(game.hero.fuelMax, game.hero.fuel + 100);
				res = Res.fx.speed.model;
			case Repair :
				game.hero.life = Math.imin(game.hero.lifeMax, game.hero.life + 100);
				res = Res.fx.speed.model;
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
		var f = 0;
		var r = 0;
		var s = 0;

		for(b in game.bonus) {
			switch(b.kind) {
				case Ammo: a++;
				case Fuel: f++;
				case Repair: r++;
				case Speed: s++;
			}
		}

		var choice = [];
		if(a == 0) choice.push(Ammo);
		if(f == 0) choice.push(Fuel);
		if(r == 0) choice.push(Repair);
		if(s == 0) choice.push(Speed);

		if(choice.length == 0)
			choice = [Ammo, Fuel, Repair, Speed];

		return choice[Std.random(choice.length)];
	}

	public function remove() {
		game.bonus.remove(this);
		model.remove();
		model.dispose();
		model = null;
	}

}