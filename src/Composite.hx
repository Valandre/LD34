package ;
import hxd.Res;

class CompoShader extends h3d.shader.ScreenShader {
	static var SRC = {
		@const var hasDOF : Bool;
		@const var hasFOG : Bool;
		@const var hasBLOOM : Bool;

		@param var camera : {
			var pos : Vec3;
			var zNear: Float;
			var zFar : Float;
		}

		@param var color : Sampler2D;
		@param var colorBlur : Sampler2D;
		@param var depth : Sampler2D;

		@param var dofStart : Float;
		@param var dofPower : Float;
		@param var dofAmount: Float;

		@param var fogStart : Float;
		@param var fogPower : Float;
		@param var fogAmount : Float;
		@param var fogColor: Vec3;

		@param var bloomPower : Float;
		@param var bloomAmount : Float;

		@param var global_brightness : Float; 	// -1 to 1
		@param var global_contrast : Float;		// 0 to 2
		@param var global_saturation: Float;    // 0 to 2

		function linearize(d : Float) : Float {
			var n = camera.zNear;
			var f = camera.zFar;
			return (2 * n * f) / (f + n - (2 * d - 1) * (f - n));
		}

		function fragment() {
			var pColor = color.get(input.uv);
			var pDepth = unpack(depth.get(input.uv));
			var d = (linearize(pDepth) - camera.zNear) / (camera.zFar - camera.zNear);

			if(hasDOF) {
				var k = ((d - dofStart).pow(dofPower).max(0.) * dofAmount).min(1.);
				pColor = mix(pColor, colorBlur.get(input.uv), k);
			}

			if(hasBLOOM) {
				var lum = log( (pColor.rgb.dot(vec3(0.2126, 0.7152, 0.0722)) * pColor.a.saturate()).pow(bloomPower) + 1. ) * 0.5;
				pColor.rgb += (exp(lum * 2.) - 1.) * bloomAmount.xxx;
			}

			if(hasFOG) {
				var k = ((d - fogStart).pow(fogPower).max(0.) * fogAmount).min(1.);
				pColor.rgb = mix(pColor.rgb, fogColor, k );
			}

			pColor.rgb = (pColor.rgb - 0.5) * (global_contrast) + 0.5;
			pColor.rgb = pColor.rgb + global_brightness;
			var intensity = dot(pColor.rgb, vec3(0.299,0.587,0.114));
			pColor.rgb = mix(intensity.xxx, pColor.rgb, global_saturation);

			output.color = pColor;
		}
	}
}

class Composite extends h3d.scene.Renderer {

	var game : Game;

	public var waterReflection : shaders.SSReflection;

	var ambientOcclusion = new h3d.pass.ScalableAO();
	var ambientOcclusionBlur = new h3d.pass.Blur(2, 3, 2);
	var waterReflectBlur = new h3d.pass.Blur(1, 2, 2);
	var antiAliasing = new h3d.pass.FXAA();
	var colorBlur = new h3d.pass.Blur(2, 1, 100);
	var ambient : h3d.pass.ScreenFx<CompoShader>;
	var all : h3d.pass.MRT;

	public function new() {
		game = Game.inst;
		super();

		ambient = new h3d.pass.ScreenFx(new CompoShader());
		ambient.shader.hasDOF = true;
		ambient.shader.hasFOG = true;
		ambient.shader.hasBLOOM = true;

		ambient.shader.global_brightness = 0.25;
		ambient.shader.global_contrast = 1.5;
		ambient.shader.global_saturation = 1.1;
		ambient.shader.bloomPower = 3.107;
		ambient.shader.bloomAmount = 0.5;
		ambient.shader.fogStart = 0.0352;
		ambient.shader.fogPower = 3.5;
		ambient.shader.fogAmount = 2;
		ambient.shader.dofStart = 0.;
		ambient.shader.dofPower = 2;
		ambient.shader.dofAmount = 1.5;
		ambient.shader.fogColor.setColor(0x4B1C6B);

		ambientOcclusion.shader.bias = 0.04;
		ambientOcclusion.shader.intensity = 0.5;
		ambientOcclusion.shader.sampleRadius = 0.25;

		waterReflection = new shaders.SSReflection();
	}

	override function render() {
		var connected = game.inspector != null && game.inspector.connected;

		shadow.draw(get("shadow"));
		var colorTex, depthTex, normalTex;

		depth.draw(get("depth"));
		normal.draw(get("normal"));
		colorTex = allocTarget("color");
		depthTex = depth.getTexture();
		normalTex = normal.getTexture();

	//color
		setTarget(colorTex);
		clear(0, 1);
		draw("default");
		draw("additive");

	//ssao
		var saoTarget = allocTarget("sao", 1, false);
		setTarget(saoTarget);
		ambientOcclusion.apply(depthTex, normalTex, ctx.camera);
		ambientOcclusionBlur.apply(saoTarget, allocTarget("saoBlurTmp", 1, false), null);
		ambientOcclusionBlur.depthBlur = { depths : depthTex, normals : normalTex, camera: ctx.camera};
		h3d.pass.Copy.run(saoTarget, colorTex, Multiply);

	//water

		var wreflect = allocTarget("wreflect", 0, false);
		setTarget(wreflect);
		clear(1, 1);
		waterReflection.rcolor = colorTex;
		waterReflection.rdepth = depthTex;
		//waterReflection.skybox = skybox;
		waterReflection.hasSkybox = false;// skybox != null;
		ctx.extraShaders = new hxsl.ShaderList(waterReflection);
		draw("waterReflect");
		ctx.extraShaders = null;
		waterReflectBlur.apply(wreflect, allocTarget("blurtmp", 1, false));

		setTarget(colorTex);
		draw("reflect");

	//fxaa
		var final = allocTarget("final", 0, false);
		setTarget(final);
		antiAliasing.apply(colorTex);

	// ambient
		var colorBlurTex = allocTarget("colorBlur", 2, false);
		h3d.pass.Copy.run(final, colorBlurTex);
		colorBlur.apply(colorBlurTex, allocTarget("colorBlurTmp", 2, false));

		ambient.shader.color = final;
		ambient.shader.colorBlur = colorBlurTex;
		ambient.shader.depth = depth.getTexture();
		ambient.shader.camera = ctx.camera;

		setTarget(null);
		ambient.render();

		//trace(h3d.Engine.getCurrent().mem.stats());
	}
}
