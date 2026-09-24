--  Standalone test suite for Floyds_Cycle_Finding_Algorithm (SPARK port).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Floyds_Cycle_Finding_Algorithm;
use Floyds_Cycle_Finding_Algorithm;

procedure Tests
  with SPARK_Mode => Off
is

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
   function Idx (X : Node_Index) return Node_Index is (X);

   function Same_Mu_Lam (A, B : Cycle_Result) return Boolean is
   begin
      return A.Has_Cycle = B.Has_Cycle
        and then A.Mu = B.Mu
        and then A.Lambda = B.Lambda
        and then A.Start_Node = B.Start_Node;
   end Same_Mu_Lam;

begin
   Section ("Pure cycle");
   declare
      M : constant Successor_Map := Pure_Cycle (5);
      R : constant Cycle_Result := Find_Cycle (M, 1);
      D : constant Cycle_Result := Detect (M, 1);
   begin
      Check (Is_Valid_Map (M), "Pure_Cycle(5) valid");
      Check (R.Has_Cycle, "pure cycle has cycle");
      Check (Nat (R.Mu) = 0, "pure cycle mu = 0");
      Check (Nat (R.Lambda) = 5, "pure cycle lambda = 5");
      Check (Idx (R.Start_Node) = 1, "pure cycle start = 1");
      Check (D.Has_Cycle, "Detect sees cycle");
      Check (Idx (D.Meeting_Point) /= Null_Index, "Detect meeting live");
      Check (Has_Cycle (M, 1), "Has_Cycle true");
      Check (Nat (Cycle_Length (M, 1)) = 5, "Cycle_Length = 5");
      Check (Idx (Cycle_Start (M, 1)) = 1, "Cycle_Start = 1");
      Check (Nat (Tail_Length (M, 1)) = 0, "Tail_Length = 0");
   end;

   Section ("Rho graph");
   declare
      M : constant Successor_Map := Rho_Graph (3, 4);
      R : constant Cycle_Result := Find_Cycle (M, 1);
      N : constant Cycle_Result := Find_Cycle_Naive (M, 1);
   begin
      Check (M'Last = 7, "rho N = 7");
      Check (Nat (R.Mu) = 3, "rho mu = 3");
      Check (Nat (R.Lambda) = 4, "rho lambda = 4");
      Check (Idx (R.Start_Node) = 4, "rho start = 4");
      Check (Same_Mu_Lam (R, N), "Floyd matches naive on rho");
      Check (Is_On_Cycle (M, 4, R.Start_Node, R.Lambda), "4 on cycle");
      Check (Is_On_Cycle (M, 7, R.Start_Node, R.Lambda), "7 on cycle");
      Check (not Is_On_Cycle (M, 1, R.Start_Node, R.Lambda), "1 not on cycle");
   end;

   Section ("Path to sink (no cycle)");
   declare
      M : constant Successor_Map := Path_To_Sink (6);
      R : constant Cycle_Result := Find_Cycle (M, 1);
      D : constant Cycle_Result := Detect (M, 1);
   begin
      Check (not R.Has_Cycle, "path has no cycle");
      Check (R = No_Cycle, "path result is No_Cycle");
      Check (not D.Has_Cycle, "Detect no cycle on path");
      Check (not Has_Cycle (M, 1), "Has_Cycle false");
      Check (Nat (Cycle_Length (M, 1)) = 0, "Cycle_Length = 0");
      Check (Idx (Cycle_Start (M, 1)) = Null_Index, "Cycle_Start null");
   end;

   Section ("Self-loop chain");
   declare
      M : constant Successor_Map := Self_Loop_Chain (4);
      R : constant Cycle_Result := Find_Cycle (M, 1);
   begin
      Check (Nat (R.Mu) = 3, "self-loop mu = 3");
      Check (Nat (R.Lambda) = 1, "self-loop lambda = 1");
      Check (Idx (R.Start_Node) = 4, "self-loop start = 4");
   end;

   Section ("Two cycles");
   declare
      M : constant Successor_Map := Two_Cycles;
      R1 : constant Cycle_Result := Find_Cycle (M, 1);
      R4 : constant Cycle_Result := Find_Cycle (M, 4);
      R6 : constant Cycle_Result := Find_Cycle (M, 6);
   begin
      Check (Nat (R1.Lambda) = 3, "from 1: lambda = 3");
      Check (Nat (R4.Lambda) = 2, "from 4: lambda = 2");
      Check (not R6.Has_Cycle, "from 6: no cycle");
   end;

   Section ("Wikipedia example");
   declare
      M : constant Successor_Map := Wikipedia_Example;
      R : constant Cycle_Result := Find_Cycle (M, 3);
      N : constant Cycle_Result := Find_Cycle_Naive (M, 3);
   begin
      Check (Nat (R.Mu) = 2, "wiki mu = 2");
      Check (Nat (R.Lambda) = 3, "wiki lambda = 3");
      Check (Idx (R.Start_Node) = 7, "wiki start = 7");
      Check (Same_Mu_Lam (R, N), "Floyd matches naive on wiki");
   end;

   Section ("Step / Iterate");
   declare
      M : constant Successor_Map := Pure_Cycle (3);
   begin
      Check (Idx (Step (M, 0)) = 0, "Step(0) = 0");
      Check (Idx (Step (M, 1)) = 2, "Step(1) = 2");
      Check (Idx (Step (M, 3)) = 1, "Step(3) = 1");
      Check (Idx (Iterate (M, 1, 0)) = 1, "Iterate 0 steps");
      Check (Idx (Iterate (M, 1, 3)) = 1, "Iterate full lap");
      Check (Idx (Iterate (M, 1, 4)) = 2, "Iterate 4 steps");
   end;

   Section ("Rho Tail = 0 (pure cycle via Rho)");
   declare
      M : constant Successor_Map := Rho_Graph (0, 5);
      R : constant Cycle_Result := Find_Cycle (M, 1);
   begin
      Check (Nat (R.Mu) = 0, "rho0 mu = 0");
      Check (Nat (R.Lambda) = 5, "rho0 lambda = 5");
   end;

   Section ("Single-node self-loop");
   declare
      M : constant Successor_Map := Self_Loop_Chain (1);
      R : constant Cycle_Result := Find_Cycle (M, 1);
   begin
      Check (R.Has_Cycle, "1-node loop has cycle");
      Check (Nat (R.Mu) = 0, "1-node mu = 0");
      Check (Nat (R.Lambda) = 1, "1-node lambda = 1");
   end;

   Section ("Is_Valid_Map / Is_On_Cycle edges");
   declare
      Bad_First : constant Successor_Map (2 .. 3) := [2 => 3, 3 => 2];
      Good      : constant Successor_Map := Pure_Cycle (3);
   begin
      Check (not Is_Valid_Map (Bad_First), "non-1-based map invalid");
      Check (Is_Valid_Map (Good), "good map valid");
      Check (not Is_On_Cycle (Good, 0, 1, 3), "null node not on cycle");
      Check (not Is_On_Cycle (Good, 1, 0, 3), "null start_node");
      Check (not Is_On_Cycle (Good, 1, 1, 0), "lambda 0");
   end;

   Section ("Agreement Floyd vs Naive (battery)");
   declare
      procedure Agree (Label : String; M : Successor_Map; S : Node_Id) is
         A : constant Cycle_Result := Find_Cycle (M, S);
         B : constant Cycle_Result := Find_Cycle_Naive (M, S);
      begin
         Check (Same_Mu_Lam (A, B), Label);
      end Agree;
   begin
      Agree ("agree pure 8", Pure_Cycle (8), 1);
      Agree ("agree rho 2,5", Rho_Graph (2, 5), 1);
      Agree ("agree path 10", Path_To_Sink (10), 1);
      Agree ("agree self 7", Self_Loop_Chain (7), 1);
      Agree ("agree two from 2", Two_Cycles, 2);
      Agree ("agree two from 5", Two_Cycles, 5);
      Agree ("agree wiki from 5", Wikipedia_Example, 5);
   end;

   New_Line;
   Put_Line
     ("=== "
      & Natural'Image (Pass_Count)
      & " passed, "
      & Natural'Image (Fail_Count)
      & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
