--  Standalone test suite for Floyds_Cycle_Finding_Algorithm.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Floyds_Cycle_Finding_Algorithm;
use Floyds_Cycle_Finding_Algorithm;

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
   function Pos (X : Positive) return Positive is (X);

   function Find_Raises
     (Next : Successor_Map; Start : Positive) return Boolean
   is
      R : Cycle_Result;
   begin
      R := Find_Cycle (Next, Start);
      pragma Unreferenced (R);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Find_Raises;

   function Detect_Raises
     (Next : Successor_Map; Start : Positive) return Boolean
   is
      R : Cycle_Result;
   begin
      R := Detect (Next, Start);
      pragma Unreferenced (R);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Detect_Raises;

   function Naive_Raises
     (Next : Successor_Map; Start : Positive) return Boolean
   is
      R : Cycle_Result;
   begin
      R := Find_Cycle_Naive (Next, Start);
      pragma Unreferenced (R);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Naive_Raises;

   function Step_Raises
     (Next : Successor_Map; X : Node_Index) return Boolean
   is
      Y : Node_Index;
   begin
      Y := Step (Next, X);
      pragma Unreferenced (Y);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Step_Raises;

   function Iterate_Raises
     (Next : Successor_Map; Start : Positive; Steps : Natural)
      return Boolean
   is
      Y : Node_Index;
   begin
      Y := Iterate (Next, Start, Steps);
      pragma Unreferenced (Y);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Iterate_Raises;

   function Pure_Raises (N : Positive) return Boolean is
      M : Successor_Map (1 .. 1);
   begin
      M := Pure_Cycle (N);
      pragma Unreferenced (M);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when Constraint_Error =>
         return True;
   end Pure_Raises;

   function Rho_Raises (Tail : Natural; Cycle : Positive) return Boolean is
      M : Successor_Map (1 .. 1);
   begin
      M := Rho_Graph (Tail, Cycle);
      pragma Unreferenced (M);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when Constraint_Error =>
         return True;
   end Rho_Raises;

   function Path_Raises (N : Positive) return Boolean is
      M : Successor_Map (1 .. 1);
   begin
      M := Path_To_Sink (N);
      pragma Unreferenced (M);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when Constraint_Error =>
         return True;
   end Path_Raises;

   function Self_Raises (N : Positive) return Boolean is
      M : Successor_Map (1 .. 1);
   begin
      M := Self_Loop_Chain (N);
      pragma Unreferenced (M);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when Constraint_Error =>
         return True;
   end Self_Raises;

   function Same_Mu_Lam (A, B : Cycle_Result) return Boolean is
   begin
      return A.Has_Cycle = B.Has_Cycle
        and then A.Mu = B.Mu
        and then A.Lambda = B.Lambda
        and then A.Start_Node = B.Start_Node;
   end Same_Mu_Lam;

   --  Library-level-style nested f for the Wikipedia map (generic).
   Wiki : constant Successor_Map := Wikipedia_Example;

   function Wiki_F (X : Node_Index) return Node_Index is
   begin
      if X = Null_Index or else X > Wiki'Last then
         return Null_Index;
      end if;
      return Node_Index (Wiki (X));
   end Wiki_F;

   function Wiki_Find is new Find_Cycle_On_Function (Wiki_F);
   function Wiki_Det is new Detect_On_Function (Wiki_F);

   --  Open path callback: 1 → 2 → 3 → 0
   function Path_F (X : Node_Index) return Node_Index is
   begin
      if X = 1 then
         return 2;
      elsif X = 2 then
         return 3;
      else
         return Null_Index;
      end if;
   end Path_F;

   function Path_Find is new Find_Cycle_On_Function (Path_F);
   function Path_Det is new Detect_On_Function (Path_F);

   --  Pure 5-cycle callback.
   function C5_F (X : Node_Index) return Node_Index is
   begin
      if X = Null_Index or else X > 5 then
         return Null_Index;
      elsif X = 5 then
         return 1;
      else
         return X + 1;
      end if;
   end C5_F;

   function C5_Find is new Find_Cycle_On_Function (C5_F);
   function C5_Det is new Detect_On_Function (C5_F);

   --  Divergent callback (never repeats, never null) — must time out.
   function Drift_F (X : Node_Index) return Node_Index is
   begin
      if X = Max_Nodes then
         return Max_Nodes;
      end if;
      return X + 1;
   end Drift_F;

   function Drift_Find is new Find_Cycle_On_Function (Drift_F);

   function Drift_Raises return Boolean is
      R : Cycle_Result;
   begin
      R := Drift_Find (1, Max_Steps => 8);
      pragma Unreferenced (R);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Drift_Raises;

   R, N : Cycle_Result;
   M    : Successor_Map (1 .. 16);
   W    : Successor_Map (1 .. 9);
   T    : Successor_Map (1 .. 6);

begin
   -----------------------------------------------------------------
   Section ("1. Invalid_Argument (bad maps / starts / builders)");
   -----------------------------------------------------------------
   declare
      Empty : Successor_Map (1 .. 0);
   begin
      Check (not Is_Valid_Map (Empty), "empty map invalid");
      Check (Find_Raises (Empty, 1), "Find empty raises");
      Check (Detect_Raises (Empty, 1), "Detect empty raises");
      Check (Step_Raises (Empty, 0), "Step empty raises");
   end;

   declare
      Shifted : constant Successor_Map (2 .. 4) := [2, 3, 2];
   begin
      Check (not Is_Valid_Map (Shifted), "non-1-based invalid");
      Check (Find_Raises (Shifted, 2), "Find shifted raises");
   end;

   declare
      OOB : constant Successor_Map (1 .. 3) := [2, 3, 9];
   begin
      Check (not Is_Valid_Map (OOB), "successor > N invalid");
      Check (Find_Raises (OOB, 1), "Find OOB raises");
      Check (Naive_Raises (OOB, 1), "Naive OOB raises");
   end;

   declare
      Ok : constant Successor_Map := [1 => 1];
   begin
      Check (Is_Valid_Map (Ok), "self-loop N=1 valid");
      Check (Find_Raises (Ok, 2), "Start > N raises");
      Check (Detect_Raises (Ok, 3), "Detect Start > N raises");
      Check (Iterate_Raises (Ok, 4, 0), "Iterate Start > N raises");
      Check (Step_Raises (Ok, 2), "Step live X > N raises");
   end;

   Check (Pure_Raises (Max_Nodes + 1), "Pure_Cycle N>Max raises");
   Check (Path_Raises (Max_Nodes + 1), "Path_To_Sink N>Max raises");
   Check (Self_Raises (Max_Nodes + 1), "Self_Loop_Chain N>Max raises");
   Check (Rho_Raises (Max_Nodes, 1), "Rho Tail+Cycle>Max raises");
   Check (Rho_Raises (1, Max_Nodes), "Rho Cycle=Max Tail=1 raises");
   Check (Drift_Raises, "generic Max_Steps exceeded raises");

   -----------------------------------------------------------------
   Section ("2. Is_Valid_Map / Step / Iterate");
   -----------------------------------------------------------------
   Check (Is_Valid_Map ([1 => 1]), "valid 1-cycle");
   Check (Is_Valid_Map ([1 => 0]), "valid 1-sink");
   Check (Is_Valid_Map ([1 => 2, 2 => 0]), "valid 2-path");
   Check (Is_Valid_Map (Pure_Cycle (7)), "valid pure-7");
   Check (not Is_Valid_Map ([1 => 4, 2 => 1, 3 => 2]), "4>3 invalid");
   Check (Step ([1 => 2, 2 => 0], 0) = 0, "Step 0 = 0");
   Check (Step ([1 => 2, 2 => 0], 1) = 2, "Step 1 = 2");
   Check (Step ([1 => 2, 2 => 0], 2) = 0, "Step 2 = 0");
   Check (Iterate ([1 => 2, 2 => 3, 3 => 1], 1, 0) = 1,
          "Iterate 0 steps is Start");
   Check (Iterate ([1 => 2, 2 => 3, 3 => 1], 1, 1) = 2,
          "Iterate 1 step");
   Check (Iterate ([1 => 2, 2 => 3, 3 => 1], 1, 3) = 1,
          "Iterate full period");
   Check (Iterate ([1 => 2, 2 => 0], 1, 5) = 0,
          "Iterate past sink stays 0");
   Check (Iterate (Self_Loop_Chain (4), 1, 10) = 4,
          "Iterate past self-loop stays");

   -----------------------------------------------------------------
   Section ("3. Pure cycles (μ = 0, λ = N)");
   -----------------------------------------------------------------
   for Len in 1 .. 12 loop
      M (1 .. Len) := Pure_Cycle (Len);
      R := Find_Cycle (M (1 .. Len), 1);
      Check (R.Has_Cycle
               and then R.Mu = 0
               and then R.Lambda = Len
               and then R.Start_Node = 1
               and then R.Meeting_Point /= Null_Index,
             "pure N=" & Len'Image & " start=1");
      if Len > 1 then
         R := Find_Cycle (M (1 .. Len), Len);
         Check (R.Has_Cycle
                  and then R.Mu = 0
                  and then R.Lambda = Len
                  and then R.Start_Node = Len,
                "pure N=" & Len'Image & " start=N");
      end if;
   end loop;

   -----------------------------------------------------------------
   Section ("4. Self-loop chains (μ = N-1, λ = 1)");
   -----------------------------------------------------------------
   for Len in 1 .. 10 loop
      declare
         G : constant Successor_Map := Self_Loop_Chain (Len);
      begin
         R := Find_Cycle (G, 1);
         Check (R.Has_Cycle
                  and then R.Lambda = 1
                  and then R.Mu = Len - 1
                  and then R.Start_Node = Len,
                "self-loop chain N=" & Len'Image);
         Check (Has_Cycle (G, 1)
                  and then Cycle_Length (G, 1) = Nat (1)
                  and then Tail_Length (G, 1) = Len - 1
                  and then Cycle_Start (G, 1) = Len,
                "wrappers chain N=" & Len'Image);
      end;
   end loop;

   -----------------------------------------------------------------
   Section ("5. Path to sink (no cycle)");
   -----------------------------------------------------------------
   for Len in 1 .. 10 loop
      declare
         G : constant Successor_Map := Path_To_Sink (Len);
      begin
         R := Find_Cycle (G, 1);
         Check (not R.Has_Cycle
                  and then R.Lambda = 0
                  and then R.Meeting_Point = Null_Index,
                "sink N=" & Len'Image & " start=1");
         if Len > 1 then
            R := Find_Cycle (G, Len);
            Check (not R.Has_Cycle, "sink N=" & Len'Image & " start=N");
         end if;
         Check (not Has_Cycle (G, 1)
                  and then Cycle_Length (G, 1) = Nat (0),
                "wrappers sink N=" & Len'Image);
      end;
   end loop;

   -----------------------------------------------------------------
   Section ("6. Rho graphs (stem + cycle)");
   -----------------------------------------------------------------
   declare
      type Pair is record
         Tail, Cyc : Positive;
      end record;
      Pairs : constant array (1 .. 10) of Pair :=
        [(1, 1), (1, 2), (1, 5), (2, 3), (3, 3),
         (4, 1), (5, 4), (6, 2), (7, 7), (8, 3)];
   begin
      for P of Pairs loop
         declare
            G : constant Successor_Map :=
              Rho_Graph (P.Tail, P.Cyc);
         begin
            R := Find_Cycle (G, 1);
            Check (R.Has_Cycle
                     and then R.Mu = P.Tail
                     and then R.Lambda = P.Cyc
                     and then R.Start_Node = Node_Index (P.Tail + 1),
                   "rho μ=" & P.Tail'Image & " λ=" & P.Cyc'Image);
            Check (Is_On_Cycle
                     (G, R.Meeting_Point, R.Start_Node, R.Lambda),
                   "rho meet on cycle μ=" & P.Tail'Image);
            --  Start already on the cycle.
            R := Find_Cycle (G, P.Tail + 1);
            Check (R.Has_Cycle
                     and then R.Mu = 0
                     and then R.Lambda = P.Cyc,
                   "rho start-on-cycle μ=" & P.Tail'Image);
         end;
      end loop;
   end;

   --  Tail = 0 is a pure cycle.
   R := Find_Cycle (Rho_Graph (0, 9), 1);
   Check (R.Has_Cycle and then R.Mu = 0 and then R.Lambda = 9,
          "rho Tail=0 is pure-9");

   -----------------------------------------------------------------
   Section ("7. Wikipedia example (start wiki 2)");
   -----------------------------------------------------------------
   W := Wikipedia_Example;
   Check (Is_Valid_Map (W), "wiki map valid");
   R := Find_Cycle (W, 3);
   Check (R.Has_Cycle, "wiki start-3 has cycle");
   Check (R.Mu = 2, "wiki μ = 2");
   Check (R.Lambda = 3, "wiki λ = 3");
   Check (R.Start_Node = 7, "wiki x_μ = 7 (wiki 6)");
   Check (Iterate (W, 3, 0) = 3, "wiki x0 = 3");
   Check (Iterate (W, 3, 1) = 1, "wiki x1 = 1 (wiki 0)");
   Check (Iterate (W, 3, 2) = 7, "wiki x2 = 7 (wiki 6)");
   Check (Iterate (W, 3, 3) = 4, "wiki x3 = 4 (wiki 3)");
   Check (Iterate (W, 3, 4) = 2, "wiki x4 = 2 (wiki 1)");
   Check (Iterate (W, 3, 5) = 7, "wiki x5 = 7 repeats");
   Check (Is_On_Cycle (W, 7, 7, 3), "wiki 7 on cycle");
   Check (Is_On_Cycle (W, 4, 7, 3), "wiki 4 on cycle");
   Check (Is_On_Cycle (W, 2, 7, 3), "wiki 2 on cycle");
   Check (not Is_On_Cycle (W, 3, 7, 3), "wiki 3 not on cycle");
   Check (not Is_On_Cycle (W, 1, 7, 3), "wiki 1 (tail) not on cycle");
   --  Self-loop cycle at wiki 4 = Ada 5.
   R := Find_Cycle (W, 5);
   Check (R.Has_Cycle and then R.Lambda = 1 and then R.Mu = 0
            and then R.Start_Node = 5,
          "wiki node 5 is λ=1 cycle");
   --  Ada 8 (wiki 7) → 5 → 5.
   R := Find_Cycle (W, 8);
   Check (R.Has_Cycle and then R.Lambda = 1 and then R.Mu = 1
            and then R.Start_Node = 5,
          "wiki node 8 tails into {5}");

   -----------------------------------------------------------------
   Section ("8. Detect vs Find_Cycle");
   -----------------------------------------------------------------
   declare
      G : constant Successor_Map := Rho_Graph (4, 6);
   begin
      R := Detect (G, 1);
      N := Find_Cycle (G, 1);
      Check (R.Has_Cycle and then N.Has_Cycle, "Detect/Find both cycle");
      Check (R.Meeting_Point = N.Meeting_Point, "same meeting point");
      Check (R.Mu = 0 and then R.Lambda = 0 and then R.Start_Node = 0,
             "Detect leaves μ/λ/start unset");
      Check (N.Mu = 4 and then N.Lambda = 6, "Find fills μ/λ");
      Check (Has_Cycle (G, 1), "Has_Cycle wrapper");
   end;
   declare
      G : constant Successor_Map := Path_To_Sink (5);
   begin
      R := Detect (G, 1);
      Check (not R.Has_Cycle and then R.Meeting_Point = 0,
             "Detect sink is No_Cycle");
   end;

   -----------------------------------------------------------------
   Section ("9. Naive reference agrees with Floyd");
   -----------------------------------------------------------------
   for Len in 1 .. 8 loop
      declare
         G : constant Successor_Map := Pure_Cycle (Len);
      begin
         R := Find_Cycle (G, 1);
         N := Find_Cycle_Naive (G, 1);
         Check (Same_Mu_Lam (R, N), "naive=floyd pure " & Len'Image);
      end;
      declare
         G : constant Successor_Map := Path_To_Sink (Len);
      begin
         R := Find_Cycle (G, 1);
         N := Find_Cycle_Naive (G, 1);
         Check (Same_Mu_Lam (R, N), "naive=floyd sink " & Len'Image);
      end;
      declare
         G : constant Successor_Map := Self_Loop_Chain (Len);
      begin
         R := Find_Cycle (G, 1);
         N := Find_Cycle_Naive (G, 1);
         Check (Same_Mu_Lam (R, N), "naive=floyd loop " & Len'Image);
      end;
   end loop;

   for Tail in 0 .. 4 loop
      for Cyc in 1 .. 4 loop
         declare
            G : constant Successor_Map := Rho_Graph (Tail, Cyc);
         begin
            R := Find_Cycle (G, 1);
            N := Find_Cycle_Naive (G, 1);
            Check (Same_Mu_Lam (R, N),
                   "naive=floyd rho " & Tail'Image & "," & Cyc'Image);
         end;
      end loop;
   end loop;

   W := Wikipedia_Example;
   for S in 1 .. 9 loop
      R := Find_Cycle (W, S);
      N := Find_Cycle_Naive (W, S);
      Check (Same_Mu_Lam (R, N), "naive=floyd wiki start=" & S'Image);
   end loop;

   -----------------------------------------------------------------
   Section ("10. Two_Cycles components");
   -----------------------------------------------------------------
   T := Two_Cycles;
   Check (Is_Valid_Map (T), "Two_Cycles valid");
   R := Find_Cycle (T, 1);
   Check (R.Has_Cycle and then R.Lambda = 3 and then R.Mu = 0
            and then R.Start_Node = 1,
          "comp A start 1: λ=3");
   R := Find_Cycle (T, 2);
   Check (R.Has_Cycle and then R.Lambda = 3 and then R.Start_Node = 2,
          "comp A start 2: still λ=3");
   R := Find_Cycle (T, 4);
   Check (R.Has_Cycle and then R.Lambda = 2 and then R.Mu = 0
            and then R.Start_Node = 4,
          "comp B start 4: λ=2");
   R := Find_Cycle (T, 5);
   Check (R.Has_Cycle and then R.Lambda = 2 and then R.Start_Node = 5,
          "comp B start 5: λ=2");
   R := Find_Cycle (T, 6);
   Check (not R.Has_Cycle, "node 6 is a sink (no cycle)");
   Check (not Is_On_Cycle (T, 4, 1, 3), "4 not on cycle A");
   Check (Is_On_Cycle (T, 1, 1, 3), "1 on cycle A");

   -----------------------------------------------------------------
   Section ("11. Convenience wrappers + Is_On_Cycle edges");
   -----------------------------------------------------------------
   declare
      G : constant Successor_Map := Rho_Graph (3, 4);
   begin
      Check (Cycle_Length (G, 1) = Nat (4), "wrapper λ");
      Check (Tail_Length (G, 1) = Nat (3), "wrapper μ");
      Check (Cycle_Start (G, 1) = 4, "wrapper start");
      Check (not Is_On_Cycle (G, 0, 4, 4), "null not on cycle");
      Check (not Is_On_Cycle (G, 4, 0, 4), "null start-node");
      Check (not Is_On_Cycle (G, 4, 4, 0), "λ=0 not a cycle");
      Check (not Is_On_Cycle (G, 9, 4, 4), "node > N");
   end;

   -----------------------------------------------------------------
   Section ("12. Generic Find_Cycle_On_Function / Detect_On_Function");
   -----------------------------------------------------------------
   R := Wiki_Find (3);
   Check (R.Has_Cycle and then R.Mu = 2 and then R.Lambda = 3
            and then R.Start_Node = 7,
          "generic wiki μ=2 λ=3");
   R := Wiki_Det (3);
   Check (R.Has_Cycle and then R.Meeting_Point /= 0
            and then R.Mu = 0 and then R.Lambda = 0,
          "generic Detect wiki");
   R := Wiki_Find (5);
   Check (R.Has_Cycle and then R.Lambda = 1 and then R.Start_Node = 5,
          "generic wiki self-loop");
   R := Path_Find (1);
   Check (not R.Has_Cycle, "generic path: no cycle");
   R := Path_Det (1);
   Check (not R.Has_Cycle, "generic Detect path: no cycle");
   R := Path_Find (0);
   Check (not R.Has_Cycle, "generic Start=0 → No_Cycle");
   R := C5_Find (1);
   Check (R.Has_Cycle and then R.Mu = 0 and then R.Lambda = 5
            and then R.Start_Node = 1,
          "generic C5 from 1");
   R := C5_Find (3);
   Check (R.Has_Cycle and then R.Lambda = 5 and then R.Start_Node = 3,
          "generic C5 from 3");
   R := C5_Det (1);
   Check (R.Has_Cycle, "generic Detect C5");

   -----------------------------------------------------------------
   Section ("13. Meeting point lies on the cycle");
   -----------------------------------------------------------------
   for Tail in 0 .. 4 loop
      for Cyc in 1 .. 4 loop
         declare
            G : constant Successor_Map := Rho_Graph (Tail, Cyc);
         begin
            R := Find_Cycle (G, 1);
            Check (Is_On_Cycle
                     (G, R.Meeting_Point, R.Start_Node, R.Lambda)
                     and then Iterate (G, 1, R.Mu) = R.Start_Node
                     and then Iterate (G, Positive (R.Start_Node), R.Lambda)
                       = R.Start_Node,
                   "meet / x_μ / f^λ " & Tail'Image & "," & Cyc'Image);
         end;
      end loop;
   end loop;

   -----------------------------------------------------------------
   Section ("14. Deterministic functional-graph batch");
   -----------------------------------------------------------------
   --  Next(I) = 1 + (A*I + C) mod N — a total map, so every start cycles.
   for Nsz in 4 .. 10 loop
      declare
         G : Successor_Map (1 .. Nsz);
         A : constant Natural := 3;
         C : constant Natural := 5;
      begin
         for I in 1 .. Nsz loop
            G (I) := 1 + (A * I + C) mod Nsz;
         end loop;
         Check (Is_Valid_Map (G), "batch map N=" & Nsz'Image);
         for S in 1 .. Nsz loop
            R := Find_Cycle (G, S);
            N := Find_Cycle_Naive (G, S);
            Check (R.Has_Cycle
                     and then Same_Mu_Lam (R, N)
                     and then R.Lambda >= 1
                     and then R.Lambda <= Nsz
                     and then Iterate (G, S, R.Mu) = R.Start_Node,
                   "batch N=" & Nsz'Image & " s=" & S'Image);
         end loop;
      end;
   end loop;

   -----------------------------------------------------------------
   Section ("15. Mixed null / cycle graph");
   -----------------------------------------------------------------
   declare
      --  1 → 2 → 3 → 2 (cycle λ=2, μ=1 from 1); 4 → 0; 5 → 4 → 0
      G : constant Successor_Map :=
        [1 => 2, 2 => 3, 3 => 2, 4 => 0, 5 => 4];
   begin
      R := Find_Cycle (G, 1);
      Check (R.Has_Cycle and then R.Mu = 1 and then R.Lambda = 2
               and then R.Start_Node = 2,
             "mixed: 1 tails into {2,3}");
      R := Find_Cycle (G, 2);
      Check (R.Has_Cycle and then R.Mu = 0 and then R.Lambda = 2,
             "mixed: start on cycle");
      R := Find_Cycle (G, 4);
      Check (not R.Has_Cycle, "mixed: 4 → 0 no cycle");
      R := Find_Cycle (G, 5);
      Check (not R.Has_Cycle, "mixed: 5 → 4 → 0 no cycle");
      Check (Detect (G, 5).Has_Cycle = False, "Detect mixed sink");
      Check (Detect (G, 1).Has_Cycle, "Detect mixed cycle");
   end;

   -----------------------------------------------------------------
   Section ("16. N=1 extremes");
   -----------------------------------------------------------------
   R := Find_Cycle ([1 => 1], 1);
   Check (R.Has_Cycle and then R.Mu = 0 and then R.Lambda = 1
            and then R.Start_Node = 1 and then R.Meeting_Point = 1,
          "N=1 self-loop");
   R := Find_Cycle ([1 => 0], 1);
   Check (not R.Has_Cycle, "N=1 sink");
   Check (Detect ([1 => 1], 1).Has_Cycle, "Detect N=1 loop");
   Check (not Detect ([1 => 0], 1).Has_Cycle, "Detect N=1 sink");
   Check (Iterate ([1 => 1], 1, 0) = 1, "Iterate 0 on loop");
   Check (Iterate ([1 => 1], 1, 20) = 1, "Iterate many on loop");

   -----------------------------------------------------------------
   New_Line;
   Put_Line ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
             & " FAIL");
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
   pragma Unreferenced (Pos);
end Tests;
