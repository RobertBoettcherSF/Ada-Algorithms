pragma Ada_2022;

package Heaters with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Position is Integer range 0 .. 1_000;
   subtype Distance is Natural range 0 .. 1_000;
   type Position_Array is array (Index) of Position;

   function Required_Radius
     (Houses : Position_Array; Heaters : Position_Array) return Distance
     with Global => null;
end Heaters;
