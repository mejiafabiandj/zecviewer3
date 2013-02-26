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
 package com.as3shplib {
	//import flash.utils.ByteArray;
	import flash.utils.ByteArray;
	
	import com.esri.ags.Graphic;
	import com.esri.ags.geometry.Extent;
	import com.esri.ags.geometry.Geometry;
	import com.esri.ags.geometry.MapPoint;
	import com.esri.ags.geometry.Polygon;
	import com.esri.ags.geometry.Polyline;
	
	import nochump.util.zip.ZipEntry;
	import nochump.util.zip.ZipOutput;
	
	/**
	 * Main class responsible for writing a set of ESRI Graphics 
	 * (geometries/attributes) to a shapefile.
	 */
	public class ShpWriter {
		/**
		 * File name specified for the shapefile
		 */
		private var _fileName:String;
		
		/**
		 * List of fields written to the DBF.
		 */
		private var _fields:Array;
		
		/**
		 * ESRI Spatial reference ID
		 */
		private var _wkid:int;
		
		/**
		 * Geometry type
		 */
		private var _shapeType:String;
		
		
		/**
		 * Shapefile Index writer
		 */
		private var _shxWriter:ShxWriter;
		
		/**
		 * DBF Writer
		 */
		private var _dbfWriter:DbfWriter;
		
		/**
		 * PRJ Writer
		 */
		private var _prjWriter:PrjWriter;
		
		
		/**
		 * Byte array for the shapefile (.shp), includes the header
		 */
		private var _shpBytes:ByteArray = new ByteArray();
				
		/**
		 * Creates a new instance of a ShpWriter class with the specified
		 * fields.
		 * 
		 * @param fileName	Filename to give the written shapefile
		 * 
		 * @param fields 	Array of fields describing field type and length
		 * 					of each field that will be written to the DBF file
		 * 
		 * @param wkid		ESRI Spatial reference ID
		 * 
		 * @param shapeType	The type of geometry.  Valid values are POINT, POLYLINE,
		 * 					and POLYGON
		 */
		public function ShpWriter(fileName:String, shapeType:String, wkid:int, fields:Array) {
			// Ensure ShapeType is one of the predefined shapes
			if (shapeType != Geometry.MAPPOINT && shapeType != Geometry.MULTIPOINT && shapeType != Geometry.POLYLINE && shapeType != Geometry.POLYGON)
				throw new Error("Invalid shapetype specified.");
			
			_fileName = fileName;
			_fields = fields;
			_shapeType = shapeType;
			_wkid = wkid;
			
			_shxWriter = new ShxWriter(_shapeType);
			_dbfWriter = new DbfWriter(_fields);
			_prjWriter = new PrjWriter(_wkid);
		}
		
		/**
		 * Writes the specified array of features to the shapefile.
		 * 
		 * @param features	Array of features to write to the shapefile.  Features
		 * 					must contain the same attributes as specified in the
		 * 					constructor.
		 */
		public function write(features:Array):void {
			initHeader();
			_shxWriter.initHeader();
			_dbfWriter.initHeader();
						
			if (_shapeType == Geometry.MAPPOINT)
				writePoints(features);
			else if (_shapeType == Geometry.MULTIPOINT)
				writeMultipoints(features);
			else if (_shapeType == Geometry.POLYLINE)
				writePolylines(features);
			else if (_shapeType == Geometry.POLYGON)
				writePolygons(features);
				
			_dbfWriter.setNumRecords(features.length);
			_dbfWriter.finishDbf();
			
			_prjWriter.createPrjFile();
		}
		
		/**
		 * Returns a ByteArray representing the shapefile and its related files
		 * compressed to a zip (shp/dbf/etc files).
		 * Note: You must call Write() before calling GetFileBytes, otherwise the
		 * function will throw an exception as there were no bytes written. 
		 */
		public function getData():ByteArray {
			if (_shpBytes.length == 0 || _shxWriter.getBytes().length == 0 || _dbfWriter.getBytes().length == 0) {
				throw new Error("Error: No bytes written to the array.  Make sure you call Write() first.");
			}
			
			// Rewind the byte arrays before returning
			var shxBytes:ByteArray = _shxWriter.getBytes();
			shxBytes.position = 0;
			var dbfBytes:ByteArray = _dbfWriter.getBytes();
			dbfBytes.position = 0;
			var prjBytes:ByteArray = _prjWriter.getBytes();
			prjBytes.position = 0;
			
			var zip:ZipOutput = new ZipOutput();
			
			// Add the individual files
			var ze:ZipEntry = new ZipEntry(_fileName + ".shp");
			zip.putNextEntry(ze);
			zip.write(_shpBytes);
			zip.closeEntry();
			
			ze = new ZipEntry(_fileName + ".shx");
			zip.putNextEntry(ze);
			zip.write(shxBytes);
			
			ze = new ZipEntry(_fileName + ".dbf");
			zip.putNextEntry(ze);
			zip.write(dbfBytes);
			
			// Ensure PRJ file was written (i.e. WKID was found) before
			// attempting to add it to the zip straem
			if (prjBytes.length > 0) {
				ze = new ZipEntry(_fileName + ".prj");
				zip.putNextEntry(ze);
				zip.write(prjBytes);
			}
			
			zip.closeEntry();
			
			zip.finish();
			
			return zip.byteArray;
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
		private function initHeader():void {
			var tmpBytes:ByteArray = new ByteArray();
			
			// Header start code			
			_shpBytes.writeInt(ShpConstants.HEADER_START_CODE);
			// 20 unused/empty bytes
			tmpBytes.length = 20;
			_shpBytes.writeBytes(tmpBytes);
			// Write the length of the header first, we'll update it later
			_shpBytes.writeInt(int(ShpConstants.HEADER_LENGTH/2));
			// Version
			_shpBytes.endian = flash.utils.Endian.LITTLE_ENDIAN;
			_shpBytes.writeInt(ShpConstants.VERSION_CODE);
			
			// Shape type
			if (_shapeType == Geometry.MAPPOINT)
				_shpBytes.writeInt(ShpConstants.POINT_SHAPE_TYPE);
			else if (_shapeType == Geometry.MULTIPOINT)
				_shpBytes.writeInt(ShpConstants.MULTIPOINT_SHAPE_TYPE);
			else if (_shapeType == Geometry.POLYLINE)
				_shpBytes.writeInt(ShpConstants.POLYLINE_SHAPE_TYPE);
			else
				_shpBytes.writeInt(ShpConstants.POLYGON_SHAPE_TYPE);

			// Enclosing bounds - minX, minY, maxX, maxY
			_shpBytes.writeDouble(0.0);
			_shpBytes.writeDouble(0.0);
			_shpBytes.writeDouble(0.0);
			_shpBytes.writeDouble(0.0);
			
			// Min and max Z/M values (unused)
			tmpBytes.length = 32;
			_shpBytes.writeBytes(tmpBytes);
		}		
		
		/**
		 * Writes an array of points to the shapefile
		 * 
		 * Each point record is composed of a header plus contents.
		 * 
		 * Header:
		 * 
		 * Bytes	Type	Endian		Name
		 * 0-3		int32	big			Record Number (record numbers start at 1)
		 * 4-8		int32	big			Content Length
		 * 
		 * Contents:
		 * 
		 * Bytes	Type	Endian		Name
		 * 0-3		int32	little		Shape Type (1 for points)
		 * 4-11		double	little		X Coordinate
		 * 12-19	double	little		Y Coordinate
		 * 
		 * 
		 * @param features	Array of points to write to the shapefile
		 */
		private function writePoints(features:Array):void {
			var feat:Graphic = features[0] as Graphic;
			var pt:MapPoint = feat.geometry as MapPoint;
			var attrs:Object = null;
			
			// Bounding box for the features
			var bb:Extent = new Extent(pt.x, pt.y, pt.x, pt.y);
			var offset:uint = 0;
			
			for (var i:int=0; i<features.length; i++) {
				offset = _shpBytes.position;
				
				feat = features[i] as Graphic;
				pt = feat.geometry as MapPoint;
				attrs = feat.attributes;
				
				_shpBytes.endian = flash.utils.Endian.BIG_ENDIAN;
				// Header - record number (starts at 1)
				_shpBytes.writeInt(i+1);
				// Header - content length in 16-bit words
				// (20 bytes: 4 for shape type + 2x8 for x/y = TEN 16 bit words)
				_shpBytes.writeInt(10);
				
				// Content - Shape Type
				_shpBytes.endian = flash.utils.Endian.LITTLE_ENDIAN;
				_shpBytes.writeInt(ShpConstants.POINT_SHAPE_TYPE);
				// Content - X/Y
				_shpBytes.writeDouble(pt.x);
				_shpBytes.writeDouble(pt.y);
				
				// Add the current point to the extent
				// This is a manual process to avoid using the ESRI Extent object
				// and save some time as points do not natively have extents created
				if (pt.x < bb.xmin)
					bb.xmin = pt.x;
				else if (pt.x > bb.xmax)
					bb.xmax = pt.x;
				if (pt.y < bb.ymin)
					bb.ymin = pt.y;
				else if (pt.y > bb.ymax)
					bb.ymax = pt.y;
					
				// Content length of a point is 8 bytes for header + 20 bytes for point
				_shxWriter.addRecord(offset, 20, i);
				_dbfWriter.addRecord(attrs);
			}
			
			updateHeader(bb);
		}
		
		/**
		 * Writes an array of multipoints to the shapefile
		 * 
		 * @param features	Array of multipoints to write to the shapefile
		 */
		private function writeMultipoints(features:Array):void {
			
		}
		
		/**
		 * Writes an array of polylines to the shapefile
		 * 
		 * Each polyline record is composed of a header plus contents.
		 * 
		 * Header:
		 * 
		 * Bytes	Type	Endian		Name
		 * 0-3		int32	big			Record Number (record numbers start at 1)
		 * 4-8		int32	big			Content Length
		 * 
		 * Contents:
		 * 
		 * Bytes	Type	Endian		Name
		 * 0-3		int32	little		Shape Type (3 for polylines)
		 * 4-35		double	little		Bounding box for the polyline
		 * 36-39	int32	little		Total number of parts in the polyline
		 * 40-43	int32	little		Total number of points for all parts
		 * 44-n		double	little		Array of length NumParts.  Stores, for each polyline,
		 * 								the index of its first point in the points array (0-based)
		 * n-m		double	little		Array of length NumPoints, stores all the points for all
		 * 								the parts.  Points for part 1 are the first X points,
		 * 								followed by points for part 2, part 3, etc.		
		 * 
		 * 
		 * @param features	Array of polylines to write to the shapefile
		 */
		private function writePolylines(features:Array):void {
			if (features.length == 0)
				return; // TODO: Handle empty files
			
			var feat:Graphic = features[0] as Graphic;
			var pl:Polyline = feat.geometry as Polyline;
			var attrs:Object = null;
			
			// Bounding box for the features
			var offset:uint = 0;
			var bb:Extent = pl.extent;
			var j:uint = 0;
			var k:uint = 0;
			
			for (var i:int=0; i<features.length; i++) {
				offset = _shpBytes.position;
				
				feat = features[i] as Graphic;
				pl = feat.geometry as Polyline;
				attrs = feat.attributes;
				
				_shpBytes.endian = flash.utils.Endian.BIG_ENDIAN;
				// Header - record number (starts at 1)
				_shpBytes.writeInt(i+1);
				// Header - content length in 16-bit words
				// 4 bytes for shape type, 32 bytes for bbox, 4 bytes for NumParts,
				// 4 bytes for NumPoints, 4*NumParts bytes for Parts,
				// 16*NumPoints bytes for Points 
				var numParts:uint = pl.paths.length;
				var numPoints:uint = 0;
				for (j=0; j<numParts; j++)
					numPoints += pl.paths[j].length;
				
				var recordLength:uint = 4 + 32 + 4 + 4 + 4*numParts + 16*numPoints;
				_shpBytes.writeInt(recordLength / 2); // in 16-bit words
				
				// Content - Shape Type
				_shpBytes.endian = flash.utils.Endian.LITTLE_ENDIAN;
				_shpBytes.writeInt(ShpConstants.POLYLINE_SHAPE_TYPE);
				// Bounding box
				_shpBytes.writeDouble(pl.extent.xmin);
				_shpBytes.writeDouble(pl.extent.ymin);
				_shpBytes.writeDouble(pl.extent.xmax);
				_shpBytes.writeDouble(pl.extent.ymax);
				// NumParts
				_shpBytes.writeInt(numParts);
				// NumPoints
				_shpBytes.writeInt(numPoints);
				
				// Write indices for all the parts
				var partIdx:uint = 0;
				_shpBytes.writeInt(0); // first index will be 0
				for (j=1; j<numParts; j++) {
					partIdx += j*pl.paths[j-1].length;
					_shpBytes.writeInt(partIdx);
				}

				// Write out the points
				for (j=0; j<numParts; j++) {
					for (k=0; k<pl.paths[j].length; k++) {
						_shpBytes.writeDouble(pl.paths[j][k].x);
						_shpBytes.writeDouble(pl.paths[j][k].y);
					}
				} 
				
				// Add the current polyline to the extent
				bb = bb.union(pl.extent);
				
				_shxWriter.addRecord(offset, recordLength, i);
				_dbfWriter.addRecord(attrs);
			}
			
			updateHeader(bb);
		}
		
		/**
		 * Writes an array of polygons to the shapefile
		 * 
		 * @param features	Array of polygons to write to the shapefile
		 */
		private function writePolygons(features:Array):void {
			if (features.length == 0)
				return; // TODO: Handle empty files
			
			var feat:Graphic = features[0] as Graphic;
			var pg:Polygon = feat.geometry as Polygon;
			var attrs:Object = null;
			
			// Bounding box for the features
			var offset:uint = 0;
			var bb:Extent = pg.extent;
			var j:uint = 0;
			var k:uint = 0;
			
			for (var i:int=0; i<features.length; i++) {
				offset = _shpBytes.position;
				
				feat = features[i] as Graphic;
				pg = feat.geometry as Polygon;
				attrs = feat.attributes;
				
				_shpBytes.endian = flash.utils.Endian.BIG_ENDIAN;
				// Header - record number (starts at 1)
				_shpBytes.writeInt(i+1);
				// Header - content length in 16-bit words
				// 4 bytes for shape type, 32 bytes for bbox, 4 bytes for NumParts,
				// 4 bytes for NumPoints, 4*NumParts bytes for Parts,
				// 16*NumPoints bytes for Points 
				var numParts:uint = pg.rings.length;
				var numPoints:uint = 0;
				for (j=0; j<numParts; j++)
					numPoints += pg.rings[j].length;
				
				var recordLength:uint = 4 + 32 + 4 + 4 + 4*numParts + 16*numPoints;
				_shpBytes.writeInt(recordLength / 2); // in 16-bit words
				
				// Content - Shape Type
				_shpBytes.endian = flash.utils.Endian.LITTLE_ENDIAN;
				_shpBytes.writeInt(ShpConstants.POLYGON_SHAPE_TYPE);
				// Bounding box
				_shpBytes.writeDouble(pg.extent.xmin);
				_shpBytes.writeDouble(pg.extent.ymin);
				_shpBytes.writeDouble(pg.extent.xmax);
				_shpBytes.writeDouble(pg.extent.ymax);
				// NumParts
				_shpBytes.writeInt(numParts);
				// NumPoints
				_shpBytes.writeInt(numPoints);
				
				// Write indices for all the parts
				var partIdx:uint = 0;
				_shpBytes.writeInt(0); // first index will be 0
				for (j=1; j<numParts; j++) {
					partIdx += pg.rings[j-1].length;
					_shpBytes.writeInt(partIdx);
				}

				// Write out the points
				for (j=0; j<numParts; j++) {
					for (k=0; k<pg.rings[j].length; k++) {
						_shpBytes.writeDouble(pg.rings[j][k].x);
						_shpBytes.writeDouble(pg.rings[j][k].y);
					}
				}
				
				// Add the current polygon to the extent
				bb = bb.union(pg.extent);
				
				_shxWriter.addRecord(offset, recordLength, i);
				_dbfWriter.addRecord(attrs);
			}
			
			updateHeader(bb);
		}
		
		/**
		 * Updates the SHP and SHX header information to include
		 * the supplied extent and current length of buffers
		 */
		private function updateHeader(extent:Extent):void {
			// Write the extent to the buffer
			// First set the buffer position to the header bbox index
			_shpBytes.endian = flash.utils.Endian.LITTLE_ENDIAN;
			var pos:uint = _shpBytes.position;
			_shpBytes.position = ShpConstants.HEADER_BBOX_INDEX;
			_shpBytes.writeDouble(extent.xmin);
			_shpBytes.writeDouble(extent.ymin);
			_shpBytes.writeDouble(extent.xmax);
			_shpBytes.writeDouble(extent.ymax);
			
			// Update the shapefile length (length is total SHP length,
			// including header, in 16-bit words)
			_shpBytes.endian = flash.utils.Endian.BIG_ENDIAN;
			_shpBytes.position = ShpConstants.HEADER_FILE_LENGTH; 
			_shpBytes.writeInt(int(_shpBytes.length/2));
			
			_shpBytes.position = pos;
			
			_shxWriter.setBBox(extent);
			_shxWriter.updateHeaderLength();
		}
	}
}