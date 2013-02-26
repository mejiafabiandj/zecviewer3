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
	/**
	 * Contains various constants used when writing shapefiles,
	 * including header constants, etc.
	 */
	internal class ShpConstants
	{
		/**
		 * Header length, in bytes.
		 */
		internal static const HEADER_LENGTH:int = 100;
		
		/**
		 * File code (header always starts with this)
		 */
		internal static const HEADER_START_CODE:int = 0x0000270A;
		
		/**
		 * Shapefile version
		 */
		internal static const VERSION_CODE:int = 1000;
		
		/**
		 * Index of the bounding box in the shapefile header
		 */
		internal static const HEADER_FILE_LENGTH:int = 24;
		
		/**
		 * Index of the bounding box in the shapefile header
		 */
		internal static const HEADER_BBOX_INDEX:int = 36;
		
		/**
		 * SHP Header point geometry type
		 */
		internal static const POINT_SHAPE_TYPE:int = 1;
		
		/**
		 * SHP Header polyline geometry type
		 */
		internal static const POLYLINE_SHAPE_TYPE:int = 3;
		
		/**
		 * SHP Header polygon geometry type
		 */
		internal static const POLYGON_SHAPE_TYPE:int = 5;
		
		/**
		 * SHP Header multipoint geometry type
		 */
		internal static const MULTIPOINT_SHAPE_TYPE:int = 8;
		
	}
}