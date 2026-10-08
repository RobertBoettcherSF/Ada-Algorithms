--  Own checks (see tests/SOURCES.txt). Assume the solver is wrong or does
--  nothing; compare it with methods that do not share its code:
--  * brute force: every one of the 2**N assignments is tried (bit masks),
--    so SAT / UNSAT is known independently; SAT and UNSAT agreement are
--    counted separately so a wrong UNSAT cannot hide in a pass rate;
--  * certificate: every SAT answer's assignment is evaluated on every
--    clause by this file's own evaluator (also for 35 .. 90 variables,
--    beyond brute force, on formulas with a planted solution, where UNSAT
--    is always wrong);
--  * pigeonhole PHP(3,2) and PHP(4,3), which are UNSAT;
--  * up to 14 variables every SAT model must be the lexicographically
--    least model (cdcl.ads: decision rule and its consequence), found here
--    by trying assignments in lexicographic order;
--  * the restart schedule and deletion choice are replayed from a trace
--    against the policies stated in cdcl.ads (Check_Policy).
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

   type Variant is (Basic, Restarts, Deletion, Instr_Plain, Instr_Low, Instr_Mid);
   --  Instr_Plain: Solve_Instrumented without restarts / deletion (counters
   --  must show none); Instr_Low: restarts after every conflict and at most
   --  one learned clause kept, so small formulas exercise both.
   --  Instr_Mid: restart interval 3 and a learned-clause limit of 1000.
   --  Bounds derived from the meaning of the options, not from runs:
   --  * restarts never come closer than the initial interval, so
   --    Restarts * 3 <= Conflicts;
   --  * with a limit of 1000, nothing is deleted while at most 1000 clauses
   --    were ever learned;
   --  * with deletion on, the kept learned clauses never exceed
   --    max (limit, Variables_Count + 1): a deletion is due whenever the
   --    count exceeds the limit, and it can only be blocked when every older
   --    learned clause is the reason of an assigned variable (one reason per
   --    variable).
   --  The lexicographically least model (variable 1 most significant,
   --  False before True), by trying assignments in that order: Mask bit
   --  (N - V) is variable V. cdcl.ads states that every SAT answer is this
   --  model, whatever the restart / deletion options.
   function Lex_Least (F : CNF; A : Assignment_Array) return Boolean is
      Want : Assignment_Array (1 .. Variable_Id (F.N));
   begin
      for Mask in 0 .. 2 ** F.N - 1 loop
         for V in 1 .. F.N loop
            Want (Variable_Id (V)) := (if (Mask / 2 ** (F.N - V)) mod 2 = 1 then True else False);
         end loop;
         if Model_OK (F, Want) then
            return Want = A;
         end if;
      end loop;
      return False;
   end Lex_Least;

   Total_Restarts, Total_Deleted, Total_Conflicts, Mid_Restarts : Natural := 0;
   procedure Run (V : Variant; F : Formula; A : out Assignment_Array; P : Positive; S : out Solve_Status) is
   begin
      case V is
         when Basic    => S := Solve_Basic (F, A);
         when Restarts => S := Solve_With_Restarts (F, A, P);
         when Deletion => S := Solve_With_Clause_Deletion (F, A, P);
         when Instr_Mid =>
            declare
               St : Solve_Statistics;
            begin
               Solve_Instrumented (F, A, True, 3, True, 1000, S, St);
               if St.Restarts * 3 > St.Conflicts then
                  Fail ("counters: restarts closer than the interval 3: restarts" & St.Restarts'Image
                        & " conflicts" & St.Conflicts'Image);
               end if;
               if St.Learned <= 1000 and then St.Deleted /= 0 then
                  Fail ("counters: deletion below the limit of 1000 learned clauses");
               end if;
               if St.Learned /= St.Conflicts - (if S = Unsatisfiable then 1 else 0) then
                  Fail ("counters inconsistent (interval 3)");
               end if;
               Mid_Restarts := Mid_Restarts + St.Restarts;
            end;
         when Instr_Plain | Instr_Low =>
            declare
               Low : constant Boolean := V = Instr_Low;
               St  : Solve_Statistics;
            begin
               Solve_Instrumented (F, A, Low, 1, Low, 1, S, St);
               if Low and then St.Peak_Learned > Natural'Max (1, F.Variables_Count + 1) then
                  Fail ("counters: kept learned clauses" & St.Peak_Learned'Image
                        & " above max (1, variables + 1) with deletion on");
               end if;
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
            elsif S = Satisfiable and then F.N <= 14 and then not Lex_Least (F, A) then
               Fail (Label & " " & V'Image & ": SAT model is not the lexicographically least model");
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

   --  Policy check (cdcl.ads, "Documented search policies"): replays the
   --  trace of one run against the stated schedule and deletion rule, with
   --  this file's own bookkeeping of which learned clauses are held, and
   --  checks that the plain variants return exactly the traced result.
   Trace_Runs, Trace_Restarts, Trace_Deleted, Trace_Locked : Natural := 0;

   procedure Check_Policy (G : CNF; Label : String; Rst : Boolean; Interval : Positive;
                           Del : Boolean; Max : Positive) is
      F     : constant Formula := To_Formula (G);
      A, B  : Assignment_Array (1 .. Variable_Id (G.N)) := [others => Unassigned];
      S, SB : Solve_Status;
      St    : Solve_Statistics;
      T     : Solve_Trace;
      Tag   : constant String := "policy " & Label & " rst=" & Rst'Image & Interval'Image
                                 & " del=" & Del'Image & Max'Image & ": ";
      Learning : Natural;
   begin
      Solve_Traced (F, A, Rst, Interval, Del, Max, S, St, T);
      Trace_Runs := Trace_Runs + 1;
      if T.Truncated then
         Fail (Tag & "trace truncated (choose a smaller formula)");
         return;
      end if;
      if S = Unknown or else (S = Satisfiable and then not Model_OK (G, A)) then
         Fail (Tag & "no answer or a wrong model");
      end if;
      Learning := St.Conflicts - (if S = Unsatisfiable and then St.Conflicts > 0 then 1 else 0);
      if St.Learned /= Learning then
         Fail (Tag & "learned" & St.Learned'Image & " clauses in" & Learning'Image & " learning conflicts");
      end if;

      --  restarts: gaps t_1 = Interval, t_(k+1) = t_k + t_k / 2
      if not Rst and then T.Restarts /= 0 then
         Fail (Tag & "restarted with restarts off");
      end if;
      if Natural (T.Restarts) /= St.Restarts then
         Fail (Tag & "trace and counter disagree on restarts");
      end if;
      if Rst then
         declare
            Gap  : Natural := Interval;
            Last : Natural := 0;
         begin
            for K in 1 .. T.Restarts loop
               if T.Restart_At (K) - Last /= Gap then
                  Fail (Tag & "restart" & K'Image & " after" & Natural'Image (T.Restart_At (K) - Last)
                        & " conflicts, schedule says" & Gap'Image);
                  exit;
               end if;
               Last := T.Restart_At (K);
               Gap := Gap + Gap / 2;
            end loop;
            if Learning - Last >= Gap then
               Fail (Tag & "a scheduled restart is missing at the end of the run");
            end if;
         end;
      end if;
      Trace_Restarts := Trace_Restarts + St.Restarts;

      --  deletion: replay the held learned clauses (learn ID = conflict index)
      declare
         Held : array (1 .. Learning) of Boolean := [others => False];
         Count, Peak, Deleted : Natural := 0;
         E : Event_Count := 0;
      begin
         if not Del and then T.Deletions /= 0 then
            Fail (Tag & "deleted with deletion off");
         end if;
         for C in 1 .. Learning loop
            Held (C) := True;
            Count := Count + 1;
            if Del and then Count > Max then
               E := E + 1;
               if E > T.Deletions or else T.Deletion_Log (E).At_Conflict /= C then
                  Fail (Tag & "limit exceeded at conflict" & C'Image & " without a deletion event");
                  return;
               end if;
               declare
                  Ev    : constant Deletion_Event := T.Deletion_Log (E);
                  Older : Natural := 0;
               begin
                  for D in 1 .. (if Ev.Learn_ID = 0 then C - 1 else Ev.Learn_ID - 1) loop
                     Older := Older + (if Held (D) then 1 else 0);
                  end loop;
                  if Ev.Learn_ID /= 0 and then (Ev.Learn_ID >= C or else not Held (Ev.Learn_ID)) then
                     Fail (Tag & "deleted learn ID" & Ev.Learn_ID'Image & " at conflict" & C'Image
                           & " (not an older held clause)");
                     return;
                  end if;
                  --  every held clause older than the victim must have been
                  --  kept as a reason; a reason belongs to one variable
                  if Ev.Skipped /= Older or else Older > G.N then
                     Fail (Tag & "conflict" & C'Image & ": skipped" & Ev.Skipped'Image & " but"
                           & Older'Image & " older held clauses (oldest non-reason rule)");
                     return;
                  end if;
                  Trace_Locked := Trace_Locked + Older;
                  if Ev.Learn_ID /= 0 then
                     Held (Ev.Learn_ID) := False;
                     Count := Count - 1;
                     Deleted := Deleted + 1;
                  end if;
               end;
            end if;
            Peak := Natural'Max (Peak, Count);
         end loop;
         if E /= T.Deletions then
            Fail (Tag & "deletion event at a conflict where the limit was not exceeded");
         end if;
         if Deleted /= St.Deleted or else Peak /= St.Peak_Learned then
            Fail (Tag & "deleted / peak counters disagree with the replay");
         end if;
         Trace_Deleted := Trace_Deleted + Deleted;
      end;

      --  the plain variants are these option settings (same answer and model)
      if (not Rst or else not Del) and then (Rst or else Del or else Interval = 1) then
         B := [others => Unassigned];
         if not Rst and then not Del then
            SB := Solve_Basic (F, B);
         elsif Rst then
            SB := Solve_With_Restarts (F, B, Interval);
         else
            SB := Solve_With_Clause_Deletion (F, B, Max);
         end if;
         if SB /= S or else (S = Satisfiable and then B /= A) then
            Fail (Tag & "plain variant differs from the traced run with the same options");
         end if;
      end if;
   exception
      when E : others =>
         Fail (Tag & "raised " & Ada.Exceptions.Exception_Name (E));
   end Check_Policy;

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

   --  4. beyond brute force: planted solution, 35 .. 90 vars, M = 4 N;
   --     any UNSAT is wrong, any SAT model is checked clause by clause
   for Round in 1 .. 12 loop
      declare
         N : constant Positive := 30 + 5 * Round;
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

   --  6. documented policies: restart schedule and deletion choice, on
   --     random 3-SAT at 4.26 N (20 .. 34 vars) and PHP(5,4)
   for Round in 1 .. 30 loop
      declare
         G : CNF;
         N : constant Natural := 20 + (Round mod 15);
      begin
         Random_3SAT (G, N, (426 * N) / 100);
         Check_Policy (G, "3sat#" & Round'Image, False, 1, False, 1);
         Check_Policy (G, "3sat#" & Round'Image, True, 1 + Round mod 4, False, 1);
         Check_Policy (G, "3sat#" & Round'Image, False, 1, True, 1 + Round mod 5);
         Check_Policy (G, "3sat#" & Round'Image, True, 2 + Round mod 3, True, 1 + Round mod 3);
      end;
   end loop;
   declare
      G : CNF;
   begin
      Pigeonhole (G, 5, 4);
      Check_Policy (G, "PHP(5,4)", True, 2, True, 3);
      Check_Policy (G, "PHP(5,4)", False, 1, True, 1);
      Check_Policy (G, "PHP(5,4)", True, 1, False, 1);
   end;
   Put_Line ("own checks: policy replay over" & Trace_Runs'Image & " runs:" & Trace_Restarts'Image
             & " restarts on schedule," & Trace_Deleted'Image & " deletions of the oldest non-reason,"
             & Trace_Locked'Image & " older clauses kept as reasons");
   if Trace_Restarts = 0 or else Trace_Deleted = 0 or else Trace_Locked = 0 then
      Fail ("policy replay never saw a restart, a deletion or a clause kept as a reason");
   end if;

   for V in Variant loop
      Put_Line ("own checks " & V'Image & ": phase-transition SAT" & Sat_Agree (V)'Image & " /" & Sat_Total (V)'Image
        & ", UNSAT" & Unsat_Agree (V)'Image & " /" & Unsat_Total (V)'Image & " (incl. PHP)"
        & ", easy" & Easy_Agree (V)'Image & " /" & Easy_Total (V)'Image
        & ", planted 35-90 vars" & Big_OK (V)'Image & " /" & Big_Total (V)'Image
        & ", PHP(5,4) PHP(6,5) PHP(7,6) UNSAT" & Big_UNSAT_OK (V)'Image & " /" & Big_UNSAT_Total (V)'Image);
   end loop;
   Put_Line ("own checks: low-threshold runs (restart every conflict, keep 1 learned clause):"
             & Total_Conflicts'Image & " conflicts," & Total_Restarts'Image & " restarts,"
             & Total_Deleted'Image & " learned clauses deleted");
   if Total_Restarts = 0 or else Total_Deleted = 0 or else Mid_Restarts = 0 then
      Fail ("low-threshold runs never restarted or never deleted a clause");
   end if;
   if Failures > 0 then
      raise Program_Error with "own checks:" & Failures'Image & " failures";
   end if;
end Own_Checks;
