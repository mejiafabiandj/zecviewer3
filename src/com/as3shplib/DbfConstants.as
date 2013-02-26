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
	public class DbfConstants
	{
		/**
		 * Initial start year, used for the header
		 */
		internal static const START_YEAR:int = 1900;
		
		/**
		 * Language driver id
		 */
		internal static const LANGUAGE_DRIVER_ID:int = 0x57;
		
		/**
		 * Maximum length of a field name
		 */
		internal static const MAX_FIELD_NAME_LENGTH:int = 10;
		
		/**
		 * Index in the header storing the number of records in the table
		 */
		internal static const NUM_RECORDS_IN_TABLE_INDEX:int = 4;
		
		/**
		 * Index in the header storing the size (in bytes) of the header
		 */
		internal static const NUM_BYTES_IN_HEADER_INDEX:int = 8;
		
		/**
		 * Index in the header storing the size (in bytes) of the record
		 */
		internal static const NUM_BYTES_IN_RECORD_INDEX:int = 10;
		
		/**
		 * Header termination character
		 */
		internal static const HEADER_TERMINATOR:int = 0x0D;
		
		/**
		 * EOF marker
		 */
		internal static const EOF_TERMINATOR:int = 0x1A;
		
		/**
		 * Padding character used by DBFs
		 */
		internal static const PAD:int = 0x20;
		
		
		/**
		 * Default data type lengths, as defined by ESRI.  REST api does
		 * not publish length/precision (with the exception of strings),
		 * so we have to use the default values which may result in
		 * values that aren't saved (instead of rounding/etc). 
		 */
		 
		 
		/**
		 * Default length of a short integer, as defined by ESRI
		 */
		internal static const SHORT_INTEGER_LENGTH:int = 4;
		
		/**
		 * Default length of an integer, as defined by ESRI
		 */
		internal static const INTEGER_LENGTH:int = 9;
		
		/**
		 * Default precision of a single, as defined by ESRI
		 */
		internal static const SINGLE_LENGTH:int = 13;
		
		/**
		 * Default precision of a single, as defined 
		 */
		internal static const SINGLE_PRECISION:int = 11;
		
		/**
		 * Default precision of a double, as defined by ESRI
		 */
		internal static const DOUBLE_LENGTH:int = 19;
		
		/**
		 * Default precision of a double, as defined by ESRI
		 */
		internal static const DOUBLE_PRECISION:int = 11;
		
		/**
		 * Length of a date
		 */
		internal static const DATE_LENGTH:int = 8;
		
		/**
		 * Length of a guid
		 */
		internal static const GUID_LENGTH:int = 38;
		
		/**
		 * Maximum string length is 255 characters
		 */
		 internal static const MAX_STRING_LENGTH:int = 255;
	}
}