pragma SPARK_Mode (On);

package body Swapping_Nodes_In_A_Linked_List is
   function Empty return List is
   begin
      return (Data => (others => 0), Size => 0);
   end Empty;

   procedure Append (L : in out List; V : Value) is
   begin
      if L.Size < Count'Last then
         L.Size := L.Size + 1;
         L.Data (L.Size) := V;
      end if;
   end Append;

   function Length (L : List) return Count is
   begin
      return L.Size;
   end Length;

   function Element (L : List; P : Position) return Value is
   begin
      return L.Data (P);
   end Element;

   procedure Swap_Nodes (L : in out List; Left, Right : Position) is
      T : Value;
   begin
      T := L.Data (Left);
      L.Data (Left) := L.Data (Right);
      L.Data (Right) := T;
   end Swap_Nodes;
end Swapping_Nodes_In_A_Linked_List;
