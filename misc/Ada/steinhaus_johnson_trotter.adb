--  Steinhaus_Johnson_Trotter body — classic mobile-integer SJT.

pragma Ada_2022;

package body Steinhaus_Johnson_Trotter
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Factorial / Count
   -------------------------------------------------------------------------

   function Factorial (N : Natural) return Natural is
      Result : Natural := 1;
   begin
      if N > Max_N then
         raise Invalid_Argument;
      end if;
      for K in 2 .. N loop
         Result := Result * K;
      end loop;
      return Result;
   end Factorial;

   function Count (N : Natural) return Natural is
   begin
      if N = 0 or else N > Max_N then
         raise Invalid_Argument;
      end if;
      return Factorial (N);
   end Count;

   -------------------------------------------------------------------------
   -- Generate (mobile integers with directions)
   -------------------------------------------------------------------------

   procedure Generate
     (N     : Natural;
      Visit : not null access procedure (P : Permutation))
   is
      --  Direction: -1 = face left (toward smaller indices), +1 = face right.
      type Direction_Array is array (Positive range <>) of Integer;

      procedure Check_N is
      begin
         if N = 0 or else N > Max_N then
            raise Invalid_Argument;
         end if;
      end Check_N;

   begin
      Check_N;

      declare
         Perm : Permutation (1 .. N);
         Dir  : Direction_Array (1 .. N);
         --  Dir(I) is the direction of the value currently at position I;
         --  it travels with that value when positions are swapped.

         procedure Emit is
         begin
            Visit.all (Perm);
         end Emit;

         function Largest_Mobile_Index return Natural is
            Best_Pos : Natural := 0;
            Best_Val : Natural := 0;
         begin
            for I in Perm'Range loop
               declare
                  Neigh : constant Integer := Integer (I) + Dir (I);
               begin
                  if Neigh in Integer (Perm'First) .. Integer (Perm'Last)
                    and then Perm (I) > Perm (Positive (Neigh))
                    and then Perm (I) > Best_Val
                  then
                     Best_Val := Perm (I);
                     Best_Pos := I;
                  end if;
               end;
            end loop;
            return Best_Pos;
         end Largest_Mobile_Index;

         procedure Swap_Positions (I, J : Positive) is
            Tmp_P : Positive;
            Tmp_D : Integer;
         begin
            Tmp_P := Perm (I);
            Perm (I) := Perm (J);
            Perm (J) := Tmp_P;
            Tmp_D := Dir (I);
            Dir (I) := Dir (J);
            Dir (J) := Tmp_D;
         end Swap_Positions;

         Mobile : Natural;
         Neigh  : Positive;
         Moved  : Positive;
      begin
         --  Identity; every element faces left.
         for I in Perm'Range loop
            Perm (I) := I;
            Dir (I)  := -1;
         end loop;

         Emit;

         loop
            Mobile := Largest_Mobile_Index;
            exit when Mobile = 0;

            Neigh := Positive (Integer (Mobile) + Dir (Mobile));
            Moved := Perm (Mobile);
            Swap_Positions (Mobile, Neigh);

            --  Reverse directions of all values strictly larger than Moved.
            for I in Perm'Range loop
               if Perm (I) > Moved then
                  Dir (I) := -Dir (I);
               end if;
            end loop;

            Emit;
         end loop;
      end;
   end Generate;

   -------------------------------------------------------------------------
   -- Helpers
   -------------------------------------------------------------------------

   function Is_Permutation (P : Permutation) return Boolean is
      Seen : array (1 .. P'Length) of Boolean := [others => False];
      V    : Positive;
   begin
      if P'Length = 0 then
         return False;
      end if;
      for I in P'Range loop
         V := P (I);
         --  Element type is Positive, so V >= 1; only upper bound + dups matter.
         if V > P'Length then
            return False;
         end if;
         if Seen (V) then
            return False;
         end if;
         Seen (V) := True;
      end loop;
      return True;
   end Is_Permutation;

   function Differs_By_Adjacent_Transposition
     (A, B : Permutation) return Boolean
   is
      N : constant Natural := A'Length;
      Diff_Count : Natural := 0;
      First_Diff : Natural := 0;
   begin
      if N /= B'Length or else N < 2 then
         return False;
      end if;

      --  Map both to 1 .. N logical positions via 'First offsets.
      for K in 0 .. N - 1 loop
         if A (A'First + K) /= B (B'First + K) then
            Diff_Count := Diff_Count + 1;
            if First_Diff = 0 then
               First_Diff := K + 1;  -- 1-based offset within the slice
            end if;
         end if;
      end loop;

      --  Exactly two positions differ, and they are adjacent.
      if Diff_Count /= 2 then
         return False;
      end if;
      if First_Diff >= N then
         return False;
      end if;

      declare
         I : constant Positive := A'First + (First_Diff - 1);
         J : constant Positive := I + 1;
         BI : constant Positive := B'First + (First_Diff - 1);
         BJ : constant Positive := BI + 1;
      begin
         if A (I) /= B (BI) and then A (J) /= B (BJ)
           and then A (I) = B (BJ) and then A (J) = B (BI)
         then
            --  Confirm no further diffs (already Diff_Count = 2).
            return True;
         end if;
      end;
      return False;
   end Differs_By_Adjacent_Transposition;

end Steinhaus_Johnson_Trotter;
