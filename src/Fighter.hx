package ;
import hxd.Res;
import hxd.Math;

class Fighter extends Entity
{
	var lastCell : h2d.col.Point;
	var targetCell : h2d.col.Point;

	var time = 0.;
	var sleep = 180.;
	var rotWait = 0.;

	public function new(x, y) {
		super(x, y);
		life = 20;

		maxSpeed = 0.04;

		var a = Res.bolide.anim_run.toHmd().loadAnimation();
		model.playAnimation(a);
		model.currentAnimation.speed = 0;
		model.setScale(0.8);

		lastCell = targetCell = new h2d.col.Point(Std.int(x), Std.int(y));
		targetCell = getNextCell();
		currentRotation = Math.atan2(targetCell.y - Std.int(y), targetCell.x - Std.int(x));

		time = 300 + 300 * Math.random();
	}

	override public function remove() {
		super.remove();
		game.fighters.remove(this);
	}

	override function getBolide() {
		var m = super.getBolide();
		for( mat in m.getMaterials())
			cast(mat, h3d.mat.MeshMaterial).texture = Res.bolide.texture02.toTexture();
		currentRotation = rotation = oldRot;
		return m;
	}

	public function mecaAttack() {
		if(delay > 0) return;
		delay = 5;
		currGun = 1 - currGun;
		new Gun(this, currentRotation, currGun);
		currGun = 1 - currGun;
		new Gun(this, currentRotation, currGun);

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

	}

	function getNextCell() {
		var cells = [];
		var p = new h2d.col.Point(targetCell.x + 1, targetCell.y);
		if((lastCell.x != p.x || lastCell.y != p.y) && !game.world.isCollide(p.x, p.y))
			cells.push(p);
		var p = new h2d.col.Point(targetCell.x - 1, targetCell.y);
		if((lastCell.x != p.x || lastCell.y != p.y) && !game.world.isCollide(p.x, p.y))
			cells.push(p);
		var p = new h2d.col.Point(targetCell.x, targetCell.y + 1);
		if((lastCell.x != p.x || lastCell.y != p.y) && !game.world.isCollide(p.x, p.y))
			cells.push(p);
		var p = new h2d.col.Point(targetCell.x, targetCell.y - 1);
		if((lastCell.x != p.x || lastCell.y != p.y) && !game.world.isCollide(p.x, p.y))
			cells.push(p);

		if(cells.length == 0)
			cells.push(lastCell);
		lastCell = targetCell;
		return cells[Std.random(cells.length)];
	}

	var addRot = 0.;
	override public function update(dt : Float) {
		super.update(dt);
		if(isDead())
			return;

		sleep -= dt;
		if(sleep > 0) return;

		time -= dt;
		var dist = game.hero == null ? 10000 : Math.distance(game.hero.x - x, game.hero.y - y);

		if(targetCell.x == Std.int(x) && targetCell.y == Std.int(y))
			targetCell = getNextCell();

		if(canMove) {
			speed += (maxSpeed - speed) * 0.03 * dt;
		}
		else {
			speed *= Math.pow(0.95, dt);
			if( speed < 0.004)
				speed = 0;
		}

		var da = Math.angle(currentRotation - rotation);
		model.currentAnimation.speed = Math.max(speed / maxSpeed, da != 0 ? 1 : 0);
		rotation = Math.atan2(targetCell.y - lastCell.y, targetCell.x - lastCell.x);
		addRot = Math.max(0, addRot - 0.025 * dt);
		rotation += addRot;
		currentRotation = Math.angleMove(currentRotation, rotation, 0.07 * dt);

		if(currentRotation == rotation)
			for(f in game.fighters) {
				if(f == this) continue;
				if(f.isDead()) continue;
				if(Std.int(f.x) == targetCell.x && Std.int(f.y) == targetCell.y) {
					addRot = 0.3;
/*
					var tmp = targetCell;
					targetCell = lastCell;
					lastCell = targetCell;

					game.event.waitUntil(function(dt) {
						speed = 0;
						if(currentRotation == rotation) return true;
						return false;
					});*/
					break;
				}

			}

		var cos = Math.cos(currentRotation);
		var sin = Math.sin(currentRotation);

		if(dist < 5 && rotation == currentRotation && (Std.int(x) == Std.int(game.hero.x) || Std.int(y) == Std.int(game.hero.y))) {
			var v1 = new h2d.col.Point(game.hero.x - x, game.hero.y - y);
			v1.normalize();
			var v2 = new h2d.col.Point(cos, sin);
			if(v1.dot(v2) > 0.99) {
				mecaAttack();
				if(dist < 1)
					speed *= Math.pow(0.9, dt);
			}
		}

		x += speed * cos;
		y += speed * sin;

		if(currentRotation == rotation) {
			var r = currentRotation / Math.PI;
			var dx = 1.;
			var dy = 1.;
			switch(r) {
				case 0, 1 : dx = 0.;
				default : dy = 0.;
			}
			x += ((targetCell.x + 0.5) - x) * 0.01 * dt * dx;
			y += ((targetCell.y + 0.5) - y) * 0.01 * dt * dy;
		}
		var c = game.world.collide(x, y, size * 0.5);
		if(c != null) {
			speed *= Math.pow(0.9, dt);
			repell(c.x, c.y, 0.5 + size * 0.5);
			if(Math.abs(Math.angle(currentRotation - Math.atan2(c.y, c.x))) > Math.PI * 0.7) {
				if(speed > 0) speed = Math.min(-0.01, -speed * 0.6);
				else speed = Math.max( 0.01, -speed * 0.6);
			}
		}

	//
		headlight.x = model.x;
		headlight.y = model.y;
		headlight.setRotate(0, 0, currentRotation);
		headlight.setScale(model.scaleX);

		rifle.x = model.x;
		rifle.y = model.y;
		rifle.setRotate(0, 0, currentRotation);
		rifle.setScale(model.scaleX);

		for(fx in fxs) {
			fx.x = model.x;
			fx.y = model.y;
			fx.setRotate(0, 0, currentRotation);
			fx.setScale(model.scaleX);
		}
	}
}