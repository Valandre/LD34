package ;
import hxd.Res;
import hxd.Math;
import hxd.Key in K;

class Hero extends Entity
{
	var subRotation = 0.;
	var deadTime = 180.;

	public var credits = 3;
	public var fuel = 100.;
	public var ammo = 150;

	public function new(x, y) {
		super(x, y);
		life = 100;
		var a = Res.bolide.anim_run.toHmd().loadAnimation();
		model.playAnimation(a);
	}

	public function mecaAttack() {
		if(delay > 0) return;
		delay = 5;
		currGun = 1 - currGun;
		new Gun(this, currentRotation, currGun);
		ammo = Math.imax(0, ammo - 1);
	}

	override public function remove() {
		if(model == null) return;
		super.remove();
		if(life <= 0) {
			game.event.wait(3, function() {
				game.generate(Std.random(0xFFFFFF));
			});
		}
	}

	override public function update(dt : Float) {
		super.update(dt);

		if(isDead())
			return;

		fuel -= (speed + 0.01) * 0.5 * dt;

		if(K.isPressed(K.MOUSE_RIGHT)) {
			canMove = !canMove;
			if(canMove) {
				model.getChildAt(0).remove();
				model.addChild(getBolide());
				var a = Res.bolide.anim_run.toHmd().loadAnimation();
				model.playAnimation(a);
				isMeca = false;
			}
		}
		if(K.isDown(K.MOUSE_LEFT) && canMove)
			speed += (maxSpeed - speed) * 0.03 * dt;
		else if(!isMeca) {
			speed *= Math.pow(0.95, dt);
			if( speed < 0.004)
				speed = 0;
		}


		var da = Math.angle(currentRotation - rotation);
		if(game.mpos != null) rotation = Math.atan2(game.mpos.y - y, game.mpos.x - x);

		if(canMove || speed != 0) {
			//MOVE
			model.currentAnimation.speed = Math.max(speed / maxSpeed, da != 0 ? 1 : 0);
			currentRotation = Math.angleMove(currentRotation, rotation, (0.05 + 0.025 * (1 - speed / maxSpeed)) * dt);
			x += speed * Math.cos(currentRotation);
			y += speed * Math.sin(currentRotation);

			var c = game.world.collide(x, y, size * 0.5 * model.scaleX);
			if(c != null) {
				speed *= Math.pow(0.95, dt);
				repell(c.x, c.y, 0.5 + size * 0.5 * model.scaleX);
				if(Math.abs(Math.angle(currentRotation - Math.atan2(c.y, c.x))) > Math.PI * 0.7) {
					if(speed > 0) speed = Math.min(-0.01, -speed * 0.6);
					else speed = Math.max( 0.01, -speed * 0.6);
				}
			}
		}
		else {
			currentRotation = Math.angleMove(currentRotation, rotation, 0.2 * dt);
			if(!isMeca) {
				isMeca = true;
				model.getChildAt(0).remove();
				model.addChild(getMeca());
				var a = Res.meca.anim_shoot.toHmd().loadAnimation();
				model.playAnimation(a);
				model.currentAnimation.speed = 0;
			}
			//ATTACK
			if(K.isDown(K.MOUSE_LEFT)) {
				mecaAttack();
				model.currentAnimation.speed += (1.5 - model.currentAnimation.speed) * 0.25 * dt;
			}
			else model.currentAnimation.speed *= Math.pow(0.9, dt);

		}

		for(f in game.fighters) {
			if(f.isDead()) continue;
			if(Math.distance(f.x - x, f.y - y) < (f.size + size) * 0.5) {
				var dir1 = new h2d.col.Point(Math.cos(currentRotation), Math.sin(currentRotation));
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

				repell((x - f.x) * 0.1, (y - f.y) * 0.1, f.size * 0.5 + size * 0.5);
				f.repell((f.x - x) * 0.1, (f.y - y) * 0.1, size * 0.5 + f.size * 0.5);
			}
		}
	}
}