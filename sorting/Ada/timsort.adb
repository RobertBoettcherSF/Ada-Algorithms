--  Timsort body — natural runs, binary insertion, stack merges, stable merge.

pragma Ada_2022;

package body Timsort
  with SPARK_Mode => Off
is

   procedure Check_Bounds (A : Element_Array) is
   begin
      if A'Length > Max_N then
         raise Invalid_Argument
           with "array length exceeds Max_N";
      end if;
   end Check_Bounds;

   --  Classic Timsort minrun: fold n so that n/minrun is just under a
   --  power of two. Result is in [32, 64] when n ≥ 64; otherwise n itself.
   function Compute_Minrun (N : Natural) return Natural is
      X : Natural := N;
      R : Natural := 0;
   begin
      if N < 64 then
         return (if N = 0 then 1 else N);
      end if;
      while X >= 64 loop
         if (X mod 2) = 1 then
            R := 1;
         end if;
         X := X / 2;
      end loop;
      return X + R;
   end Compute_Minrun;

   procedure Reverse_Range
     (A : in out Element_Array; Lo, Hi : Natural)
   is
      I : Natural := Lo;
      J : Natural := Hi;
      T : Integer;
   begin
      while I < J loop
         T := A (I);
         A (I) := A (J);
         A (J) := T;
         I := I + 1;
         J := J - 1;
      end loop;
   end Reverse_Range;

   --  Binary-search insertion point for Key in A(Lo .. I-1), which is
   --  already sorted ascending. Prefer the rightmost slot among equals
   --  (upper bound) so the overall sort stays stable when extending a run.
   function Upper_Bound
     (A : Element_Array; Lo, Hi_Exclusive : Natural; Key : Integer)
      return Natural
   is
      L : Natural := Lo;
      R : Natural := Hi_Exclusive;
      M : Natural;
   begin
      while L < R loop
         M := L + (R - L) / 2;
         if A (M) <= Key then
            L := M + 1;
         else
            R := M;
         end if;
      end loop;
      return L;
   end Upper_Bound;

   --  Extend sorted prefix A(Lo .. Sorted_Last) by inserting each of
   --  A(Sorted_Last+1 .. Hi) with binary insertion (stable).
   procedure Binary_Insertion_Extend
     (A : in out Element_Array; Lo, Sorted_Last, Hi : Natural)
   is
      Key  : Integer;
      Pos  : Natural;
      From : Natural;
   begin
      for I in Sorted_Last + 1 .. Hi loop
         Key := A (I);
         Pos := Upper_Bound (A, Lo, I, Key);
         --  Shift A(Pos .. I-1) one slot right.
         From := I;
         while From > Pos loop
            A (From) := A (From - 1);
            From := From - 1;
         end loop;
         A (Pos) := Key;
      end loop;
   end Binary_Insertion_Extend;

   --  Stable merge of A(Lo .. Mid) and A(Mid+1 .. Hi) via Temp.
   --  Prefer left on ties (A(I) <= A(J)) to keep equal-key order.
   procedure Merge_Runs
     (A    : in out Element_Array;
      Temp : in out Element_Array;
      Lo, Mid, Hi : Natural)
   is
      I : Natural := Lo;
      J : Natural := Mid + 1;
      K : Natural := Lo;
   begin
      while I <= Mid and then J <= Hi loop
         if A (I) <= A (J) then
            Temp (K) := A (I);
            I := I + 1;
         else
            Temp (K) := A (J);
            J := J + 1;
         end if;
         K := K + 1;
      end loop;

      while I <= Mid loop
         Temp (K) := A (I);
         I := I + 1;
         K := K + 1;
      end loop;

      while J <= Hi loop
         Temp (K) := A (J);
         J := J + 1;
         K := K + 1;
      end loop;

      for X in Lo .. Hi loop
         A (X) := Temp (X);
      end loop;
   end Merge_Runs;

   --  Run descriptor: start index and length in A.
   type Run_Info is record
      Base : Natural;
      Len  : Natural;
   end record;

   --  Stack large enough for Max_N with minrun ≥ 32 (~ n/32 runs worst).
   Max_Stack : constant := 4096;
   type Run_Stack is array (1 .. Max_Stack) of Run_Info;

   procedure Sort (A : in out Element_Array) is
      N      : constant Natural := A'Length;
      Minrun : Natural;
      Stack  : Run_Stack;
      Top    : Natural := 0;
      Temp   : Element_Array (A'Range);
      Pos    : Natural;
      Run_Lo : Natural;
      Run_Hi : Natural;
      Remaining : Natural;
      Force  : Natural;

      procedure Push_Run (Base, Len : Natural) is
      begin
         Top := Top + 1;
         Stack (Top) := (Base => Base, Len => Len);
      end Push_Run;

      procedure Merge_At (I : Natural) is
         --  Merge stack runs I and I+1 (must be adjacent). Compact stack.
         Lo  : constant Natural := Stack (I).Base;
         Mid : constant Natural := Stack (I).Base + Stack (I).Len - 1;
         Hi  : constant Natural := Stack (I + 1).Base + Stack (I + 1).Len - 1;
      begin
         Merge_Runs (A, Temp, Lo, Mid, Hi);
         Stack (I).Len := Stack (I).Len + Stack (I + 1).Len;
         for K in I + 1 .. Top - 1 loop
            Stack (K) := Stack (K + 1);
         end loop;
         Top := Top - 1;
      end Merge_At;

      --  Enforce classic Timsort stack invariants after each push.
      --  X = Stack(Top) newest, Y = Stack(Top-1), Z = Stack(Top-2).
      procedure Collapse is
         Merged : Boolean;
      begin
         loop
            Merged := False;
            exit when Top < 2;

            if Top >= 3
              and then Stack (Top - 2).Len
                         <= Stack (Top - 1).Len + Stack (Top).Len
            then
               --  |Z| ≤ |Y| + |X|: merge Y with the smaller of X and Z.
               if Stack (Top - 2).Len < Stack (Top).Len then
                  Merge_At (Top - 2);  -- Z + Y
               else
                  Merge_At (Top - 1);  -- Y + X
               end if;
               Merged := True;
            elsif Stack (Top - 1).Len <= Stack (Top).Len then
               --  |Y| ≤ |X|: merge Y + X
               Merge_At (Top - 1);
               Merged := True;
            end if;

            exit when not Merged;
         end loop;
      end Collapse;

      procedure Collapse_All is
      begin
         while Top > 1 loop
            --  Prefer merging the pair that keeps balance when ≥ 3 remain.
            if Top >= 3
              and then Stack (Top - 2).Len < Stack (Top).Len
            then
               Merge_At (Top - 2);
            else
               Merge_At (Top - 1);
            end if;
         end loop;
      end Collapse_All;

   begin
      Check_Bounds (A);

      if N <= 1 then
         return;
      end if;

      Minrun := Compute_Minrun (N);
      Pos := A'First;

      while Pos <= A'Last loop
         Run_Lo := Pos;

         --  Identify a natural run of length at least 1.
         if Pos = A'Last then
            Run_Hi := Pos;
         elsif A (Pos) <= A (Pos + 1) then
            --  Nondecreasing (ascending / equal) run.
            Pos := Pos + 1;
            while Pos < A'Last and then A (Pos) <= A (Pos + 1) loop
               Pos := Pos + 1;
            end loop;
            Run_Hi := Pos;
         else
            --  Strictly descending run (A(Pos) > A(Pos+1)).
            Pos := Pos + 1;
            while Pos < A'Last and then A (Pos) > A (Pos + 1) loop
               Pos := Pos + 1;
            end loop;
            Run_Hi := Pos;
            Reverse_Range (A, Run_Lo, Run_Hi);
         end if;

         --  Extend short runs to minrun with binary insertion.
         Remaining := A'Last - Run_Hi;
         Force := Run_Hi - Run_Lo + 1;
         if Force < Minrun and then Remaining > 0 then
            declare
               Want : constant Natural :=
                 Natural'Min (Minrun - Force, Remaining);
               New_Hi : constant Natural := Run_Hi + Want;
            begin
               Binary_Insertion_Extend (A, Run_Lo, Run_Hi, New_Hi);
               Run_Hi := New_Hi;
            end;
         end if;

         Push_Run (Run_Lo, Run_Hi - Run_Lo + 1);
         Collapse;

         Pos := Run_Hi + 1;
      end loop;

      Collapse_All;
   end Sort;

   function Is_Sorted (A : Element_Array) return Boolean is
   begin
      if A'Length <= 1 then
         return True;
      end if;
      for I in A'First + 1 .. A'Last loop
         if A (I - 1) > A (I) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Sorted;

end Timsort;
