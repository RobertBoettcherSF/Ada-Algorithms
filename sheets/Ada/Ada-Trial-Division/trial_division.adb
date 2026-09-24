--  Trial division — Ada 2023 body.
--  Classic trial with even-wheel: peel 2, then odd candidates only.

pragma Ada_2022;

package body Trial_Division
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Floor_Sqrt
   ------------------------------------------------------------------

   function Floor_Sqrt (N : U64) return U64 is
      --  Binary search for largest R with R*R ≤ N. Compare via R ≤ N/R
      --  (never form R*R) so the full U64 domain is safe.
      Lo  : U64 := 0;
      Hi  : U64 := N;
      Mid : U64;
   begin
      if N = 0 or else N = 1 then
         return N;
      end if;
      --  For N ≥ 2, floor(sqrt(N)) ≤ N/2 + something small; searching
      --  0 .. N is correct and educational (Hi shrinks quickly).
      while Lo < Hi loop
         Mid := Lo + (Hi - Lo + 1) / 2;
         if Mid > 0 and then Mid > N / Mid then
            Hi := Mid - 1;
         else
            Lo := Mid;
         end if;
      end loop;
      return Lo;
   end Floor_Sqrt;

   ------------------------------------------------------------------
   --  Internal: count how many times P divides N (and strip them)
   ------------------------------------------------------------------

   procedure Peel
     (N        : in out U64;
      P        : U64;
      Exponent : out Natural)
   is
      E : Natural := 0;
   begin
      while N rem P = 0 loop
         E := E + 1;
         N := N / P;
      end loop;
      Exponent := E;
   end Peel;

   ------------------------------------------------------------------
   --  Is_Prime
   ------------------------------------------------------------------

   function Is_Prime (N : U64) return Boolean is
      D    : U64;
      Root : U64;
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      if N = 1 then
         return False;
      end if;
      if N = 2 or else N = 3 then
         return True;
      end if;
      if (N and 1) = 0 then
         return False;
      end if;
      if N rem 3 = 0 then
         return False;
      end if;

      --  Wheel: after 2 and 3, candidates ≡ ±1 (mod 6) — implemented as
      --  odd steps from 5 with D*D-safe bound D ≤ N/D.
      Root := Floor_Sqrt (N);
      D := 5;
      while D <= Root loop
         if N rem D = 0 then
            return False;
         end if;
         if D + 2 <= Root and then N rem (D + 2) = 0 then
            return False;
         end if;
         --  Advance by 6: next pair is D+6, D+8.
         if D > U64'Last - 6 then
            exit;
         end if;
         D := D + 6;
      end loop;
      return True;
   end Is_Prime;

   ------------------------------------------------------------------
   --  Smallest_Prime_Factor
   ------------------------------------------------------------------

   function Smallest_Prime_Factor (N : U64) return U64 is
      D    : U64;
      Root : U64;
      M    : U64;
   begin
      if N = 0 or else N = 1 then
         raise Invalid_Argument;
      end if;
      if (N and 1) = 0 then
         return 2;
      end if;
      if N rem 3 = 0 then
         return 3;
      end if;

      M := N;
      Root := Floor_Sqrt (M);
      D := 5;
      while D <= Root loop
         if M rem D = 0 then
            return D;
         end if;
         if D + 2 <= Root and then M rem (D + 2) = 0 then
            return D + 2;
         end if;
         if D > U64'Last - 6 then
            exit;
         end if;
         D := D + 6;
      end loop;
      return M;  --  M is prime
   end Smallest_Prime_Factor;

   ------------------------------------------------------------------
   --  Factorize
   ------------------------------------------------------------------

   function Factorize (N : U64) return Factor_List is
      --  ω(n) for n < 2^64 is at most 15 (2·3·…·47 overflows U64).
      Max_Distinct : constant := 16;
      Buf          : array (1 .. Max_Distinct) of Prime_Power;
      Count        : Natural := 0;
      M            : U64 := N;
      D            : U64;
      Root         : U64;
      E            : Natural;
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      if N = 1 then
         declare
            Empty : Factor_List (1 .. 0);
         begin
            return Empty;
         end;
      end if;

      --  Factor out 2.
      if (M and 1) = 0 then
         Peel (M, 2, E);
         Count := Count + 1;
         Buf (Count) := (Prime => 2, Exponent => E);
      end if;

      --  Factor out 3.
      if M > 1 and then M rem 3 = 0 then
         Peel (M, 3, E);
         Count := Count + 1;
         Buf (Count) := (Prime => 3, Exponent => E);
      end if;

      --  Odd wheel from 5: try D and D+2 (≡ 5,7 mod 6), step +6.
      D := 5;
      while M > 1 loop
         Root := Floor_Sqrt (M);
         exit when D > Root;

         if M rem D = 0 then
            Peel (M, D, E);
            Count := Count + 1;
            Buf (Count) := (Prime => D, Exponent => E);
            --  Recompute Root after shrinking M (handled next iteration).
         elsif D + 2 <= Root and then M rem (D + 2) = 0 then
            Peel (M, D + 2, E);
            Count := Count + 1;
            Buf (Count) := (Prime => D + 2, Exponent => E);
         else
            if D > U64'Last - 6 then
               exit;
            end if;
            D := D + 6;
         end if;
      end loop;

      if M > 1 then
         --  Remaining cofactor is prime.
         Count := Count + 1;
         Buf (Count) := (Prime => M, Exponent => 1);
      end if;

      declare
         Result : Factor_List (1 .. Count);
      begin
         for I in 1 .. Count loop
            Result (I) := Buf (I);
         end loop;
         return Result;
      end;
   end Factorize;

end Trial_Division;
