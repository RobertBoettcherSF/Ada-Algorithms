pragma Ada_2022;
with Interfaces;
package Complement_Of_Base_10_Integer with SPARK_Mode => On is
   subtype Word is Interfaces.Unsigned_32;
   function Complement (Value : Word) return Word with Global => null;
end Complement_Of_Base_10_Integer;
