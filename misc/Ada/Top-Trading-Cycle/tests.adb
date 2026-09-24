--  Standalone test suite for Top_Trading_Cycle.

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Top_Trading_Cycle; use Top_Trading_Cycle;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Condition : Boolean; Message : String) is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   --  Non-static views (avoid -gnatwa constant-condition warnings).
   function Nat (X : Natural) return Natural is (X);
   function Aid (X : Positive) return Agent_Id is (Agent_Id (X));

   function Clear_Raises (Size : Natural) return Boolean is
      Inst : Instance;
   begin
      Clear (Inst, Size);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Clear_Raises;

   function Set_Pref_Raises
     (Inst  : in out Instance;
      Agent : Agent_Id;
      Rank  : Agent_Id;
      House : House_Id) return Boolean
   is
   begin
      Set_Preference (Inst, Agent, Rank, House);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Set_Pref_Raises;

   function Set_Endow_Raises
     (Inst  : in out Instance;
      Agent : Agent_Id;
      House : House_Id) return Boolean
   is
   begin
      Set_Endowment (Inst, Agent, House);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Set_Endow_Raises;

   function Load_Prefs_Raises
     (Inst : in out Instance; Prefs : Pref_Matrix) return Boolean
   is
   begin
      Load_Preferences (Inst, Prefs);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Load_Prefs_Raises;

   function Load_Endow_Raises
     (Inst : in out Instance; Endow : Id_Array) return Boolean
   is
   begin
      Load_Endowment (Inst, Endow);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Load_Endow_Raises;

   function Load_Both_Raises
     (Prefs : Pref_Matrix; Endow : Id_Array) return Boolean
   is
      Inst : Instance;
   begin
      Load (Inst, Prefs, Endow);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Load_Both_Raises;

   function Pref_Raises
     (Inst : Instance; Agent, Rank : Agent_Id) return Boolean
   is
      Unused : House_Id;
   begin
      Unused := Preference (Inst, Agent, Rank);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Pref_Raises;

   function Rank_Raises
     (Inst : Instance; Agent : Agent_Id; House : House_Id) return Boolean
   is
      Unused : Agent_Id;
   begin
      Unused := Rank_Of (Inst, Agent, House);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Rank_Raises;

   function Solve_Raises (Inst : Instance) return Boolean is
      R : Allocation;
   begin
      Solve (Inst, R);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Solve_Raises;

   function Core_Raises
     (Inst : Instance; Result : Allocation) return Boolean
   is
      Unused : Boolean;
   begin
      Unused := Is_In_Core (Inst, Result);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Core_Raises;

   function House_Raises
     (Result : Allocation; Agent : Agent_Id) return Boolean
   is
      Unused : House_Id;
   begin
      Unused := House_Of (Result, Agent);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end House_Raises;

   procedure Expect_Assign
     (Result : Allocation; Agent, House : Positive; Label : String)
   is
   begin
      Check
        (Result.House_Of (Agent) = House,
         Label & " agent" & Positive'Image (Agent)
         & " -> house" & Positive'Image (House));
      Check
        (Result.Agent_Of (House) = Agent,
         Label & " house" & Positive'Image (House)
         & " <- agent" & Positive'Image (Agent));
   end Expect_Assign;

   procedure Expect_Identity (Result : Allocation; N : Positive; Label : String)
   is
   begin
      Check (Result.N = N, Label & " size");
      Check (Is_Bijection (Result), Label & " bijection");
      for I in 1 .. N loop
         Check
           (Result.House_Of (I) = I,
            Label & " fixed" & Positive'Image (I));
      end loop;
   end Expect_Identity;

   procedure Fill_Identity_Prefs (Inst : in out Instance; N : Natural) is
   begin
      for I in 1 .. N loop
         for K in 1 .. N loop
            Set_Preference (Inst, Aid (I), Aid (K), Aid (K));
         end loop;
      end loop;
   end Fill_Identity_Prefs;

   --  Rotated preference: agent I ranks houses starting at Start.
   procedure Set_Rotated
     (Inst : in out Instance; Agent : Positive; Start : Positive; N : Positive)
   is
      H : Positive := Start;
   begin
      for Rank in 1 .. N loop
         Set_Preference (Inst, Aid (Agent), Aid (Rank), Aid (H));
         if H = N then
            H := 1;
         else
            H := H + 1;
         end if;
      end loop;
   end Set_Rotated;

begin
   ---------------------------------------------------------------------
   Section ("1. empty / clear / size");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      R    : Allocation;
   begin
      Clear (Inst, Nat (0));
      Check (Size (Inst) = 0, "empty size");
      Solve (Inst, R);
      Check (R.N = 0, "empty solve N");
      Check (Is_Bijection (R), "empty bijection");
      Check (Is_Individually_Rational (Inst, R), "empty IR");
      Check (Is_In_Core (Inst, R), "empty core");
      Check (Allocate (Inst).N = 0, "empty allocate");
      Check (Clear_Raises (Nat (Max_N + 1)), "clear Max_N+1 raises");
      Check (not Clear_Raises (Nat (Max_N)), "clear Max_N ok");
      Clear (Inst, Nat (Max_N));
      Check (Size (Inst) = Max_N, "size Max_N");
   end;

   ---------------------------------------------------------------------
   Section ("2. identity market — all fixed points");
   ---------------------------------------------------------------------
   for N in 1 .. 8 loop
      declare
         Inst : Instance;
         R    : Allocation;
      begin
         Clear (Inst, Nat (N));
         Solve (Inst, R);
         Expect_Identity (R, N, "id n=" & Positive'Image (N));
         Check (Is_Individually_Rational (Inst, R),
                "id IR n=" & Positive'Image (N));
         Check (Is_In_Core (Inst, R),
                "id core n=" & Positive'Image (N));
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("3. mutual swap (2-cycle)");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      R    : Allocation;
   begin
      Clear (Inst, 2);
      --  1: 2 > 1 ; 2: 1 > 2
      Set_Preference (Inst, 1, 1, 2);
      Set_Preference (Inst, 1, 2, 1);
      Set_Preference (Inst, 2, 1, 1);
      Set_Preference (Inst, 2, 2, 2);
      Solve (Inst, R);
      Expect_Assign (R, 1, 2, "swap");
      Expect_Assign (R, 2, 1, "swap");
      Check (Is_In_Core (Inst, R), "swap core");
      Check (House_Of (R, 1) = 2, "House_Of 1");
      Check (Agent_Of (R, 2) = 1, "Agent_Of 2");
   end;

   ---------------------------------------------------------------------
   Section ("4. longer cycle (3-cycle)");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      R    : Allocation;
   begin
      Clear (Inst, 3);
      --  1 wants 2, 2 wants 3, 3 wants 1
      Set_Preference (Inst, 1, 1, 2);
      Set_Preference (Inst, 1, 2, 3);
      Set_Preference (Inst, 1, 3, 1);
      Set_Preference (Inst, 2, 1, 3);
      Set_Preference (Inst, 2, 2, 1);
      Set_Preference (Inst, 2, 3, 2);
      Set_Preference (Inst, 3, 1, 1);
      Set_Preference (Inst, 3, 2, 2);
      Set_Preference (Inst, 3, 3, 3);
      Solve (Inst, R);
      Expect_Assign (R, 1, 2, "c3");
      Expect_Assign (R, 2, 3, "c3");
      Expect_Assign (R, 3, 1, "c3");
      Check (Is_In_Core (Inst, R), "c3 core");
   end;

   ---------------------------------------------------------------------
   Section ("5. Wikipedia Shapley–Scarf example (n=6)");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      R    : Allocation;
      --  Complete permutations consistent with Wikipedia top choices.
      Prefs : constant Pref_Matrix (1 .. 6, 1 .. 6) :=
        [[3, 2, 4, 1, 5, 6],
         [3, 5, 6, 1, 2, 4],
         [3, 1, 2, 4, 5, 6],
         [2, 5, 6, 4, 1, 3],
         [1, 3, 2, 4, 5, 6],
         [2, 4, 5, 6, 1, 3]];
   begin
      Load_Identity_Endowment (Inst, Prefs);
      Check (Size (Inst) = 6, "wiki size");
      Check (Preference (Inst, 1, 1) = 3, "wiki 1 top");
      Check (Preference (Inst, 3, 1) = 3, "wiki 3 top self");
      Check (Endowment (Inst, 4) = 4, "wiki endow id");
      Check (Owner_Of_House (Inst, 5) = 5, "wiki owner");
      Solve (Inst, R);
      --  Final: 1→2, 2→5, 3→3, 4→6, 5→1, 6→4
      Expect_Assign (R, 1, 2, "wiki");
      Expect_Assign (R, 2, 5, "wiki");
      Expect_Assign (R, 3, 3, "wiki");
      Expect_Assign (R, 4, 6, "wiki");
      Expect_Assign (R, 5, 1, "wiki");
      Expect_Assign (R, 6, 4, "wiki");
      Check (Is_Bijection (R), "wiki bij");
      Check (Is_Individually_Rational (Inst, R), "wiki IR");
      Check (Is_In_Core (Inst, R), "wiki core");
      Check (Allocate (Inst).House_Of (3) = 3, "wiki allocate fixed 3");
   end;

   ---------------------------------------------------------------------
   Section ("6. already-happy fixed points mixed with swap");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      R    : Allocation;
   begin
      Clear (Inst, 4);
      --  1 and 2 swap; 3 and 4 keep own (top = self)
      Set_Preference (Inst, 1, 1, 2);
      Set_Preference (Inst, 1, 2, 1);
      Set_Preference (Inst, 1, 3, 3);
      Set_Preference (Inst, 1, 4, 4);
      Set_Preference (Inst, 2, 1, 1);
      Set_Preference (Inst, 2, 2, 2);
      Set_Preference (Inst, 2, 3, 3);
      Set_Preference (Inst, 2, 4, 4);
      Set_Preference (Inst, 3, 1, 3);
      Set_Preference (Inst, 3, 2, 1);
      Set_Preference (Inst, 3, 3, 2);
      Set_Preference (Inst, 3, 4, 4);
      Set_Preference (Inst, 4, 1, 4);
      Set_Preference (Inst, 4, 2, 1);
      Set_Preference (Inst, 4, 3, 2);
      Set_Preference (Inst, 4, 4, 3);
      Solve (Inst, R);
      Expect_Assign (R, 1, 2, "mix");
      Expect_Assign (R, 2, 1, "mix");
      Expect_Assign (R, 3, 3, "mix");
      Expect_Assign (R, 4, 4, "mix");
      Check (Is_In_Core (Inst, R), "mix core");
   end;

   ---------------------------------------------------------------------
   Section ("7. general (non-identity) endowment");
   ---------------------------------------------------------------------
   declare
      Inst  : Instance;
      R     : Allocation;
      Prefs : constant Pref_Matrix (1 .. 3, 1 .. 3) :=
        [[1, 2, 3],
         [2, 3, 1],
         [3, 1, 2]];
      --  Agent 1 owns house 2, 2 owns 3, 3 owns 1
      Endow : constant Id_Array (1 .. 3) := [2, 3, 1];
   begin
      Load (Inst, Prefs, Endow);
      Check (Endowment (Inst, 1) = 2, "gen endow 1");
      Check (Owner_Of_House (Inst, 2) = 1, "gen owner 2");
      Check (Owner_Of_House (Inst, 1) = 3, "gen owner 1");
      Solve (Inst, R);
      --  Each already holds their top house among remaining: 1 holds 2
      --  but wants 1 (owned by 3); wait — prefs: 1 ranks 1>2>3, holds 2.
      --  Top remaining: house 1 owned by 3. Agent 2 holds 3, wants 2 owned
      --  by 1. Agent 3 holds 1, wants 3 owned by 2. Cycle 1→3→2→1.
      --  1 gets holding of 3 = house 1; 3 gets holding of 2 = house 3;
      --  2 gets holding of 1 = house 2.
      Expect_Assign (R, 1, 1, "gen");
      Expect_Assign (R, 2, 2, "gen");
      Expect_Assign (R, 3, 3, "gen");
      Check (Is_In_Core (Inst, R), "gen core");
   end;

   ---------------------------------------------------------------------
   Section ("8. pointing graph and cycle helpers");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      Remain  : Id_Array (1 .. 4) := [1, 1, 1, 1];
      Pt   : Pointing_Array (1 .. 4);
      Cyc  : Cycle_Array (1 .. 4);
      Len  : Natural;
   begin
      Clear (Inst, 4);
      --  Mutual swap 1↔2; agents 3 and 4 top their own houses.
      Set_Preference (Inst, 1, 1, 2);
      Set_Preference (Inst, 1, 2, 1);
      Set_Preference (Inst, 1, 3, 3);
      Set_Preference (Inst, 1, 4, 4);
      Set_Preference (Inst, 2, 1, 1);
      Set_Preference (Inst, 2, 2, 2);
      Set_Preference (Inst, 2, 3, 3);
      Set_Preference (Inst, 2, 4, 4);
      Set_Preference (Inst, 3, 1, 3);
      Set_Preference (Inst, 3, 2, 1);
      Set_Preference (Inst, 3, 3, 2);
      Set_Preference (Inst, 3, 4, 4);
      Set_Preference (Inst, 4, 1, 4);
      Set_Preference (Inst, 4, 2, 1);
      Set_Preference (Inst, 4, 3, 2);
      Set_Preference (Inst, 4, 4, 3);
      Compute_Pointing (Inst, Remain, Pt);
      Check (Pt (1) = 2, "point 1->2");
      Check (Pt (2) = 1, "point 2->1");
      Check (Pt (3) = 3, "point 3->3");
      Check (Pt (4) = 4, "point 4->4");
      Check (Has_Cycle (Pt, 4), "has cycle");
      Check (Count_Cycles (Pt, 4) = 3, "three cycles (2+1+1)");
      Find_Cycle (Pt, 4, 1, Cyc, Len);
      Check (Len = 2, "cycle len 2");
      Check
        ((Cyc (1) = 1 and then Cyc (2) = 2)
         or else (Cyc (1) = 2 and then Cyc (2) = 1),
         "cycle members {1,2}");
      Find_Cycle (Pt, 4, 3, Cyc, Len);
      Check (Len = 1 and then Cyc (1) = 3, "self-cycle 3");
      Remain (1) := 0;
      Remain (2) := 0;
      Compute_Pointing (Inst, Remain, Pt);
      Check (Pt (1) = 0 and then Pt (2) = 0, "removed no point");
      Check (Pt (3) = 3 and then Pt (4) = 4, "remaining self");
      Check (Count_Cycles (Pt, 4) = 2, "two self-cycles left");
      Check (not Has_Cycle (Pt, Nat (0)), "n=0 no cycle");
   end;

   ---------------------------------------------------------------------
   Section ("9. rank / prefers / permutation helpers");
   ---------------------------------------------------------------------
   declare
      Inst  : Instance;
      Prefs : constant Pref_Matrix (1 .. 3, 1 .. 3) :=
        [[2, 3, 1],
         [1, 2, 3],
         [3, 2, 1]];
      Bad   : constant Pref_Matrix (1 .. 3, 1 .. 3) :=
        [[1, 1, 2],
         [1, 2, 3],
         [3, 2, 1]];
      Perm  : constant Id_Array (1 .. 3) := [3, 1, 2];
      Dup   : constant Id_Array (1 .. 3) := [1, 1, 2];
   begin
      Load_Identity_Endowment (Inst, Prefs);
      Check (Rank_Of (Inst, 1, 2) = 1, "rank top");
      Check (Rank_Of (Inst, 1, 1) = 3, "rank bottom");
      Check (Prefers (Inst, 1, 2, 1), "prefers 2>1");
      Check (not Prefers (Inst, 1, 1, 2), "not prefers 1>2");
      Check (Is_Complete_Permutation (Prefs, 3), "complete ok");
      Check (not Is_Complete_Permutation (Bad, 3), "complete bad");
      Check (Is_Complete_Permutation (Prefs, Nat (0)), "complete n0");
      Check (Is_Permutation (Perm, 3), "perm ok");
      Check (not Is_Permutation (Dup, 3), "perm dup");
      Check (Is_Permutation (Perm, Nat (0)), "perm n0");
      Check (not Is_Permutation (Perm, Nat (4)), "perm short");
   end;

   ---------------------------------------------------------------------
   Section ("10. Invalid_Argument coverage");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      Prefs_Ok : constant Pref_Matrix (1 .. 2, 1 .. 2) :=
        [[1, 2], [2, 1]];
      Prefs_Dup : constant Pref_Matrix (1 .. 2, 1 .. 2) :=
        [[1, 1], [2, 1]];
      Prefs_Big : Pref_Matrix (1 .. 2, 1 .. 2) :=
        [[1, 2], [2, 1]];
      Endow_Ok : constant Id_Array (1 .. 2) := [1, 2];
      Endow_Bad : constant Id_Array (1 .. 2) := [1, 1];
      R : Allocation;
   begin
      Clear (Inst, 2);
      Check (Set_Pref_Raises (Inst, Aid (3), 1, 1), "set pref agent OOB");
      Check (Set_Pref_Raises (Inst, 1, Aid (3), 1), "set pref rank OOB");
      Check (Set_Pref_Raises (Inst, 1, 1, Aid (3)), "set pref house OOB");
      Check (Set_Endow_Raises (Inst, Aid (3), 1), "set endow agent OOB");
      Check (Set_Endow_Raises (Inst, 1, Aid (3)), "set endow house OOB");
      Check (Load_Prefs_Raises (Inst, Prefs_Dup), "load prefs dup");
      Check (Load_Endow_Raises (Inst, Endow_Bad), "load endow dup");
      Check (Load_Both_Raises (Prefs_Dup, Endow_Ok), "load both bad prefs");
      Check (Load_Both_Raises (Prefs_Ok, Endow_Bad), "load both bad endow");
      pragma Unreferenced (Prefs_Big);
      Clear (Inst, 2);
      Set_Preference (Inst, 1, 1, 1);
      Set_Preference (Inst, 1, 2, 1);  -- duplicate, incomplete
      Set_Preference (Inst, 2, 1, 2);
      Set_Preference (Inst, 2, 2, 1);
      Check (Solve_Raises (Inst), "solve bad prefs");
      Clear (Inst, 2);
      Set_Endowment (Inst, 1, 1);
      Set_Endowment (Inst, 2, 1);  -- duplicate endowment
      Check (Solve_Raises (Inst), "solve bad endow");
      Clear (Inst, 2);
      Check (Pref_Raises (Inst, Aid (3), 1), "pref OOB");
      Check (Rank_Raises (Inst, Aid (3), 1), "rank OOB");
      Solve (Inst, R);
      Check (House_Raises (R, Aid (3)), "House_Of OOB");
      --  Core check too large
      Clear (Inst, Nat (Max_Core_Check_N + 1));
      Solve (Inst, R);
      Check (Core_Raises (Inst, R), "core too large raises");
   end;

   ---------------------------------------------------------------------
   Section ("11. Load / Set overwrite / getters");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      Prefs : constant Pref_Matrix (1 .. 3, 1 .. 3) :=
        [[3, 2, 1],
         [1, 3, 2],
         [2, 1, 3]];
      Endow : constant Id_Array (1 .. 3) := [1, 2, 3];
   begin
      Load (Inst, Prefs, Endow);
      Check (Preference (Inst, 1, 1) = 3, "load top");
      Check (Endowment (Inst, 2) = 2, "load endow");
      Set_Preference (Inst, 1, 1, 2);
      Set_Preference (Inst, 1, 2, 3);
      Set_Preference (Inst, 1, 3, 1);
      Check (Preference (Inst, 1, 1) = 2, "overwrite top");
      Check (Rank_Of (Inst, 1, 2) = 1, "overwrite rank");
      Set_Endowment (Inst, 1, 3);
      Set_Endowment (Inst, 3, 1);
      Check (Endowment (Inst, 1) = 3, "overwrite endow");
      Check (Owner_Of_House (Inst, 3) = 1, "overwrite owner");
   end;

   ---------------------------------------------------------------------
   Section ("12. two disjoint swaps same round");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      R    : Allocation;
   begin
      Clear (Inst, 4);
      --  1↔2 and 3↔4
      Set_Preference (Inst, 1, 1, 2);
      Set_Preference (Inst, 1, 2, 1);
      Set_Preference (Inst, 1, 3, 3);
      Set_Preference (Inst, 1, 4, 4);
      Set_Preference (Inst, 2, 1, 1);
      Set_Preference (Inst, 2, 2, 2);
      Set_Preference (Inst, 2, 3, 3);
      Set_Preference (Inst, 2, 4, 4);
      Set_Preference (Inst, 3, 1, 4);
      Set_Preference (Inst, 3, 2, 3);
      Set_Preference (Inst, 3, 3, 1);
      Set_Preference (Inst, 3, 4, 2);
      Set_Preference (Inst, 4, 1, 3);
      Set_Preference (Inst, 4, 2, 4);
      Set_Preference (Inst, 4, 3, 1);
      Set_Preference (Inst, 4, 4, 2);
      Solve (Inst, R);
      Expect_Assign (R, 1, 2, "2swap");
      Expect_Assign (R, 2, 1, "2swap");
      Expect_Assign (R, 3, 4, "2swap");
      Expect_Assign (R, 4, 3, "2swap");
      Check (Is_In_Core (Inst, R), "2swap core");
   end;

   ---------------------------------------------------------------------
   Section ("13. 4-cycle");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      R    : Allocation;
   begin
      Clear (Inst, 4);
      Set_Rotated (Inst, 1, 2, 4);  -- 2,3,4,1
      Set_Rotated (Inst, 2, 3, 4);  -- 3,4,1,2
      Set_Rotated (Inst, 3, 4, 4);  -- 4,1,2,3
      Set_Rotated (Inst, 4, 1, 4);  -- 1,2,3,4
      Solve (Inst, R);
      Expect_Assign (R, 1, 2, "c4");
      Expect_Assign (R, 2, 3, "c4");
      Expect_Assign (R, 3, 4, "c4");
      Expect_Assign (R, 4, 1, "c4");
      Check (Is_In_Core (Inst, R), "c4 core");
   end;

   ---------------------------------------------------------------------
   Section ("14. sequential rounds (path into later cycle)");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      R    : Allocation;
   begin
      --  Agent 3 tops self first round; then 1 and 2 swap on house 2/1.
      Clear (Inst, 3);
      Set_Preference (Inst, 1, 1, 3);
      Set_Preference (Inst, 1, 2, 2);
      Set_Preference (Inst, 1, 3, 1);
      Set_Preference (Inst, 2, 1, 3);
      Set_Preference (Inst, 2, 2, 1);
      Set_Preference (Inst, 2, 3, 2);
      Set_Preference (Inst, 3, 1, 3);
      Set_Preference (Inst, 3, 2, 1);
      Set_Preference (Inst, 3, 3, 2);
      Solve (Inst, R);
      Expect_Assign (R, 3, 3, "seq");
      Expect_Assign (R, 1, 2, "seq");
      Expect_Assign (R, 2, 1, "seq");
      Check (Is_In_Core (Inst, R), "seq core");
   end;

   ---------------------------------------------------------------------
   Section ("15. IR fails on non-TTC assignment");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      R    : Allocation;
   begin
      Clear (Inst, 2);
      Set_Preference (Inst, 1, 1, 1);
      Set_Preference (Inst, 1, 2, 2);
      Set_Preference (Inst, 2, 1, 2);
      Set_Preference (Inst, 2, 2, 1);
      --  Forced bad assignment: give each the other's house
      R.N := 2;
      R.House_Of (1) := 2;
      R.House_Of (2) := 1;
      R.Agent_Of (2) := 1;
      R.Agent_Of (1) := 2;
      Check (Is_Bijection (R), "forced bij");
      Check (not Is_Individually_Rational (Inst, R), "forced not IR");
      Check (not Is_In_Core (Inst, R), "forced not core");
      --  TTC keeps identity
      Solve (Inst, R);
      Expect_Identity (R, 2, "ttc id");
      Check (Is_In_Core (Inst, R), "ttc core");
   end;

   ---------------------------------------------------------------------
   Section ("16. blocking coalition detected");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      R    : Allocation;
   begin
      Clear (Inst, 2);
      Set_Preference (Inst, 1, 1, 2);
      Set_Preference (Inst, 1, 2, 1);
      Set_Preference (Inst, 2, 1, 1);
      Set_Preference (Inst, 2, 2, 2);
      --  Identity allocation is blocked by {1,2}
      R.N := 2;
      R.House_Of (1) := 1;
      R.House_Of (2) := 2;
      R.Agent_Of (1) := 1;
      R.Agent_Of (2) := 2;
      Check (Is_Individually_Rational (Inst, R), "id still IR");
      Check (not Is_In_Core (Inst, R), "id blocked by swap coalition");
      Solve (Inst, R);
      Check (Is_In_Core (Inst, R), "ttc unblocks");
   end;

   ---------------------------------------------------------------------
   Section ("17. random-ish rotated markets n=1..8 core");
   ---------------------------------------------------------------------
   for N in 1 .. 8 loop
      declare
         Inst : Instance;
         R    : Allocation;
      begin
         Clear (Inst, Nat (N));
         for I in 1 .. N loop
            Set_Rotated
              (Inst, I, Positive (((I * 3 + 1) rem N) + 1), N);
         end loop;
         Solve (Inst, R);
         Check (Is_Bijection (R),
                "rot bij n=" & Positive'Image (N));
         Check (Is_Individually_Rational (Inst, R),
                "rot IR n=" & Positive'Image (N));
         Check (Is_In_Core (Inst, R),
                "rot core n=" & Positive'Image (N));
         --  Every agent gets something ≥ endowment
         for I in 1 .. N loop
            Check
              (Natural (Rank_Of (Inst, Aid (I),
               Aid (Positive (R.House_Of (I)))))
               <= Natural (Rank_Of (Inst, Aid (I), Aid (I))),
               "rot IR agent" & Positive'Image (I)
               & " n=" & Positive'Image (N));
         end loop;
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("18. larger n bijection / IR without full core");
   ---------------------------------------------------------------------
   for N in 12 .. 16 loop
      declare
         Inst : Instance;
         R    : Allocation;
      begin
         Clear (Inst, Nat (N));
         for I in 1 .. N loop
            Set_Rotated
              (Inst, I, Positive (((I * 5) rem N) + 1), N);
         end loop;
         Solve (Inst, R);
         Check (R.N = N, "big size n=" & Positive'Image (N));
         Check (Is_Bijection (R), "big bij n=" & Positive'Image (N));
         Check (Is_Individually_Rational (Inst, R),
                "big IR n=" & Positive'Image (N));
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("19. n=32 stress (identity + one swap)");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      R    : Allocation;

      procedure Pref_Swap_Pair (A, B : Positive) is
         Rank : Positive := 1;
      begin
         --  A ranks B first, own house second, then other houses in order.
         Set_Preference (Inst, Aid (A), Aid (Rank), Aid (B));
         Rank := Rank + 1;
         Set_Preference (Inst, Aid (A), Aid (Rank), Aid (A));
         Rank := Rank + 1;
         for H in 1 .. 32 loop
            if H /= A and then H /= B then
               Set_Preference (Inst, Aid (A), Aid (Rank), Aid (H));
               Rank := Rank + 1;
            end if;
         end loop;
      end Pref_Swap_Pair;
   begin
      Clear (Inst, Nat (32));
      Check (Size (Inst) = 32, "n32 size");
      Pref_Swap_Pair (7, 11);
      Pref_Swap_Pair (11, 7);
      Solve (Inst, R);
      Check (Is_Bijection (R), "n32 bij");
      Expect_Assign (R, 7, 11, "n32");
      Expect_Assign (R, 11, 7, "n32");
      for I in 1 .. 32 loop
         if I /= 7 and then I /= 11 then
            Check (R.House_Of (I) = I,
                   "n32 fixed" & Positive'Image (I));
         end if;
      end loop;
      Check (Is_Individually_Rational (Inst, R), "n32 IR");
   end;

   ---------------------------------------------------------------------
   Section ("20. Compute_Pointing_With_Holdings after trade");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      Remain  : Id_Array (1 .. 3) := [1, 1, 1];
      Hold : Id_Array (1 .. 3) := [1, 2, 3];
      Pt   : Pointing_Array (1 .. 3);
   begin
      Clear (Inst, 3);
      Set_Preference (Inst, 1, 1, 2);
      Set_Preference (Inst, 1, 2, 3);
      Set_Preference (Inst, 1, 3, 1);
      Set_Preference (Inst, 2, 1, 1);
      Set_Preference (Inst, 2, 2, 2);
      Set_Preference (Inst, 2, 3, 3);
      Set_Preference (Inst, 3, 1, 3);
      Set_Preference (Inst, 3, 2, 1);
      Set_Preference (Inst, 3, 3, 2);
      Compute_Pointing_With_Holdings (Inst, Remain, Hold, Pt);
      Check (Pt (1) = 2, "hold point 1");
      Check (Pt (2) = 1, "hold point 2");
      Check (Pt (3) = 3, "hold point 3");
      --  After removing {1,2}, only 3 remains holding 3
      Remain := [0, 0, 1];
      Hold := [0, 0, 3];
      Compute_Pointing_With_Holdings (Inst, Remain, Hold, Pt);
      Check (Pt (3) = 3, "hold residual self");
      Check (Pt (1) = 0 and then Pt (2) = 0, "hold residual cleared");
   end;

   ---------------------------------------------------------------------
   Section ("21. Is_Bijection negatives");
   ---------------------------------------------------------------------
   declare
      R : Allocation;
   begin
      R.N := 2;
      R.House_Of (1) := 1;
      R.House_Of (2) := 1;  -- dup
      R.Agent_Of (1) := 1;
      R.Agent_Of (2) := 0;
      Check (not Is_Bijection (R), "bij dup");
      R.House_Of (2) := 2;
      R.Agent_Of (2) := 1;  -- wrong inverse
      Check (not Is_Bijection (R), "bij bad inverse");
      R.Agent_Of (2) := 2;
      Check (Is_Bijection (R), "bij ok");
      R.N := Nat (Max_N + 1);
      Check (not Is_Bijection (R), "bij N>Max");
   end;

   ---------------------------------------------------------------------
   Section ("22. preference matrix Load_Identity vs Clear");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      Prefs : constant Pref_Matrix (1 .. 1, 1 .. 1) := [[1]];
      R1, R2 : Allocation;
   begin
      Load_Identity_Endowment (Inst, Prefs);
      Solve (Inst, R1);
      Clear (Inst, 1);
      Solve (Inst, R2);
      Check (R1.House_Of (1) = R2.House_Of (1), "n1 agree");
      Check (Is_In_Core (Inst, R1), "n1 core");
   end;

   ---------------------------------------------------------------------
   Section ("23. five-agent chain then self");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      R    : Allocation;
   begin
      Clear (Inst, 5);
      --  Tops: 1→2, 2→3, 3→4, 4→5, 5→5 (self). First round clears {5};
      --  then 1→2→3→4→1 becomes a 4-cycle once 5 is gone? After 5 leaves,
      --  house 5 gone. Agent 4's top was 5 — next is ... need full lists.
      Set_Rotated (Inst, 1, 2, 5); -- 2,3,4,5,1
      Set_Rotated (Inst, 2, 3, 5); -- 3,4,5,1,2
      Set_Rotated (Inst, 3, 4, 5); -- 4,5,1,2,3
      Set_Rotated (Inst, 4, 5, 5); -- 5,1,2,3,4
      --  Agent 5 tops self
      Set_Preference (Inst, 5, 1, 5);
      Set_Preference (Inst, 5, 2, 1);
      Set_Preference (Inst, 5, 3, 2);
      Set_Preference (Inst, 5, 4, 3);
      Set_Preference (Inst, 5, 5, 4);
      Solve (Inst, R);
      Expect_Assign (R, 5, 5, "chain");
      --  After 5 leaves: 1→2→3→4→1 (4's next top is 1)
      Expect_Assign (R, 1, 2, "chain");
      Expect_Assign (R, 2, 3, "chain");
      Expect_Assign (R, 3, 4, "chain");
      Expect_Assign (R, 4, 1, "chain");
      Check (Is_In_Core (Inst, R), "chain core");
   end;

   ---------------------------------------------------------------------
   Section ("24. getters after Solve");
   ---------------------------------------------------------------------
   declare
      Inst : Instance;
      R    : Allocation;
   begin
      Clear (Inst, 3);
      Fill_Identity_Prefs (Inst, 3);
      Set_Preference (Inst, 1, 1, 2);
      Set_Preference (Inst, 1, 2, 1);
      Set_Preference (Inst, 1, 3, 3);
      Set_Preference (Inst, 2, 1, 1);
      Set_Preference (Inst, 2, 2, 2);
      Set_Preference (Inst, 2, 3, 3);
      Solve (Inst, R);
      Check (House_Of (R, 1) = 2, "get house");
      Check (Agent_Of (R, 2) = 1, "get agent");
      Check (House_Of (R, 3) = 3, "get fixed");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   New_Line;
   Put_Line ("=================================");
   Put_Line
     ("Results: " & Natural'Image (Pass_Count)
      & " PASS," & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count = 0 and then Pass_Count >= 150 then
      Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Put_Line ("SOME FAILED OR TOO FEW");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
