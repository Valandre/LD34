package ;
import hxd.Res;
import hxd.Math;
import hxd.Key in K;

class UI
{
	var game : Game;
	var menu : h2d.Sprite;
	var ingame : h2d.Sprite;

	var blackScreen : h2d.Bitmap;

	var buttons : h2d.Sprite;
	var btStart : h2d.Interactive;

	var life : h2d.Sprite;
	var hlife : h2d.Sprite;
	var mlife : h2d.Sprite;

	var armor : h2d.Sprite;
	var fuel : h2d.Sprite;
	var ammo : h2d.Sprite;

	var armorTxt : h2d.Sprite;
	var fuelTxt : h2d.Sprite;
	var ammoTxt : h2d.Sprite;

	var ammoIco : h2d.Bitmap;

	var currArmor = 0;
	var currFuel = 0;
	var currAmmo = 0;
	var currCredits = 0;
	var currMobs = 0;

	var scale = 1.;

	public function new() {
		game = Game.inst;
	}

	function reset() {
		if(ingame != null)
			while(ingame.numChildren > 0)
				ingame.removeChild(ingame.getChildAt(0));
		if(menu != null)
			while(menu.numChildren > 0)
				menu.removeChild(menu.getChildAt(0));
	}

	public function fadeIn(instant = false) {
		if(blackScreen == null)
			blackScreen = new h2d.Bitmap(h2d.Tile.fromColor(0, game.s2d.width, game.s2d.height));
		game.s2d.addChildAt(blackScreen, 10);
		if(!instant) {
			blackScreen.alpha = 0;
			game.event.waitUntil(function(dt) {
				if(blackScreen == null) return true;
				blackScreen.alpha += 0.08 * dt;
				if(blackScreen.alpha >= 1) {
					blackScreen.alpha = 1;
					return true;
				}
				return false;
			});
		}
	}

	public function fadeOut(instant = false) {
		if(blackScreen == null) return;
		if(instant) {
			blackScreen.remove();
			blackScreen = null;
		}
		else {
			game.event.waitUntil(function(dt) {
				if(blackScreen == null) return true;
				blackScreen.alpha -= 0.08 * dt;
				if(blackScreen.alpha <= 0) {
					blackScreen.remove();
					blackScreen = null;
					return true;
				}
				return false;
			});
		}
	}

	public function setMenu() {
		reset();
		menu = new h2d.Sprite(game.s2d);
		var t = Res.UI.title.toTile();
		var title = new h2d.Bitmap(t, menu);
		title.x = 50; title.y = 50;

		buttons = new h2d.Sprite(menu);

		var t = Res.UI.bt_controls.toTile();
		var help = new h2d.Bitmap(t, buttons);
		help.blendMode = Alpha;
		help.x = -t.width; help.y = -t.height;

		var t = Res.UI.bt_credits.toTile();
		var credits = new h2d.Bitmap(t, buttons);
		credits.blendMode = Alpha;
		credits.x = -t.width; credits.y = help.y - 100;

		var t = Res.UI.bt_start.toTile();
		var start = new h2d.Bitmap(t, buttons);
		start.blendMode = Alpha;
		start.x = -t.width; start.y = credits.y - 100;

		btStart = new h2d.Interactive(t.width, t.height, buttons);
		btStart.x = start.x; btStart.y = start.y;
		btStart.onOver = function(e : hxd.Event) {
			start.colorAdd = new h3d.Vector(200, 200, 200);
			start.alpha = 0.9;
			var cpt = 0.;
			game.event.waitUntil(function(dt) {
				if(start.colorAdd == null)
					return true;
				if(cpt > 3) {
					start.colorAdd.x = 200 - start.colorAdd.x;
					start.colorAdd.y = 200 - start.colorAdd.y;
					start.colorAdd.z = 200 - start.colorAdd.z;
					start.alpha = start.alpha == 1 ? 0.9 : 1;
					cpt = 0;
				}
				cpt += dt;
				return false;
			});
		}
		btStart.onOut = function(e : hxd.Event) {
			start.colorAdd = null;
			start.alpha = 1;
		}
		btStart.onClick = function(e : hxd.Event) {
			game.start();
		}

		onResize();
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
		var tile = Res.UI.counter_repair.toTile();
		var ico = new h2d.Bitmap(tile, armor);
		ico.x -= 5; ico.y -= 2;
		armorTxt = new h2d.Sprite(armor);
		armorTxt.x = 70; armorTxt.y = 10;
		setValue(game.hero.life, armorTxt);

		fuel = new h2d.Sprite(ingame);
		var tile = Res.UI.counter_bg.toTile();
		var bg = new h2d.Bitmap(tile, fuel);
		var tile = Res.UI.counter_fuel.toTile();
		var ico = new h2d.Bitmap(tile, fuel);
		ico.y -= 14;
		fuelTxt = new h2d.Sprite(fuel);
		fuelTxt.x = armorTxt.x; fuelTxt.y = armorTxt.y;
		setValue(Math.ceil(game.hero.fuel), fuelTxt);

		ammo = new h2d.Sprite(ingame);
		var tile = Res.UI.counter_bg.toTile();
		var bg = new h2d.Bitmap(tile, ammo);
		var tile = Res.UI.counter_ammo.toTile();
		ammoIco = new h2d.Bitmap(tile, ammo);
		ammoIco.y -= 5;
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
		if(v == -1) {
			var t = Res.UI.counter_infinite.toTile();
			var bg = new h2d.Bitmap(t, s);
			return;
		}
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
		//scale = game.s2d.height / 1080;
		//trace(scale);

		if(ingame != null) {
			life.x = game.s2d.width * 0.5;
			life.y = 30;
			ammo.x = 60;
			ammo.y = game.s2d.height - 150;
			fuel.x = ammo.x;
			fuel.y = ammo.y - 70;
			armor.x = fuel.x;
			armor.y = fuel.y - 70;
		}

		if(menu != null) {
			buttons.x = game.s2d.width - 400;
			buttons.y = game.s2d.height - 150;
		}
	}

	public function updateIco(v : Int) {
		ammoIco.remove();
		var tile = switch(v) {
			case 0:	Res.UI.counter_ammo.toTile();
			case 1:	Res.UI.counter_mine.toTile();
			case 2:	Res.UI.counter_rocket.toTile();
			default: null;
		}
		ammoIco = new h2d.Bitmap(tile, ammo);
		ammoIco.y -= 5;
	}


	public function update(dt : Float) {

		if(game.hero == null) return;

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
		if(currAmmo != game.hero.getAmmo()) {
			while(ammoTxt.numChildren > 0)
				ammoTxt.getChildAt(0).remove();
			currAmmo = game.hero.getAmmo();
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