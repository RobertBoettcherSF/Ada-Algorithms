pragma SPARK_Mode (On);
package body Flatten_Nested_List_Stub is
   function Empty return Values is
   begin return (Data => (others => 0), Size => 0); end Empty;
   function Length (N : Values) return Count is
   begin return N.Size; end Length;
   procedure Add (N : in out Values; V : Value) is
   begin
      case N.Size is
         when 0 => N.Data (1) := V; when 1 => N.Data (2) := V;
         when 2 => N.Data (3) := V; when 3 => N.Data (4) := V;
         when 4 => N.Data (5) := V; when 5 => N.Data (6) := V;
         when 6 => N.Data (7) := V; when 7 => N.Data (8) := V; when 8 => null;
      end case;
      if N.Size < Capacity then N.Size := N.Size + 1; end if;
   end Add;
   function Flatten (N : Values) return Values is
   begin return N; end Flatten;
   function Element_At (N : Values; Position : Positive) return Value is
   begin return N.Data (Position); end Element_At;
end Flatten_Nested_List_Stub;
