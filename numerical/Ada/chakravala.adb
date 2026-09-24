--  Chakravala body — cyclic method for Pell's equation x² − n y² = 1.

pragma Ada_2022;

package body Chakravala
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Helpers
   -------------------------------------------------------------------------

   function Abs_LI (V : Long_Integer) return Long_Integer is
   begin
      if V < 0 then
         return -V;
      else
         return V;
      end if;
   end Abs_LI;

   function Floor_Sqrt (N : Long_Integer) return Long_Integer is
      --  Binary search for largest R with R² ≤ N (no Float).
      Lo  : Long_Integer := 0;
      Hi  : Long_Integer := N;
      Mid : Long_Integer;
   begin
      if N = 0 or else N = 1 then
         return N;
      end if;
      --  Hi starts at N; for large N, Mid*Mid may overflow — clamp Hi
      --  to a safe upper bound (2^31 fits squared in Long_Integer).
      if Hi > 3_037_000_499 then
         --  floor(sqrt(2^63 − 1)) ≈ 3_037_000_499
         Hi := 3_037_000_499;
      end if;
      while Lo < Hi loop
         Mid := (Lo + Hi + 1) / 2;
         if Mid > N / Mid then
            --  Mid² would exceed N (avoid Mid*Mid overflow)
            Hi := Mid - 1;
         else
            Lo := Mid;
         end if;
      end loop;
      return Lo;
   end Floor_Sqrt;

   function Is_Perfect_Square (N : Long_Integer) return Boolean is
      R : Long_Integer;
   begin
      if N < 0 then
         return False;
      end if;
      R := Floor_Sqrt (N);
      return R * R = N;
   end Is_Perfect_Square;

   function Verify_Pell
     (N : Long_Integer; P : Pell_Pair) return Boolean
   is
   begin
      return P.X * P.X - N * P.Y * P.Y = 1;
   end Verify_Pell;

   function Verify_Triple
     (N : Long_Integer; T : Auxiliary_Triple) return Boolean
   is
   begin
      return T.A * T.A - N * T.B * T.B = T.K;
   end Verify_Triple;

   -------------------------------------------------------------------------
   -- Brahmagupta–Bhāskara composition
   -------------------------------------------------------------------------

   function Compose
     (N                      : Long_Integer;
      X1, Y1, K1, X2, Y2, K2 : Long_Integer) return Auxiliary_Triple
   is
      T : Auxiliary_Triple;
   begin
      T.A := X1 * X2 + N * Y1 * Y2;
      T.B := X1 * Y2 + X2 * Y1;
      T.K := K1 * K2;
      return T;
   end Compose;

   function Compose
     (N : Long_Integer; T1, T2 : Auxiliary_Triple) return Auxiliary_Triple
   is
   begin
      return Compose (N, T1.A, T1.B, T1.K, T2.A, T2.B, T2.K);
   end Compose;

   -------------------------------------------------------------------------
   -- Initial triple / Choose_M / one step
   -------------------------------------------------------------------------

   function Initial_Triple (N : Long_Integer) return Auxiliary_Triple is
      S  : constant Long_Integer := Floor_Sqrt (N);
      A  : Long_Integer;
      T  : Auxiliary_Triple;
   begin
      --  Among S and S+1 pick the closer square to N (minimize |a²−N|).
      if Abs_LI (S * S - N) <= Abs_LI ((S + 1) * (S + 1) - N) then
         A := S;
      else
         A := S + 1;
      end if;
      if A < 1 then
         A := 1;
      end if;
      T.A := A;
      T.B := 1;
      T.K := A * A - N;
      return T;
   end Initial_Triple;

   function Choose_M
     (N, A, B, K : Long_Integer) return Long_Integer
   is
      Abs_K  : Long_Integer;
      Target : Long_Integer;
      Best_M : Long_Integer := 0;
      Best_V : Long_Integer := Long_Integer'Last;
      R      : Long_Integer;
      Base   : Long_Integer;
      M      : Long_Integer;
      Val    : Long_Integer;
      Found  : Boolean := False;
   begin
      if K = 0 then
         raise Invalid_Argument;
      end if;
      Abs_K  := Abs_LI (K);
      Target := Floor_Sqrt (N);

      --  Residues r ∈ [0, |k|) with (A + B·r) ≡ 0 (mod |k|).
      for Idx in 0 .. Abs_K - 1 loop
         R := Idx;
         if (A + B * R) rem Abs_K = 0 then
            if Abs_K = 1 then
               --  Every m works; scan a window about √N.
               for D in -20 .. 20 loop
                  M := Target + Long_Integer (D);
                  if M < 1 then
                     M := 1;
                  end if;
                  Val := Abs_LI (M * M - N);
                  if (not Found)
                    or else Val < Best_V
                    or else (Val = Best_V and then M < Best_M)
                  then
                     Best_V := Val;
                     Best_M := M;
                     Found  := True;
                  end if;
               end loop;
            else
               --  Candidates m ≡ R (mod |k|) near √N.
               Base := Target - (Target rem Abs_K) + R;
               for T in -5 .. 5 loop
                  M := Base + Long_Integer (T) * Abs_K;
                  if M >= 1 then
                     Val := Abs_LI (M * M - N);
                     if (not Found)
                       or else Val < Best_V
                       or else (Val = Best_V and then M < Best_M)
                     then
                        Best_V := Val;
                        Best_M := M;
                        Found  := True;
                     end if;
                  end if;
               end loop;
               if Base < 1 then
                  if R >= 1 then
                     M := R;
                  else
                     M := Abs_K + R;
                  end if;
                  if M >= 1 then
                     Val := Abs_LI (M * M - N);
                     if (not Found)
                       or else Val < Best_V
                       or else (Val = Best_V and then M < Best_M)
                     then
                        Best_V := Val;
                        Best_M := M;
                        Found  := True;
                     end if;
                  end if;
               end if;
            end if;
         end if;
      end loop;

      if not Found then
         raise Invalid_Argument;
      end if;
      return Best_M;
   end Choose_M;

   function Chakravala_Step_From
     (N : Long_Integer;
      T : Auxiliary_Triple;
      M : Long_Integer) return Auxiliary_Triple
   is
      Abs_K : constant Long_Integer := Abs_LI (T.K);
      New_T : Auxiliary_Triple;
   begin
      if Abs_K = 0 then
         raise Invalid_Argument;
      end if;
      --  Bhāskara's lemma:
      --    a ← (a m + N b) / |k|
      --    b ← (a + b m) / |k|
      --    k ← (m² − N) / k
      New_T.A := Abs_LI ((T.A * M + N * T.B) / Abs_K);
      New_T.B := Abs_LI ((T.A + T.B * M) / Abs_K);
      New_T.K := (M * M - N) / T.K;
      return New_T;
   end Chakravala_Step_From;

   -------------------------------------------------------------------------
   -- Internal solver (shared by Solve_Pell / Solve_Pell_With_Chain)
   -------------------------------------------------------------------------

   procedure Require_Valid_N (N : Long_Integer) is
   begin
      if N <= 0 or else N > Max_N or else Is_Perfect_Square (N) then
         raise Invalid_Argument;
      end if;
   end Require_Valid_N;

   --  Run the cyclic method; optionally fill Chain_Buf (1 .. Count).
   procedure Run_Chakravala
     (N         : Long_Integer;
      Solution  : out Pell_Pair;
      Chain_Buf : in out Chakravala_Chain;
      Count     : out Natural;
      Record_It : Boolean)
   is
      T     : Auxiliary_Triple := Initial_Triple (N);
      M     : Long_Integer;
      Steps : Natural := 0;
      Self  : Auxiliary_Triple;
   begin
      Count := 0;
      if Record_It and then Chain_Buf'Length > 0 then
         Count := 1;
         Chain_Buf (Chain_Buf'First) :=
           (Triple => T, M => 0);
      end if;

      while T.K /= 1 and then Steps < Max_Steps loop
         if T.K = -1 then
            --  Compose with itself: (a²+N b², 2 a b, 1).
            Self := Compose (N, T, T);
            T.A := Self.A;
            T.B := Self.B;
            T.K := 1;
            if Record_It
              and then Count < Chain_Buf'Length
            then
               Count := Count + 1;
               Chain_Buf (Chain_Buf'First + Count - 1) :=
                 (Triple => T, M => -1);  -- sentinel: self-composition
            end if;
            exit;
         end if;

         M := Choose_M (N, T.A, T.B, T.K);
         T := Chakravala_Step_From (N, T, M);
         Steps := Steps + 1;

         if Record_It
           and then Count < Chain_Buf'Length
         then
            Count := Count + 1;
            Chain_Buf (Chain_Buf'First + Count - 1) :=
              (Triple => T, M => M);
         end if;
      end loop;

      if T.K /= 1 then
         raise Invalid_Argument;  -- exceeded Max_Steps (should not happen)
      end if;

      Solution.X := T.A;
      Solution.Y := T.B;
   end Run_Chakravala;

   -------------------------------------------------------------------------
   -- Public solvers
   -------------------------------------------------------------------------

   function Solve_Pell (N : Long_Integer) return Pell_Pair is
      Dummy : Chakravala_Chain (1 .. 0);
      Sol   : Pell_Pair;
      Count : Natural;
   begin
      Require_Valid_N (N);
      Run_Chakravala (N, Sol, Dummy, Count, Record_It => False);
      return Sol;
   end Solve_Pell;

   function Solve_Pell_With_Chain
     (N : Long_Integer) return Solve_With_Chain_Result
   is
      Buf   : Chakravala_Chain (1 .. 256);
      Sol   : Pell_Pair;
      Count : Natural;
   begin
      Require_Valid_N (N);
      Run_Chakravala (N, Sol, Buf, Count, Record_It => True);
      declare
         Result : Solve_With_Chain_Result (Length => Count);
      begin
         Result.Solution := Sol;
         Result.Chain    := Buf (1 .. Count);
         return Result;
      end;
   end Solve_Pell_With_Chain;

end Chakravala;
