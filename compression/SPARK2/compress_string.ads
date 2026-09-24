pragma Ada_2022;
package Compress_String with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   type Text is array (Index) of Character;
   function Compressed_Length (Input : Text) return Natural with Global => null;
end Compress_String;
