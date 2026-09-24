pragma SPARK_Mode (On);

package body Sorted_Array_To_BST is
   function Empty return Tree is
   begin
      return (Values => (others => 0), Lefts => (others => 0), Rights => (others => 0), Used => (others => False));
   end Empty;

   procedure Build (T : out Tree; Input : Value_Array; Length : Count) is
      Starts : array (Positive range 1 .. 31) of Count := (others => 0);
      Stops : array (Positive range 1 .. 31) of Count := (others => 0);
      Nodes : array (Positive range 1 .. 31) of Index := (others => 0);
      Top : Natural range 0 .. 31;
   begin
      T := Empty;
      if Length = 0 then return; end if;
      Top := 1; Starts (Top) := 1; Stops (Top) := Length; Nodes (Top) := 1;
      for Step in 1 .. 31 loop
         if Top = 0 then null; else
            declare First : constant Count := Starts (Top); Last : constant Count := Stops (Top); N : constant Index := Nodes (Top); Mid : Count; begin
               Top := Top - 1;
               Mid := First + (Last - First) / 2;
               T.Values (N) := Input (Mid); T.Used (N) := True;
               if N < 16 then
                  if First < Mid and then Top < 31 then Top := Top + 1; Starts (Top) := First; Stops (Top) := Mid - 1; Nodes (Top) := N * 2; end if;
                  if Mid < Last and then Top < 31 then Top := Top + 1; Starts (Top) := Mid + 1; Stops (Top) := Last; Nodes (Top) := N * 2 + 1; end if;
               end if;
            end;
         end if;
      end loop;
      for I in 1 .. 31 loop
         if T.Used (I) then
            if I * 2 <= 31 and then T.Used (I * 2) then T.Lefts (I) := I * 2; end if;
            if I * 2 + 1 <= 31 and then T.Used (I * 2 + 1) then T.Rights (I) := I * 2 + 1; end if;
         end if;
      end loop;
   end Build;

   function Root_Value (T : Tree) return Value is begin return T.Values (1); end Root_Value;

   function Is_BST (T : Tree) return Boolean is
      Good : Boolean := True;
   begin
      for I in 1 .. 15 loop
         if T.Used (I) then
            if T.Lefts (I) /= 0 and then T.Values (T.Lefts (I)) >= T.Values (I) then Good := False; end if;
            if T.Rights (I) /= 0 and then T.Values (T.Rights (I)) <= T.Values (I) then Good := False; end if;
         end if;
      end loop;
      return Good;
   end Is_BST;
end Sorted_Array_To_BST;
