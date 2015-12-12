import hxd.Math;
import hxd.Key in K;
import hxd.Res;

class Game extends hxd.App {

	public static var inst : Game;
	public var world : World;
	public var hero : Hero;
	public var fighters : Array<Fighter>;
	var citySize = 8;
	var width = 0;

	var camOffset : h3d.Vector;

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

		resetCamOffset();
		var cam = s3d.camera;
		cam.target.set(width * 0.5, width * 0.5, 0);
		cam.pos.set(cam.target.x + camOffset.x, cam.target.y + camOffset.y, cam.target.z + camOffset.z);
		cam.fovY = 36;
		cam.zNear = 5;
		cam.zFar = 100;

		generate(0);
	}

	function resetCamOffset() {
		camOffset = new  h3d.Vector(4, 6, 9);
		if(hero != null) {
			s3d.camera.target.x = hero.x;
			s3d.camera.target.y = hero.y;
		}
	}

	function generate(seed) {
		if(world == null)
			world = new World(width);
		world.generate(seed);

		var p = world.startPoint;
		var cam = s3d.camera;
		cam.target.x = p.x + 0.5;
		cam.target.y = p.y + 0.5;

		if( hero != null) hero.remove();
		hero = new Hero(p.x + 0.5, p.y + 0.5);

		if(fighters == null)
			fighters = [];
		for( f in fighters)
			f.remove();
	}

	public function loadModel( m : hxd.res.Model ) {
		var lib = m.toHmd();
		var e = lib.makeObject(loadTexture.bind(m.entry.path));
		for( m in e.getMaterials()) {
			m.mainPass.enableLights = true;
			m.addPass(new h3d.mat.Pass("depth", m.mainPass));
			m.addPass(new h3d.mat.Pass("normal", m.mainPass));
			cast(m, h3d.mat.MeshMaterial).shadows = true;
		}
		return e;
	}

	function loadTexture( modelPath : String, texPath : String ) {
		var t : h3d.mat.Texture;

		try {
			t = Res.load(texPath).toTexture();
		} catch( e : hxd.res.NotFound ) {
			var s1 = modelPath.split("/");
			s1.pop();
			var s2 = texPath.split("/");
			texPath = "";
			for (s in s1) texPath += s + "/";
			texPath += s2[s2.length - 1];
			t = Res.load(texPath).toTexture();
		}

		if(t != null)
			t.wrap = Repeat;
		return t;
	}

	public function getMousePicker() {
		var mx = s2d.mouseX;
		var my = s2d.mouseY;
		var cam = s3d.camera;
		var p = new h2d.col.Point( -1 + 2 * mx / s2d.width, 1 - 2 * my / s2d.height);
		var pn = cam.unproject(p.x, p.y, 0);
		var pf = cam.unproject(p.x, p.y, 1);
		var pMin = pn;
		var pMax = pf;
		var dir = pMax.sub(pMin);
		dir.normalize();
		dir.scale3(0.01);
		while( pMin.sub(pMax).dot3(dir) < 0 ) {
			if( pMin.z < 0)	return pMin;
			pMin.x += dir.x;
			pMin.y += dir.y;
			pMin.z += dir.z;
		}
		return null;
	}

	function keys(dt : Float) {
		var cam = s3d.camera;

		if(K.isDown(K.CTRL) && K.isPressed("F".code))
			engine.fullScreen = !engine.fullScreen;

		if(K.isDown(K.NUMPAD_ADD)) {
			camOffset.x *= 0.95;
			camOffset.y *= 0.95;
			camOffset.z *= 0.95;
		}
		if(K.isDown(K.NUMPAD_SUB)) {
			camOffset.x *= 1.05;
			camOffset.y *= 1.05;
			camOffset.z *= 1.05;
		}

		if(K.isPressed(K.BACKSPACE))
			resetCamOffset();

		if(hero != null) {
			cam.target.x = hero.x;
			cam.target.y = hero.y;
		}
		var a = Math.atan2(cam.target.y - cam.pos.y, cam.target.x - cam.pos.x);
		var d = 0.01 * Math.distance(cam.target.x - cam.pos.x, cam.target.y - cam.pos.y, cam.target.z - cam.pos.z);

		if(K.isDown(K.UP)) {
			cam.target.x += d * Math.cos(a) * dt; cam.target.y += d * Math.sin(a) * dt;
		}
		else if(K.isDown(K.DOWN)) {
			cam.target.x -= d * Math.cos(a) * dt; cam.target.y -= d* Math.sin(a) * dt;
		}

		if(K.isDown(K.RIGHT)) {
			a += Math.PI * 0.5;
			cam.target.x += d * Math.cos(a) * dt; cam.target.y += d * Math.sin(a) * dt;
		}
		else if(K.isDown(K.LEFT)) {
			a += Math.PI * 0.5;
			cam.target.x -= d * Math.cos(a) * dt; cam.target.y -= d * Math.sin(a) * dt;
		}

		cam.pos.set(cam.target.x + camOffset.x, cam.target.y + camOffset.y, cam.target.z + camOffset.z);

		if(K.isPressed(K.SPACE))
			generate(Std.random(0xFFFFFF));
	}

	override function update(dt:Float) {
		super.update(dt);

		keys(dt);
		world.update(dt);
		hero.update(dt);
	}
}