
import flash.events.Event;

typedef S = flash.media.Sound;
typedef C = flash.media.SoundChannel;
typedef T = flash.media.SoundTransform;

@:keep @:sound("res/sfx/ValMak.mp3")
class Loop extends S {
}
@:keep @:sound("res/sfx/menu2.mp3")
class MenuClick extends S {
}
@:keep @:sound("res/sfx/menu1.mp3")
class MenuOver extends S {
}
@:keep @:sound("res/sfx/autoshoot2.mp3")
class Rifle extends S {
}
@:keep @:sound("res/sfx/carcrash1.mp3")
class Bump extends S {
}
@:keep @:sound("res/sfx/carcrash3.mp3")
class Bump2 extends S {
}
@:keep @:sound("res/sfx/explode3.mp3")
class Explode extends S {
}

class Sounds {

	static var sounds:Map<String, S> = new Map();
	static var musicChannel:C;


	public static function play( name : String ) {

		var s : S = sounds.get(name);
		if( s == null ) {
			var cl = Type.resolveClass(name.charAt(0).toUpperCase() + name.substr(1));
			if( cl == null ) throw "No sound " + name;
			s = Type.createInstance(cl, []);
			sounds.set(name, s);
		}

		switch(name) {
			case "Loop":
				var t = new T();
				t.volume = 0.7;
				musicChannel = s.play(0, 99999, t);
			case "MenuClick":
				s.play(0, 0);
			case "MenuOver":
				s.play(0, 0);
			case "Rifle":
				var t = new T();
				t.volume = 0.5;
				s.play(0, 0, t);
			case "Bump":
				var t = new T();
				t.volume = 0.5;
				s.play(0, 0, t);
			case "Bump2":
				var t = new T();
				t.volume = 0.6;
				s.play(0, 0, t);
			case "Explode":
				var t = new T();
				t.volume = 0.6;
				s.play(0, 0, t);

		}
	}

	public static function stop(name:String) {
		var s : S = sounds.get(name);

		if( s == null )
			return;

		switch(name) {
			case "Loop":
				musicChannel.stop();
		}
	}
}