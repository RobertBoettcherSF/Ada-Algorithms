pragma Ada_2022;
package Add_Binary with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Bit is Character range '0' .. '1';
   type Bits is array (Index) of Bit;
   function Add (Left : Bits; Right : Bits) return Bits with Global => null;
end Add_Binary;
