pragma Ada_2022;
pragma SPARK_Mode (On);

package body Sorted_Array_To_BST is
   function Empty return Tree is
   begin
      return (Values => [others => 0], Used => [others => False]);
   end Empty;

   procedure Build (T : out Tree; Input : Value_Array; Length : Count) is
      Starts : array (Positive range 1 .. 31) of Count := [others => 0];
      Stops : array (Positive range 1 .. 31) of Count := [others => 0];
      Nodes : array (Positive range 1 .. 31) of Index := [others => 0];
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
   end Build;

   function Root_Value (T : Tree) return Value is begin return T.Values (1); end Root_Value;

   subtype Bound is Integer range Value'First - 1 .. Value'Last + 1;

   --  Every used node in the subtree at N lies strictly between Low and
   --  High, and each node bounds its own subtrees.
   function Within (T : Tree; N : Node_Index; Low, High : Bound) return Boolean
   is (not T.Used (N)
       or else (T.Values (N) > Low
                and then T.Values (N) < High
                and then (N > 15
                          or else (Within (T, 2 * N, Low, T.Values (N))
                                   and then Within (T, 2 * N + 1, T.Values (N), High)))))
   with Subprogram_Variant => (Increases => N);

   function Is_BST (T : Tree) return Boolean is
     (Within (T, 1, Bound'First, Bound'Last));

   function Height_From (T : Tree; N : Node_Index) return Natural
   is (if not T.Used (N) then 0
       elsif N > 15 then 1
       else 1 + Natural'Max (Height_From (T, 2 * N), Height_From (T, 2 * N + 1)))
   with Subprogram_Variant => (Increases => N),
        Post => Height_From'Result <= (if N = 1 then 5 elsif N <= 3 then 4 elsif N <= 7 then 3 elsif N <= 15 then 2 else 1);

   function Height (T : Tree) return Height_Type is (Height_From (T, 1));

   function Contains (T : Tree; V : Value) return Boolean is
      N : Positive := 1;
   begin
      while N <= 31 loop
         pragma Loop_Variant (Increases => N);
         if not T.Used (N) then
            return False;
         end if;
         if V = T.Values (N) then
            return True;
         end if;
         N := (if V < T.Values (N) then 2 * N else 2 * N + 1);
      end loop;
      return False;
   end Contains;
end Sorted_Array_To_BST;
