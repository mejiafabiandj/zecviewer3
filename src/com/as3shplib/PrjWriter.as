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
	public class PrjWriter
	{
		import flash.utils.ByteArray;
		
		private var _wkid:int;
		
		private var _bytes:ByteArray = new ByteArray();
		
		public function PrjWriter(wkid:int)
		{
			_wkid = wkid;
		}
		
		/**
		 * Creates the ESRI projection file from the specified WKID
		 */
		public function createPrjFile():void {
			var wktString:String = WktStrings.spatialReference[_wkid];
			if (wktString != null) {
				_bytes.writeMultiByte(wktString, "iso-8859-1");
			} 
		}
		
		/**
		 * Returns the bytearray containing data written to the prj file.
		 */
		public function getBytes():ByteArray {
			return _bytes;
		}
	}
}