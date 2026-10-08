pragma SPARK_Mode (On);
package body Reverse_Linked_List_II is
   function Empty return List is
   begin
      return (Data => (others => 0), Length => 0);
   end Empty;
   procedure Append (L : in out List; Value : Integer) is
   begin
      L.Length := L.Length + 1;
      L.Data (L.Length) := Value;
   end Append;
   function Get (L : List; P : Position) return Integer is
   begin
      return L.Data (P);
   end Get;
   procedure Solve (L : in out List; First : Position; Last : Position) is
      I : Position := First;
      J : Position := Last;
      Temp : Integer;
   begin
      while I < J loop
         pragma Loop_Invariant (I in Position and then J in Position);
         Temp := L.Data (I);
         L.Data (I) := L.Data (J);
         L.Data (J) := Temp;
         I := I + 1;
         J := J - 1;
      end loop;
   end Solve;
end Reverse_Linked_List_II;
