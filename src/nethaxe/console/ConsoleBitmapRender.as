package rogueutil.console 
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	/**
	 * ...
	 * @author Kyle Stewart
	 */
	public class ConsoleBitmapRender extends Bitmap 
	{
		
		protected var _consoleFont:ConsoleFont
		protected var _consoleData:ConsoleData
		
		protected var _fgCopy:Vector.<uint>
		protected var _bgCopy:Vector.<uint>
		protected var _charCopy:Vector.<uint>
		
		
		/**
		 * This object is slower than ConsoleRender!
		 */
		
		public function ConsoleBitmapRender(consoleData:ConsoleData, consoleFont:ConsoleFont) 
		{
			_consoleFont = consoleFont
			_consoleData = consoleData
			
			super(new BitmapData(_consoleFont.tileWidth * _consoleData.width,
			                     _consoleFont.tileHeight * consoleData.height), "auto", false);
			
			addEventListener(Event.ENTER_FRAME, update, false, 0, true)
			addEventListener(Event.RENDER, update, false, 0, true)
			
			_fgCopy = new Vector.<uint>(_width * _height)
			_bgCopy = new Vector.<uint>(_width * _height)
			_charCopy = new Vector.<uint>(_width * _height)
		}
		
		protected function get _width():int {
			return _consoleData.width
		}
		
		protected function get _height():int {
			return _consoleData.height
		}
		
		protected function update(e:Event):void {
			var chars:Vector.<int> = _consoleData._chars
			var fg:Vector.<uint> = _consoleData.fgColor.getVector(_consoleData.rect)
			var bg:Vector.<uint> = _consoleData.bgColor.getVector(_consoleData.rect)
			//var fg:Vector.<uint> = _consoleData._fgColorVector
			//var bg:Vector.<uint> = _consoleData._bgColorVector
			
			var i:int = _width * _height - 1
			
			var pos:Point = new Point()
			var rect:Rectangle = new Rectangle
			rect.width = _consoleFont.tileWidth
			rect.height = _consoleFont.tileHeight
			
			for (var y:int = _height - 1; y >= 0; y-- ) {
				rect.y = y * _consoleFont.tileHeight
				pos.y = rect.y
				for (var x:int = _width - 1; x >= 0; x-- ) {
					rect.x = x * _consoleFont.tileWidth
					pos.x = rect.x
					if (_charCopy[i] != chars[i] || _fgCopy[i] != fg[i] || _bgCopy[i] != bg[i]) {
						bitmapData.fillRect(rect, bg[i])
						var glyph:BitmapData = _consoleFont.getGlyph(chars[i])
						if(glyph){
							bitmapData.merge(glyph, glyph.rect, pos, fg[i] >> 16 & 0xff, fg[i] >> 8 & 0xff, fg[i] & 0xff, 1)
						}
						_bgCopy[i] = bg[i]
						_fgCopy[i] = fg[i]
						_charCopy[i] = chars[i]
					}
					i--
				}
			}
		}
		
	}

}