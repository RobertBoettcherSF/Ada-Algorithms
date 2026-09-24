--  Fibonacci_Search body — Lourakis / Wikipedia Fibonacci search.
--  Finds the smallest F_m >= n, then probes with an F_{m-2} offset from
--  the current eliminated-front base, shrinking the Fibonacci triple
--  with addition/subtraction only (no division).

pragma Ada_2022;

package body Fibonacci_Search
  with SPARK_Mode => Off
is

   function Find (A : Element_Array; Key : Integer) return Integer is
      N         : constant Natural := A'Length;
      First     : constant Natural := A'First;
      Sentinel  : constant Integer := Integer (First) - 1;
      Fib_M     : Natural;
      Fib_Mm1   : Natural;
      Fib_Mm2   : Natural;
      Offset    : Integer;
      --  Offset is the 0-based index of the last eliminated element to the
      --  left of the remaining window (−1 means nothing eliminated yet).
      Probe_Off : Natural;
      Candidate : Integer;
      Idx       : Natural;
   begin
      if N > Max_N then
         raise Invalid_Argument with
           "Find: array length exceeds Max_N";
      end if;

      if N = 0 then
         return Sentinel;
      end if;

      --  Smallest Fibonacci number Fib_M >= N (F_0 = 0, F_1 = 1, …).
      Fib_Mm2 := 0;
      Fib_Mm1 := 1;
      Fib_M   := 1;
      while Fib_M < N loop
         Fib_Mm2 := Fib_Mm1;
         Fib_Mm1 := Fib_M;
         Fib_M   := Fib_Mm1 + Fib_Mm2;
      end loop;

      Offset := -1;

      while Fib_M > 1 loop
         --  i = min(offset + Fib_Mm2, n − 1). When Fib_M > 1 the Fibonacci
         --  identity guarantees Fib_Mm2 >= 1, so offset + Fib_Mm2 >= 0.
         Candidate := Offset + Integer (Fib_Mm2);
         if Candidate < Integer (N - 1) then
            Probe_Off := Natural (Candidate);
         else
            Probe_Off := N - 1;
         end if;

         Idx := First + Probe_Off;

         if A (Idx) < Key then
            --  Discard A(First .. Idx); reduce triple by one step.
            Fib_M   := Fib_Mm1;
            Fib_Mm1 := Fib_Mm2;
            Fib_Mm2 := Fib_M - Fib_Mm1;
            Offset  := Integer (Probe_Off);
         elsif A (Idx) > Key then
            --  Discard A(Idx .. Last); reduce triple by two steps.
            Fib_M   := Fib_Mm2;
            Fib_Mm1 := Fib_Mm1 - Fib_Mm2;
            Fib_Mm2 := Fib_M - Fib_Mm1;
         else
            return Integer (Idx);
         end if;
      end loop;

      --  One candidate may remain when Fib_Mm1 ≠ 0 (typically 1).
      if Fib_Mm1 /= 0
        and then Offset + 1 < Integer (N)
        and then A (First + Natural (Offset + 1)) = Key
      then
         return Integer (First + Natural (Offset + 1));
      end if;

      return Sentinel;
   end Find;

end Fibonacci_Search;
