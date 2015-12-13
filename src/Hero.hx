package ;
import hxd.Res;
import hxd.Math;
import hxd.Key in K;

class Hero extends Entity
{
	var rotation = 0.;
	var subRotation = 0.;
	var maxSpeed = 0.05;
	var speed = 0.;
	var size = 0.5;


	var canMove = true;
	var isMeca = false;
	var delay = 0.;
	var currGun = 0;

	public function new(x, y) {
		super(x, y);
		life = 250;
		var a = Res.bolide.anim_run.toHmd().loadAnimation();
		model.playAnimation(a);
	}

	public function mecaAttack() {
		if(delay > 0) return;
		delay = 5;
		currGun = 1 - currGun;
		new Gun(this, currentRotation, currGun);
	}

	override public function update(dt : Float) {
		super.update(dt);
		delay -= dt;

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
		//subRotation += ( -da * 0.8 - subRotation) * Math.min(1, (0.05 + 0.5 * (1 - speed / maxSpeed)) * dt);
		//model.getChildAt(0).setRotate(0, 0, subRotation);
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
	}
}