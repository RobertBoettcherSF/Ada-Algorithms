pragma Ada_2022;
package Climbing_Stairs with SPARK_Mode => On is
   subtype Steps is Natural range 0 .. 10;
   subtype Ways is Natural range 0 .. 144;
   function Count (N : Steps) return Ways with Global => null;
end Climbing_Stairs;
