pragma SPARK_Mode (On);

package body Design_Linked_List is
   function Empty return List is
   begin
      return (Values => (others => 0), Size => 0);
   end Empty;

   function Length (L : List) return Count is
   begin
      return L.Size;
   end Length;

   procedure Push_Front (L : in out List; V : Value) is
   begin
      case L.Size is
         when 0 => L.Values (1) := V;
         when 1 => L.Values (2) := L.Values (1); L.Values (1) := V;
         when 2 => L.Values (3) := L.Values (2); L.Values (2) := L.Values (1); L.Values (1) := V;
         when 3 => L.Values (4) := L.Values (3); L.Values (3) := L.Values (2); L.Values (2) := L.Values (1); L.Values (1) := V;
         when 4 => L.Values (5) := L.Values (4); L.Values (4) := L.Values (3); L.Values (3) := L.Values (2); L.Values (2) := L.Values (1); L.Values (1) := V;
         when 5 => L.Values (6) := L.Values (5); L.Values (5) := L.Values (4); L.Values (4) := L.Values (3); L.Values (3) := L.Values (2); L.Values (2) := L.Values (1); L.Values (1) := V;
         when 6 => L.Values (7) := L.Values (6); L.Values (6) := L.Values (5); L.Values (5) := L.Values (4); L.Values (4) := L.Values (3); L.Values (3) := L.Values (2); L.Values (2) := L.Values (1); L.Values (1) := V;
         when 7 => L.Values (8) := L.Values (7); L.Values (7) := L.Values (6); L.Values (6) := L.Values (5); L.Values (5) := L.Values (4); L.Values (4) := L.Values (3); L.Values (3) := L.Values (2); L.Values (2) := L.Values (1); L.Values (1) := V;
         when 8 => null;
      end case;
      if L.Size < Capacity then L.Size := L.Size + 1; end if;
   end Push_Front;

   procedure Append (L : in out List; V : Value) is
   begin
      case L.Size is
         when 0 => L.Values (1) := V;
         when 1 => L.Values (2) := V;
         when 2 => L.Values (3) := V;
         when 3 => L.Values (4) := V;
         when 4 => L.Values (5) := V;
         when 5 => L.Values (6) := V;
         when 6 => L.Values (7) := V;
         when 7 => L.Values (8) := V;
         when 8 => null;
      end case;
      if L.Size < Capacity then L.Size := L.Size + 1; end if;
   end Append;

   function Contains (L : List; V : Value) return Boolean is
      Found : Boolean := False;
   begin
      for I in Index loop
         if I <= L.Size and then L.Values (I) = V then Found := True; end if;
      end loop;
      return Found;
   end Contains;

   function Element_At (L : List; Position : Positive) return Value is
   begin
      return L.Values (Position);
   end Element_At;
end Design_Linked_List;
