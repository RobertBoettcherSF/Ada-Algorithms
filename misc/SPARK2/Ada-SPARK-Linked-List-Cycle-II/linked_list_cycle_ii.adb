pragma SPARK_Mode (On);

package body Linked_List_Cycle_II is
   function Make (Entry_Node : Node) return Chain is
   begin
      return (Entry_Node => Entry_Node);
   end Make;

   function Cycle_Entry (C : Chain) return Node is
   begin
      return C.Entry_Node;
   end Cycle_Entry;

   function Has_Cycle (C : Chain) return Boolean is
   begin
      return C.Entry_Node /= 0;
   end Has_Cycle;
end Linked_List_Cycle_II;
