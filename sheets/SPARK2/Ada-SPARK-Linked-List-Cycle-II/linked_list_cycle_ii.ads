pragma SPARK_Mode (On);

package Linked_List_Cycle_II is
   subtype Node is Natural range 0 .. 16;
   type Chain is private;

   function Make (Entry_Node : Node) return Chain;
   function Cycle_Entry (C : Chain) return Node;
   function Has_Cycle (C : Chain) return Boolean;
private
   type Chain is record
      Entry_Node : Node := 0;
   end record;
end Linked_List_Cycle_II;
