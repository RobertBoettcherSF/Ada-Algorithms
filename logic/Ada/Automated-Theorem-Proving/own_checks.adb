--  Own checks (see tests/SOURCES.txt). Assume every decision procedure is
--  wrong or does nothing; compare with methods that share no code with it:
--  * brute force over all 2**N assignments (bit masks) decides SAT / UNSAT;
--    SAT and UNSAT agreement are counted separately per variant;
--  * pigeonhole PHP(3,2) is UNSAT;
--  * the helpers against their semantic definitions, checked on every
--    assignment (unit propagation and pure-literal elimination preserve the
--    truth value whenever the chosen literal is true; a resolvent contains
--    exactly the literals of both clauses except the pivot's).
--  The package returns only True / False: there is no proof object, so no
--  UNSAT answer can be replayed against inference rules.
pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Exceptions;
with Automated_Theorem_Proving; use Automated_Theorem_Proving;

procedure Own_Checks is
   Seed : Long_Long_Integer := 20261008;
   Failures : Natural := 0;

   function Rand (Lo, Hi : Integer) return Integer is   --  Park-Miller
   begin
      Seed := (Seed * 16807) mod 2147483647;
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Rand;

   procedure Fail (What : String) is
   begin
      Put_Line ("FAIL own check: " & What);
      Failures := Failures + 1;
   end Fail;

   function Lit_True (L : Literal; Mask : Natural) return Boolean is
     (((Mask / 2 ** (Natural (L.Var) - 1)) mod 2 = 1) = (L.Pol = Positive_Pol));

   function Clause_True (C : Clause; Mask : Natural) return Boolean is
     (for some L of C => Lit_True (L, Mask));

   function Formula_True (F : CNF_Formula; Mask : Natural) return Boolean is
     (for all C of F => Clause_True (C, Mask));

   function Brute_SAT (F : CNF_Formula; N : Natural) return Boolean is
     (for some Mask in 0 .. 2 ** N - 1 => Formula_True (F, Mask));

   function Random_Lit (N : Positive) return Literal is
     (Var => Variable_ID (Rand (1, N)), Pol => (if Rand (0, 1) = 1 then Positive_Pol else Negative_Pol));

   function Random_Clause (N : Positive; Width : Natural) return Clause is
      C : Clause (1 .. Width);
   begin
      for L of C loop
         L := Random_Lit (N);
      end loop;
      return C;
   end Random_Clause;

   function Random_3SAT (N, M : Positive) return CNF_Formula is
      F : CNF_Formula;
   begin
      for I in 1 .. M loop
         declare
            C : Clause (1 .. 3);
         begin
            loop   --  three distinct variables
               C := Random_Clause (N, 3);
               exit when C (1).Var /= C (2).Var and then C (1).Var /= C (3).Var and then C (2).Var /= C (3).Var;
            end loop;
            F.Append (C);
         end;
      end loop;
      return F;
   end Random_3SAT;

   type Variant is (Exhaustive, DPLL, DP_Resolution);
   type Count_Row is array (Variant) of Natural;
   Sat_Agree, Sat_Total, Unsat_Agree, Unsat_Total, Easy_Agree, Easy_Total : Count_Row := [others => 0];

   procedure Compare (F : CNF_Formula; N : Positive; Label : String; Easy : Boolean) is
      Expect : constant Boolean := Brute_SAT (F, N);
   begin
      for V in Variant loop
         declare
            Got : Boolean := not Expect;
            OK  : Boolean := False;
         begin
            begin
               Got := (case V is
                         when Exhaustive    => Is_Satisfiable_Exhaustive (F, Variable_ID (N)),
                         when DPLL          => Is_Satisfiable_DPLL (F),
                         when DP_Resolution => Is_Satisfiable_DP_Resolution (F));
               OK := Got = Expect;
               if not OK then
                  Fail (Label & " " & V'Image & ": got SAT=" & Got'Image & ", brute force SAT=" & Expect'Image);
               end if;
            exception
               when E : others =>
                  Fail (Label & " " & V'Image & " raised " & Ada.Exceptions.Exception_Name (E));
            end;
            if Easy then
               Easy_Total (V) := Easy_Total (V) + 1;
               Easy_Agree (V) := Easy_Agree (V) + (if OK then 1 else 0);
            elsif Expect then
               Sat_Total (V) := Sat_Total (V) + 1;
               Sat_Agree (V) := Sat_Agree (V) + (if OK then 1 else 0);
            else
               Unsat_Total (V) := Unsat_Total (V) + 1;
               Unsat_Agree (V) := Unsat_Agree (V) + (if OK then 1 else 0);
            end if;
         end;
      end loop;
   end Compare;

   function Count_With (F : CNF_Formula; L : Literal) return Natural is
      K : Natural := 0;
   begin
      for C of F loop
         if (for some X of C => X = L) then
            K := K + 1;
         end if;
      end loop;
      return K;
   end Count_With;

   procedure Check_Clause_Helpers (N : Positive) is
      C1 : constant Clause := Random_Clause (N, Rand (0, 4));
      C2 : constant Clause := Random_Clause (N, Rand (0, 4));
      P  : constant Variable_ID := Variable_ID (Rand (1, N));
      A  : constant Clause := C1 & Clause'([1 => Pos (P)]);
      B  : constant Clause := C2 & Clause'([1 => Neg (P)]);
      R  : constant Clause := Resolve_Clauses (A, B, P);
      AB : constant Clause := A & B;
      D  : constant Clause := Remove_Duplicates (AB);
      function In_Set (X : Literal; C : Clause) return Boolean is (for some Y of C => Y = X);
   begin
      --  resolvent = literals of A and B except P and not P
      for X of AB loop
         if X.Var /= P and then not In_Set (X, R) then
            Fail ("Resolve_Clauses drops a literal");
         end if;
      end loop;
      for X of R loop
         if X.Var = P or else not In_Set (X, AB) then
            Fail ("Resolve_Clauses keeps the pivot or invents a literal");
         end if;
      end loop;
      --  Remove_Duplicates: same set, no repeats
      if (for some X of AB => not In_Set (X, D)) or else (for some X of D => not In_Set (X, AB))
        or else (for some I in D'Range => (for some J in D'Range => I < J and then D (I) = D (J)))
      then
         Fail ("Remove_Duplicates");
      end if;
      --  Is_Tautology: some literal and its negation
      if Is_Tautology (C1) /= (for some X of C1 => In_Set (Negate (X), C1)) then
         Fail ("Is_Tautology");
      end if;
      if not Is_Tautology (AB) then
         Fail ("Is_Tautology misses P, not P");
      end if;
   end Check_Clause_Helpers;

   procedure Check_Helpers (F : CNF_Formula; N : Positive; Label : String) is
      L  : constant Literal := Random_Lit (N);
      UP : constant CNF_Formula := Simplify_Unit_Propagation (F, L);
      PL : constant CNF_Formula := Simplify_Pure_Literal (F, L);
   begin
      for Mask in 0 .. 2 ** N - 1 loop
         if Lit_True (L, Mask) then
            if Formula_True (UP, Mask) /= Formula_True (F, Mask) then
               Fail (Label & ": Simplify_Unit_Propagation changes the truth value"); exit;
            end if;
            if Formula_True (PL, Mask) /= Formula_True (F, Mask) then
               Fail (Label & ": Simplify_Pure_Literal changes the truth value"); exit;
            end if;
         end if;
      end loop;
      if (for some C of UP => Contains_Literal (C, L) or else Contains_Literal (C, Negate (L))) then
         Fail (Label & ": unit propagation leaves the unit's variable in the formula");
      end if;
      if (for some C of PL => Contains_Literal (C, L)) then
         Fail (Label & ": pure-literal elimination keeps a clause containing the literal");
      end if;
      if Natural (PL.Length) /= Natural (F.Length) - Count_With (F, L) then
         Fail (Label & ": pure-literal elimination removed the wrong number of clauses");
      end if;
      if Contains_Empty_Clause (F) /= (for some C of F => C'Length = 0) then
         Fail (Label & ": Contains_Empty_Clause");
      end if;
   end Check_Helpers;

   function Pigeonhole (P, H : Positive) return CNF_Formula is
      F : CNF_Formula;
      function X (I, J : Positive) return Variable_ID is (Variable_ID ((I - 1) * H + J));
   begin
      for I in 1 .. P loop
         declare
            C : Clause (1 .. H);
         begin
            for J in 1 .. H loop
               C (J) := Pos (X (I, J));
            end loop;
            F.Append (C);
         end;
      end loop;
      for J in 1 .. H loop
         for I1 in 1 .. P loop
            for I2 in I1 + 1 .. P loop
               F.Append (Clause'[Neg (X (I1, J)), Neg (X (I2, J))]);
            end loop;
         end loop;
      end loop;
      return F;
   end Pigeonhole;

begin
   --  random 3-SAT, 6 .. 9 vars, M = 4.26 N (odd) / 5.2 N (even rounds)
   for Round in 1 .. 120 loop
      declare
         N : constant Positive := 6 + Round mod 4;
         M : constant Positive := (N * (if Round mod 2 = 1 then 426 else 520) + 50) / 100;
         F : constant CNF_Formula := Random_3SAT (N, M);
      begin
         Compare (F, N, "3-SAT#" & Round'Image, Easy => False);
         Check_Helpers (F, N, "3-SAT#" & Round'Image);
      end;
   end loop;
   --  easy: 1 .. 6 vars, 0 .. 8 clauses of width 0 .. 4 (empty clauses,
   --  duplicates and complementary literals allowed)
   for Round in 1 .. 300 loop
      declare
         N : constant Positive := Rand (1, 6);
         F : CNF_Formula;
      begin
         for I in 1 .. Rand (0, 8) loop
            F.Append (Random_Clause (N, (if Rand (1, 10) = 1 then 0 else Rand (1, 4))));
         end loop;
         Compare (F, N, "easy#" & Round'Image, Easy => True);
         Check_Helpers (F, N, "easy#" & Round'Image);
         Check_Clause_Helpers (N);
      end;
   end loop;
   Compare (Pigeonhole (3, 2), 6, "PHP(3,2)", Easy => False);
   Compare (Pigeonhole (4, 3), 12, "PHP(4,3)", Easy => False);

   for V in Variant loop
      Put_Line ("own checks " & V'Image & ": phase-transition SAT" & Sat_Agree (V)'Image & " /" & Sat_Total (V)'Image
        & ", UNSAT" & Unsat_Agree (V)'Image & " /" & Unsat_Total (V)'Image & " (incl. PHP)"
        & ", easy" & Easy_Agree (V)'Image & " /" & Easy_Total (V)'Image);
   end loop;
   if Failures > 0 then
      raise Program_Error with "own checks:" & Failures'Image & " failures";
   end if;
end Own_Checks;
