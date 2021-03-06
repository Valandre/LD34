import hxd.Math;
import hxd.Key in K;
import hxd.Res;

class Game extends hxd.App {

	public static var inst : Game;
	public var inspector : hxd.net.SceneInspector;
	public var world : World;
	public var entities : Array<Entity>;
	public var bonus : Array<Bonus>;
	public var hero : Hero;
	public var fighters : Array<Fighter>;
	var citySize = 7;
	public var width = 0;
	public var event : WaitEvent;

	var camOffset : h3d.Vector;
	public var renderer : Composite;
	public var mpos: h3d.Vector;
	public var ui: UI;
	public var credits = 3;

	public var mines : Array<Mine> = [];
	public var fxs = [];

	var bg : h3d.scene.Object;
	public var level = 0;
	public var mute = false;

	static function main() {
		//hxd.Res.initLocal();
		//hxd.res.Resource.LIVE_UPDATE = true;
		//hxd.Res.initEmbed({ compressSounds : true });
		inst = new Game();
	}

	override function loadAssets(done) {
		new hxd.fmt.pak.Loader(s2d, done);
	}

	override function init() {
		event = new WaitEvent();
		inspector = new hxd.net.SceneInspector(s3d);
		width = 3 * citySize + 1;

		s2d.setFixedSize(1920, 1080);

		//var light = new h3d.scene.DirLight(new h3d.Vector( 0.3, -0.4, -0.9), s3d);
		//light.color.setColor(0x8EA59E);
		s3d.lightSystem.ambientLight.setColor(0xA0A0A0);
		s3d.lightSystem.perPixelLighting = true;

		renderer = new Composite();
		s3d.renderer = renderer;
		s3d.lightSystem.maxLightsPerObject = 10;

		var shadow = Std.instance(s3d.renderer.getPass("shadow"), h3d.pass.ShadowMap);
		shadow.color.setColor(0x74717A);

		resetCamOffset();
		var cam = s3d.camera;
		cam.target.set(width * 0.5, width * 0.5, 0);
		cam.pos.set(cam.target.x + camOffset.x, cam.target.y + camOffset.y, cam.target.z + camOffset.z);
		cam.fovY = 36;
		cam.zNear = 1;
		cam.zFar = 20;

		ui = new UI();

		entities = [];
		bonus = [];

		bg = loadModel(Res.city.bg);
		for( mat in bg.getMaterials()) {
			mat.mainPass.enableLights = true;
			mat.allocPass("depth");
			mat.allocPass("normal");
			cast(mat, h3d.mat.MeshMaterial).shadows = true;
		}
		s3d.addChild(bg);
		world = new World(16, width, s3d);
		menu();
	}

	public function menu() {
		reset();
		hero = null;

		world.generate(16486732);
		resetCamOffset();

		fighters = [];
		for( i in 0...8) {
			var p = world.getFreePos();
			fighters.push(new Fighter(p.x + 0.5, p.y + 0.5));
		}

		ui.fadeIn(true);
		event.wait(0.2, function() {
			ui.setMenu();
			ui.fadeOut();
		});
	}

	function resetCamOffset() {
		var c = 0.67;
		if(hero != null) {
			camOffset = new  h3d.Vector(4 * c, 6 * c, 8 * c);
			s3d.camera.target.x = hero.x;
			s3d.camera.target.y = hero.y;
		}
		else {
			camOffset = new  h3d.Vector(4 * c * 1.1, 6 * c * 1.1, 8 * c * 0.7);
			var px = width * 0.5;
			var py = width * 0.5;
			var ray = 0.5;
			var cpt = Math.PI;
			event.waitUntil(function(dt) {
				if(hero != null)
					return true;
				s3d.camera.target.x = px + ray * Math.cos(cpt);
				s3d.camera.target.y = py + ray * Math.sin(cpt);
				cpt += 0.0006 * dt;
				return false;
			});
		}
	}

	function reset() {
		if(bonus != null)
			while(bonus.length > 0)
				bonus[0].remove();

		if(fighters != null)
			while(fighters.length > 0)
				fighters[0].remove();
		fighters = [];

		if( hero != null) hero.remove();

		if(mines != null)
			for( m in mines)
				m.remove();
		mines = [];

		if(fxs != null)
			for( fx in fxs)
				fx.remove();
		fxs = [];

		event.clear();
	}

	public function generate(seed : Int) {
		reset();

		world.generate(seed);
		trace("seed : " + seed);

		var p = world.startPoint;
		var cam = s3d.camera;
		cam.target.x = p.x + 0.5;
		cam.target.y = p.y + 0.5;

		hero = new Hero(p.x + 0.5, p.y + 0.5);

		for( i in 0...9) { //no more than 9
			var p = world.getFreePos();
			fighters.push(new Fighter(p.x + 0.5, p.y + 0.5));
		}

		ui.init();
		resetCamOffset();
	}

	public var anims : Map<String,h3d.anim.Animation> = new Map();
	var models : Map<String, h3d.scene.Object> = new Map();
	public function loadModel( m : hxd.res.Model ) {
		var e = models.get(m.entry.path);
		if(e == null) {
			var lib = m.toHmd();
			e = lib.makeObject(loadTexture.bind(m.entry.path));
			for( m in e.getMaterials()) {
				m.mainPass.enableLights = true;
				m.addPass(new h3d.mat.Pass("depth", m.mainPass));
				m.addPass(new h3d.mat.Pass("normal", m.mainPass));
				cast(m, h3d.mat.MeshMaterial).shadows = true;
			}
			models.set(m.entry.path, e);
			var a = lib.loadAnimation();
			if(a != null)
				anims.set(m.entry.path, a);
		}
		return e.clone();
	}

	var textures : Map<String, h3d.mat.Texture> = new Map();
	function loadTexture( modelPath : String, texPath : String ) {
		var t = textures.get(modelPath);
		if(t == null) {
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

			if(t != null) {
				t.wrap = Repeat;
				textures.set(modelPath, t);
			}
		}
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

	override function onResize() {
		super.onResize();
		if(ui != null)
			ui.onResize();
	}

	function keys(dt : Float) {
		var cam = s3d.camera;

		if(K.isPressed("M".code)) {
			mute = !mute;
			if(!mute && ui != null && ui.ingame != null) Sounds.play("Loop");
			else Sounds.stop("Loop");
		}

		if(K.isDown(K.CTRL) && K.isPressed("F".code))
			engine.fullScreen = !engine.fullScreen;
/*
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
*/

		if(hero != null && cam.follow == null) {
			cam.target.x = hero.x;
			cam.target.y = hero.y;
			//cam.target.x = fighters[1].x;
			//cam.target.y = fighters[1].y;
		}
		if(cam.follow == null)
			cam.pos.set(cam.target.x + camOffset.x, cam.target.y + camOffset.y, cam.target.z + camOffset.z);
/*
		if(K.isPressed("K".code)) {
			if(fighters != null)
				while(fighters.length > 0)
					fighters[0].remove();
			if(hero != null)
				hero.cheat = true;
		}*/
/*
		if(K.isPressed(K.SPACE)) {
			Sounds.stop("Loop");
			start();
		}*/
	}

	public function start() {
		credits = 3;
		level = 0;
		ui.fadeIn();
		event.wait(0.2, function() {
			Sounds.play("Loop");
			generate(Std.random(0xFFFFFF));
			ui.fadeOut();
			ui.setGo();
		});
	}


	public function victory() {
		ui.setVictory();
	}


	public function nextStage() {
		level++;
		ui.fadeIn();
		event.wait(0.2, function() {
			generate(Std.random(0xFFFFFF));
			ui.fadeOut();
			ui.setGo();
		});
	}

	public function respawn() {
		ui.fadeIn();
		var n = fighters.length;
		event.wait(0.2, function() {
			reset();

			var p = world.startPoint;
			var cam = s3d.camera;
			cam.target.x = p.x + 0.5;
			cam.target.y = p.y + 0.5;

			hero = new Hero(p.x + 0.5, p.y + 0.5);

			for( i in 0...n) {
				var p = world.getFreePos();
				fighters.push(new Fighter(p.x + 0.5, p.y + 0.5));
			}

			ui.init();
			resetCamOffset();

			ui.fadeOut();
			ui.setGo();
		});
	}

	var objs = [];
	public function menuBack() {
		ui.fadeIn();
		event.wait(0.2, function() {
			for(o in objs)
				o.remove();
			objs = [];

			bg.visible = true;
			@:privateAccess for(c in world.allChunks) c.root.visible = true;
			renderer.ambient.shader.hasDOF = true;
			renderer.ambient.shader.hasFOG = true;
			renderer.ambient.shader.hasBLOOM = true;
			renderer.enableSAO = true;

			s3d.camera.follow = null;
			resetCamOffset();

			menu();
			ui.fadeOut();
		});
	}

	public function helpPage() {
		ui.fadeIn();
		event.wait(0.2, function() {
			reset();

			bg.visible = false;
			@:privateAccess for(c in world.allChunks) c.root.visible = false;
			renderer.ambient.shader.hasDOF = false;
			renderer.ambient.shader.hasFOG = false;
			renderer.ambient.shader.hasBLOOM = false;
			renderer.enableSAO = false;

			var garage = loadModel(Res.garage.model);
			for( mat in garage.getMaterials()) {
				mat.mainPass.enableLights = false;
				mat.removePass(mat.getPass("depth"));
				mat.removePass(mat.getPass("normal"));
				cast(mat, h3d.mat.MeshMaterial).shadows = false;
			}
			s3d.camera.follow = { pos : garage.getObjectByName("CamCredits"), target : garage.getObjectByName("CamCredits.Target") };
			s3d.addChild(garage);

			var bolid = new Hero(garage.x + 1.42, garage.y - 0.28);
			bolid.model.setScale(1.2);
			bolid.lock = true;
			bolid.model.currentAnimation.speed = 0;
			bolid.rifle.currentAnimation.speed = 0;
			bolid.rifle.x = bolid.x;
			bolid.rifle.y = bolid.y;
			bolid.rifle.setScale(1.2);
			bolid.rifle.z -= 0.05;
			bolid.headlight.visible = false;

			var rot = Math.PI * 0.25;
			event.waitUntil(function(dt) {
				bolid.model.setRotate(0, 0, rot);
				bolid.rifle.setRotate(0, 0, rot);
				rot += 0.01 * dt;
				return false;
			});

			objs.push(garage);
			objs.push(bolid.model);
			objs.push(bolid.rifle);
			objs.push(bolid.headlight);

			event.waitUntil(function(dt) {
				if(K.isDown(K.MOUSE_LEFT))
					bolid.model.currentAnimation.speed = 1.;
				else bolid.model.currentAnimation.speed = 0;
				if(K.isDown(K.MOUSE_RIGHT))
					bolid.rifle.currentAnimation.speed = 1.5;
				else bolid.rifle.currentAnimation.speed = 0;
				return false;
			});

			ui.setHelp();
			ui.fadeOut();
		});
	}

	public function creditsPage() {
		ui.fadeIn();
		event.wait(0.2, function() {
			reset();

			bg.visible = false;
			@:privateAccess for(c in world.allChunks) c.root.visible = false;
			renderer.ambient.shader.hasDOF = false;
			renderer.ambient.shader.hasFOG = false;
			renderer.ambient.shader.hasBLOOM = false;
			renderer.enableSAO = false;

			var garage = loadModel(Res.garage.model);
			for( mat in garage.getMaterials()) {
				mat.mainPass.enableLights = false;
				mat.removePass(mat.getPass("depth"));
				mat.removePass(mat.getPass("normal"));
				cast(mat, h3d.mat.MeshMaterial).shadows = false;
			}
			s3d.camera.follow = { pos : garage.getObjectByName("CamCredits"), target : garage.getObjectByName("CamCredits.Target") };
			s3d.addChild(garage);

			var bolid = new Hero(garage.x + 1.42, garage.y - 0.28);
			bolid.model.setScale(1.2);
			bolid.lock = true;
			bolid.model.currentAnimation.speed = 0;
			bolid.rifle.currentAnimation.speed = 0;
			bolid.rifle.x = bolid.x;
			bolid.rifle.y = bolid.y;
			bolid.rifle.setScale(1.2);
			bolid.rifle.z -= 0.05;
			bolid.headlight.visible = false;

			var rot = Math.PI * 0.25;
			event.waitUntil(function(dt) {
				bolid.model.setRotate(0, 0, rot);
				bolid.rifle.setRotate(0, 0, rot);
				rot += 0.01 * dt;
				return false;
			});

			objs.push(garage);
			objs.push(bolid.model);
			objs.push(bolid.rifle);
			objs.push(bolid.headlight);

			ui.setCredits();
			ui.fadeOut();
		});
	}

	public function gameOver() {
		Sounds.stop("Loop");
		menu();
	}

	override function update(dt:Float) {
		super.update(dt);

		mpos = getMousePicker();

		keys(dt);
		ui.update(dt);
		event.update(dt);
		for( e in entities)
			e.update(dt);

		if(hero != null && bonus.length < 20)
			new Bonus();

		for(m in mines) {
			m.update(dt);
			if(m.explode)
				mines.remove(m);
		}
	}
}