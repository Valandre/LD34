package ;
import hxd.Res;
import hxd.Math;
import hxd.Key in K;

class Hero extends Entity
{
	var subRotation = 0.;
	var deadTime = 180.;

	public var fuelMax = 0.;
	public var ammoMax = 0;
	public var fuel = 0.;
	public var ammo = 0;
	public var boost = 0.;
	public var lifeMax = 0;
	public var mine = 0;
	public var rocket = 0;

	var maxSpeedRef = 0.;
	var scale = 1.;
	var ammoId = 0;

	var wmine : h3d.scene.Object;
	var lRocket : Rocket;
	var rRocket : Rocket;

	public var cheat = false;

	public function new(x, y) {
		super(x, y);
		life = lifeMax = 100;
		fuel = fuelMax = 100;
		ammo = ammoMax = 100;

		maxSpeedRef = maxSpeed = 0.04;
		scale = 0.8;

		var a = Res.bolide.anim_run.toHmd().loadAnimation();
		model.playAnimation(a);

		wmine = game.loadModel(Res.mine.model);
		wmine.x = x;
		wmine.y = y;
		wmine.z = 0.3 * model.scaleX;
		game.s3d.addChild(wmine);
		for( mat in wmine.getMaterials()) {
			mat.mainPass.enableLights = true;
			mat.shadows = true;
			if(mat.name == "Mine2") cast(mat, h3d.mat.MeshMaterial).texture = Res.mine.texture.toTexture();
			if(mat.name == "minelight") cast(mat, h3d.mat.MeshMaterial).mainPass.culling = Both;
		}
	}


	public function setMine() {
		mine = 3;
		rocket = 0;
		ammoId = 1;
		game.ui.updateIco(ammoId);
	}


	public function setRocket() {
		rocket = 2;
		mine = 0;
		ammoId = 2;
		game.ui.updateIco(ammoId);

		inline function initRocket(r : Rocket) {
			if(r == null || r.launched)
				return new Rocket(this);
			return r;
		}
		lRocket = initRocket(lRocket);
		rRocket = initRocket(rRocket);
	}

	public function getAmmo() {
		return switch(ammoId) {
			case 0 : ammo;
			case 1 : mine;
			case 2 : rocket;
			default: -1;
		}
	}

	function mecaAttack() {
		if(delay > 0) return;
		delay = 5 - (boost > 0 ? 1 : 0);
		currGun = 1 - currGun;
		new Gun(this, currentRotation, currGun, boost > 0 ? true : false);

		var fx = game.loadModel(Res.fx.rifle.model);
		for( mat in fx.getMaterials()) {
			mat.mainPass.enableLights = true;
			cast(mat, h3d.mat.MeshMaterial).blendMode = Add;
		}

		fx.x = x;
		fx.y = y;
		fx.setScale(model.scaleX);
		fx.setRotate(0, 0, currentRotation);
		fx.playAnimation(game.anims.get(Res.fx.rifle.model.entry.path));
		fx.currentAnimation.speed = 1.5;
		fx.currentAnimation.onAnimEnd = function() {
			fx.remove();
			fxs.remove(fx);
		}
		game.s3d.addChild(fx);
		fxs.push(fx);

		ammo = Math.imax(0, ammo - 1);
	}

	function mineSpawn() {
		game.mines.push(new Mine(this, currentRotation));
		mine--;
		if(mine == 0) {
			ammoId = 0;
			game.ui.updateIco(ammoId);
		}
	}

	function rocketLaunch() {
		rocket--;
		if(lRocket != null && !lRocket.launched) {
			lRocket.launch(currentRotation);
			lRocket = null;
		}
		else if(rRocket != null && !rRocket.launched) {
			rRocket.launch(currentRotation);
			rRocket = null;
		}
		if(rocket == 0) {
			ammoId = 0;
			game.ui.updateIco(ammoId);
		}
	}

	override public function remove() {
		if(model == null) return;
		super.remove();
		if(life <= 0) {
			game.event.wait(3, function() {
				game.credits = Math.imax(0, game.credits - 1);
				if(game.credits > 0)
					game.generate(Std.random(0xFFFFFF));
				else game.gameOver();
			});
		}

		wmine.remove();
	}

	var oldBoost = 0.;
	override public function update(dt : Float) {
		super.update(dt);

		if(isDead())
			return;

		if(!cheat)
			fuel = Math.max(0, fuel - (speed + 0.02) * 0.6 * dt);
		boost -= dt;
		maxSpeed = maxSpeedRef * (boost > 0 ? 1.3 : 1);
		if(fuel <= 0)
			maxSpeed *= 0.5;
		if(boost > 0 && oldBoost < 0)
			speed = maxSpeed * 1.2;
		oldBoost = boost;
		scale = boost > 0 ? 0.95 : 0.8;
		model.setScale(model.scaleX + (scale-model.scaleX) * 0.25 * dt);

		if(K.isDown(K.MOUSE_RIGHT) && canMove)
			speed += (maxSpeed - speed) * 0.03 * dt;
		else if(!isMeca) {
			speed *= Math.pow(0.95, dt);
			if( speed < 0.004)
				speed = 0;
		}


		var da = Math.angle(currentRotation - rotation);
		if(game.mpos != null) rotation = Math.atan2(game.mpos.y - y, game.mpos.x - x);

		model.currentAnimation.speed = Math.max(speed / maxSpeed, da != 0 ? 1 : 0);
		currentRotation = Math.angleMove(currentRotation, rotation, (0.05 + 0.025 * (1 - speed / maxSpeed)) * dt);
		var cos = Math.cos(currentRotation);
		var sin = Math.sin(currentRotation);

		if(canMove || speed != 0) {
			//MOVE
			x += speed * cos;
			y += speed * sin;

			if(!cheat) {
				var c = game.world.collide(x, y, size * 0.5);
				if(c != null) {
					speed *= Math.pow(0.95, dt);
					repell(c.x, c.y, 0.5 + size * 0.5);
					if(Math.abs(Math.angle(currentRotation - Math.atan2(c.y, c.x))) > Math.PI * 0.7) {
						if(speed > 0) speed = Math.min(-0.01, -speed * 0.6);
						else speed = Math.max( 0.01, -speed * 0.6);
					}
				}
			}

			switch(ammoId) {
				case 0:
					if(K.isDown(K.MOUSE_LEFT) && ammo > 0) {
						rifle.currentAnimation.speed = 1.5;
						mecaAttack();
					}
					else {
						rifle.currentAnimation.speed = 0;
						for(fx in fxs)
							fx.remove();
						fxs = [];
					}
				case 1:
					if(K.isPressed(K.MOUSE_LEFT) && mine > 0) {
						mineSpawn();
					}
				case 2:
					if(K.isPressed(K.MOUSE_LEFT) && rocket > 0) {
						rocketLaunch();
					}
			}
		}

		for(f in game.fighters) {
			if(f.isDead()) continue;
			if(Math.distance(f.x - x, f.y - y) < (f.size + size) * 0.5) {
				var dir1 = new h2d.col.Point(cos, sin);
				var dir2 = new h2d.col.Point(Math.cos(f.currentRotation), Math.sin(f.currentRotation));
				var n1 = new h2d.col.Point(f.x - x, f.y - y);
				n1.normalize();
				var n2 = new h2d.col.Point(x - f.x, y - f.y);
				n2.normalize();

				var v1 = dir1.dot(n1);
				var v2 = dir2.dot(n2);
				if(v1 <= 0 && v2 <= 0) continue;

				f.impact = new h2d.col.Point(n1.x * speed * 2 * v1, n1.y * speed * 2 * v1);
				f.speed *= Math.pow(0.1, dt);

				impact = new h2d.col.Point(n2.x * f.speed * 2 * v2, n2.y * f.speed * 2 * v2);
				speed *= Math.pow(0.1, dt);

				repell((x - f.x) * 0.1, (y - f.y) * 0.1, f.size * 0.5 + size * model.scaleX * 0.5);
				f.repell((f.x - x) * 0.1, (f.y - y) * 0.1, size * 0.5 * model.scaleX + f.size * 0.5);
			}
		}

		if(model != null) {
			for(b in game.bonus)
				if(Math.distance(b.model.x - x, b.model.y - y) < 0.5)
					b.loot();


			headlight.x = model.x;
			headlight.y = model.y;
			headlight.setRotate(0, 0, currentRotation);
			headlight.setScale(model.scaleX);

			for(fx in fxs) {
				fx.x = model.x;
				fx.y = model.y;
				fx.setRotate(0, 0, currentRotation);
				fx.setScale(model.scaleX);
			}

			if(rifle != null) {
				rifle.visible = ammoId == 0;
				rifle.x = model.x;
				rifle.y = model.y;
				rifle.setRotate(0, 0, currentRotation);
				rifle.setScale(model.scaleX);
			}
			if(wmine != null ) {
				wmine.visible = ammoId == 1;
				wmine.x = x - 0.1 * cos;
				wmine.y = y - 0.1 * sin;
				wmine.z = 0.3 * model.scaleX;
				wmine.setRotate(0, 0, currentRotation);
				wmine.setScale(model.scaleX * 0.9);
			}

			if(lRocket != null) {
				lRocket.m.visible = ammoId == 2;
				lRocket.m.x = x + 0.1 * Math.cos(currentRotation - Math.PI * 0.5) * model.scaleX - 0.2 * cos;
				lRocket.m.y = y + 0.1 * Math.sin(currentRotation - Math.PI * 0.5) * model.scaleX - 0.2 * sin;
				lRocket.m.z = 0.3 * model.scaleX;
				lRocket.m.setRotate(0, 0, currentRotation);
			}

			if(rRocket != null) {
				rRocket.m.visible = ammoId == 2;
				rRocket.m.x = x + 0.1 * Math.cos(currentRotation + Math.PI * 0.5) * model.scaleX - 0.2 * cos;
				rRocket.m.y = y + 0.1 * Math.sin(currentRotation + Math.PI * 0.5) * model.scaleX - 0.2 * sin;
				rRocket.m.z = 0.3 * model.scaleX;
				rRocket.m.setRotate(0, 0, currentRotation);
			}
		}
	}
}