/**
 * In addition to the MIT license, if you make use of this code
 * you should notify the author (Zohar Babin: z.babin@gmail.com).
 * 
 * This program is distributed under the terms of the MIT License as found 
 * in a file called LICENSE. If it is not present, the license
 * is always available at http://www.opensource.org/licenses/mit-license.php.
 *
 * This program is distributed in the hope that it will be useful, but
 * without any waranty; without even the implied warranty of merchantability
 * or fitness for a particular purpose. See the MIT License for full details.
 **/ 
package com.zoharbabin.bytearray.flv
{
	import flash.utils.ByteArray;
	
	/**
	 * Utility class for manipulating FLV bits - trim, merge and more. 
	 * 
	 * @author Zohar Babin
	 * @see http://www.zoharbabin.com
	 * @see https://github.com/zoharbabin/FlvWizard/
	 * @see http://www.openscreenproject.org/about/publications.html
	 * @see http://www.kaltura.org/demos/RemixGenderedAds/
	 */	
	public class FlvWizard
	{
		/**
		 *FlvWizard utility flag for relating to the sound channel in the flv, use with extract/merge methods. 
		 */		
		public static const SOUND_CHANNEL:int = 0x2;
		/**
		 *FlvWizard utility flag for relating to the video channel in the flv, use with extract/merge methods. 
		 */		
		public static const VIDEO_CHANNEL:int = 0x4;
		
		protected static const AUDIO_TAG:int = 0x08;
		protected static const VIDEO_TAG:int = 0x09;
		protected static const SCRIPT_TAG:int = 0x12;
		protected static const SIGNATURE:String = "FLV";
		protected static const METADATA:String = "onMetaData";
		protected static const DURATION:String = "duration";
		protected static const CANSEEKEND:String = "canSeekToEnd";
		protected static const CREATOR:String = "metadatacreator";
		protected static const CREDITS:String = "FlvWizard 1.0 by Zohar Babin";
		
		/**
		 * Utility function to find the position in a given FLV bytearray of the start of body tags. 
		 * @param input		The FLV bytearray to find it's first tag position.
		 * @return 			The position in the given bytearray of the first body tag.
		 * 
		 */		
		protected function findTagsStart (input:ByteArray):uint 
		{
			input.position = 0;
			var signature:String = input.readUTFBytes(3);
			if ( signature != FlvWizard.SIGNATURE ) throw new Error("Not a valid VIDEO FLV file.");
			var version:int = input.readByte();
			var infos:int = input.readByte();
			var typeFlagsReserved1:int = (infos >> 3);
			var typeFlagsAudio:int = ((infos & 0x4 ) >> 2);
			var typeFlagsReserved2:int = ((infos & 0x2 ) >> 1);
			var typeFlagsVideo:int = (infos & 0x1);
			var dataOffset:int = input.readUnsignedInt();
			var position:uint = input.position + 4;
			return position;
		}
		
		/**
		 * Creates an FLV header. 
		 * @param hasVideo		Will this FLV have Video tags. 
		 * @param hasAudio		Will this FLV have Audio tags.
		 * @return 		An FLV header.
		 * 
		 */				
		protected function createFLVHeader (hasVideo:Boolean, hasAudio:Boolean):ByteArray 
		{
			var flvHeader:ByteArray = new ByteArray ();
			flvHeader.writeByte(0x46); //F
			flvHeader.writeByte(0x4C); //L
			flvHeader.writeByte(0x56); //V
			flvHeader.writeByte(0x01); //Version 1.0
			var audioVideo:uint = 0; 
			if (hasVideo) audioVideo += 1; //does this FLV has video
			if (hasAudio) audioVideo += 4; //does this FLV has audio
			flvHeader.writeByte(audioVideo);
			flvHeader.writeUnsignedInt(0x09); //size of header in 32bit unsigned int
			flvHeader.writeUnsignedInt(0); //PreviousTagSize0 - this always 0, there are no tags before
			return flvHeader;
		}
		
		/**
		 * Creates a template metadata tag. 
		 * @return 	An array containing 1: a valid FLV metadata tag, and 2: the position inside the metadata of the duration variable.
		 * 
		 */		
		protected function createMetaData ():Array 
		{
			//create the metadata tag body
			var metadataBody:ByteArray = new ByteArray ();
			metadataBody.writeByte(2); // type String for array script tag name
			// the metadata tag name
			metadataBody.writeBytes(writeString(FlvWizard.METADATA));
			// array of metadata variables
			metadataBody.writeByte(8); // type: SCRIPTDATAECMAARRAY
			metadataBody.writeUnsignedInt(3); //ECMAArrayLength
			var durationPos:uint = metadataBody.position;
			metadataBody.writeBytes(writeNumberVariable(FlvWizard.DURATION, 0));
			metadataBody.writeBytes(writeBooleanVariable(FlvWizard.CANSEEKEND, 1));
			metadataBody.writeBytes(writeString(FlvWizard.CREATOR)); //id of string variable
			metadataBody.writeByte(2); //type string
			metadataBody.writeBytes(writeString(FlvWizard.CREDITS)); //value of string variable
			// SCRIPTDATAOBJECTEND 
			metadataBody.writeShort(9 >> 8);
			metadataBody.writeByte(9 & 0xff);
			
			//wrap the body with the tag 
			var metadataTag:ByteArray = new ByteArray ();
			metadataTag.writeByte(FlvWizard.SCRIPT_TAG);
			// DataSize - the size of the metadata tag (we'll fill it after creating the tag)
			var dataSize:uint = metadataBody.length;
			metadataTag.writeShort(dataSize >> 8);
			metadataTag.writeByte(dataSize & 0xff);
			// Timestamp
			metadataTag.writeShort(0);
			metadataTag.writeByte(0);
			// TimestampExtended
			metadataTag.writeByte(0);
			// StreamID (0)
			metadataTag.writeShort(0);
			metadataTag.writeByte(0);
			durationPos += metadataTag.position; // get the position of the duration var for later update
			metadataTag.writeBytes(metadataBody);
			metadataTag.writeUnsignedInt(11+metadataTag.position); // PreviousTagSize1 (metadata should be the first tag)
			return [metadataTag, durationPos];
		}
		
		/**
		 * Creates a Boolean type variable according to the FLV specs. 
		 * @param varName		The name of the variable.
		 * @param boolValue		The value of the variable.
		 * @return 	A bytearray containing the variable.
		 * 
		 */		
		protected function writeBooleanVariable (varName:String, boolValue:int):ByteArray
		{
			var bytes:ByteArray = new ByteArray ();
			bytes.writeBytes(writeString(varName));
			bytes.writeByte(1); //type boolean
			bytes.writeByte(boolValue);
			return bytes;
		}
		
		/**
		 * Creates a Number type variable according to the FLV specs. 
		 * @param varName		The name of the variable.
		 * @param numValue		The value of the variable.
		 * @return 	A bytearray containing the variable.
		 * 
		 */		
		protected function writeNumberVariable (varName:String, numValue:Number):ByteArray
		{
			var bytes:ByteArray = new ByteArray ();
			bytes.writeBytes(writeString(varName));
			bytes.writeByte(0); //type number
			bytes.writeDouble(numValue);
			return bytes;
		}
		
		/**
		 * Encodes a String according to the FLV specs. 
		 * @param string2write		The value of the String to encode.
		 * @return 	A bytearray containing the encoded String.
		 * 
		 */	
		protected function writeString (string2write:String):ByteArray 
		{
			var bytes:ByteArray = new ByteArray ();
			bytes.writeShort(string2write.length); // SCRIPTDATASTRING length
			bytes.writeUTFBytes(string2write); // SCRIPTDATASTRING value
			return bytes;
		}
		
		protected function writeTag (input:ByteArray):ByteArray 
		{
			var bytes:ByteArray = new ByteArray ();
			input
			return bytes;
		}
		
		/**
		 * Given an FLV bytearray, extracts and returns a new FLV that contains either the audio or the video of the given FLV.
		 * @param input		An input FLV bytearray.
		 * @param channel	Either SOUND_CHANNEL or VIDEO_CHANNEL.
		 * @return 			Either the audio or the video of the given FLV (depending on the value of channel).
		 * 
		 */		
		public function extractChannel (input:ByteArray, channel:uint):ByteArray
		{
			input = clone(input);
			var offset:int; 
			var end:int;
			var tagLength:int;
			var currentTag:int;
			var step:int;
			var bodyTagHeader:int;
			var time:int;
			var timestampExtended:int;
			var streamID:int;
			var _sound:ByteArray = new ByteArray(); 
			var _video:ByteArray = new ByteArray();
			
			// find where the data tags begin (after flv header)
			input.position = findTagsStart(input);
			var currentPos:int = input.position;
			
			//write headers -
			_sound.writeBytes(createFLVHeader(false,true));
			_video.writeBytes(createFLVHeader(true,false));
			
			while ( input.bytesAvailable > 0 )
			{		
				offset = input.position; 
				currentTag = input.readByte();
				step = (input.readUnsignedShort() << 8) | input.readUnsignedByte();
				time = (input.readUnsignedShort() << 8) | input.readUnsignedByte();
				timestampExtended = input.readUnsignedByte();
				streamID = ((input.readUnsignedShort() << 8) | input.readUnsignedByte());
				bodyTagHeader = input.readByte();
				end = input.position + step + 3;
				tagLength = end-offset;
				
				if ( currentTag == FlvWizard.AUDIO_TAG ) 
				{
					_sound.writeBytes(input, offset, tagLength);
					
				} else if ( currentTag == FlvWizard.VIDEO_TAG )
				{
					_video.writeBytes(input, offset, tagLength);
					
				} else if ( currentTag == FlvWizard.SCRIPT_TAG )
				{
					_sound.writeBytes(input, offset, tagLength);	
					_video.writeBytes(input, offset, tagLength);
				}
				input.position = end;
			}
			
			if (channel == FlvWizard.SOUND_CHANNEL) {
				return _sound;
			} else if (channel == FlvWizard.VIDEO_CHANNEL) {
				return _video;
			} else {
				throw(new Error("Can only handle audio or video tags, please validate that channel value is either FlvWizard.SOUND_CHANNEL or FlvWizard.VIDEO_CHANNEL."));
			}
		}
		
		/**
		 * Given a video only FLV and an audio only FLV, merges the two into a new FLV. 
		 * @param videoInput	FLV bytearray containing the video channel.
		 * @param soundInput	FLV bytearray containing the audio channel.
		 * @param syncToAudio	Pass true (default) to sync according to the audio channel or false to sync by the video channel.
		 * @return	A merged FLV that contains both audio and video channels. 
		 * 
		 */		
		public function mergeChannels (videoInput:ByteArray, soundInput:ByteArray, syncToAudio:Boolean = true):ByteArray 
		{
			videoInput = clone(videoInput);
			soundInput = clone(soundInput);
			var offset:int, offset1:int; 
			var end:int, end1:int;
			var tagLength:int, tagLength1:int;
			var currentTag:int, currentTag1:int;
			var step:int, step1:int;
			var bodyTagHeader:int, bodyTagHeader1:int;
			var streamID:int, streamID1:int;
			var time1:int;
			var timestampExtended1:int;
			var _merged:ByteArray = new ByteArray ();
			
			// skip the headers of the inputs
			videoInput.position = findTagsStart(videoInput);
			soundInput.position = findTagsStart(soundInput);
			
			//write FLV header
			_merged.writeBytes(createFLVHeader(videoInput.bytesAvailable > 0, soundInput.bytesAvailable > 0));
			var posBeforeMetadata:int = _merged.position;
			//write FLV metadata tag
			var metadata:Array = createMetaData();
			_merged.writeBytes(metadata[0]);
			//calc position of duration var in metadata
			var durationVarPos:uint = metadata[1] + posBeforeMetadata;
			
			var bytes:Array; 
			bytes = (syncToAudio ? [soundInput, videoInput] : [videoInput, soundInput]);
			
			// run for all the tags in the inputs, syncing to the desired channel (video/audio input)
			while ( bytes[0].bytesAvailable > 0 )
			{
				// read tag N from syncTo input
				offset1 = bytes[0].position; 
				currentTag1 = bytes[0].readByte();
				step1 = (bytes[0].readUnsignedShort() << 8) | bytes[0].readUnsignedByte();
				time1 = (bytes[0].readUnsignedShort() << 8) | bytes[0].readUnsignedByte();
				timestampExtended1 = bytes[0].readUnsignedByte();
				streamID1 = ((bytes[0].readUnsignedShort() << 8) | bytes[0].readUnsignedByte());
				bodyTagHeader1 = bytes[0].readByte();
				end1 = bytes[0].position + step1 + 3;
				tagLength1 = end1 - offset1;
				
				if (bytes[1].bytesAvailable > 0) {
					// read tag N from synced input
					offset = bytes[1].position; 
					currentTag = bytes[1].readByte();
					step = (bytes[1].readUnsignedShort() << 8) | bytes[1].readUnsignedByte();
					//override the time with the time of the channel we're syncing to:
					bytes[1].writeShort(time1 >> 8); //time upper 8bit
					bytes[1].writeByte(time1 & 0xff); //time lower
					bytes[1].writeByte(timestampExtended1); //TimestampExtended
					streamID = ((bytes[1].readUnsignedShort() << 8) | bytes[1].readUnsignedByte());
					bodyTagHeader = bytes[1].readByte();
					end = bytes[1].position + step + 3;
					tagLength = end - offset;
				}
				
				// if it's not script-tags, write to the merged flv
				if ( currentTag != FlvWizard.SCRIPT_TAG ) 
					_merged.writeBytes(bytes[1], offset, tagLength);
				if ( currentTag1 != FlvWizard.SCRIPT_TAG ) 
					_merged.writeBytes(bytes[0], offset1, tagLength1);
				
				bytes[1].position = end;
				bytes[0].position = end1;
			}
			// update the duration variable in the FLV metadata
			_merged.position = durationVarPos;
			_merged.writeBytes(writeNumberVariable(FlvWizard.DURATION, (timestampExtended1 << 8 | time1)/1000));
			return _merged;
		}
		
		/**
		 * Slices (Clip) a given FLV bytearray according to given in and out points (millis).
		 * @param videoInput	the FLV bytearray to slice.
		 * @param in_point			in point in millisec.
		 * @param out_point			out point in millisec.
		 * @param pin2keyframe	if true will slice the video in the nearest keyframe rather than frame, true will usually produce better video results.
		 * @return	A newly clipped FLV of the given FLV according to the in and out points.
		 */             
		public function slice (videoInput:ByteArray, in_point:int, out_point:int = -1, pin2keyframe:Boolean = true):ByteArray
		{
			if ( (out_point >= 0) && (out_point <= in_point) ) throw new Error ("in point must be smaller than out point");
			videoInput = clone(videoInput);
			var offset:int; 
			var end:int;
			var tagLength:int;
			var currentTag:int;
			var step:int;
			var bodyTagHeader:int;
			var streamID:int;
			var time:int = 0;
			var timestampExtended:int;
			var keyframe:int;
			var soundFormat:int;
			var soundRate:int;
			var soundSize:int;
			var soundType:int;
			var codecID:int;
			var _sliced:ByteArray = new ByteArray ();
			
			//write FLV header
			_sliced.writeBytes(createFLVHeader(true, true));
			var posBeforeMetadata:int = _sliced.position;
			//write FLV metadata tag
			var metadata:Array = createMetaData();
			_sliced.writeBytes(metadata[0]);
			//calc position of duration var in metadata
			var durationVarPos:uint = metadata[1] + posBeforeMetadata;
			var beforeTimeRead:uint = 0;
			// skip the headers of the inputs
			videoInput.position = findTagsStart(videoInput);
			// run for all the tags in the inputs, syncing to the desired channel (video/audio input)
			var foundStart:Boolean = false;
			var startTime:uint = 0;
			while (videoInput.bytesAvailable > 0)
			{
				if ((out_point > 0) && (time >= out_point)) {
					if (!pin2keyframe) {
						break;
					} else if ((pin2keyframe && (keyframe == 1))) { 
						break;
					}	
				}
				// read tag N from input
				offset = videoInput.position; 
				currentTag = videoInput.readByte();
				step = (videoInput.readUnsignedShort() << 8) | videoInput.readUnsignedByte();
				beforeTimeRead = videoInput.position;
				time = (videoInput.readUnsignedShort() << 8) | videoInput.readUnsignedByte();
				timestampExtended = videoInput.readUnsignedByte();
				streamID = ((videoInput.readUnsignedShort() << 8) | videoInput.readUnsignedByte());
				bodyTagHeader = videoInput.readByte();
				end = videoInput.position + step + 3;
				tagLength = end - offset;
				
				if ( currentTag == FlvWizard.AUDIO_TAG ) 
				{
					soundFormat = (bodyTagHeader & 0xF0) >> 4;
					soundRate = (bodyTagHeader & 0xC) >> 2;
					soundSize = (bodyTagHeader & 0x2) >> 1;
					soundType = (bodyTagHeader & 0x1);
					
				} else if ( currentTag == FlvWizard.VIDEO_TAG ) {
					keyframe = (bodyTagHeader & 0xF0) >> 4;
					codecID = (bodyTagHeader & 0xF0) >> 4;
				}
				
				if (time >= in_point && !foundStart) {
					if ((!pin2keyframe) || (pin2keyframe && (keyframe == 1))) {
						foundStart = true;
						startTime = time;
					}
				}
				if (time >= in_point) {
					//override the time with the time of the channel we're syncing to:
					videoInput.position = beforeTimeRead;
					videoInput.writeShort((time-startTime) >> 8); //time upper 8bit
					videoInput.writeByte((time-startTime) & 0xff); //time lower
					videoInput.writeByte(((time-startTime)& 0xFF000000) >> 24); //TimestampExtended
				}
				
				// if it's time to cut and if it's not script-tags, write to the merged flv
				if (foundStart && (currentTag != FlvWizard.SCRIPT_TAG) ) 
					_sliced.writeBytes(videoInput, offset, tagLength);
				
				videoInput.position = end;
			}
			// update the duration variable in the FLV metadata
			_sliced.position = durationVarPos;
			var totalTime:uint = 0;
			if(in_point < 0) in_point = 0;
			if(in_point > time) in_point = time;
			if((out_point < 0) || (out_point > time)) out_point = time;
			totalTime = out_point - in_point;
			_sliced.writeBytes(writeNumberVariable(FlvWizard.DURATION, (timestampExtended << 8 | totalTime)/1000));
			return _sliced;
		}
		
		/**
		 * Given an FLV and in time (millis) returns the time (millis) of the next keyframe.
		 * @param videoInput	the FLV bytearray to slice.
		 * @param in_point			in point in millisec.
		 * @return	A newly clipped FLV of the given FLV according to the in and out points.
		 */             
		public function getNextKeyframeTime (videoInput:ByteArray, in_point:int, backward:Boolean = false):uint
		{
			videoInput = clone(videoInput);
			var offset:int; 
			var end:int;
			var tagLength:int;
			var currentTag:int;
			var step:int;
			var bodyTagHeader:int;
			var streamID:int;
			var time:int = 0;
			var timestampExtended:int;
			var keyframe:int;
			var soundFormat:int;
			var soundRate:int;
			var soundSize:int;
			var soundType:int;
			var codecID:int;
			var lastkf:uint = 0;
			// skip the headers of the inputs
			videoInput.position = findTagsStart(videoInput);
			// run for all the tags in the inputs, syncing to the desired channel (video/audio input)
			var foundStart:Boolean = false;
			var startTime:uint = 0;
			while (videoInput.bytesAvailable > 0)
			{
				// read tag N from input
				offset = videoInput.position; 
				currentTag = videoInput.readByte();
				step = (videoInput.readUnsignedShort() << 8) | videoInput.readUnsignedByte();
				time = (videoInput.readUnsignedShort() << 8) | videoInput.readUnsignedByte();
				timestampExtended = videoInput.readUnsignedByte();
				streamID = ((videoInput.readUnsignedShort() << 8) | videoInput.readUnsignedByte());
				bodyTagHeader = videoInput.readByte();
				end = videoInput.position + step + 3;
				tagLength = end - offset;
				
				if ( currentTag == FlvWizard.AUDIO_TAG ) 
				{
					soundFormat = (bodyTagHeader & 0xF0) >> 4;
					soundRate = (bodyTagHeader & 0xC) >> 2;
					soundSize = (bodyTagHeader & 0x2) >> 1;
					soundType = (bodyTagHeader & 0x1);
					
				} else if ( currentTag == FlvWizard.VIDEO_TAG ) {
					keyframe = (bodyTagHeader & 0xF0) >> 4;
					codecID = (bodyTagHeader & 0xF0) >> 4;
				}
				
				if (keyframe == 1) {
					lastkf = startTime;
					startTime = time;
				}
				if (time >= in_point && !foundStart) {
					foundStart = true;
					break;
				}
				
				videoInput.position = end;
			}
			if (backward)
				return lastkf;
			else
				return startTime;
				
		}
		
		/**
		 * Retrieves the duration of the video in millisec.
		 * @param videoInput	the FLV bytearray to slice.
		 * @return The duration of the video in millisec.
		 */             
		public function findDuration (videoInput:ByteArray):uint
		{
			var offset:int; 
			var end:int;
			var currentTag:int;
			var step:int;
			var bodyTagHeader:int;
			var streamID:int;
			var time:int = 0;
			var timestampExtended:int;
			videoInput.position = findTagsStart(videoInput);
			while (videoInput.bytesAvailable > 0)
			{
				offset = videoInput.position; 
				currentTag = videoInput.readByte();
				step = (videoInput.readUnsignedShort() << 8) | videoInput.readUnsignedByte();
				time = (videoInput.readUnsignedShort() << 8) | videoInput.readUnsignedByte();
				timestampExtended = videoInput.readUnsignedByte();
				streamID = ((videoInput.readUnsignedShort() << 8) | videoInput.readUnsignedByte());
				bodyTagHeader = videoInput.readByte();
				end = videoInput.position + step + 3;
				videoInput.position = end;
			}
			return ((timestampExtended << 8) | time);
		}
		
		/**
		 * Given a Vector of FLV bytearray, returns a merged FLV bytearray of all given FLVs.  
		 * @param streams	A vector of FLV bytearraus.
		 * @return	A merged FLV that contains all given FLVs in sequential manner. 
		 * 
		 */		
		public function concatStreams (streams:Vector.<ByteArray>):ByteArray 
		{
			var offset:int; 
			var end:int;
			var tagLength:int;
			var currentTag:int;
			var step:int;
			var bodyTagHeader:int;
			var streamID:int;
			var time:int;
			var timestampExtended:int;
			var _merged:ByteArray = new ByteArray ();
			
			//write FLV header
			_merged.writeBytes(createFLVHeader(true, true));
			var posBeforeMetadata:int = _merged.position;
			//write FLV metadata tag
			var metadata:Array = createMetaData();
			_merged.writeBytes(metadata[0]);
			//calc position of duration var in metadata
			var durationVarPos:uint = metadata[1] + posBeforeMetadata;
			var beforeTimeRead:uint = 0;
			var totalTime:uint = 0;
			for each (var videoInput:ByteArray in streams) {
				videoInput = clone(videoInput);
				// skip the headers of the inputs
				videoInput.position = findTagsStart(videoInput);
				// run for all the tags in the inputs, syncing to the desired channel (video/audio input)
				while ( videoInput.bytesAvailable > 0 )
				{
					// read tag N from input
					offset = videoInput.position; 
					currentTag = videoInput.readByte();
					step = (videoInput.readUnsignedShort() << 8) | videoInput.readUnsignedByte();
					beforeTimeRead = videoInput.position;
					time = (videoInput.readUnsignedShort() << 8) | videoInput.readUnsignedByte();
					timestampExtended = videoInput.readUnsignedByte();
					//override the time with the time of the channel we're syncing to:
					videoInput.position = beforeTimeRead;
					videoInput.writeShort((time+totalTime) >> 8); //time upper 8bit
					videoInput.writeByte((time+totalTime) & 0xff); //time lower
					videoInput.writeByte(((time+totalTime)& 0xFF000000) >> 24); //TimestampExtended
					streamID = ((videoInput.readUnsignedShort() << 8) | videoInput.readUnsignedByte());
					bodyTagHeader = videoInput.readByte();
					end = videoInput.position + step + 3;
					tagLength = end - offset;
					
					// if it's not script-tags, write to the merged flv
					if ( currentTag != FlvWizard.SCRIPT_TAG ) 
						_merged.writeBytes(videoInput, offset, tagLength);
					
					videoInput.position = end;
				}
				totalTime += (timestampExtended & 0xFF000000) | time & 0xffff;
			}
			// update the duration variable in the FLV metadata
			_merged.position = durationVarPos;
			_merged.writeBytes(writeNumberVariable(FlvWizard.DURATION, (timestampExtended << 8 | totalTime)/1000));
			return _merged;
		}
		
		/**
		 * Utility function to clone a bytearray to a new one (used to not mess up source bytearrays).
		 * @param source	The bytearray to clone.
		 * @return	A new bytearray containing the exact source bytes.
		 **/ 
		public function clone(source:ByteArray):ByteArray
		{
			var myBA:ByteArray = new ByteArray();
			myBA.writeBytes(source);
			myBA.position = 0;
			return myBA;
		}
	}
}