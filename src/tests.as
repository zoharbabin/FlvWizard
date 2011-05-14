package
{
	import com.zoharbabin.bytearray.flv.FlvWizard;
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.media.Video;
	import flash.net.FileReference;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
		
	public class tests extends Sprite
	{
		private var nc:NetConnection;
		private var ns:NetStream;
		private var ldr:URLLoader;
		private var ldr2:URLLoader;
		private var boyVideo:ByteArray = null;
		private var girlVideo:ByteArray = null;
		private var videoBytes:ByteArray;
		private var soundBytes:ByteArray;
		private var mergedBytes:ByteArray;
		private var video:Video = new Video ();
		private var downloadBtn:MovieClip = new MovieClip();
		
		public function tests()
		{
			downloadBtn.graphics.beginFill(0);
			downloadBtn.graphics.drawRect(0,0,60,60);
			downloadBtn.graphics.endFill();
			addChild(downloadBtn);
			downloadBtn.x = 0;
			downloadBtn.y = 0;
			downloadBtn.addEventListener(MouseEvent.CLICK, saveFile);
			ldr = new URLLoader();
			ldr.addEventListener(Event.COMPLETE, downloaded);
			ldr.dataFormat = URLLoaderDataFormat.BINARY;
			ldr.load(new URLRequest('boy.flv'));
			ldr2 = new URLLoader();
			ldr2.addEventListener(Event.COMPLETE, downloaded2);
			ldr2.dataFormat = URLLoaderDataFormat.BINARY;
			ldr2.load(new URLRequest('girl.flv'));
		}
		
		private function saveFile (event:MouseEvent):void {
			if (!mergedBytes) return;
			
			var fR:FileReference = new FileReference();
			fR.save(mergedBytes, "mergedVideo.flv");
		}
		
		private function downloaded(event:Event):void {
			trace ('boy');
			boyVideo = ldr.data;
			if (girlVideo != null) merge();
		}

		private function downloaded2(event:Event):void {
			trace ('girl');
			girlVideo = ldr2.data;
			if (boyVideo != null) merge();
		}
		
		private function merge ():void {
			var flvwiz:FlvWizard = new FlvWizard ();
			videoBytes = flvwiz.extractChannel(boyVideo, FlvWizard.VIDEO_CHANNEL);
			soundBytes = flvwiz.extractChannel(girlVideo, FlvWizard.SOUND_CHANNEL);
			mergedBytes = flvwiz.mergeChannels(videoBytes, soundBytes);
			playback (mergedBytes);
			
		}
		
		private function playback (bytes:ByteArray):void {
			trace ('playback');
			nc = new NetConnection();
			nc.connect(null);
			ns = new NetStream(nc);
			ns.play(null);
			ns.client = new Object();
			ns.client.onMetaData = function (...args):void {};
			ns.appendBytes(bytes);
			video.attachNetStream(ns);
			addChild(video);
		}
	}
}