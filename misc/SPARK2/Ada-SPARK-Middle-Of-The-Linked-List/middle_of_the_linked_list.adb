pragma Ada_2022;
pragma SPARK_Mode (On);
package body Middle_Of_The_Linked_List is
   function Empty return List is begin return (Data => [others => 0], Size => 0); end Empty;
   procedure Append (L : in out List; V : Value) is
   begin if L.Size < Count'Last then L.Size := L.Size + 1; L.Data (L.Size) := V; end if; end Append;
   function Length (L : List) return Count is (L.Size);
   function Middle (L : List) return Value is
   begin
      return L.Data (L.Size / 2 + 1);
   end Middle;
end Middle_Of_The_Linked_List;
