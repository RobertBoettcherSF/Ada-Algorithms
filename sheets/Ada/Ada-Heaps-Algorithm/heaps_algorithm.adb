--  Heaps_Algorithm body — classic recursive Heap permutation generation.
--  Not heapsort.

pragma Ada_2022;

package body Heaps_Algorithm
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
   -- Generate (classic recursive Heap)
   -------------------------------------------------------------------------

   procedure Generate
     (N     : Natural;
      Visit : not null access procedure (P : Permutation))
   is
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

         procedure Swap (I, J : Positive) is
            Tmp : Positive;
         begin
            Tmp := Perm (I);
            Perm (I) := Perm (J);
            Perm (J) := Tmp;
         end Swap;

         procedure Heap_Generate (K : Natural) is
         begin
            if K = 1 then
               Visit.all (Perm);
               return;
            end if;

            Heap_Generate (K - 1);

            for I in 1 .. K - 1 loop
               if K rem 2 = 0 then
                  Swap (I, K);
               else
                  Swap (1, K);
               end if;
               Heap_Generate (K - 1);
            end loop;
         end Heap_Generate;

      begin
         for I in Perm'Range loop
            Perm (I) := I;
         end loop;
         Heap_Generate (N);
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

   function Differs_By_Single_Swap
     (A, B : Permutation) return Boolean
   is
      N : constant Natural := A'Length;
      Diff_Count : Natural := 0;
      First_Off  : Natural := 0;
      Second_Off : Natural := 0;
   begin
      if N /= B'Length or else N < 2 then
         return False;
      end if;

      for K in 0 .. N - 1 loop
         if A (A'First + K) /= B (B'First + K) then
            Diff_Count := Diff_Count + 1;
            if First_Off = 0 then
               First_Off := K + 1;
            elsif Second_Off = 0 then
               Second_Off := K + 1;
            else
               return False;  -- more than two diffs
            end if;
         end if;
      end loop;

      if Diff_Count /= 2 then
         return False;
      end if;

      declare
         AI : constant Positive := A'First + (First_Off - 1);
         AJ : constant Positive := A'First + (Second_Off - 1);
         BI : constant Positive := B'First + (First_Off - 1);
         BJ : constant Positive := B'First + (Second_Off - 1);
      begin
         return A (AI) = B (BJ) and then A (AJ) = B (BI);
      end;
   end Differs_By_Single_Swap;

end Heaps_Algorithm;
