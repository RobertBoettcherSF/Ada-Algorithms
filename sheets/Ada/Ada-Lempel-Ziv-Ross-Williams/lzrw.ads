with Ada.Streams; use Ada.Streams;

package LZRW is
   -- All variants mentioned in the LZRW Wikipedia article
   type LZRW_Variant is (LZRW1, LZRW1_A, LZRW2, LZRW3, LZRW3_A, LZRW4, LZRW5);
   
   Compression_Error   : exception;
   Decompression_Error : exception;
   
   -- Computes the maximum possible size for the output buffer to avoid overflow
   function Max_Compressed_Size (Input_Size : Natural) return Natural;
   
   -- Compresses the input using the specified LZRW variant
   procedure Compress 
     (Input       : in Stream_Element_Array;
      Output      : out Stream_Element_Array;
      Output_Size : out Natural;
      Variant     : in LZRW_Variant := LZRW1);
      
   -- Decompresses the input using the specified LZRW variant
   procedure Decompress 
     (Input       : in Stream_Element_Array;
      Output      : out Stream_Element_Array;
      Output_Size : out Natural;
      Variant     : in LZRW_Variant := LZRW1);
end LZRW;
