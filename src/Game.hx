import hxd.Math;
import hxd.Key in K;
import hxd.Res;

class Game extends hxd.App {

	public static var inst : Game;
	var world : h3d.scene.Object;
	var citySize = 8;
	var width = 0;
	var grid : hxd.Pixels;

	var camOffset = new h3d.Vector(8, 10, 20);
	var rand : hxd.Rand;

	static function main() {
		hxd.Res.initLocal();
		hxd.res.Resource.LIVE_UPDATE = true;
		inst = new Game();
	}

	override function init() {
		width = 3 * citySize + 1;

		var light = new h3d.scene.DirLight(new h3d.Vector( 0.3, -0.4, -0.9), s3d);
		light.color.set(0.28, 0.28, 0.28);
		s3d.lightSystem.ambientLight.set(0.74, 0.74, 0.74);
		s3d.lightSystem.perPixelLighting = true;

		var cam = s3d.camera;
		cam.target.set(width * 0.5, width * 0.5, 0);
		cam.pos.set(cam.target.x + camOffset.x, cam.target.y + camOffset.y, cam.target.z + camOffset.z);
		cam.fovY = 36;
		cam.zNear = 5;
		cam.zFar = 100;

		world = new h3d.scene.Object(s3d);
		generate(0);
	}

	function generate(seed) {
		while(s2d.numChildren > 0)
			s2d.removeChild(s2d.getChildAt(0));
		while(world.numChildren > 0)
			world.removeChild(world.getChildAt(0));

		setGround();
		grid = buildCity(seed);

		inline function addCube(x: Float, y : Float) {
			var c = new h3d.prim.Cube(1, 1, 0.1);
			c.unindex();
			c.addNormals();
			c.addUVs();
			c.translate( -0.5, -0.5, 0);
			var m = new h3d.scene.Mesh(c, world);
			m.material.mainPass.enableLights = true;
			m.material.color.setColor(0x608A36);
			m.x = x + 0.5;
			m.y = y + 0.5;

			if(rand.rand() < 0.8) {
				var c = new h3d.prim.Cube(0.8, 0.8, 0.5 + 0.5 * rand.random(2));
				c.unindex();
				c.addNormals();
				c.addUVs();
				c.translate( -0.4, -0.4, 0);
				var m = new h3d.scene.Mesh(c, world);
				m.material.mainPass.enableLights = true;
				m.material.color.setColor(0x8CA0A8);
				m.x = x + 0.5;
				m.y = y + 0.5;
			}
		}

		for(x in 0...grid.width)
			for(y in 0...grid.height)
				if(grid.getPixel(x, y) == -1)
					addCube(x, y);

	}

	function buildCity(seed) {
		rand = new hxd.Rand(seed);

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
				var r = rand.random(3);
				if(r == 1 && (x == n - 1 || swapped[x + 1 + y * n] == true)) r = 0;
				if(r == 2 && y == n - 1) r = 0;
				switch(r) {
					case 0:
						if(rand.rand() < 0.8) g.drawRect((x + 1) * 3, y * 3, 1, 4);
						if(rand.rand() < 0.8) g.drawRect(x * 3, (y + 1) * 3, 4, 1);
					case 1:
						var d = rand.random(2) == 0 ? 1 : -1;
						g.drawRect((x + 1) * 3 + d, y * 3, 1, 4);
						g.drawRect(x * 3, (y + 1) * 3, 4, 1);
						if(x < n - 1) {
							if(rand.rand() < 0.8) g.drawRect((x + 2) * 3, y * 3, 1, 4);
							if(rand.rand() < 0.8) g.drawRect((x + 1) * 3, (y + 1) * 3, 4, 1);
						}
						swapped[x + 1 + y * n] = true;
					case 2:
						var d = rand.random(2) == 0 ? 1 : -1;
						g.drawRect((x + 1) * 3, y * 3, 1, 4);
						g.drawRect(x * 3, (y + 1) * 3 + d, 4, 1);
						if(y < n - 1) {
							if(rand.rand() < 0.8) g.drawRect((x + 1) * 3, (y + 1) * 3, 1, 4);
							if(rand.rand() < 0.8) g.drawRect(x * 3, (y + 2) * 3, 4, 1);
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
			prim.addVertexValue(0);

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


		var m = new h3d.scene.Mesh(prim, world);
		m.material.mainPass.enableLights = true;
		m.material.texture = Res.tile.toTexture();
		m.material.texture.wrap = Repeat;
		m.material.shadows = true;
	}


	override function update(dt:Float) {
		super.update(dt);
		var cam = s3d.camera;

		if(K.isDown(K.CTRL) && K.isPressed("F".code))
			engine.fullScreen = !engine.fullScreen;

		if(K.isDown(K.NUMPAD_ADD))
			cam.forward(dt);
		if(K.isDown(K.NUMPAD_SUB))
			cam.backward(dt);

		var a = Math.atan2(cam.target.y - cam.pos.y, cam.target.x - cam.pos.x);
		var d = 0.01 * Math.distance(cam.target.x - cam.pos.x, cam.target.y - cam.pos.y, cam.target.z - cam.pos.z);

		if(K.isDown(K.UP)) {
			cam.target.x += d * Math.cos(a) * dt; cam.target.y += d * Math.sin(a) * dt;
			cam.pos.x += d * Math.cos(a) * dt; cam.pos.y += d * Math.sin(a) * dt;
		}
		else if(K.isDown(K.DOWN)) {
			cam.target.x -= d * Math.cos(a) * dt; cam.target.y -= d* Math.sin(a) * dt;
			cam.pos.x -= d * Math.cos(a) * dt; cam.pos.y -= d* Math.sin(a) * dt;
		}

		if(K.isDown(K.RIGHT)) {
			a += Math.PI * 0.5;
			cam.target.x += d * Math.cos(a) * dt; cam.target.y += d * Math.sin(a) * dt;
			cam.pos.x += d * Math.cos(a) * dt; cam.pos.y += d * Math.sin(a) * dt;
		}
		else if(K.isDown(K.LEFT)) {
			a += Math.PI * 0.5;
			cam.target.x -= d * Math.cos(a) * dt; cam.target.y -= d * Math.sin(a) * dt;
			cam.pos.x -= d * Math.cos(a) * dt; cam.pos.y -= d * Math.sin(a) * dt;
		}

		if(K.isPressed(K.SPACE))
			generate(Std.random(0xFFFFFF));
	}
}