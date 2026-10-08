pragma Ada_2022;

package body Delete_Node_BST_Stub with SPARK_Mode => On is
   function Empty return Tree is
   begin return (Values => [others => 0], Used => [others => False], Count => 0); end Empty;

   procedure Insert (T : in out Tree; V : Value) is P : Slot; begin
      if T.Count < Capacity then
         T.Count := T.Count + 1; P := T.Count; T.Values (P) := V; T.Used (P) := True;
      end if;
   end Insert;

   procedure Delete (T : in out Tree; V : Value) is
      Removed : Boolean := False;
   begin
      for I in Slot loop
         if not Removed and then T.Used (I) and then T.Values (I) = V then
            T.Used (I) := False; Removed := True;
         end if;
      end loop;
   end Delete;

   function Size (T : Tree) return Natural is begin return T.Count; end Size;

   function Contains (T : Tree; V : Value) return Boolean is Found : Boolean := False; begin
      for I in Slot loop if T.Used (I) and then T.Values (I) = V then Found := True; end if; end loop;
      return Found;
   end Contains;
end Delete_Node_BST_Stub;
