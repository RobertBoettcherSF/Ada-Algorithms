pragma Ada_2022;

package Maximum_Candies_Allocated_To_K_Children with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Pile is Natural range 0 .. 1_000;
   subtype Candy_Count is Positive range 1 .. 1_000;
   subtype Children is Positive range 1 .. 32;
   type Pile_Array is array (Index) of Pile;

   function Maximum_Candies
     (Piles : Pile_Array; K : Children) return Natural
     with Global => null;
end Maximum_Candies_Allocated_To_K_Children;
