package ;
import hxd.Res;
import hxd.Math;

class Fighter
{
	var game : Game;
	var model : h3d.scene.Object;
	public var x(get, set) : Float;
	public var y(get, set) : Float;
	public var currentRotation(default, set) : Float = 0;
	var rotation = 0.;
	var maxSpeed = 0.04;
	var speed = 0.;
	var size = 0.5;

	var canMove = true;
	var lastCell : h2d.col.Point;
	var targetCell : h2d.col.Point;

	var life = 100;

	public function new(x, y) {
		game = Game.inst;
		model = new h3d.scene.Object(game.s3d);
		model.addChild(getBolide());
		this.x = x;
		this.y = y;
		currentRotation = 0;

		var a = Res.bolide.anim_run.toHmd().loadAnimation();
		model.playAnimation(a);

		targetCell = new h2d.col.Point(Std.int(x), Std.int(y));
		lastCell = new h2d.col.Point(Std.int(x - 1), Std.int(y));
	}

	function get_x() return model.x;
	function set_x(v : Float) return model.x = v;
	function get_y() return model.y;
	function set_y(v : Float) return model.y = v;
	function set_currentRotation(v : Float) {
		model.setRotate(0, 0, v);
		return currentRotation = v;
	}

	public function remove() {
		model.remove();
		model.dispose();
		model = null;
	}

	function getBolide() {
		/*
		var c = new h3d.prim.Cube(size, size * 0.8 , size * 0.6);
		c.unindex();
		c.addNormals();
		c.addUVs();
		c.translate( -size * 0.5, -size * 0.8 * 0.5, 0);
		var m = new h3d.scene.Mesh(c, game.s3d);
		m.material.mainPass.enableLights = true;
		m.material.shadows = true;*/

		var m = game.loadModel(Res.bolide.model);
		for( mat in m.getMaterials()) {
			mat.mainPass.enableLights = true;
			mat.shadows = true;
			cast(mat, h3d.mat.MeshMaterial).texture = Res.bolide.texture02.toTexture();
		}
		return m;
	}

	function repell(dx : Float, dy : Float, r : Float) {
		var d = dx * dx + dy * dy;
		if ( d < r * r * 0.99 ) {
			var r = -(r - Math.sqrt(d));
			dx *= r;
			dy *= r;
			x -= dx;
			y -= dy;
		}
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

	public function update(dt : Float) {
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
			currentRotation = Math.angleMove(currentRotation, rotation, 0.06 * dt);
			x += speed * Math.cos(currentRotation);
			y += speed * Math.sin(currentRotation);

			if(currentRotation == rotation) {
				x += ((targetCell.x + 0.5) - x) * 0.01 * dt;
				y += ((targetCell.y + 0.5) - y) * 0.01 * dt;
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