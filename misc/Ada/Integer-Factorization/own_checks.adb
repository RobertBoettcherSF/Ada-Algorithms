--  Own checks (see tests/SOURCES.txt). Assume Integer_Factorization is wrong
--  or does nothing; compare it with references that use different methods:
--  a sieve of Eratosthenes (primes and least prime factors), divisor scans
--  (gcd, largest divisor <= sqrt N), linear root search, double-and-add
--  modular multiplication, and the definitions of the congruence predicates
--  evaluated with plain integers. Exhaustive for N in 0 .. Lim, seeded
--  random 64-bit operands for Mul_Mod, Gcd and the square roots.
pragma Ada_2022;
with Ada.Text_IO;
with Integer_Factorization; use Integer_Factorization;

procedure Own_Checks is
   Lim : constant := 3_000;
   SPF : array (0 .. Lim) of Natural := [others => 0];   --  0 for 0 and 1
   Checked : Natural := 0;
   State : U64 := 20261008;

   function Rand return U64 is   --  xorshift64, seeded
   begin
      State := State xor (State * 2 ** 13);
      State := State xor (State / 2 ** 7);
      State := State xor (State * 2 ** 17);
      return State;
   end Rand;

   procedure Fail (What : String; N : U64; Got, Want : String) is
   begin
      Ada.Text_IO.Put_Line ("FAIL own check: " & What & " for" & N'Image
                            & " gave " & Got & ", reference " & Want);
      raise Program_Error;
   end Fail;

   --  (A * B) mod M by double-and-add, all sums kept below M (no overflow).
   function Ref_Mul_Mod (A, B, M : U64) return U64 is
      R : U64 := 0;
      X : U64 := A mod M;
      Y : U64 := B;
      function Add (P, Q : U64) return U64 is
        (if P >= M - Q then P - (M - Q) else P + Q);
   begin
      while Y /= 0 loop
         if Y mod 2 = 1 then
            R := Add (R, X);
         end if;
         X := Add (X, X);
         Y := Y / 2;
      end loop;
      return R;
   end Ref_Mul_Mod;

   function Ref_Gcd_Small (A, B : Natural) return Natural is
   begin
      if A = 0 then return B; end if;
      if B = 0 then return A; end if;
      for D in reverse 1 .. Natural'Min (A, B) loop
         if A mod D = 0 and then B mod D = 0 then return D; end if;
      end loop;
      return 1;
   end Ref_Gcd_Small;

   function Ref_Bin_Gcd (A0, B0 : U64) return U64 is
      A : U64 := A0;
      B : U64 := B0;
      K : Natural := 0;
      T : U64;
   begin
      if A = 0 then return B; end if;
      if B = 0 then return A; end if;
      while (A or B) mod 2 = 0 loop A := A / 2; B := B / 2; K := K + 1; end loop;
      while A mod 2 = 0 loop A := A / 2; end loop;
      loop
         while B mod 2 = 0 loop B := B / 2; end loop;
         if A > B then T := A; A := B; B := T; end if;
         B := B - A;
         exit when B = 0;
      end loop;
      return A * 2 ** K;
   end Ref_Bin_Gcd;

   function Is_Prime (N : Natural) return Boolean is (N >= 2 and then SPF (N) = N);

   --  Largest divisor D of N with D * D <= N (scan).
   function Near_Divisor (N : Natural) return Natural is
      Best : Natural := 1;
   begin
      for D in 1 .. N loop
         exit when D * D > N;
         if N mod D = 0 then Best := D; end if;
      end loop;
      return Best;
   end Near_Divisor;

   function Raises_Invalid (Kind : Natural; N : U64) return Boolean is
      R : U64 := 0;
   begin
      case Kind is
         when 1 => R := Smallest_Prime_Factor (N);
         when 2 => R := Fermat_Factor (N);
         when 3 => R := Factor (N);
         when 4 => R := U64 (Factorize (N)'Length);
         when 5 => R := Mul_Mod (1, 1, N);
         when others => R := U64 (Factorize_Trial (N)'Length);
      end case;
      return R = U64'Last;   --  never: every call above must raise
   exception
      when Invalid_Argument => return True;
   end Raises_Invalid;
begin
   --  sieve of least prime factors
   for I in 2 .. Lim loop
      if SPF (I) = 0 then
         for J in I .. Lim loop
            if J mod I = 0 and then SPF (J) = 0 then SPF (J) := I; end if;
         end loop;
      end if;
   end loop;

   for N in 0 .. Lim loop
      declare
         U : constant U64 := U64 (N);
         R : Natural := 0;
      begin
         --  integer square roots by linear search
         while (R + 1) * (R + 1) <= N loop R := R + 1; end loop;
         if Floor_Sqrt (U) /= U64 (R) then Fail ("Floor_Sqrt", U, Floor_Sqrt (U)'Image, R'Image); end if;
         if Ceil_Sqrt (U) /= U64 (if R * R = N then R else R + 1) then
            Fail ("Ceil_Sqrt", U, Ceil_Sqrt (U)'Image, "");
         end if;
         if Is_Perfect_Square (U) /= (R * R = N) then Fail ("Is_Perfect_Square", U, "", ""); end if;
         if Is_Prime_Trial (U) /= Is_Prime (N) then Fail ("Is_Prime_Trial", U, Is_Prime_Trial (U)'Image, ""); end if;
         if N >= 2 then
            if Smallest_Prime_Factor (U) /= U64 (SPF (N)) then
               Fail ("Smallest_Prime_Factor", U, Smallest_Prime_Factor (U)'Image, SPF (N)'Image);
            end if;
            if Trial_Division_Factor (U) /= U64 (SPF (N)) then
               Fail ("Trial_Division_Factor", U, Trial_Division_Factor (U)'Image, SPF (N)'Image);
            end if;
            --  Fermat: even -> 2; odd -> largest divisor <= sqrt N (1 for an odd prime)
            declare
               Want : constant Natural := (if N mod 2 = 0 then 2 else Near_Divisor (N));
               P    : constant Factor_Pair := Fermat_Factor_Pair (U);
               WP1  : constant Natural :=
                 (if N = 2 then 1 elsif N mod 2 = 0 then 2 else Near_Divisor (N));
            begin
               if Fermat_Factor (U) /= U64 (Want) then
                  Fail ("Fermat_Factor", U, Fermat_Factor (U)'Image, Want'Image);
               end if;
               if P.F1 /= U64 (WP1) or else P.F2 /= U / U64 (WP1) then
                  Fail ("Fermat_Factor_Pair", U, P.F1'Image & P.F2'Image, WP1'Image & Natural'Image (N / WP1));
               end if;
            end;
            --  Pollard rho: N for a prime, 2 for even, else 1 or a proper divisor
            declare
               F : constant U64 := Pollard_Rho_Factor (U);
            begin
               if (Is_Prime (N) and then F /= U)
                 or else (not Is_Prime (N) and then N mod 2 = 0 and then F /= 2)
                 or else (not Is_Prime (N) and then F /= 1
                          and then (F <= 1 or else F >= U or else U mod F /= 0))
               then
                  Fail ("Pollard_Rho_Factor", U, F'Image, "N / 2 / 1 / proper divisor");
               end if;
            end;
            --  Factor: a divisor > 1; N itself exactly when N is prime
            declare
               F : constant U64 := Factor (U);
            begin
               --  documented strategy: even -> 2, prime -> N, else the small trial SPF
               if F /= (if Is_Prime (N) then U else U64 (SPF (N))) then
                  Fail ("Factor", U, F'Image, "N if prime, else least prime factor");
               end if;
            end;
         end if;
         if N >= 1 then
            --  complete factorizations: expected list from the sieve
            declare
               L1 : constant Factor_List := Factorize_Trial (U);
               L2 : constant Factor_List := Factorize (U);
               M  : Natural := N;
               K  : Natural := 0;
            begin
               while M > 1 loop
                  declare
                     P : constant Natural := SPF (M);
                     E : Natural := 0;
                  begin
                     while M mod P = 0 loop M := M / P; E := E + 1; end loop;
                     K := K + 1;
                     if K > L1'Length or else L1 (L1'First + K - 1) /= (U64 (P), E) then
                        Fail ("Factorize_Trial", U, "", "prime power" & P'Image & " **" & E'Image);
                     end if;
                     if K > L2'Length or else L2 (L2'First + K - 1) /= (U64 (P), E) then
                        Fail ("Factorize", U, "", "prime power" & P'Image & " **" & E'Image);
                     end if;
                  end;
               end loop;
               if L1'Length /= K or else L2'Length /= K then
                  Fail ("Factorize lengths", U, L1'Length'Image & L2'Length'Image, K'Image);
               end if;
            end;
         end if;
         Checked := Checked + 1;
      end;
   end loop;

   --  congruence of squares: definitions with plain integers, all X, Y mod N, N in 2 .. 40
   for N in 2 .. 40 loop
      for X in 0 .. N - 1 loop
         for Y in 0 .. N - 1 loop
            declare
               U  : constant U64 := U64 (N);
               Sq : constant Boolean := (X * X - Y * Y) mod N = 0;
               Tr : constant Boolean := (X - Y) mod N = 0 or else (X + Y) mod N = 0;
               G1 : constant Natural := Ref_Gcd_Small (abs (X - Y), N);
               G2 : constant Natural := Ref_Gcd_Small (X + Y, N);
               F  : constant U64 := Factor_From_Congruence (U64 (X), U64 (Y), U);
               P  : constant Factor_Pair := Factors_From_Congruence (U64 (X), U64 (Y), U);
               W1 : constant Natural := Natural'Min (G1, N / G1);
            begin
               if Squares_Congruent (U64 (X), U64 (Y), U) /= Sq
                 or else Is_Trivial_Pair (U64 (X), U64 (Y), U) /= Tr
                 or else Is_Nontrivial_Congruence (U64 (X), U64 (Y), U) /= (Sq and not Tr)
               then
                  Fail ("congruence predicates (X, Y =" & X'Image & Y'Image & ")", U, "", "");
               end if;
               if Sq and not Tr then
                  if F <= 1 or else F >= U or else U mod F /= 0
                    or else (F /= U64 (G1) and then F /= U64 (G2))
                  then
                     Fail ("Factor_From_Congruence (X, Y =" & X'Image & Y'Image & ")", U, F'Image, G1'Image & G2'Image);
                  end if;
                  if P.F1 /= U64 (W1) or else P.F2 /= U64 (N / W1) then
                     Fail ("Factors_From_Congruence (X, Y =" & X'Image & Y'Image & ")", U, P.F1'Image & P.F2'Image, W1'Image);
                  end if;
               elsif F /= 0 or else P /= (0, 0) then
                  Fail ("congruence factor on a trivial pair (X, Y =" & X'Image & Y'Image & ")", U, F'Image, "0");
               end if;
            end;
         end loop;
      end loop;
   end loop;

   --  random 64-bit operands
   for I in 1 .. 20_000 loop
      declare
         A : constant U64 := Rand;
         B : constant U64 := (if I mod 3 = 0 then Rand / 2 ** 40 else Rand);
         M : constant U64 := (if I mod 2 = 0 then Rand else Rand / 2 ** 32 + 1);
         S : constant U64 := Floor_Sqrt (A);
      begin
         if M /= 0 and then Mul_Mod (A, B, M) /= Ref_Mul_Mod (A, B, M) then
            Fail ("Mul_Mod", M, Mul_Mod (A, B, M)'Image, Ref_Mul_Mod (A, B, M)'Image);
         end if;
         --  floor sqrt property: S*S <= A < (S+1)*(S+1), checked without overflow
         if S > 2 ** 32 - 1 or else S * S > A
           or else (S < 2 ** 32 - 1 and then (S + 1) * (S + 1) <= A)
         then
            Fail ("Floor_Sqrt (random)", A, S'Image, "");
         end if;
         --  gcd against binary (Stein) gcd: shifts and subtraction, no division
         declare
            G : constant U64 := Gcd (A, B);
            W : constant U64 := Ref_Bin_Gcd (A, B);
         begin
            if G /= W then
               Fail ("Gcd (random)", A, G'Image, W'Image);
            end if;
         end;
      end;
   end loop;

   --  upper end of the driver's range and factors above the small-trial limit (1000)
   declare
      L  : constant Factor_List := Factorize (Factor_Max);   --  10**7 = 2**7 * 5**7
      N2 : constant U64 := 1_009 * 9_901;
      F2 : constant U64 := Factor (N2);
      L2 : constant Factor_List := Factorize (N2);
   begin
      if L /= [(2, 7), (5, 7)] or else Factor (Factor_Max) /= 2 then
         Fail ("Factorize / Factor at Factor_Max", Factor_Max, L'Length'Image, "2**7 * 5**7");
      end if;
      --  17 * 19 * 23: the small trial stage must give 17 (Fermat alone would give 23)
      if Factor (7_429) /= 17 then
         Fail ("Factor (17 * 19 * 23)", 7_429, Factor (7_429)'Image, "17");
      end if;
      if (F2 /= 1_009 and then F2 /= 9_901) or else L2 /= [(1_009, 1), (9_901, 1)] then
         Fail ("Factor / Factorize above the trial limit", N2, F2'Image, "1009 or 9901");
      end if;
   end;

   --  step caps are honoured: with one rho step some odd composite must still
   --  report failure (1); a capped result is 1 or the uncapped answer.
   declare
      Capped_Failures : Natural := 0;   --  capped 1 where the uncapped run succeeds
   begin
      for N in 9 .. Lim loop
         if N mod 2 = 1 and then not Is_Prime (N) then
            declare
               R1 : constant U64 := Pollard_Rho_Factor (U64 (N), Max_Steps => 1);
            begin
               if R1 = 1 then
                  if Pollard_Rho_Factor (U64 (N)) /= 1 then
                     Capped_Failures := Capped_Failures + 1;
                  end if;
               elsif R1 /= Pollard_Rho_Factor (U64 (N)) then
                  Fail ("Pollard_Rho_Factor (Max_Steps => 1)", U64 (N), R1'Image, "1 or the uncapped result");
               end if;
            end;
         end if;
      end loop;
      if Capped_Failures = 0 or else Fermat_Factor (2_991, Max_Steps => 1) /= 1
        or else Fermat_Factor_Pair (2_991, Max_Steps => 1) /= (0, 0)
      then
         Fail ("step caps ignored", 2_991, Capped_Failures'Image, "> 0 rho failures; Fermat 3 * 997 fails in 1 step");
      end if;
   end;

   --  rejected inputs
   if not (Raises_Invalid (1, 0) and then Raises_Invalid (1, 1) and then Raises_Invalid (2, 1)
           and then Raises_Invalid (3, 0) and then Raises_Invalid (3, 1)
           and then Raises_Invalid (3, Factor_Max + 1) and then Raises_Invalid (4, 0)
           and then Raises_Invalid (4, Factor_Max + 1) and then Raises_Invalid (5, 0)
           and then Raises_Invalid (6, 0))
   then
      Fail ("Invalid_Argument on rejected inputs", 0, "no raise", "raise");
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Checked'Image
                         & " N (sieve, divisor scans, congruence definitions) + 20000 random 64-bit operands");
end Own_Checks;
