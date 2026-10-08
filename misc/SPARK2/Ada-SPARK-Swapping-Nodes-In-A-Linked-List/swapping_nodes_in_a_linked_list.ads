pragma SPARK_Mode (On);

package Swapping_Nodes_In_A_Linked_List is
   subtype Count is Natural range 0 .. 16;
   subtype Position is Count range 1 .. 16;
   subtype Value is Integer range -100 .. 100;
   type List is private;

   function Empty return List;
   procedure Append (L : in out List; V : Value);
   function Length (L : List) return Count;
   function Element (L : List; P : Position) return Value
     with Pre => P <= Length (L);
   procedure Swap_Nodes (L : in out List; Left, Right : Position)
     with Pre => Left <= Length (L) and then Right <= Length (L);
private
   type Value_Array is array (Position) of Value;
   type List is record
      Data : Value_Array := (others => 0);
      Size : Count := 0;
   end record;
end Swapping_Nodes_In_A_Linked_List;
