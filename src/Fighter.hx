package ;
import hxd.Res;
import hxd.Math;

class Fighter extends Entity
{
	var rotation = 0.;
	var maxSpeed = 0.03;
	var speed = 0.;
	var size = 0.5;

	var canMove = true;
	var lastCell : h2d.col.Point;
	var targetCell : h2d.col.Point;

	public function new(x, y) {
		super(x, y);
		life = 100;

		var a = Res.bolide.anim_run.toHmd().loadAnimation();
		model.playAnimation(a);

		targetCell = new h2d.col.Point(Std.int(x), Std.int(y));
		lastCell = new h2d.col.Point(Std.int(x - 1), Std.int(y));
	}

	override public function remove() {
		super.remove();
		game.fighters.remove(this);
	}

	override function getBolide() {
		var m = super.getBolide();
		for( mat in m.getMaterials())
			cast(mat, h3d.mat.MeshMaterial).texture = Res.bolide.texture02.toTexture();
		return m;
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
		if(targetCell.x == Std.int(x) && targetCell.y == Std.int(y))
			targetCell = getNextCell();

		if(canMove)
			speed += (maxSpeed - speed) * 0.03 * dt;
		else {
			speed *= Math.pow(0.95, dt);
			if( speed < 0.004)
				speed = 0;
		}

		var da = Math.angle(currentRotation - rotation);
		model.currentAnimation.speed = Math.max(speed / maxSpeed, da != 0 ? 1 : 0);

		if(canMove)
			rotation = Math.atan2(targetCell.y - lastCell.y, targetCell.x - lastCell.x);

		if(canMove || speed != 0) {
			//MOVE
			currentRotation = Math.angleMove(currentRotation, rotation, 0.07 * dt);
			x += speed * Math.cos(currentRotation);
			y += speed * Math.sin(currentRotation);

			if(currentRotation == rotation) {
				var r = currentRotation / Math.PI;
				var dx = 0.;
				var dy = 0.;
				/*switch(r) {
					case 0 : dy = 0.25;
					case 1 : dy = -0.25;
					case 0.5 : dx = -0.25;
					case -0.5 : dx = 0.25;
				}*/
				//x += ((targetCell.x + 0.5 + dx) - x) * 0.01 * dt;
				//y += ((targetCell.y + 0.5 + dy) - y) * 0.01 * dt;
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
			//ATTACK
		}
	}
}