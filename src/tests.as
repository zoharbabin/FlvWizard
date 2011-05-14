package
{
	import com.zoharbabin.bytearray.flv.FlvWizard;
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.media.Video;
	import flash.net.FileReference;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.NetStreamAppendBytesAction;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	
	[SWF(width=320,height=280)]
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
		private var downloadingMsg:Sprite;
		private var flvwiz:FlvWizard = new FlvWizard ();
		
		public function tests()
		{
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.color = 0xc0c0c0;
			downloadVideoFLVs ();
		}
		
		// merge channels using FlvWizard
		private function merge (event:MouseEvent):void {
			mergedBytes = flvwiz.mergeChannels(videoBytes, soundBytes);
			playback (mergedBytes);
			createButton ("4-Download", 240, saveFile);
		}
		
		// save the merged flv file to client disk
		private function saveFile (event:MouseEvent):void {
			if (!mergedBytes) return;
			var fR:FileReference = new FileReference();
			fR.save(mergedBytes, "mergedVideo.flv");
		}
		
		// Play original videos
		private function playBoy (event:MouseEvent):void {
			playback(boyVideo);
		}
		private function playGirl (event:MouseEvent):void {
			playback(girlVideo);
		}
		// Play a given ByteArray
		private function playback (bytes:ByteArray):void {
			ns.play(null);
			ns.appendBytesAction(NetStreamAppendBytesAction.RESET_BEGIN);
			ns.appendBytes(bytes);
		}
		private function preparePlayback ():void {
			nc = new NetConnection();
			nc.connect(null);
			ns = new NetStream(nc);
			ns.play(null);
			ns.client = new Object();
			ns.client.onMetaData = function (...args):void {};
			video.attachNetStream(ns);
			video.y = 40;
			addChild(video);
		}
		
		// Videos were downloaded, what to do now?
		private function videosDownloaded ():void {
			removeChild(downloadingMsg);
			createButton ("1-Play Boy", 0, playBoy, 70);
			createButton ("2-Play Girl", 72, playGirl, 70);
			createButton ("3-Play Merged", 144, merge, 94);
			preparePlayback ();
		}
		
		/// Download the video flv files
		private function downloaded(event:Event):void {
			boyVideo = ldr.data;
			//extract the video channel using FlvWizard
			videoBytes = flvwiz.extractChannel(boyVideo, FlvWizard.VIDEO_CHANNEL);
			if (girlVideo != null) videosDownloaded();
		}
		private function downloaded2(event:Event):void {
			girlVideo = ldr2.data;
			//extract the audio channel using FlvWizard
			soundBytes = flvwiz.extractChannel(girlVideo, FlvWizard.SOUND_CHANNEL);
			if (boyVideo != null) videosDownloaded();
		}
		private function downloadVideoFLVs ():void {
			downloadingMsg = createButton ("Downloading Videos...", 80, null, 160, 160);
			ldr = new URLLoader();
			ldr.addEventListener(Event.COMPLETE, downloaded);
			ldr.dataFormat = URLLoaderDataFormat.BINARY;
			ldr.load(new URLRequest('boy.flv'));
			ldr2 = new URLLoader();
			ldr2.addEventListener(Event.COMPLETE, downloaded2);
			ldr2.dataFormat = URLLoaderDataFormat.BINARY;
			ldr2.load(new URLRequest('girl.flv'));
		}
		
		/// Create Buttons 
		private function createButton (btntext:String, x:Number, handler:Function = null, width:Number = 80, y:Number = 0):Sprite {
			var downloadBtn:Sprite = new Sprite();
			var txtField:TextField = new TextField ();
			var txtFormat:TextFormat = new TextFormat(); 
			downloadBtn.graphics.beginFill(0xa0a0c0);
			downloadBtn.graphics.drawRect(0,0,width,40);
			downloadBtn.graphics.endFill();
			addChild(downloadBtn);
			downloadBtn.x = x;
			downloadBtn.y = y;
			txtField.text = btntext;
			txtField.autoSize = TextFieldAutoSize.LEFT;
			txtField.x = width/10-4;
			txtField.y = 8;
			txtField.selectable = false;
			txtFormat.size = 12;
			txtFormat.font = "Arial";
			txtFormat.bold = true;
			txtFormat.color = 0x303030;
			txtField.setTextFormat(txtFormat);
			if (handler != null) downloadBtn.addEventListener(MouseEvent.CLICK, handler);
			downloadBtn.buttonMode = true;
			downloadBtn.useHandCursor = true;
			downloadBtn.addChild(txtField);
			downloadBtn.mouseChildren = false;
			return downloadBtn;
		}
	}
}