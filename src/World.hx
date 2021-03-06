package ;
import hxd.Res;
using hxd.Math;

enum MatKind {
	Road;
	Zebra;
	CLight;
	Default;
}

class Element {
	public var modelPath : String;
	public var x : Float;
	public var y : Float;
	public var z : Float;
	public var scale : Float;
	public var rotation : Float;

	public function new(path : String, x, y, z, s, r) {
		this.modelPath = path;
		this.x = x;
		this.y = y;
		this.z = z;
		this.scale = s;
		this.rotation = r;
	}
}

class World extends h3d.scene.World
{
	public var models : Map<String, h3d.scene.World.WorldModel>;
	public var startPoint : h2d.col.Point;
	var map : hxd.Pixels;
	var grid : Array<Int>;
	public var hasZebra : Array<Int>;
	var rnd : hxd.Rand;
	var game : Game;
	public var elements : Map<Int, Array<Element>>;

	public function new( chunkSize : Int, worldSize : Int, ?parent ) {
		super(chunkSize, worldSize, parent);
		game = Game.inst;
		enableSpecular = true;
		models = new Map();
	}

	override function initChunk(c:h3d.scene.World.WorldChunk) {
		addElements(c);
	}

	override function initChunksBounds() {
		var n = Math.ceil(worldSize / chunkSize);
		for(x in 0...n)
			for(y in 0...n) {
				var c = getChunk(x * chunkSize, y * chunkSize, true);

				//add heightmap bounds
				for(dx in 0...chunkSize)
					for(dy in 0...chunkSize)
						c.bounds.addPoint(new h3d.col.Point(c.x + dx, c.y + dy, 0));

				//add elements bounds
				var elts = elements.get(x + y * n);
				if(elts == null) continue;
				for(e in elts) {
					var m = models.get(e.modelPath);
					if( m == null ) continue;
					updateChunkBounds(c, m, e.rotation, e.scale);
				}
			}
	}

	function addElements(c:h3d.scene.World.WorldChunk) {
		var index = Std.int(c.x / chunkSize) + Std.int(c.y / chunkSize) * Math.ceil(worldSize / chunkSize);
		var elts = elements.get(index);
		if(elts == null) return;
		for(e in elts) {
			var m = models.get(e.modelPath);
			if( m == null ) {
				m = getModel(@:privateAccess Res.loader.loadModel(e.modelPath));
				models.set(e.modelPath, m);
			}
			add(m, e.x, e.y, e.z, e.scale, e.rotation);
		}
	}

	function createElement(path : String, x = 0., y = 0., z = 0., scale = 1., rotation = 0.) {
		var index = Std.int(x / chunkSize) + Std.int(y / chunkSize) * Math.ceil(worldSize / chunkSize);
		var c = elements.get(index);
		if(c == null) {
			c = [];
			elements.set(index, c);
		}
		c.push(new Element(path, x, y, z, scale, rotation));
	}

	override function initMaterial( mesh : h3d.scene.Mesh, mat ) {
		super.initMaterial(mesh, mat);
		mesh.material.receiveShadows = true;

		if( mesh.material.specularTexture != null ) {
			mesh.material.specularAmount = 5;
			mesh.material.specularPower = 3;
		}

		if( !mesh.material.shadows )
			return;

		mesh.material.allocPass("depth");
		mesh.material.allocPass("normal");
	}


	function resolveMaterialKind(name : String) {
		name = name.split(".").shift().split("_").shift();
		name = ~/[0-9]+/g.replace(name.split("/").pop(), "");
		return switch(name) {
			case "buildlight" : CLight;
			case "road" : Road;
			case "zebra" : Zebra;
			default : Default;
		}
	}

	function setMaterial(model : h3d.scene.World.WorldModel) {
		var matKind = resolveMaterialKind(model.r.name);
		switch(matKind) {
			case Road:
			case CLight:
					for( g in model.geometries) {
						g.m.blend = Add;
						g.m.shadows = false;
						g.m.updateBits();
					}
			case Zebra:
					for( g in model.geometries) {
						g.m.blend = Add;
						g.m.shadows = false;
						g.m.updateBits();
					}
			case Default:
		}
	}

	public function getModel(r : hxd.res.Model) {
		return getModelPath(r.entry.path);
	}

	function getModelPath( path : String ) {
		var model = models.get(path);
		if(model == null) {
			var r = @:privateAccess Res.loader.loadModel(path);
			model = loadModel(r);
			setMaterial(model);
			models.set(path, model);
		}
		return model;
	}

	function reset() {
		models = new Map();
		elements = new Map();
		dispose();
	}

	public function getFreePos() {
		while(true) {
			var x = rnd.random(worldSize);
			var y = rnd.random(worldSize);

			if(game.hero != null && Math.distance(x - game.hero.x, y - game.hero.y) < 5)
				continue;
			if(grid[x + y * worldSize] == 0)
				return new h2d.col.Point(x, y);
		}
	}

	public function getStartingPoint() {
		var x = Std.int(worldSize * 0.5);
		var y = Std.int(worldSize * 0.5);

		var deep = 1;
		while(deep < worldSize * 0.5) {
			for( i in -deep...deep)
				for( j in -deep...deep) {
					if(Math.abs(i) != deep && Math.abs(j) != deep) continue;
					if(map.getPixel(x + i, y + j) != -1 && map.getPixel(x + i + 1, y + j) != -1 && map.getPixel(x + i, y + j + 1) != -1)
						return new h2d.col.Point(x + i, y + j);
				}
			deep++;
		}

		return new h2d.col.Point(0, 0);
	}

	public function generate(seed) {
		reset();

		map = buildCity(seed);

		//add building on borders
		var index = 0;
		for(x in 0...map.height) {
			if(x <= index) continue;
			index = x;
			var draw = rnd.rand() < 0.15;
			while(map.getPixel(index, 1) == -1) {
				if(draw) map.setPixel(index, 0, -1);
				index++;
			}
		}
		var index = 0;
		for(x in 0...map.height) {
			if(x <= index) continue;
			index = x;
			var draw = rnd.rand() < 0.15;
			while(map.getPixel(index, map.width - 2) == -1) {
				if(draw) map.setPixel(index, map.width - 1, -1);
				index++;
			}
		}
		var index = 0;
		for(y in 0...map.height) {
			if(y <= index) continue;
			index = y;
			var draw = rnd.rand() < 0.15;
			while(map.getPixel(1, index) == -1) {
				if(draw) map.setPixel(0, index, -1);
				index++;
			}
		}
		var index = 0;
		for(y in 0...map.height) {
			if(y <= index) continue;
			index = y;
			var draw = rnd.rand() < 0.15;
			while(map.getPixel(map.width - 2, index) == -1) {
				if(draw) map.setPixel(map.width - 1, index, -1);
				index++;
			}
		}
		//

		inline function isZebraNear(x : Int, y : Int) {
			if(hasZebra[x + y * worldSize] == 1) return true;
			if(hasZebra[x + 1 + y * worldSize] == 1) return true;
			if(hasZebra[x - 1 + y * worldSize] == 1) return true;
			if(hasZebra[x + (y + 1) * worldSize] == 1) return true;
			if(hasZebra[x + (y - 1) * worldSize] == 1) return true;
			return false;
		}

		startPoint = getStartingPoint();

		var citylight = [Res.city.buildlight01, Res.city.buildlight02, Res.city.buildlight03, Res.city.buildlight04];
		var models = [Res.city.build01, Res.city.build02, Res.city.build03, Res.city.build04, Res.city.build01, Res.city.build02, Res.city.tree01, Res.city.tree02, Res.city.tree03, Res.city.tree04, Res.city.tree05, Res.city.tree06];
		var roads = [Res.city.road01, Res.city.road02, Res.city.road03, Res.city.road04, Res.city.road05];

		inline function addBuilding(x: Int, y : Int) {
			var r = rnd.random(models.length);
			if(x - 1 == startPoint.x && y - 1 == startPoint.y)
				r = Math.imax(2, r);
			var rot = r < 6 ? Math.PI * 0.5 * rnd.random(4) : 0;
			createElement(models[r].entry.path, x + 0.5, y + 0.5, 0, 1, rot);
			if(r < citylight.length)
				createElement(citylight[r].entry.path, x + 0.5, y + 0.5, 0, 1, rot);
			var k = r < 6 ? 2 : 1;
			grid[x + y * worldSize] = k;
		}

		inline function addRoad(x: Int, y : Int) {
			var l = x - 1 >= 0 && map.getPixel(x - 1, y) != -1;
			var r = x + 1 < worldSize && map.getPixel(x + 1, y) != -1;
			var u = y - 1 >= 0 && map.getPixel(x, y - 1) != -1;
			var d = y + 1 < worldSize && map.getPixel(x, y + 1) != -1;
			var count = 0;
			if(l) count++;
			if(r) count++;
			if(u) count++;
			if(d) count++;

			var id = 0;
			var rot = 0;
			switch(count) {
				case 0 :
				case 1 :
					id = 4;
					if(r) rot = 0;
					else if(d) rot = 1;
					else if(l) rot = 2;
					else if(u) rot = 3;
				case 2 :
					if((l && r)) {
						id = 0;
						rot = 0;
					}
					else if((u && d)) {
						id = 0;
						rot = 1;
					}
					else if((u && r)) {
						id = 1;
						rot = 0;
					}
					else if((r && d)) {
						id = 1;
						rot = 1;
					}
					else if((d && l)) {
						id = 1;
						rot = 2;
					}
					else if((l && u)) {
						id = 1;
						rot = 3;
					}
				case 3 :
					id = 2;
					if((l && u && r)) {
						rot = 0;
						if(rnd.rand() < 0.2 && !isZebraNear(x, y - 1)) {
							createElement(Res.city.zebra.entry.path, x + 0.5, y - 1 + 0.5, -0.02, 1, Math.PI * 0.5);
							hasZebra[x + (y - 1) * worldSize] = 1;
						}
					}
					else if((u && r && d)) {
						rot = 1;
						if(rnd.rand() < 0.2 && !isZebraNear(x + 1, y)) {
							createElement(Res.city.zebra.entry.path, x + 1 + 0.5, y + 0.5, -0.02, 1, 0);
							hasZebra[x + 1 + y * worldSize] = 1;
						}
					}
					else if((r && d && l)) {
						rot = 2;
						if(rnd.rand() < 0.2 && !isZebraNear(x, y + 1)) {
							createElement(Res.city.zebra.entry.path, x + 0.5, y + 1 + 0.5, -0.02, 1, Math.PI * 0.5);
							hasZebra[x + (y + 1) * worldSize] = 1;
						}
					}
					else if((d && l && u)) {
						rot = 3;
						if(rnd.rand() < 0.2 && !isZebraNear(x - 1, y)) {
							createElement(Res.city.zebra.entry.path, x - 1 + 0.5, y + 0.5, -0.02, 1, 0);
							hasZebra[x - 1 + y * worldSize] = 1;
						}
					}

				case 4:
					id = 3;
					rot = 0;
					if(rnd.rand() < 0.25 && !isZebraNear(x, y - 1)) {
						createElement(Res.city.zebra.entry.path, x + 0.5, y - 1 + 0.5, -0.02, 1, Math.PI * 0.5);
						hasZebra[x + (y - 1) * worldSize] = 1;
					}
					if(rnd.rand() < 0.25 && !isZebraNear(x, y + 1)) {
						createElement(Res.city.zebra.entry.path, x + 0.5, y + 1 + 0.5, -0.02, 1, Math.PI * 0.5);
						hasZebra[x + (y + 1) * worldSize] = 1;
					}
					if(rnd.rand() < 0.25 && !isZebraNear(x + 1, y)) {
						createElement(Res.city.zebra.entry.path, x + 1 + 0.5, y + 0.5, -0.02, 1, 0);
						hasZebra[x + 1 + y * worldSize] = 1;
					}
					if(rnd.rand() < 0.25 && !isZebraNear(x - 1, y)) {
						createElement(Res.city.zebra.entry.path, x - 1 + 0.5, y + 0.5, -0.02, 1, 0);
						hasZebra[x - 1 + y * worldSize] = 1;
					}

				default : throw "not supported";
			}

			if(count == 0)
				addBuilding(x, y);
			else {
				createElement(roads[id].entry.path, x + 0.5, y + 0.5, 0, 1, Math.PI * 0.5 * rot);
				grid[x + y * worldSize] = 0;
			}
		}

		grid = [];
		hasZebra = [];
		for(x in 0...map.width)
			for(y in 0...map.height)
				if(map.getPixel(x, y) == -1)
					addBuilding(x, y);
				else addRoad(x, y);

		initChunksBounds();
	}

	function buildCity(seed) {
		rnd = new hxd.Rand(seed);

		var g = new h2d.Graphics();
		g.beginFill(0);
		g.drawRect(0, 0, worldSize, worldSize);
		g.endFill();


		var n = Std.int((worldSize - 1) / 3);
		g.beginFill(0xFFFFFF);
		for(i in 0...n) {
			g.drawRect(i * 3 + 1, 1, 2, worldSize - 2);
			g.drawRect(1, i * 3 + 1, worldSize - 2, 2);
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

		var tex = new h3d.mat.Texture(worldSize, worldSize, [Target]);
		g.drawTo(tex);
		return tex.capturePixels();
	}

	public function collide(x: Float, y : Float,  ray : Float) {

		if(x < 0.2) return new h2d.col.Point(0.05, 0);
		if(x > worldSize - 0.2) return new h2d.col.Point( -0.05, 0);
		if(y < 0.2) return new h2d.col.Point(0, 0.05);
		if(y > worldSize - 0.2) return new h2d.col.Point(0, -0.05);

		inline function isCollide(px : Int, py : Int) {
			if(grid[px + py * worldSize] == 0) return null;
			var dx = x - (px + 0.5);
			var dy = y - (py + 0.5);
			if(Math.abs(dx) < 0.5 + ray && Math.abs(dy) < 0.5 + ray)
				return new h2d.col.Point((Std.int(x) - Std.int(px)) * Math.abs(dx), (Std.int(y) - Std.int(py)) * Math.abs(dy));
			return null;
		}

		var p = isCollide(Std.int(x + 1), Std.int(y));
		if(p != null) return p;
		var p = isCollide(Std.int(x - 1), Std.int(y));
		if(p != null) return p;
		var p = isCollide(Std.int(x), Std.int(y - 1));
		if(p != null) return p;
		var p = isCollide(Std.int(x), Std.int(y + 1));
		if(p != null) return p;
		return null;
	}

	public function isCollide(x : Float, y : Float, special = false) {
		if(x < 0 || x >= worldSize || y < 0 || y >= worldSize) return true;
		if(special)
			return grid[Std.int(x) + Std.int(y) * worldSize] > 1;
		return grid[Std.int(x) + Std.int(y) * worldSize] != 0;
	}


	override function sync(ctx) {
		for( c in allChunks ) {
			if( !c.initialized) {
				c.initialized = true;
				initChunk(c);
			}
		}
	}
}