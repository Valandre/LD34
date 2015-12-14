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

		maxSpeed = 0.03;

		var a = Res.bolide.anim_run.toHmd().loadAnimation();
		model.playAnimation(a);
		model.currentAnimation.speed = 0;

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

	override function getMeca() {
		var m = super.getMeca();
		for( mat in m.getMaterials()) {
			if(mat.name != "Cannon")
				cast(mat, h3d.mat.MeshMaterial).texture = Res.meca.texture02.toTexture();
		}
		oldRot = currentRotation;
		return m;
	}

	public function mecaAttack() {
		if(delay > 0) return;
		delay = 5;
		currGun = 1 - currGun;
		new Gun(this, currentRotation, currGun);
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

	override public function update(dt : Float) {
		super.update(dt);
		if(isDead())
			return;

		sleep -= dt;
		if(sleep > 0) return;

		time -= dt;
		var dist = game.hero == null ? 10000 : Math.distance(game.hero.x - x, game.hero.y - y);
		if(dist < 1 && canMove) time = 0;
		if(time < 0 && canMove && currentRotation == rotation && Math.random() < (dist < 1 ? 0.1 : 0.01)) {
			canMove = false;
			time = 300 + 300 * Math.random();
		}
		if(time < 0 && !canMove && Math.random() < 0.01) {
			if(game.hero != null && !game.hero.isDead() && dist < 5) {
				time += 60;
				return;
			}
			model.getChildAt(0).remove();
			model.addChild(getBolide());
			var a = Res.bolide.anim_run.toHmd().loadAnimation();
			model.playAnimation(a);
			isMeca = false;
			canMove = true;
			time = 300 + 300 * Math.random();
		}

		if(targetCell.x == Std.int(x) && targetCell.y == Std.int(y))
			targetCell = getNextCell();

		if(canMove) {
			if(currentRotation == rotation)
				for(f in game.fighters) {
					if(Std.is(f, this)) continue;
					if(f.isDead()) continue;
					if(Std.int(f.x) == targetCell.x && Std.int(f.y) == targetCell.y) {
						var tmp = targetCell;
						targetCell = lastCell;
						lastCell = targetCell;

						game.event.waitUntil(function(dt) {
							speed = 0;
							if(currentRotation == rotation) return true;
							return false;
						});
						break;
					}

				}
			speed += (maxSpeed - speed) * 0.03 * dt;
		}
		else {
			speed *= Math.pow(0.95, dt);
			if( speed < 0.004)
				speed = 0;
		}

		var da = Math.angle(currentRotation - rotation);
		if(canMove)
			rotation = Math.atan2(targetCell.y - lastCell.y, targetCell.x - lastCell.x);

		if(canMove || speed != 0) {
			//MOVE

			model.currentAnimation.speed = Math.max(speed / maxSpeed, da != 0 ? 1 : 0);
			currentRotation = Math.angleMove(currentRotation, rotation, 0.07 * dt);

			var cos = Math.cos(currentRotation);
			var sin = Math.sin(currentRotation);

			if(dist < 3) {
				var v1 = new h2d.col.Point(game.hero.x - x, game.hero.y - y);
				var v2 = new h2d.col.Point(cos, sin);
				if(v1.dot(v2) > 0.8)
					canMove = false;
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
			var c = game.world.collide(x, y, size * 0.5 * model.scaleX);
			if(c != null) {
				speed *= Math.pow(0.9, dt);
				repell(c.x, c.y, 0.5 + size * 0.5 * model.scaleX);
				if(Math.abs(Math.angle(currentRotation - Math.atan2(c.y, c.x))) > Math.PI * 0.7) {
					if(speed > 0) speed = Math.min(-0.01, -speed * 0.6);
					else speed = Math.max( 0.01, -speed * 0.6);
				}
			}
		}
		else {
			if(!isMeca) {
				isMeca = true;
				model.getChildAt(0).remove();
				model.addChild(getMeca());
				var a = Res.meca.anim_shoot.toHmd().loadAnimation();
				model.playAnimation(a);
				model.currentAnimation.speed = 0;
				rotWait = 60 + 120 * Math.random();
				return;
			}

			currentRotation = Math.angleMove(currentRotation, rotation, 0.05 * dt);

			//ATTACK
			if(dist > 4 || game.hero.isDead()) {
				rotWait -= dt;
				if(rotWait < 0) {
					rotWait = 60 + 120 * Math.random();
					rotation += Math.srand(Math.PI);
				}
			}
			else {
				rotation = Math.atan2(game.hero.y - y, game.hero.x - x);
				if(Math.abs(Math.angle(rotation - currentRotation)) < 0.1)
					mecaAttack();
			}
			/*
			if(K.isDown(K.MOUSE_LEFT)) {
				mecaAttack();
				model.currentAnimation.speed += (1.5 - model.currentAnimation.speed) * 0.25 * dt;
			}
			else model.currentAnimation.speed *= Math.pow(0.9, dt);
			*/
		}
	}
}