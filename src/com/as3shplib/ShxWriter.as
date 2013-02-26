/**
 * The MIT License
 * 
 * Copyright (c) 2011 Sasa Ivetic, Map It Out Inc.
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
 package com.as3shplib
{
	import com.esri.ags.geometry.Extent;
	import com.esri.ags.geometry.Geometry;
	
	public class ShxWriter
	{
		//import flash.utils.ByteArray;
		import flash.utils.ByteArray;
		
		/**
		 * Byte buffer representing data written to the SHX file
		 */
		private var _bytes:ByteArray = new ByteArray();
		
		/**
		 * Shapefile geometry type
		 */
		private var _shapeType:String;
		
		public function ShxWriter(shapeType:String)
		{
			_shapeType = shapeType;
		}
		
		/**
		 * Returns the byte array containing data written to this point
		 */
		internal function getBytes():ByteArray {
			return _bytes;
		}
		
		/**
		 * Populates the header byte array.
		 * Header is always 100 bytes long, and is as follows:
		 * 
		 * Bytes	Type	Endian		Name
		 * 0-3		int32	big			File Code (0x0000270A)
		 * 4-23		int32	big			Unused
		 * 24-27	int32	big			File length (in 16-bit words, including header)
		 * 28-31	int32	little		Version (always 1000)
		 * 32-35	int32	little		Shape type (see ShpConstants)
		 * 36-67	double	little		Minimum bounding rectangle (extent as four doubles:
		 * 								minX, minY, maxX, maxY)
		 * 68-83	double	little		Range of Z (two doubles: minZ, maxZ).  Empty in our case.
		 * 84-99	double	little		Range of M (two doubles: minM, maxM).  Empty in our case.
		 */
		internal function initHeader():void {
			var tmpBytes:ByteArray = new ByteArray();
			
			_bytes.endian = flash.utils.Endian.BIG_ENDIAN;
			// Header start code			
			_bytes.writeInt(ShpConstants.HEADER_START_CODE);
			// 20 unused/empty bytes
			tmpBytes.length = 20;
			_bytes.writeBytes(tmpBytes);
			// Write the length of the header first, we'll update it later
			_bytes.writeInt(int(ShpConstants.HEADER_LENGTH/2));
			
			_bytes.endian = flash.utils.Endian.LITTLE_ENDIAN;
			// Version
			_bytes.writeInt(ShpConstants.VERSION_CODE);
			
			// Shape type
			if (_shapeType == Geometry.MAPPOINT)
				_bytes.writeInt(ShpConstants.POINT_SHAPE_TYPE);
			else if (_shapeType == Geometry.MULTIPOINT)
				_bytes.writeInt(ShpConstants.MULTIPOINT_SHAPE_TYPE);
			else if (_shapeType == Geometry.POLYLINE)
				_bytes.writeInt(ShpConstants.POLYLINE_SHAPE_TYPE);
			else
				_bytes.writeInt(ShpConstants.POLYGON_SHAPE_TYPE);

			// Enclosing bounds - minX, minY, maxX, maxY
			_bytes.writeDouble(0.0);
			_bytes.writeDouble(0.0);
			_bytes.writeDouble(0.0);
			_bytes.writeDouble(0.0);
			
			// Min and max Z/M values (unused)
			tmpBytes.length = 32;
			_bytes.writeBytes(tmpBytes);
		}
		
		/**
		 * Adds a record to the index file at the specified index.
		 * 
		 * Index Record:
		 * 
		 * Bytes	Type	Endian		Name
		 * 0-3		int32	big			Offset as number of 16-bit words from start of the file
		 * 								First record has offset 50, second record has offset 
		 * 								50+1st record length, etc
		 * 4-7		int32	big			Contente Lenght of the shapefile record (same as written to SHP)
		 */
		internal function addRecord(offset:uint, recordLength:uint, index:int):void {
			_bytes.endian = flash.utils.Endian.BIG_ENDIAN;			
			// Offset and record length are in 16-bit words, so we divide by 2 
			_bytes.writeInt(offset / 2);
			_bytes.writeInt(recordLength / 2);
		}
		
		/**
		 * Updates extent stored in the header
		 * 
		 * @param extent		Minimum bounding box of all the features stored 
		 * 						in the shapefile
		 */
		internal function setBBox(extent:Extent):void {
			// First set the buffer position to the header bbox index
			_bytes.endian = flash.utils.Endian.LITTLE_ENDIAN;
			var pos:uint = _bytes.position;
			_bytes.position = ShpConstants.HEADER_BBOX_INDEX;
			_bytes.writeDouble(extent.xmin);
			_bytes.writeDouble(extent.ymin);
			_bytes.writeDouble(extent.xmax);
			_bytes.writeDouble(extent.ymax);
			
			// Go to the end of the buffer
			_bytes.position = pos;
		}
		
		/**
		 * Updates the length of the SHX file.
		 * Length is stored in 16-bit words.
		 */
		internal function updateHeaderLength():void {
			_bytes.endian = flash.utils.Endian.BIG_ENDIAN;
			// Set the position to the header file length index
			var pos:uint = _bytes.position;
			_bytes.position = ShpConstants.HEADER_FILE_LENGTH; 
			_bytes.writeInt(int(_bytes.length/2));
			
			// Go to the end of the buffer
			_bytes.position = pos;
		}
	}
}