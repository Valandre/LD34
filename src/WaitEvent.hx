

class WaitEvent
{
	var updateList : Array <{ callb : Float -> Void, breakable:Bool }> ;

	public var timeSpeed = 1.;

	public function new() {
		updateList = [];
	}

	public inline function hasEvent() {
		return updateList.length > 0;
	}

	public function clear(force = false) {
		var index = updateList.length - 1;
		while(index >= 0) {
			var e = updateList[index--];
			if(force || e.breakable)
				updateList.remove(e);
		}
	}

	public function add( callb ) {
		updateList.push( { callb : callb, breakable : false } );
	}

	public function remove(callb) {
		for( u in updateList )
			if( u.callb == callb ) {
				updateList.remove(u);
				return;
			}
	}

	public function wait( time : Float, callb, breakable = true ) {
		var e = { callb : null, breakable : breakable };
		function tmp(_) {
			time -= hxd.Timer.deltaT * timeSpeed;
			if( time < 0 ) {
				updateList.remove(e);
				callb();
			}
		}
		e.callb = tmp;
		updateList.push(e);
	}

	public function waitUntil( callb, breakable = true ) {
		var e = { callb : null, breakable : breakable };
		function tmp(dt) {
			if( callb(dt) )
				updateList.remove(e);
		}
		e.callb = tmp;
		updateList.push(e);
	}

	public function update(dt:Float) {
		if( updateList.length == 0 ) return;
		for( f in updateList.copy() )
			f.callb(dt);
	}
}