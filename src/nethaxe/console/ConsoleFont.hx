package nethaxe.console;
#if !macro
import flash.display.BitmapData;
import flash.display.Graphics;
import flash.geom.Point;
import flash.geom.Rectangle;
#end
import openfl.display.Tilesheet;

/**
 * ...
 * @author Kyle Stewart
 */
class ConsoleFont
{

	public var glyphWidth(default, null):Int;
	public var glyphHeight(default, null):Int;
	public var tileSheet(default, null):Tilesheet;
	
	static private inline var BUCKET_SIZE:Int = 256;
	static private inline var MAX_GLYPHS:Int = 0x1000;
	
	/**
	 * Most of the time entire pages of glpyhs will be missing from  a font,
	 * a bucket sort seems ideal for this kind of data
	 */
	private var _glyphBucket:Array<Array<Int>>; // create these as they are used
	private var _bitmapBucket:Array<Array<BitmapData>>;
	
	/**
	 * One texture to rule them all, hopefully optimized under most implementations
	 */
	private var _megaTex:BitmapData;
	private var _megaTexColumns:Int;
	private var _megaTexRows:Int;
	
	
	private var _nextFreeTex:Int = 0;
	
	public function new() 
	{
		//tileSheet = new Tilesheet(_megaTex);
	}
	
	/**
	 * Set the glyph state directly, usally an internal call
	 */
	private inline function setGlyphDirectly(glyph:Int, statusOrIndex:Int):Void {
		var bucketIndex:Int = Math.floor(glyph / BUCKET_SIZE);
		if (_glyphBucket[bucketIndex] == null) {
			// init bucket with unknown status
			_glyphBucket[bucketIndex] = [for (_ in 0...BUCKET_SIZE) -1];
		}
		_glyphBucket[bucketIndex][glyph % BUCKET_SIZE] = statusOrIndex;
	}
	
	/**
	 * Get the status of a glyph
	 * -1 is unknown
	 * -2 means the glyph is known to not exist or is blank
	 * any postive number starting at 0 is the index on the megaTex
	 */
	public inline function getGlyphStatus(glyph:Int):Int {
		var bucketIndex:Int = Math.floor(glyph / BUCKET_SIZE);
		if (_glyphBucket[bucketIndex] != null) {
			return _glyphBucket[bucketIndex][glyph % BUCKET_SIZE];
		}else {
			return -1; // no bucket means unknown status
		}
	}
	
	/**
	 * Get the rect of where the a texture on this index would have been placed
	 * Use getGlyphStatus(glyph) to get the status and if the return value is >= 0 then use it with this call
	 */
	public inline function getTexureRect(index:Int):Rectangle {
		var x:Int = index % _megaTexColumns;
		var y:Int = Math.floor(index / _megaTexColumns);
		return new Rectangle(x * glyphWidth, y * glyphHeight, glyphWidth, glyphHeight);
	}
	
	/**
	 * Like getTexureRect but returns u,v data
	 
	public inline function getTexureUV(index:Int):Rectangle {
		if (index < 0) { index = 0; }
		var x:Int = index % _megaTexColumns;
		var y:Int = Math.floor(index / _megaTexColumns);
		var width:Float = 1 / _megaTexColumns;
		var height:Float = 1 / _megaTexRows;
		return new Rectangle(x * width, y * height, width, height);
	}*/
	
	public function getTextureRows():Int {
		return _megaTexRows;
	}
	
	public function getTextureColumns():Int {
		return _megaTexColumns;
	}
	
	public function getTilePos(index:Int):Point {
		if (index < 0) { index = 0; }
		return new Point(index % _megaTexColumns, Math.floor(index / _megaTexColumns));
	}
	
	public inline function getTexture():BitmapData {
		updateTexture();
		return _megaTex;
	}
	
	public function getTileSheet():Tilesheet {
		updateTexture();
		return new Tilesheet(_megaTex);
	}
	
	/**
	 * Lazy update the master texture.
	 */
	private function updateTexture():Void {
		if (_megaTex != null) { return; } // only lazy updates
		if(_glyphBucket==null){
			_glyphBucket = [for ( _ in 0...(Math.floor(MAX_GLYPHS / BUCKET_SIZE))) null];
		}
		//_megaTexRows = 1;
		//_megaTexColumns = getGlypthCount();
		// TODO: dynamic texture size
		_megaTexRows = Math.floor(1024 / glyphWidth);
		_megaTexColumns = Math.floor(1024 / glyphHeight);
		_megaTex = new BitmapData(glyphWidth * _megaTexColumns, glyphHeight * _megaTexRows, true, 0x00000000);
		var texIndex:Int = 1;
		for (bIndex in 0..._bitmapBucket.length) {
			if (_bitmapBucket[bIndex] == null) { continue; }
			for (sIndex in 0...BUCKET_SIZE) {
				if (_bitmapBucket[bIndex][sIndex] == null) { continue; }
				var p:Point = getTilePos(texIndex);
				p.x *= glyphWidth;
				p.y *= glyphHeight;
				_megaTex.copyPixels(_bitmapBucket[bIndex][sIndex], _bitmapBucket[bIndex][sIndex].rect, p);
				setGlyphDirectly(bIndex * BUCKET_SIZE + sIndex, texIndex++);
			}
		}
	}
	
	/**
	 * Return a total number of glyphs to reserve texture space for
	 */
	private function getGlypthCount():Int {
		var count:Int = 1; // reserve an extra free sapce
		for (bucket in _bitmapBucket) {
			if (bucket == null) { continue; }
			for (status in bucket) {
				if (status != null) { count++; }
			}
		}
		return count;
	}
	
	public inline function getTile(glyph:Int):BitmapData {
		var status:Int = getGlyphStatus(glyph);
		if (status >= 0) {
			var bucketIndex:Int = Math.floor(status / BUCKET_SIZE);
			var subIndex:Int = glyph % BUCKET_SIZE;
			if (_bitmapBucket[bucketIndex] == null) {
				_bitmapBucket[bucketIndex] = [for (_ in 0...BUCKET_SIZE) null];
			}
			if (_bitmapBucket[bucketIndex][subIndex] == null) {
				_bitmapBucket[bucketIndex][subIndex] = new BitmapData(glyphWidth, glyphHeight, false);
				_bitmapBucket[bucketIndex][subIndex].copyPixels(getTexture(), getTexureRect(status), new Point(0, 0));
			}
			return _bitmapBucket[bucketIndex][subIndex];
		}else {
			return null;
		}
	}
	
	/**
	 * Return the index of this glyph on the texture
	 * If the glyph doesn't exist a space will be reserved and returned
	 */
	private inline function initGlyph(glpyh:Int):Int {
		var status:Int = getGlyphStatus(glpyh);
		if (status >= 0) {
			return status;
		}else {
			status = _nextFreeTex++;
			setGlyphDirectly(glpyh, status);
			return status;
		}
	}
	
	
	public function setGlyphWithBitmap(glyph:Int, bitmap:BitmapData):Void {
		if(_bitmapBucket==null){
			_bitmapBucket = [for ( _ in 0...(Math.floor(MAX_GLYPHS / BUCKET_SIZE))) null];
		}
		var bucketIndex:Int = Math.floor(glyph / BUCKET_SIZE);
		if (_bitmapBucket[bucketIndex] == null) {
			// init bucket with nulls
			_bitmapBucket[bucketIndex] = [for (_ in 0...BUCKET_SIZE) null];
		}
		_bitmapBucket[bucketIndex][glyph % BUCKET_SIZE] = bitmap;
	}
	
}