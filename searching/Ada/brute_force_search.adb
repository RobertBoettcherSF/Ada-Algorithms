--  Brute_Force_Search body — exhaustive generate-and-test demos.

pragma Ada_2022;

with Interfaces;

package body Brute_Force_Search
  with SPARK_Mode => Off
is

   use type Interfaces.Unsigned_64;

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   procedure Check_Linear_Bounds (A : Element_Array) is
   begin
      if A'Length > Max_Linear_N then
         raise Invalid_Argument
           with "array length exceeds Max_Linear_N";
      end if;
   end Check_Linear_Bounds;

   procedure Check_Subset_Bounds (A : Element_Array) is
   begin
      if A'Length > Max_Subset_N then
         raise Invalid_Argument
           with "array length exceeds Max_Subset_N";
      end if;
   end Check_Subset_Bounds;

   procedure Check_Perm_N (N : Natural) is
   begin
      if N > Max_Perm_N then
         raise Invalid_Argument
           with "permutation n exceeds Max_Perm_N";
      end if;
   end Check_Perm_N;

   function Sentinel (A : Element_Array) return Integer is
   begin
      return Integer (A'First) - 1;
   end Sentinel;

   ---------------------------------------------------------------------------
   -- 1. Find_Divisor — trial candidates 2 .. N
   ---------------------------------------------------------------------------

   function Find_Divisor (N : Positive) return Natural is
   begin
      --  N = 1: range 2 .. 1 is empty; educational result is N.
      if N = 1 then
         return 1;
      end if;

      for C in 2 .. N loop
         if N rem C = 0 then
            return Natural (C);
         end if;
      end loop;

      --  Unreachable for N >= 2 (N always divides N).
      return Natural (N);
   end Find_Divisor;

   ---------------------------------------------------------------------------
   -- 2. Linear_Search — exhaustive index scan
   ---------------------------------------------------------------------------

   function Linear_Search
     (A   : Element_Array;
      Key : Integer) return Integer
   is
   begin
      Check_Linear_Bounds (A);

      if A'Length = 0 then
         return Sentinel (A);
      end if;

      for I in A'Range loop
         if A (I) = Key then
            return Integer (I);
         end if;
      end loop;

      return Sentinel (A);
   end Linear_Search;

   ---------------------------------------------------------------------------
   -- 3. Subset_Sum_Exists — bit-mask generate-and-test
   ---------------------------------------------------------------------------

   function Subset_Sum_Exists
     (A      : Element_Array;
      Target : Integer) return Boolean
   is
      N : constant Natural := A'Length;
   begin
      Check_Subset_Bounds (A);

      --  Empty array: only the empty subset (sum 0).
      if N = 0 then
         return Target = 0;
      end if;

      declare
         Last_Mask : constant Interfaces.Unsigned_64 :=
           Interfaces.Shift_Left (1, N) - 1;
         Mask      : Interfaces.Unsigned_64 := 0;
      begin
         loop
            declare
               Sum : Integer := 0;
               Idx : Natural := A'First;
            begin
               for K in 0 .. N - 1 loop
                  if (Mask and Interfaces.Shift_Left (1, K)) /= 0 then
                     Sum := Sum + A (Idx);
                  end if;
                  Idx := Idx + 1;
               end loop;

               if Sum = Target then
                  return True;
               end if;
            end;

            exit when Mask = Last_Mask;
            Mask := Mask + 1;
         end loop;
      end;

      return False;
   end Subset_Sum_Exists;

   ---------------------------------------------------------------------------
   -- 4. Permutation helpers — lexicographic generate-and-test
   ---------------------------------------------------------------------------

   subtype Perm_Index is Positive range 1 .. Max_Perm_N;
   type Perm_Buffer is array (Perm_Index) of Natural;

   procedure Swap (P : in out Perm_Buffer; I, J : Perm_Index) is
      T : constant Natural := P (I);
   begin
      P (I) := P (J);
      P (J) := T;
   end Swap;

   function Next_Lex (P : in out Perm_Buffer; N : Natural) return Boolean is
      I, J, K, L : Integer;
   begin
      if N <= 1 then
         return False;
      end if;

      I := Integer (N) - 1;
      while I >= 1 and then P (Perm_Index (I)) >= P (Perm_Index (I + 1)) loop
         I := I - 1;
      end loop;

      if I < 1 then
         return False;
      end if;

      J := Integer (N);
      while P (Perm_Index (J)) <= P (Perm_Index (I)) loop
         J := J - 1;
      end loop;

      Swap (P, Perm_Index (I), Perm_Index (J));

      K := I + 1;
      L := Integer (N);
      while K < L loop
         Swap (P, Perm_Index (K), Perm_Index (L));
         K := K + 1;
         L := L - 1;
      end loop;

      return True;
   end Next_Lex;

   procedure Init_Identity (P : out Perm_Buffer; N : Natural) is
   begin
      P := [others => 0];
      for I in 1 .. N loop
         P (Perm_Index (I)) := I;
      end loop;
   end Init_Identity;

   function Matches_Target
     (P      : Perm_Buffer;
      N      : Natural;
      Target : Element_Array) return Boolean
   is
      Idx : Natural := Target'First;
   begin
      for I in 1 .. N loop
         if Integer (P (Perm_Index (I))) /= Target (Idx) then
            return False;
         end if;
         Idx := Idx + 1;
      end loop;
      return True;
   end Matches_Target;

   function Is_Permutation_Of_1_To_N
     (Target : Element_Array;
      N      : Natural) return Boolean
   is
      Seen : array (1 .. Max_Perm_N) of Boolean := [others => False];
      V    : Integer;
   begin
      if Target'Length /= N then
         return False;
      end if;

      for Idx in Target'Range loop
         V := Target (Idx);
         if V < 1 or else V > Integer (N) then
            return False;
         end if;
         if Seen (V) then
            return False;
         end if;
         Seen (V) := True;
      end loop;

      return True;
   end Is_Permutation_Of_1_To_N;

   ---------------------------------------------------------------------------
   -- Count_Permutations / Enumerate_Permutations
   ---------------------------------------------------------------------------

   function Count_Permutations (N : Natural) return Natural is
      P     : Perm_Buffer;
      Total : Natural := 0;
   begin
      Check_Perm_N (N);

      if N = 0 then
         return 1;
      end if;

      Init_Identity (P, N);
      Total := 1;

      while Next_Lex (P, N) loop
         Total := Total + 1;
      end loop;

      return Total;
   end Count_Permutations;

   procedure Enumerate_Permutations
     (N     : Natural;
      Count : out Natural)
   is
   begin
      Count := Count_Permutations (N);
   end Enumerate_Permutations;

   ---------------------------------------------------------------------------
   -- Find_Permutation — 1-based lex rank, or 0
   ---------------------------------------------------------------------------

   function Find_Permutation (Target : Element_Array) return Natural is
      Len  : constant Natural := Target'Length;
      P    : Perm_Buffer;
      Rank : Natural := 0;
   begin
      Check_Perm_N (Len);

      if Len = 0 then
         return 1;
      end if;

      if not Is_Permutation_Of_1_To_N (Target, Len) then
         return 0;
      end if;

      Init_Identity (P, Len);
      Rank := 1;

      if Matches_Target (P, Len, Target) then
         return Rank;
      end if;

      while Next_Lex (P, Len) loop
         Rank := Rank + 1;
         if Matches_Target (P, Len, Target) then
            return Rank;
         end if;
      end loop;

      return 0;
   end Find_Permutation;

end Brute_Force_Search;
