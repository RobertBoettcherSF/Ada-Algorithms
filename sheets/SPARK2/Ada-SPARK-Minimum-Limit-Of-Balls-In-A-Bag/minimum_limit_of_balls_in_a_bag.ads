pragma Ada_2022;

package Minimum_Limit_Of_Balls_In_A_Bag with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Ball_Count is Positive range 1 .. 1_000;
   subtype Limit is Positive range 1 .. 1_000;
   subtype Operations is Natural range 0 .. 8_000;
   type Bag_Array is array (Index) of Ball_Count;

   function Minimum_Limit
     (Bags : Bag_Array; Allowed : Operations) return Limit
     with Global => null;
end Minimum_Limit_Of_Balls_In_A_Bag;
