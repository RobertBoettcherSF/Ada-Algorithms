pragma Ada_2022;

package Koko_Eating_Bananas with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Pile_Size is Positive range 1 .. 100;
   subtype Speed is Positive range 1 .. 100;
   subtype Hour_Count is Positive range Length .. 100;
   type Pile_Array is array (Index) of Pile_Size;

   function Minimum_Speed
     (Piles : Pile_Array; Hours : Hour_Count) return Speed
     with Global => null;
end Koko_Eating_Bananas;
