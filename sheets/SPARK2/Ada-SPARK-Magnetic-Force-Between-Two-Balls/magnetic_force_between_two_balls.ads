pragma Ada_2022;

package Magnetic_Force_Between_Two_Balls with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Position is Integer range 0 .. 1_000;
   subtype Distance is Natural range 0 .. 1_000;
   type Position_Array is array (Index) of Position;

   function Maximum_Force (Positions : Position_Array) return Distance
     with Pre => Positions (Index'First) <= Positions (Index'Last),
          Global => null;
end Magnetic_Force_Between_Two_Balls;
