pragma Ada_2022;

package Pattern_132 with SPARK_Mode => On is
   subtype Length_Type is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   subtype Value is Integer range -32 .. 32;
   type Values is array (Index) of Value;

   function Exists (A : Values; Length : Length_Type) return Boolean
     with Global => null;
end Pattern_132;
