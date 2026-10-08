pragma Ada_2022;

package body Insert_Into_BST with SPARK_Mode => On is
   function Empty return Tree is
   begin
      return (Values => [others => 0], Lefts => [others => 0], Rights => [others => 0],
              Lo => [others => Bound'First], Hi => [others => Bound'Last], Count => 0);
   end Empty;

   procedure Insert (T : in out Tree; V : Value) is
      Cur : Slot := 1;
      New_Slot : Slot;
   begin
      if T.Count = 0 then
         T.Count := 1;
         T.Values (1) := V;
         T.Lefts (1) := 0;
         T.Rights (1) := 0;
         T.Lo (1) := Bound'First;
         T.Hi (1) := Bound'Last;
         return;
      end if;
      --  walk down; Cur's slot grows at every step, so at most Count steps
      for Step in Slot loop
         pragma Loop_Invariant (T = T'Loop_Entry);
         pragma Loop_Invariant (Cur in Step .. T.Count);
         pragma Loop_Invariant (T.Lo (Cur) < V and then V < T.Hi (Cur));
         if V = T.Values (Cur) then
            return;   --  already present
         end if;
         New_Slot := T.Count + 1;
         if V < T.Values (Cur) then
            if T.Lefts (Cur) = 0 then
               T.Values (New_Slot) := V;
               T.Lefts (New_Slot) := 0;
               T.Rights (New_Slot) := 0;
               T.Lo (New_Slot) := T.Lo (Cur);
               T.Hi (New_Slot) := T.Values (Cur);
               T.Lefts (Cur) := New_Slot;
               T.Count := New_Slot;
               return;
            end if;
            Cur := T.Lefts (Cur);
         else
            if T.Rights (Cur) = 0 then
               T.Values (New_Slot) := V;
               T.Lefts (New_Slot) := 0;
               T.Rights (New_Slot) := 0;
               T.Lo (New_Slot) := T.Values (Cur);
               T.Hi (New_Slot) := T.Hi (Cur);
               T.Rights (Cur) := New_Slot;
               T.Count := New_Slot;
               return;
            end if;
            Cur := T.Rights (Cur);
         end if;
      end loop;
   end Insert;

   function Contains (T : Tree; V : Value) return Boolean is
      Cur : Index := (if T.Count = 0 then 0 else 1);
   begin
      for Step in Slot loop
         pragma Loop_Invariant (Cur = 0 or else Cur in Step .. T.Count);
         if Cur = 0 then
            return False;
         elsif V = T.Values (Cur) then
            return True;
         elsif V < T.Values (Cur) then
            Cur := T.Lefts (Cur);
         else
            Cur := T.Rights (Cur);
         end if;
      end loop;
      return False;
   end Contains;
end Insert_Into_BST;
