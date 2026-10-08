pragma Ada_2022;

package body Insert_Into_BST with SPARK_Mode => On is
   function Empty return Tree is
   begin
      return (Values => [others => 0], Used => [others => False], Count => 0);
   end Empty;

   procedure Insert (T : in out Tree; V : Value) is
      P : Slot;
   begin
      if T.Count < Capacity then
         T.Count := T.Count + 1;
         P := T.Count;
         T.Values (P) := V;
         T.Used (P) := True;
      end if;
   end Insert;

   function Contains (T : Tree; V : Value) return Boolean is
      Found : Boolean := False;
   begin
      for I in Slot loop
         if T.Used (I) and then T.Values (I) = V then Found := True; end if;
      end loop;
      return Found;
   end Contains;

   function Size (T : Tree) return Natural is
   begin
      return T.Count;
   end Size;
end Insert_Into_BST;
