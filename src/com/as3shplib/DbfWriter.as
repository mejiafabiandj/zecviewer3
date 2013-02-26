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
	import com.esri.ags.layers.supportClasses.Field;
	
	public class DbfWriter
	{
		//import flash.utils.ByteArray;
		import flash.utils.ByteArray;
		
		/**
		 * Byte array for the dbf attribute file (.dbf)
		 */
		private var _bytes:ByteArray = new ByteArray();
		
		/**
		 * Array of fields each feature contains
		 */
		private var _fields:Array;
		
		/**
		 * Stores the size of an individual record in bytes
		 */ 
		private var _recordSize:int = 0;
		
		public function DbfWriter(fields:Array)
		{
			_fields = fields;
		}
		
		/**
		 * Returns the byte array containing data written to this point
		 */
		internal function getBytes():ByteArray {
			return _bytes;
		}
		
		/**
		 * Initializes the header.  Base DBF header is composed of 68 
		 * bytes.  The rest of the header is composed of the Field Descriptor
		 * array
		 * 
		 * Note: Unlike SHP/SHX files, DBF files are entirely stored in little
		 * endian mode.
		 * 
		 * Base Header:
		 * 
		 * Bytes	Type	Endian		Name
		 * 0		byte	little		Bits 0 to 2 indicate version number (3 for 
		 * 								level 5, 4 for dBase level 7)
		 * 								Bits 3 and 7 indicate presence of a dBase IV or
		 * 								dBzse for windows memo file.
		 * 								Bits 4-6 indicate presence of a dBase IV SQL table
		 * 								Bit 7 indicate presence of any .DBT memo file
		 * 								For ESRI purposes, we set this to 0x3, indicating
		 * 								level 5, and setting rest of the bits to empty.
		 * 1-3		byte	little		Date of last updated in YYMMDD format.  YY is added to
	 	 * 								1900 to determine the actual year.
	 	 * 4-7		int32	little		Number of records in the table
	 	 * 8-9		int16	little		Size of the header, in bytes
	 	 * 10-11	int16	little		Size of each individual record, in bytes
	 	 * 12-13	byte	little		Reserved, fill with 0
	 	 * 14		byte	little		Flag indicating incomplete dBase IV transaction
	 	 * 15		byte	little		dBase IV encryption flag
	 	 * 16-27	byte	little		Reserved for multi-user processing
	 	 * 28		byte	little		Produtin MDX flag. 0x01 if a production .MDX exists, 0x00 otherwise
	 	 * 29		byte	little		Language driver ID
	 	 * 30-31	byte	little		Reserved, filled with 0s
	 	 * 
		 */
		internal function initHeader():void {
			// Entire DBF file is stored in little endian
			_bytes.endian = flash.utils.Endian.LITTLE_ENDIAN;
			
			// Version information
			_bytes.writeByte(0x3);
			// Date of last updated in YYMMDD format
			var dt:Date = new Date();
			_bytes.writeByte(dt.fullYear - DbfConstants.START_YEAR);
			_bytes.writeByte(dt.month+1);
			_bytes.writeByte(dt.date);
			// Number of records in the table - write 0 for the time being, updated later
			_bytes.writeInt(0);
			// Number of bytes in the header - write 0 for the time being, updated later
			_bytes.writeShort(0);
			// Number of bytes in the record - write 0 for the time being, updated later	
			_bytes.writeShort(0);
			// Reserved (2 bytes)
			_bytes.writeShort(0);
			// dBASE IV transaction
			_bytes.writeByte(0);
			// dBASE IV encryption flag
			_bytes.writeByte(0);
			// 12 bytes for multi-user (0s)
			_bytes.writeDouble(0);
			_bytes.writeInt(0);
			// 1 byte for MDX flag
			_bytes.writeByte(0);
			// Language driver ID
			_bytes.writeByte(DbfConstants.LANGUAGE_DRIVER_ID);
			// Reserved (2 bytes)
			_bytes.writeShort(0);
			
			writeFieldDescriptors();
			
			// Update the size of header
			var pos:uint = _bytes.position;
			_bytes.position = DbfConstants.NUM_BYTES_IN_HEADER_INDEX;
			_bytes.writeShort(_bytes.length);
			
			// Update the size of record
			_bytes.position = DbfConstants.NUM_BYTES_IN_RECORD_INDEX;
			_bytes.writeShort(_recordSize + 1); // Add 1 for record termination byte
			
			_bytes.position = pos;
		}
		
		/**
		 * Writes inidivual field descriptors to the dbf
		 * 
		 * Field Descriptor Headers:
	 	 * 
	 	 * Bytes	Type	Endian		Name
	 	 * 0-10		byte	little		Field name in ASCII (zero-filled)
	 	 * 11		byte	little		Field type in ASCII (C, D, L, M, or N)
	 	 * 12-15	byte	little	Field data address (address is in memory, not useful on disk)
	 	 * 16		byte	Field length in binary
	 	 * 17		byte	Field decimal count in binary
	 	 * 18-19	byte	Reserved
	 	 * 20		byte	Work area ID (null bytes)
	 	 * 21-22	byte	Reserved
	 	 * 23		byte	SET FIELDS flag (null bytes)
	 	 * 24-31	byte	Reserved
	 	 * 
	 	 * Allowable data types:
	 	 * C - Character
	 	 * D - Date.  Stored as 8 digits in YYYYMMDD format,
	 	 * N - Numeric.
	 	 * F - Float.
	 	 * L - Logical.  Stored as ? Y y N n T t F f (? when not initialized)
	 	 * M - Memo.  Unused?
		 */
		private function writeFieldDescriptors():void {
			// Write the field descriptors
			var f:Field = null;
			var fn:String = "";
			var dbfFields:Array = new Array();
			// 14 reserved bytes
			var tmpArr:ByteArray = new ByteArray();
			tmpArr.length = 14;
			for (var i:int; i<_fields.length; i++) {
				f = _fields[i] as Field;
				
				// Make sure the field type is supported
				if (!isFieldSupported(f))
					continue;
				
				// Names are limited to 8 characters
				fn = f.name;
				if (fn.length > DbfConstants.MAX_FIELD_NAME_LENGTH) {
					// Shorten the name to 8 characters
					fn = fn.substr(0, DbfConstants.MAX_FIELD_NAME_LENGTH);
					
					// Make sure the shortened name isn't taken
					var tfn:String = fn;
					var idx:int = 0;
					while (dbfFields.indexOf(fn) >= 0)
						tfn = fn.substr(0, DbfConstants.MAX_FIELD_NAME_LENGTH - idx.toString().length - 1) + "_" + idx++;
						
					fn = tfn;
					
					dbfFields.push(fn);
				}
				
				// Write the field description to the header
				// Field name, padded with 0s
				for (var j:int=0; j<DbfConstants.MAX_FIELD_NAME_LENGTH; j++) {
					if (fn.length > j)
						_bytes.writeByte(fn.charCodeAt(j));
					else
						_bytes.writeByte(0); // pad the rest of the name w/ 0s
				}
				_bytes.writeByte(0);
				
				// Field type
				if (f.type == Field.TYPE_INTEGER || f.type == Field.TYPE_OID) {
					_bytes.writeByte("N".charCodeAt(0)); // Data type
					_bytes.writeInt(0); // Data address - null
					_bytes.writeByte(DbfConstants.INTEGER_LENGTH); // Data length - 9 for ints
					_bytes.writeByte(0); // Decimal count - 0 for ints
					_recordSize += DbfConstants.INTEGER_LENGTH;
				} else if (f.type == Field.TYPE_SMALL_INTEGER) {
					_bytes.writeByte("N".charCodeAt(0)); // Data type
					_bytes.writeInt(0); // Data address - null
					_bytes.writeByte(DbfConstants.SHORT_INTEGER_LENGTH); // Data length - 4 for short ints
					_bytes.writeByte(0); // Decimal count - 0 for ints
					_recordSize += DbfConstants.SHORT_INTEGER_LENGTH;
				} else if (f.type == Field.TYPE_DOUBLE) {
					_bytes.writeByte("F".charCodeAt(0)); // Data type
					_bytes.writeInt(0); // Data address - null
					_bytes.writeByte(DbfConstants.DOUBLE_LENGTH); // Data length - 19 for doubles
					_bytes.writeByte(DbfConstants.DOUBLE_PRECISION); // Decimal count - 11 for doubles
					_recordSize += DbfConstants.DOUBLE_LENGTH;
				} else if (f.type == Field.TYPE_SINGLE) {
					// Single is a float in AGS
					_bytes.writeByte("F".charCodeAt(0)); // Data type
					_bytes.writeInt(0); // Data address - null
					_bytes.writeByte(DbfConstants.SINGLE_LENGTH); // Data length - 13 for floats
					_bytes.writeByte(DbfConstants.SINGLE_PRECISION); // Decimal count - 11 for f
					_recordSize += DbfConstants.SINGLE_LENGTH;
				} else if (f.type == Field.TYPE_STRING) {
					_bytes.writeByte("C".charCodeAt(0)); // Data type
					_bytes.writeInt(0); // Data address - null
					_bytes.writeByte(f.length); // Data length
					_bytes.writeByte(0); // Decimal count - 0 for strings
					_recordSize += f.length;
				} else if (f.type == Field.TYPE_DATE) {
					_bytes.writeByte("D".charCodeAt(0)); // Data type
					_bytes.writeInt(0); // Data address - null
					_bytes.writeByte(DbfConstants.DATE_LENGTH); // Data length - 8 for dates
					_bytes.writeByte(0); // Decimal count - 0 for dates
					_recordSize += DbfConstants.DATE_LENGTH;
				} else if (f.type == Field.TYPE_GUID) {
					// GUIDs are 38 characters long, including dashes and { }
					// Unuspported by DBF - convert them to strings
					_bytes.writeByte("C".charCodeAt(0)); // Data type
					_bytes.writeInt(0); // Data address - null
					_bytes.writeByte(DbfConstants.GUID_LENGTH); // Data length - 38 for GUIDs
					_bytes.writeByte(0); // Decimal count - 0 for strings
					_recordSize += DbfConstants.GUID_LENGTH;
				}
				
				// 14 reserved bytes
				_bytes.writeBytes(tmpArr);
			}
			
			// Header terminator
			_bytes.writeByte(DbfConstants.HEADER_TERMINATOR);
		}
		
		/**
		 * Checks if the supplied field is a supported field.
		 * 
		 * @param f			Field to check against aa list of supported fields
		 */
		private function isFieldSupported(f:Field):Boolean {
			return f.type == Field.TYPE_INTEGER || f.type == Field.TYPE_SMALL_INTEGER || f.type == Field.TYPE_DOUBLE ||
					f.type == Field.TYPE_SINGLE || f.type == Field.TYPE_STRING || f.type == Field.TYPE_DATE || 
					f.type == Field.TYPE_GUID || f.type == Field.TYPE_OID;
		}
		
		/**
		 * Adds the feature attributes to the DBF file.
		 * 
		 * @param g			Graphic feature containing attributes to be added to the dbf
		 */
		internal function addRecord(attrs:Object):void {
			var f:Field = null;
			
			// Loop through all the fields, ensuring we write attributes
			// in correct order
			_bytes.writeByte(DbfConstants.PAD); // Deleted flag - record OK
			for (var i:int; i<_fields.length; i++) {
				f = _fields[i] as Field;
				
				// Make sure the field type is supported
				if (!isFieldSupported(f))
					continue;
				
				if (f.type == Field.TYPE_INTEGER || f.type == Field.TYPE_OID) {
					writeInteger(attrs[f.name], DbfConstants.INTEGER_LENGTH);					
				} else if (f.type == Field.TYPE_SMALL_INTEGER) {
					writeInteger(attrs[f.name], DbfConstants.SHORT_INTEGER_LENGTH);
				} else if (f.type == Field.TYPE_DOUBLE) {
					writeDecimal(attrs[f.name], DbfConstants.DOUBLE_LENGTH, DbfConstants.DOUBLE_PRECISION);
				} else if (f.type == Field.TYPE_SINGLE) {
					writeDecimal(attrs[f.name], DbfConstants.SINGLE_LENGTH, DbfConstants.SINGLE_PRECISION);
				} else if (f.type == Field.TYPE_STRING) {
					writeString(attrs[f.name], f.length);
				} else if (f.type == Field.TYPE_DATE) {
					writeDate(attrs[f.name]);
				} else if (f.type == Field.TYPE_GUID) {
					writeGuid(attrs[f.name]);
				}
			}
		}
		
		/**
		 * Adds the specified number of empty characters to
		 * padd a value in the buffer.
		 * 
		 * @param length		Number of empty characters to write to the buffer
		 */
		private function pad(length:int):void {
			for (var i:int=0; i<length; i++)
				_bytes.writeByte(DbfConstants.PAD);
		}
		
		/**
		 * Writes a short/long integer (NO decimal places)
		 * 
		 * @param val		Integer value to write to the buffer
		 * @param length	Lentgh of the field in the dbf
		 */
		private function writeInteger(val:Object, length:int):void {
			// Null value, write empty string and retur
			if (val == null) {
				pad(length);					
				return;
			}
			
			var iVal:Number = parseInt(val.toString());
			if (isNaN(iVal) || val.toString().length > length) {
				// Invalid value, or value too long.  Write empty string and return.
				pad(length);					
				return;
			}
			
			// Convert the number to a string
			var strVal:String = iVal.toString();
			pad(length-strVal.length);
				
			// Write the rest of the number
			_bytes.writeMultiByte(strVal, "us-ascii");
		}
		
		/**
		 * Writes a single/double value.
		 * 
		 * @param val		Decimal value to write to the buffer
		 * @param length	Length of the decimal field in the dbf
		 * @param precision	Number of decimal points of the field in the dbf
		 */
		private function writeDecimal(val:Object, length:int, precision:int):void {
			if (val == null) {
				// Null value, write empty string and return
				pad(length);
				return;
			}
			
			var dVal:Number = parseFloat(val.toString());
			if (isNaN(dVal)) {
				// Invalid value, write empty string and return
				pad(length);
				return;
			}
			
			// Convert the number to exponential notation
			// Number of fraction digits is the total length of the field
			// minus the potential negative sign, minus 1 character for whole #,
			// minus 1 character for the decimal place, 
			// minus 5 characters for exponential notation (e+000) 
			var strVal:String = dVal.toString();
			var fractionDigits:int = length-8;
			if (fractionDigits > Math.abs(dVal).toString().length - (strVal.indexOf(".") > -1 ? 2 : 1))
				fractionDigits = Math.abs(dVal).toString().length - (strVal.indexOf(".") > -1 ? 2 : 1);
				
			var eNotation:String;
			eNotation = toScientific(dVal, Math.max(fractionDigits, 0));
			
			pad(length-eNotation.length);
			_bytes.writeMultiByte(eNotation, "us-ascii");
		}

		/**
		 * Writes a string value.  Strings are limited to 255 characters.
		 * If the supplied string is longer, it will be trimmed.
		 * 
		 * @param val		String value to write to the buffer
		 * @param length	Length of the string field in the DBF
		 */
		private function writeString(val:Object, length:int):void {
			if (length > DbfConstants.MAX_STRING_LENGTH)
				length = DbfConstants.MAX_STRING_LENGTH;
				
			if (val == null) {
				// Null value, write empty string and return
				pad(length);
				return;
			}
			
			var str:String = val.toString();
			_bytes.writeMultiByte(str, "us-ascii");
			// Padding comes AFTER the string
			pad(length - str.length);
		}
		
		/**
		 * Writes a date to the DBF
		 * 
		 * @param val		Date value to write to the dbf
		 */
		private function writeDate(val:Object):void {
			var dt:Date = new Date(val);
			if (val == null || dt == null) {
				// Null value, write empty string and return
				pad(DbfConstants.DATE_LENGTH);
				return;
			}
			
			// Write the string date representation
			// Note: AS returns months starting at 0
			var strMonth:String = (dt.getMonth()+1<10) ? "0" + (dt.getMonth()+1).toString() : dt.getMonth().toString();
			var strDay:String = (dt.getDate()<10) ? "0" + dt.getDate().toString() : dt.getDate().toString();
			
			var strDate:String = dt.getFullYear().toString() + strMonth + strDay;
			_bytes.writeMultiByte(strDate, "us-ascii");
		}
		
		
		/**
		 * Writes a guid to the DBF
		 */
		private function writeGuid(val:Object):void {
			if (val == null) {
				// Empty value, write empty string and return
				pad(DbfConstants.GUID_LENGTH);
				return;
			}
			
			var guidStr:String = val.toString();
			_bytes.writeMultiByte(guidStr, "us-ascii");
		}
		
		/**
		 * Set the # of records in the table
		 * 
		 * @param numRecords		Total number of records contained in the dbf
		 */
		public function setNumRecords(numRecords:uint):void {
			var pos:uint = _bytes.position;
			_bytes.position = DbfConstants.NUM_RECORDS_IN_TABLE_INDEX;
			_bytes.writeInt(numRecords);
			_bytes.position = pos;
		}
		
		/**
		 * Adds a terminator string to the end of the dbf
		 */
		public function finishDbf():void {
			_bytes.writeByte(DbfConstants.EOF_TERMINATOR);
		}		
		
		// Format a number to specified number of decimal places
		// Written by Robert Penner in May 2001 - www.robertpenner.com
		// Optimized by Ben Glazer - ben@blinkonce.com - on June 8, 2001
		// Optimized by Robert Penner on June 15, 2001
		private function formatDecimals(num:Number, digits:uint):String {
			// If no decimal places needed, just use built-in Math.round
			if (digits <= 0)
				return String(Math.round(num));
		
			//temporarily make number positive, for efficiency
			if (num < 0) {
				var isNegative:Boolean = true;
				num *= -1;
			}
		
			// Round the number to specified decimal places
			// e.g. 12.3456 to 3 digits (12.346) -> mult. by 1000, round, div. by 1000
			var tenToPower:Number = Math.pow(10, digits);
			var cropped:String = String(Math.round(num * tenToPower));
		
			// Prepend zeros as appropriate for numbers between 0 and 1
			if (num < 1) {
				while (cropped.length < digits+1)
					cropped = "0" + cropped;
			}
			//restore negative sign if necessary
			if (isNegative) cropped = "-" + cropped; 
		
			// Insert decimal point in appropriate place (this has the same effect
			// as dividing by tenToPower, but preserves trailing zeros)
			var roundedNumStr:String = cropped.slice(0, -digits) + "." + cropped.slice(-digits);
			return roundedNumStr;
		};
		
		
		//convert any number to scientific notation with specified significant digits
		//e.g. .012345 -> 1.2345e-2 -- but 6.34e0 is displayed "6.34"
		//requires function formatDecimals()
		private function toScientific(num:Number, sigDigs:uint):String {
	        //find exponent using logarithm
	        //e.g. log10(150) = 2.18 -- round down to 2 using floor()
	        var exponent:Number = Math.floor(Math.log(Math.abs(num)) / Math.LN10); 
	        if (num == 0) exponent = 0; //handle glitch if the number is zero
	
	        //find mantissa (e.g. "3.47" is mantissa of 3470; need to divide by 1000)
	        var tenToPower:Number = Math.pow(10, exponent);
	        var mantissa:Number = num / tenToPower;
	
	        //force significant digits in mantissa
	        //e.g. 3 sig digs: 5 -> 5.00, 7.1 -> 7.10, 4.2791 -> 4.28
	        var output:String = formatDecimals(mantissa, sigDigs); //use custom function
	        
	        if (exponent != 0) {
	        	if (exponent < 10)
	        		output += "e+00" + exponent;
        		else if (exponent < 100)
        			output += "e+0" + exponent;
    			else
                	output += "e+" + exponent;
	        } else {
	        	output += "e+000";
	        }
	        return(output);
		}
	}
}