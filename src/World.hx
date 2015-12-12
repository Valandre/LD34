package ;
import hxd.Res;
import hxd.Math;

class World
{
	var game : Game;
	var width : Int;
	var root : h3d.scene.Object;
	var grid : hxd.Pixels;
	var rnd : hxd.Rand;
	public var startPoint : h2d.col.Point;

	public function new(width) {
		game = Game.inst;
		this.width = width;

		root = new h3d.scene.Object(game.s3d);
	}

	function reset() {
		while(root.numChildren > 0) {
			var o = root.getChildAt(0);
			o.remove();
			o.dispose();
			o = null;
		}
	}

	public function getStartingPoint() {
		var x = Std.int(width * 0.5);
		var y = Std.int(width * 0.5);

		var deep = 1;
		while(deep < width * 0.5) {
			for( i in -deep...deep)
				for( j in -deep...deep) {
					if(Math.abs(i) != deep && Math.abs(j) != deep) continue;
					if(grid.getPixel(x + i, y + j) != -1 && grid.getPixel(x + i + 1, y + j) != -1 && grid.getPixel(x + i, y + j + 1) != -1)
						return new h2d.col.Point(x + i, y + j);
				}
			deep++;
		}

		return new h2d.col.Point(0, 0);
	}

	public function generate(seed) {
		reset();

		setGround();
		grid = buildCity(seed);
		startPoint = getStartingPoint();

		var models = [Res.city.build01, Res.city.build01, Res.city.tree01];

		inline function addBuilding(x: Float, y : Float) {
			var r = rnd.random(models.length);
			if(x - 1 == startPoint.x && y - 1 == startPoint.y)
				r = Math.imax(2, r);
			var m = game.loadModel(models[r]);
			m.x = x + 0.5;
			m.y = y + 0.5;
			if(r < 2)
				m.setRotate(0, 0, Math.PI * 0.5 * rnd.random(4));
			root.addChild(m);
		}

		for(x in 0...grid.width)
			for(y in 0...grid.height)
				if(grid.getPixel(x, y) == -1)
					addBuilding(x, y);
	}

	function buildCity(seed) {
		rnd = new hxd.Rand(seed);

		var g = new h2d.Graphics();
		g.beginFill(0);
		g.drawRect(0, 0, width, width);
		g.endFill();


		var n = Std.int((width - 1) / 3);
		g.beginFill(0xFFFFFF);
		for(i in 0...n) {
			g.drawRect(i * 3 + 1, 1, 2, width - 2);
			g.drawRect(1, i * 3 + 1, width - 2, 2);
		}
		g.endFill();

		var swapped = [];
		g.beginFill(0);
		for(y in 0...n)
			for(x in 0...n) {
				if(swapped[x + y * n] == true) continue;
				swapped[x + y * n] = true;
				var r = rnd.random(3);
				if(r == 1 && (x == n - 1 || swapped[x + 1 + y * n] == true)) r = 0;
				if(r == 2 && y == n - 1) r = 0;
				switch(r) {
					case 0:
						if(rnd.rand() < 0.8) g.drawRect((x + 1) * 3, y * 3, 1, 4);
						if(rnd.rand() < 0.8) g.drawRect(x * 3, (y + 1) * 3, 4, 1);
					case 1:
						var d = rnd.random(2) == 0 ? 1 : -1;
						g.drawRect((x + 1) * 3 + d, y * 3, 1, 4);
						g.drawRect(x * 3, (y + 1) * 3, 4, 1);
						if(x < n - 1) {
							if(rnd.rand() < 0.8) g.drawRect((x + 2) * 3, y * 3, 1, 4);
							if(rnd.rand() < 0.8) g.drawRect((x + 1) * 3, (y + 1) * 3, 4, 1);
						}
						swapped[x + 1 + y * n] = true;
					case 2:
						var d = rnd.random(2) == 0 ? 1 : -1;
						g.drawRect((x + 1) * 3, y * 3, 1, 4);
						g.drawRect(x * 3, (y + 1) * 3 + d, 4, 1);
						if(y < n - 1) {
							if(rnd.rand() < 0.8) g.drawRect((x + 1) * 3, (y + 1) * 3, 1, 4);
							if(rnd.rand() < 0.8) g.drawRect(x * 3, (y + 2) * 3, 4, 1);
						}
						swapped[x + (y + 1) * n] = true;
				}
			}

		g.endFill();

		var tex = new h3d.mat.Texture(width, width, [Target]);
		g.drawTo(tex);
		return tex.capturePixels();
	}

	function setGround() {
		var prim = new h3d.prim.BigPrimitive(8);

		inline function addVertice(x : Float, y : Float) {
			prim.addVertexValue(x);
			prim.addVertexValue(y);
			prim.addVertexValue(-0.01);

			prim.addVertexValue(0);
			prim.addVertexValue(0);
			prim.addVertexValue(1);

			prim.addVertexValue(x);
			prim.addVertexValue(y);
		}

		prim.begin(0);

		var w = width;
		for(y in 0...w + 1 )
			for(x in 0...w + 1 )
				addVertice(x, y);

		for(y in 0...w )
			for(x in 0...w ) {
				var i = x + y * (w + 1);
				prim.addIndex(i);
				prim.addIndex(i + 1);
				prim.addIndex(i + w + 2);
				prim.addIndex(i);
				prim.addIndex(i + w + 2);
				prim.addIndex(i + w + 1);
			}

		prim.flush();


		var m = new h3d.scene.Mesh(prim, root);
		m.material.mainPass.enableLights = true;
		m.material.texture = Res.city.groun01.toTexture();
		m.material.texture.wrap = Repeat;
		m.material.shadows = true;
	}

	public function update(dt : Float) {

	}

}