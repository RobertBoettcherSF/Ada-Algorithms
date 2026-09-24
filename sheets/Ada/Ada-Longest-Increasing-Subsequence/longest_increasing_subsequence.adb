--  Longest_Increasing_Subsequence body — O(n²) DP and O(n log n) patience.

pragma Ada_2022;

package body Longest_Increasing_Subsequence is

   --  Value of A at 1-based logical position I.
   function At_A (A : Int_Array; I : Positive) return Integer is
     (A (A'First + (I - 1)));

   procedure Check_NLogN (A : Int_Array) is
   begin
      if A'Length = 0 or else A'Length > Max_Length then
         raise Invalid_Argument;
      end if;
   end Check_NLogN;

   procedure Check_DP (A : Int_Array) is
   begin
      if A'Length = 0 or else A'Length > Max_Length_DP then
         raise Invalid_Argument;
      end if;
   end Check_DP;

   function Length_DP (A : Int_Array) return Positive is
      N : constant Natural := A'Length;
   begin
      Check_DP (A);

      declare
         DP   : array (1 .. N) of Positive := [others => 1];
         Best : Positive := 1;
      begin
         for I in 1 .. N loop
            for J in 1 .. I - 1 loop
               if At_A (A, J) < At_A (A, I)
                 and then DP (J) + 1 > DP (I)
               then
                  DP (I) := DP (J) + 1;
               end if;
            end loop;
            if DP (I) > Best then
               Best := DP (I);
            end if;
         end loop;
         return Best;
      end;
   end Length_DP;

   --  Shared patience-sorting scan.
   --  M(Len) = 1-based index of the smallest tail of an increasing
   --  subsequence of length Len found so far.
   --  P(I)   = 1-based predecessor index of position I in that chain
   --  (0 if I starts a subsequence).
   --  L      = length of a longest increasing subsequence of A.
   type Index_Vec is array (Natural range <>) of Natural;

   procedure Run_Patience
     (A : Int_Array;
      L : out Natural;
      M : in out Index_Vec;
      P : in out Index_Vec)
   is
      N : constant Natural := A'Length;

      --  First Len in 1 .. L such that At_A (A, M(Len)) >= Value,
      --  or L + 1 if every tail is strictly smaller than Value.
      function Lower_Bound (Value : Integer) return Positive is
         Lo  : Natural := 1;
         Hi  : Natural := L;
         Mid : Natural;
      begin
         while Lo <= Hi loop
            Mid := Lo + (Hi - Lo) / 2;
            if At_A (A, M (Mid)) < Value then
               Lo := Mid + 1;
            else
               Hi := Mid - 1;
            end if;
         end loop;
         return Lo;
      end Lower_Bound;
   begin
      L := 0;

      for I in 1 .. N loop
         declare
            New_L : constant Positive := Lower_Bound (At_A (A, I));
         begin
            if New_L = 1 then
               P (I) := 0;
            else
               P (I) := M (New_L - 1);
            end if;

            M (New_L) := I;

            if New_L > L then
               L := New_L;
            end if;
         end;
      end loop;
   end Run_Patience;

   --  Length-only patience scan (no predecessor chain).
   function Length_Patience (A : Int_Array) return Positive is
      N : constant Natural := A'Length;
      M : Index_Vec (0 .. N) := [others => 0];
      L : Natural := 0;

      function Lower_Bound (Value : Integer) return Positive is
         Lo  : Natural := 1;
         Hi  : Natural := L;
         Mid : Natural;
      begin
         while Lo <= Hi loop
            Mid := Lo + (Hi - Lo) / 2;
            if At_A (A, M (Mid)) < Value then
               Lo := Mid + 1;
            else
               Hi := Mid - 1;
            end if;
         end loop;
         return Lo;
      end Lower_Bound;
   begin
      for I in 1 .. N loop
         declare
            New_L : constant Positive := Lower_Bound (At_A (A, I));
         begin
            M (New_L) := I;
            if New_L > L then
               L := New_L;
            end if;
         end;
      end loop;
      return L;
   end Length_Patience;

   function Length (A : Int_Array) return Positive is
   begin
      Check_NLogN (A);
      return Length_Patience (A);
   end Length;

   function Find (A : Int_Array) return Int_Array is
      N : constant Natural := A'Length;
   begin
      Check_NLogN (A);

      declare
         M : Index_Vec (0 .. N) := [others => 0];
         P : Index_Vec (1 .. N) := [others => 0];
         L : Natural := 0;
      begin
         Run_Patience (A, L, M, P);

         declare
            Result : Int_Array (1 .. L);
            K      : Natural := M (L);
         begin
            for I in reverse 1 .. L loop
               Result (I) := At_A (A, K);
               if I > 1 then
                  K := P (K);
               end if;
            end loop;
            return Result;
         end;
      end;
   end Find;

end Longest_Increasing_Subsequence;
