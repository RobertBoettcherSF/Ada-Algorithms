pragma Ada_2022;
with Interfaces;
package Neighboring_Bitwise_XOR with SPARK_Mode => On is
   subtype Byte is Interfaces.Unsigned_8;
   type Derived_Array is array (1 .. 4) of Byte;
   function Is_Valid (Derived : Derived_Array) return Boolean
     with Global => null;
end Neighboring_Bitwise_XOR;
