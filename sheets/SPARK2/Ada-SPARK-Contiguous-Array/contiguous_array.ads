pragma Ada_2022;

package Contiguous_Array with SPARK_Mode => On is
   Size : constant := 32;
   subtype Index is Positive range 1 .. Size;
   subtype Bit is Integer range 0 .. 1;
   subtype Count is Integer range 0 .. Size;
   type Bits is array (Index) of Bit;

   function One_Count (A : Bits) return Count with Global => null;
end Contiguous_Array;
