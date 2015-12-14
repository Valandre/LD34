package ;

import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.display.Loader;
import flash.system.LoaderContext;
import flash.system.ApplicationDomain;
import flash.Lib;
import flash.net.*;
import flash.events.Event;
import flash.utils.ByteArray;
import flash.events.ProgressEvent;

/**
 * ...
 * @author bstouls
 */

class Main
{
	var loader :URLLoader;
	var loader2 :Loader;
	var progressBar:flash.display.Bitmap;
	
	public function new() {
		
		var w = 200;
		var h = 10;
		var bmp = new flash.display.BitmapData(w, h);
		progressBar = new flash.display.Bitmap(bmp);
		progressBar.x = (Lib.current.stage.stageWidth - w) * 0.5;
		progressBar.y = (Lib.current.stage.stageHeight - h) * 0.5;
		Lib.current.addChild(progressBar);
		
		loader = new URLLoader();
		loader.dataFormat = URLLoaderDataFormat.BINARY;
		loader.addEventListener (Event.COMPLETE, _binaryLoaded);
		loader.load ( new URLRequest ( "LD27.swf?" + Math.random() ) );
	}
	
	function _binaryLoaded(e:Event):Void {
		var ba :ByteArray = loader.data;
		loader2 = new Loader();
		loader2.contentLoaderInfo.addEventListener (Event.INIT, completeHandler);
		loader2.contentLoaderInfo.addEventListener (ProgressEvent.PROGRESS, progressHandler);
		loader2.loadBytes (ba, new LoaderContext (false, ApplicationDomain.currentDomain));
	}

	function completeHandler(e) {
		Lib.current.removeChild(progressBar);
		trace("complete");
	}

	function progressHandler(e:ProgressEvent ) {
		progressBar.scaleX = e.bytesLoaded / e.bytesTotal;
		trace(e.bytesLoaded, e.bytesTotal);
	}
	
	
	public static var inst : Main;
	static function main() {
		inst = new Main();
	}
}