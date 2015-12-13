package ;
import hxd.Res;
import hxd.Math;

class UI
{
	var game : Game;
	var ingame : h2d.Sprite;
	var life : h2d.Sprite;
	var hlife : h2d.Sprite;
	var mlife : h2d.Sprite;

	var armor : h2d.Sprite;
	var fuel : h2d.Sprite;
	var ammo : h2d.Sprite;

	var armorTxt : h2d.Sprite;
	var fuelTxt : h2d.Sprite;
	var ammoTxt : h2d.Sprite;

	var currArmor = 0;
	var currFuel = 0;
	var currAmmo = 0;
	var currCredits = 0;
	var currMobs = 0;

	public function new() {
		game = Game.inst;
	}

	function reset() {
		if(ingame != null)
			while(ingame.numChildren > 0)
				ingame.removeChild(ingame.getChildAt(0));
	}

	public function init() {
		reset();

		ingame = new h2d.Sprite(game.s2d);

		life = new h2d.Sprite(ingame);
		var tile = Res.UI.life_bg.toTile();
		var bg = new h2d.Bitmap(tile, life);
		bg.x = -tile.width * 0.5;

		hlife = new h2d.Sprite(life);
		hlife.x = -210; hlife.y = 20;
		setBigValue(game.credits, hlife);

		mlife = new h2d.Sprite(life);
		mlife.x = 210; mlife.y = 20;
		setBigValue(game.fighters.length, mlife);

		armor = new h2d.Sprite(ingame);
		var tile = Res.UI.counter_bg.toTile();
		var bg = new h2d.Bitmap(tile, armor);
		armorTxt = new h2d.Sprite(armor);
		armorTxt.x = 70; armorTxt.y = 10;
		setValue(game.hero.life, armorTxt);

		fuel = new h2d.Sprite(ingame);
		var tile = Res.UI.counter_bg.toTile();
		var bg = new h2d.Bitmap(tile, fuel);
		var tile = Res.UI.counter_fuel.toTile();
		var ico = new h2d.Bitmap(tile, fuel);
		ico.y -= 8;
		fuelTxt = new h2d.Sprite(fuel);
		fuelTxt.x = armorTxt.x; fuelTxt.y = armorTxt.y;
		setValue(Math.ceil(game.hero.fuel), fuelTxt);

		ammo = new h2d.Sprite(ingame);
		var tile = Res.UI.counter_bg.toTile();
		var bg = new h2d.Bitmap(tile, ammo);
		var tile = Res.UI.counter_ammo.toTile();
		var ico = new h2d.Bitmap(tile, ammo);
		ico.y -= 5;
		ammoTxt = new h2d.Sprite(ammo);
		ammoTxt.x = armorTxt.x; ammoTxt.y = armorTxt.y;
		setValue(game.hero.ammo, ammoTxt);

		onResize();
	}


	function setBigValue(v:Int, s : h2d.Sprite) {
		var t = getLifeTile(v);
		var bg = new h2d.Bitmap(t, s);
		bg.x = -t.width * 0.5;
	}

	function setValue(v:Int, s : h2d.Sprite) {
		var nums = Std.string(v).split("");
		var tiles = [for(e in nums) getCounterTile(Std.parseInt(e))];
		var dx = 0.;
		for(i in 0...tiles.length) {
			var t = tiles[i];
			var bg = new h2d.Bitmap(t, s);

			if(i != 0 && nums[i] == "1") dx += 8;
			else if(nums[i] == "4") dx += 4;
			else if(nums[i] == "7") dx += 8;

			bg.x = dx;
			dx += t.width - 22;
		}
	}

	function getCounterTile(v : Int) {
		return Res.load("UI/counter_" + v + ".png").toTile();
	}

	function getLifeTile(v : Int) {
		return Res.load("UI/life_" + v + ".png").toTile();
	}

	public function onResize() {
		if(life != null) {
			life.x = game.s2d.width * 0.5;
			life.y = 30;
		}
		if(ammo != null) {
			ammo.x = 60;
			ammo.y = game.s2d.height - 150;
		}
		if(fuel != null) {
			fuel.x = ammo.x;
			fuel.y = ammo.y - 70;
		}
		if(armor != null) {
			armor.x = fuel.x;
			armor.y = fuel.y - 70;
		}
	}

	public function update(dt : Float) {
		if(currArmor != game.hero.life) {
			while(armorTxt.numChildren > 0)
				armorTxt.getChildAt(0).remove();
			currArmor = game.hero.life;
			setValue(currArmor, armorTxt);
		}
		if(currFuel != Math.ceil(game.hero.fuel)) {
			while(fuelTxt.numChildren > 0)
				fuelTxt.getChildAt(0).remove();
			currFuel = Math.ceil(game.hero.fuel);
			setValue(currFuel, fuelTxt);
		}
		if(currAmmo != game.hero.ammo) {
			while(ammoTxt.numChildren > 0)
				ammoTxt.getChildAt(0).remove();
			currAmmo = game.hero.ammo;
			setValue(currAmmo, ammoTxt);
		}

		if(currCredits != game.credits) {
			while(hlife.numChildren > 0)
				hlife.getChildAt(0).remove();
			currCredits = game.credits;
			setBigValue(currCredits, hlife);
		}

		if(currMobs != game.fighters.length) {
			while(mlife.numChildren > 0)
				mlife.getChildAt(0).remove();
			currMobs = game.fighters.length;
			setBigValue(currMobs, mlife);
		}
	}

}