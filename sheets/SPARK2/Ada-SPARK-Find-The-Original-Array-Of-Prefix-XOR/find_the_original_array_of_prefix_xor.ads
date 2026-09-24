pragma Ada_2022;
with Interfaces;
package Find_The_Original_Array_Of_Prefix_XOR with SPARK_Mode => On is
   subtype Byte is Interfaces.Unsigned_8;
   type Prefix_Array is array (1 .. 4) of Byte;
   type Original_Array is array (1 .. 4) of Byte;
   function Recover (Prefix : Prefix_Array) return Original_Array
     with Global => null;
end Find_The_Original_Array_Of_Prefix_XOR;
