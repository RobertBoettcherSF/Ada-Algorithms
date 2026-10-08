pragma SPARK_Mode (On);

package Linked_List_Cycle is
   subtype Index is Natural range 0 .. 16;
   subtype Node_Index is Index range 1 .. 16;
   type List is private;
   function Empty return List;
   procedure Set_Next (L : in out List; Node : Node_Index; Next : Index);
   function Has_Cycle (L : List; Head : Index) return Boolean;
private
   type Next_Array is array (Index) of Index;
   type Used_Array is array (Index) of Boolean;
   type List is record
      Nexts : Next_Array := (others => 0);
      Used : Used_Array := (others => False);
   end record;
end Linked_List_Cycle;
