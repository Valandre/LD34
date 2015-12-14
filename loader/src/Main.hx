
import flash.net.URLRequest;
import flash.display.Loader;
import flash.events.Event;
import flash.events.ProgressEvent;
import flash.Lib;

class Main
{
	var progressBar:flash.display.Bitmap;
	var bg:flash.display.Bitmap;

	function new() {
		var loader:Loader = new Loader();
		loader.contentLoaderInfo.addEventListener(Event.OPEN, createProgressBar);
		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onCompleteHandler);
		loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, onProgressHandler);
		loader.load(new URLRequest("LD34.swf?" + Math.random()), new flash.system.LoaderContext(false,new flash.system.ApplicationDomain()));
	}

	function createProgressBar(e) {
		var w = 340, h = 10;
		var bmp = new flash.display.BitmapData(w, h, true, 0xFFFFFFFF);
		progressBar = new flash.display.Bitmap(bmp);
		progressBar.x = (Lib.current.stage.stageWidth - w) * 0.5;
		progressBar.y = (Lib.current.stage.stageHeight - 256) * 0.5 + 180;
		progressBar.scaleX = 0;
		Lib.current.addChild(progressBar);
	}

	function onCompleteHandler(e:Event){
		Lib.current.removeChild(progressBar);
		Lib.current.addChild(e.currentTarget.content);
	}

	function onProgressHandler(e:ProgressEvent){
		progressBar.scaleX = e.bytesLoaded / e.bytesTotal;
		#if debug
		trace(e.bytesLoaded / e.bytesTotal);
		#end
	}

	public static var inst : Main;
	static function main() {
		inst = new Main();
	}
}