package shaders;
import hxd.Res;

class SSReflection extends hxsl.Shader
{
	static var SRC = {
		@:import h3d.shader.BaseMesh;

		var calculatedUV : Vec2;

		@param var skybox : SamplerCube;
		@param var rdepth : Sampler2D;
		@param var rcolor : Sampler2D;

		@param var searchDist : Float;
		@param var reflectAmount : Float;
		@param var waterAlpha : Float;
		@const var steps : Int;
		@const var hasSkybox : Bool;

		function linearize(d : Float) : Float {
			var n = camera.zNear;
			var f = camera.zFar;
			return (2 * n * f) / (f + n - (2 * d - 1) * (f - n));
		}

		function fragment() {
			var r = reflect(( - camera.dir).normalize(),transformedNormal).normalize();
			var p = transformedPosition;
			var pproj = vec4(p, 1) * camera.viewProj;
			var uv : Vec2;
			var dv = searchDist / steps;
			var delta : Float;

			var v0 = vec3(p.xy - camera.position.xy, 0);

			for( i in 0...steps ) {
				pproj = vec4(p, 1) * camera.viewProj;
				pproj.xyz /= pproj.w;
				uv = pproj.xy * vec2(0.5, -0.5) + 0.5;
				var dd = unpack(rdepth.get(uv));
				var dp = pproj.z;
				delta = linearize(dd) - linearize(dp);
				dv *= delta > 0 ? -0.5 : 1.;
				p += r * abs(delta) * dv;
			}

			var ruv = abs((uv - 0.5) * 2);
			var borders = 1 - max(ruv.x, ruv.y).pow(5.);
			var notTooNear = float(delta > -searchDist);
			var notTooFar = float(delta < searchDist);
			var k = borders * notTooNear * notTooFar;
			var v = vec3(p.xy - camera.position.xy, 0);
			k *= float(v.dot(v) > v0.dot(v0) * 0.99);

			var nx = vec3(transformedNormal.x, 0, transformedNormal.z);
			var ny = vec3( 0, transformedNormal.y, transformedNormal.z);
			var offset = vec2(vec3(1, 0, 0).dot(nx), vec3(0, 1, 0).dot(ny)) * 0.2;
			offset *= float(unpack(rdepth.get(screenUV + offset) + 0.001) > unpack(rdepth.get(screenUV)));
			var tcolor = rcolor.get(screenUV + offset);

			var c : Vec4;
			if(hasSkybox)
				c = mix( skybox.get(r), rcolor.get(uv), k.saturate() );
			else c.rgb = tcolor.xyz * k;

			pixelColor = mix(c * reflectAmount, tcolor, (1 - waterAlpha * waterAlpha) * screenUV.y);
		}
	}


	public function new(?skybox : h3d.mat.Texture) {
		super();
		steps = 6;
		searchDist = 3;
		reflectAmount = 0.8;
		waterAlpha = 0.;
		this.skybox = skybox;
		hasSkybox = skybox != null;
	}

}