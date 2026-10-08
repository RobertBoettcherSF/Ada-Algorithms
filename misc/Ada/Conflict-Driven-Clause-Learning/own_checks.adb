--  Own checks (see tests/SOURCES.txt). Assume the solver is wrong or does
--  nothing; compare it with methods that do not share its code:
--  * brute force: every one of the 2**N assignments is tried (bit masks),
--    so SAT / UNSAT is known independently; SAT and UNSAT agreement are
--    counted separately so a wrong UNSAT cannot hide in a pass rate;
--  * certificate: every SAT answer's assignment is evaluated on every
--    clause by this file's own evaluator (also for 30 .. 120 variables,
--    beyond brute force, on formulas with a planted solution, where UNSAT
--    is always wrong);
--  * pigeonhole PHP(3,2) and PHP(4,3), which are UNSAT.
pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with CDCL; use CDCL;
with Ada.Exceptions;

procedure Own_Checks is
   Seed : Long_Long_Integer := 20261008;
   Failures : Natural := 0;

   function Rand (Lo, Hi : Integer) return Integer is   --  Park-Miller
   begin
      Seed := (Seed * 16807) mod 2147483647;
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Rand;

   Max_Clauses : constant := 600;
   Max_Width   : constant := 7;
   type Lit_Row is array (1 .. Max_Width) of Integer;
   type Clause_Table is array (1 .. Max_Clauses) of Lit_Row;   --  0 = unused slot
   type CNF is record
      N, M : Natural := 0;
      C    : Clause_Table := [others => [others => 0]];
   end record;

   procedure Fail (What : String) is
   begin
      Put_Line ("FAIL own check: " & What);
      Failures := Failures + 1;
   end Fail;

   --  brute force over bit masks: bit (V-1) of Mask is variable V
   function Brute_SAT (F : CNF) return Boolean is
   begin
      for Mask in 0 .. 2 ** F.N - 1 loop
         declare
            All_OK : Boolean := True;
         begin
            for I in 1 .. F.M loop
               declare
                  Sat : Boolean := False;
               begin
                  for L of F.C (I) loop
                     if L /= 0 then
                        declare
                           Bit : constant Boolean := (Mask / 2 ** (abs L - 1)) mod 2 = 1;
                        begin
                           if Bit = (L > 0) then
                              Sat := True;
                           end if;
                        end;
                     end if;
                  end loop;
                  if not Sat then
                     All_OK := False;
                     exit;
                  end if;
               end;
            end loop;
            if All_OK then
               return True;
            end if;
         end;
      end loop;
      return False;
   end Brute_SAT;

   --  certificate check: every clause has a literal made true by A
   function Model_OK (F : CNF; A : Assignment_Array) return Boolean is
   begin
      for I in 1 .. F.M loop
         declare
            Sat : Boolean := False;
         begin
            for L of F.C (I) loop
               if L /= 0 then
                  if (L > 0 and then A (Variable_Id (L)) = True)
                    or else (L < 0 and then A (Variable_Id (-L)) = False)
                  then
                     Sat := True;
                  end if;
               end if;
            end loop;
            if not Sat then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Model_OK;

   function Show (F : CNF) return String is
      function Cl (I : Positive) return String is
         R : constant String := (if F.C (I) (1) /= 0 then F.C (I) (1)'Image else "")
           & (if F.C (I) (2) /= 0 then F.C (I) (2)'Image else "")
           & (if F.C (I) (3) /= 0 then F.C (I) (3)'Image else "")
           & (if F.C (I) (4) /= 0 then F.C (I) (4)'Image else "");
      begin
         return " (" & R & " )";
      end Cl;
      function From (I : Positive) return String is
        (if I > F.M or else I > 12 then "" else Cl (I) & From (I + 1));
   begin
      return " N=" & F.N'Image & ":" & From (1);
   end Show;

   function To_Formula (F : CNF) return Formula is
      R : Formula;
   begin
      Init_Formula (R, F.N);
      for I in 1 .. F.M loop
         declare
            C : Clause;
         begin
            for L of F.C (I) loop
               if L /= 0 then
                  C.Append (Literal (L));
               end if;
            end loop;
            Add_Clause (R, C);
         end;
      end loop;
      return R;
   end To_Formula;

   type Variant is (Basic, Restarts, Deletion, Instr_Plain, Instr_Low);
   --  Instr_Plain: Solve_Instrumented without restarts / deletion (counters
   --  must show none); Instr_Low: restarts after every conflict and at most
   --  one learned clause kept, so small formulas exercise both.
   Total_Restarts, Total_Deleted, Total_Conflicts : Natural := 0;
   procedure Run (V : Variant; F : Formula; A : out Assignment_Array; P : Positive; S : out Solve_Status) is
   begin
      case V is
         when Basic    => S := Solve_Basic (F, A);
         when Restarts => S := Solve_With_Restarts (F, A, P);
         when Deletion => S := Solve_With_Clause_Deletion (F, A, P);
         when Instr_Plain | Instr_Low =>
            declare
               Low : constant Boolean := V = Instr_Low;
               St  : Solve_Statistics;
            begin
               Solve_Instrumented (F, A, Low, 1, Low, 1, S, St);
               if not Low and then (St.Restarts /= 0 or else St.Deleted /= 0) then
                  Fail ("counters: restarts or deletions without the option");
               end if;
               if St.Learned /= St.Conflicts - (if S = Unsatisfiable then 1 else 0)
                 or else St.Restarts > St.Conflicts or else St.Deleted > St.Learned
                 or else St.Peak_Learned > St.Learned
                 or else (S = Unsatisfiable and then St.Conflicts = 0)
                 or else (Low and then St.Peak_Learned < Natural'Min (St.Learned, 1))
                 or else (Low and then St.Restarts /= St.Learned)
               then
                  Fail ("counters inconsistent: conflicts" & St.Conflicts'Image & " learned" & St.Learned'Image
                        & " deleted" & St.Deleted'Image & " restarts" & St.Restarts'Image
                        & " peak" & St.Peak_Learned'Image);
               end if;
               if Low then
                  Total_Restarts := Total_Restarts + St.Restarts;
                  Total_Deleted := Total_Deleted + St.Deleted;
                  Total_Conflicts := Total_Conflicts + St.Conflicts;
               end if;
            end;
      end case;
   end Run;

   type Count_Row is array (Variant) of Natural;
   Sat_Agree, Sat_Total, Unsat_Agree, Unsat_Total, Easy_Agree, Easy_Total,
     Big_OK, Big_Total, Big_UNSAT_OK, Big_UNSAT_Total : Count_Row := [others => 0];

   procedure Compare (F : CNF; Label : String; Expect : Boolean;
                      Agree, Total : in out Count_Row) is
      Fo : constant Formula := To_Formula (F);
   begin
      for V in Variant loop
         declare
            A : Assignment_Array (1 .. Variable_Id (F.N)) := [others => Unassigned];
            S : Solve_Status := Unknown;
            P : constant Positive := Rand (1, 6);
         begin
            Total (V) := Total (V) + 1;
            begin
               Run (V, Fo, A, P, S);
            exception
               when E : others =>
                  Fail (Label & " " & V'Image & " raised " & Ada.Exceptions.Exception_Information (E)
                        & " on" & Show (F));
                  goto Next;
            end;
            if S = Unknown then
               Fail (Label & " " & V'Image & ": Unknown");
            elsif (S = Satisfiable) /= Expect then
               Fail (Label & " " & V'Image & ": got " & S'Image & ", brute force says SAT=" & Expect'Image
                     & " (N=" & F.N'Image & " M=" & F.M'Image & ")");
            elsif S = Satisfiable and then not Model_OK (F, A) then
               Fail (Label & " " & V'Image & ": SAT model falsifies a clause");
            elsif S = Satisfiable and then not Is_Satisfied (Fo, A) then
               Fail (Label & " " & V'Image & ": Is_Satisfied rejects a valid model");
            else
               Agree (V) := Agree (V) + 1;
            end if;
            <<Next>>
         end;
      end loop;
   end Compare;

   procedure Random_3SAT (F : out CNF; N, M : Natural) is
   begin
      F.N := N; F.M := M;
      F.C := [others => [others => 0]];
      for I in 1 .. M loop
         for J in 1 .. 3 loop
            declare
               V : Integer;
               Dup : Boolean;
            begin
               loop   --  three distinct variables per clause
                  V := Rand (1, N);
                  Dup := False;
                  for K in 1 .. J - 1 loop
                     Dup := Dup or else abs F.C (I) (K) = V;
                  end loop;
                  exit when not Dup;
               end loop;
               F.C (I) (J) := (if Rand (0, 1) = 1 then V else -V);
            end;
         end loop;
      end loop;
   end Random_3SAT;

   procedure Pigeonhole (F : out CNF; P, H : Positive) is
      --  variable (I, J) = pigeon I in hole J
      function X (I, J : Positive) return Integer is ((I - 1) * H + J);
   begin
      F.N := P * H; F.M := 0;
      F.C := [others => [others => 0]];
      for I in 1 .. P loop                       --  every pigeon in some hole
         F.M := F.M + 1;
         for J in 1 .. H loop
            F.C (F.M) (J) := X (I, J);
         end loop;
      end loop;
      for J in 1 .. H loop                       --  no two pigeons share a hole
         for I1 in 1 .. P loop
            for I2 in I1 + 1 .. P loop
               F.M := F.M + 1;
               F.C (F.M) (1) := -X (I1, J);
               F.C (F.M) (2) := -X (I2, J);
            end loop;
         end loop;
      end loop;
   end Pigeonhole;

   F : CNF;
begin
   --  1. random 3-SAT near the phase transition, 8 .. 11 vars: M = 4.26 N
   --     in odd rounds, M = 5.2 N in even rounds (at these small N the
   --     50 % point lies above 4.26, so this keeps SAT and UNSAT balanced)
   for Round in 1 .. 200 loop
      declare
         N : constant Positive := 8 + Round mod 4;
         M : constant Positive := (N * (if Round mod 2 = 1 then 426 else 520) + 50) / 100;
      begin
         Random_3SAT (F, N, M);
         declare
            Expect : constant Boolean := Brute_SAT (F);
         begin
            if Expect then
               Compare (F, "3-SAT#" & Round'Image, True, Sat_Agree, Sat_Total);
            else
               Compare (F, "3-SAT#" & Round'Image, False, Unsat_Agree, Unsat_Total);
            end if;
         end;
      end;
   end loop;

   --  2. easy cases: 1 .. 6 vars, clause widths 1 .. 4, few clauses
   for Round in 1 .. 200 loop
      F.N := Rand (1, 6); F.M := Rand (0, 8);
      F.C := [others => [others => 0]];
      for I in 1 .. F.M loop
         for J in 1 .. Rand (1, 4) loop
            F.C (I) (J) := Rand (1, F.N) * (if Rand (0, 1) = 1 then 1 else -1);
         end loop;
      end loop;
      Compare (F, "easy#" & Round'Image, Brute_SAT (F), Easy_Agree, Easy_Total);
   end loop;

   --  3. pigeonhole: UNSAT
   Pigeonhole (F, 3, 2);
   Compare (F, "PHP(3,2)", False, Unsat_Agree, Unsat_Total);
   Pigeonhole (F, 4, 3);
   Compare (F, "PHP(4,3)", False, Unsat_Agree, Unsat_Total);
   --  beyond brute force (20, 30, 42 variables): UNSAT by the pigeonhole
   --  principle; each run of each variant takes well under a second
   Pigeonhole (F, 5, 4);
   Compare (F, "PHP(5,4)", False, Big_UNSAT_OK, Big_UNSAT_Total);
   Pigeonhole (F, 6, 5);
   Compare (F, "PHP(6,5)", False, Big_UNSAT_OK, Big_UNSAT_Total);
   Pigeonhole (F, 7, 6);
   Compare (F, "PHP(7,6)", False, Big_UNSAT_OK, Big_UNSAT_Total);

   --  4. beyond brute force: planted solution, 40 .. 120 vars, M = 4 N;
   --     any UNSAT is wrong, any SAT model is checked clause by clause
   for Round in 1 .. 12 loop
      declare
         N : constant Positive := 30 + 10 * Round mod 100;
         Hidden : array (1 .. N) of Boolean;
      begin
         for V in Hidden'Range loop
            Hidden (V) := Rand (0, 1) = 1;
         end loop;
         loop
            Random_3SAT (F, N, 4 * N);
            for I in 1 .. F.M loop   --  repair clauses the hidden model falsifies
               if (for all L of F.C (I) => L = 0 or else Hidden (abs L) /= (L > 0)) then
                  F.C (I) (1) := -F.C (I) (1);
               end if;
            end loop;
            exit;
         end loop;
         Compare (F, "planted#" & Round'Image, True, Big_OK, Big_Total);
      end;
   end loop;

   for V in Variant loop
      Put_Line ("own checks " & V'Image & ": phase-transition SAT" & Sat_Agree (V)'Image & " /" & Sat_Total (V)'Image
        & ", UNSAT" & Unsat_Agree (V)'Image & " /" & Unsat_Total (V)'Image & " (incl. PHP)"
        & ", easy" & Easy_Agree (V)'Image & " /" & Easy_Total (V)'Image
        & ", planted 30-120 vars" & Big_OK (V)'Image & " /" & Big_Total (V)'Image
        & ", PHP(5,4) PHP(6,5) PHP(7,6) UNSAT" & Big_UNSAT_OK (V)'Image & " /" & Big_UNSAT_Total (V)'Image);
   end loop;
   Put_Line ("own checks: low-threshold runs (restart every conflict, keep 1 learned clause):"
             & Total_Conflicts'Image & " conflicts," & Total_Restarts'Image & " restarts,"
             & Total_Deleted'Image & " learned clauses deleted");
   if Total_Restarts = 0 or else Total_Deleted = 0 then
      Fail ("low-threshold runs never restarted or never deleted a clause");
   end if;
   if Failures > 0 then
      raise Program_Error with "own checks:" & Failures'Image & " failures";
   end if;
end Own_Checks;
