--  Standalone test suite for Backtracking (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Backtracking; use Backtracking;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
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
   function I (X : Integer)  return Integer  is (X);
   function N (X : Natural)  return Natural  is (X);
   function P (X : Positive) return Positive is (X);
   function B (X : Boolean)  return Boolean  is (X);

   ---------------------------------------------------------------------------
   -- Exception probes
   ---------------------------------------------------------------------------

   function Count_Raises (K : Positive) return Boolean is
      Unused : Natural;
   begin
      Unused := Count_N_Queens (K);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Count_Raises;

   function Solve_Raises (K : Positive) return Boolean is
      Place  : Queen_Array (1 .. K);
      Unused : Boolean;
   begin
      Unused := Solve_N_Queens (K, Place);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Solve_Raises;

   function Solve_Bad_Bounds_Raises return Boolean is
      Place  : Queen_Array (2 .. 5);
      Unused : Boolean;
   begin
      Unused := Solve_N_Queens (P (4), Place);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Solve_Bad_Bounds_Raises;

   function Subset_Raises
     (A : Element_Array; Target : Integer) return Boolean
   is
      Unused : Boolean;
   begin
      Unused := Subset_Sum_Exists (A, Target);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Subset_Raises;

   function Subset_Chosen_Mismatch_Raises return Boolean is
      A      : constant Element_Array (1 .. 3) := [1, 2, 3];
      Chosen : Boolean_Array (1 .. 2);
      Unused : Boolean;
   begin
      Unused := Subset_Sum (A, I (3), Chosen);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Subset_Chosen_Mismatch_Raises;

   function Color_Raises_K return Boolean is
      Adj    : constant Adjacency_Matrix (1 .. 2, 1 .. 2) :=
        [1 => [1 => False, 2 => True],
         2 => [1 => True,  2 => False]];
      Colors : Color_Array (1 .. 2);
      Unused : Boolean;
   begin
      Unused := Color_Graph (Adj, P (Max_Colors + 1), Colors);
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Color_Raises_K;

   function Safe_Placement_Raises return Boolean is
      Place  : constant Queen_Array (1 .. 2) := [1, 2];
      Unused : Boolean;
   begin
      Unused := Is_Safe_Placement (Place, P (Max_N + 1));
      pragma Unreferenced (Unused);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Safe_Placement_Raises;

   function Sum_Chosen
     (A : Element_Array; Chosen : Boolean_Array) return Integer
   is
      S : Integer := 0;
   begin
      for Idx in A'Range loop
         if Chosen (Idx) then
            S := S + A (Idx);
         end if;
      end loop;
      return S;
   end Sum_Chosen;

begin
   Put_Line ("Backtracking — Ada 2023 educational test suite");
   Put_Line ("==============================================");

   ---------------------------------------------------------------------------
   Section ("Count_N_Queens — known sequence");
   ---------------------------------------------------------------------------

   Check (Count_N_Queens (P (1)) = N (1), "N=1 → 1");
   Check (Count_N_Queens (P (2)) = N (0), "N=2 → 0");
   Check (Count_N_Queens (P (3)) = N (0), "N=3 → 0");
   Check (Count_N_Queens (P (4)) = N (2), "N=4 → 2");
   Check (Count_N_Queens (P (5)) = N (10), "N=5 → 10");
   Check (Count_N_Queens (P (6)) = N (4), "N=6 → 4");
   Check (Count_N_Queens (P (7)) = N (40), "N=7 → 40");
   Check (Count_N_Queens (P (8)) = N (92), "N=8 → 92");
   Check (Count_N_Queens (P (9)) = N (352), "N=9 → 352");
   Check (Count_N_Queens (P (10)) = N (724), "N=10 → 724");
   Check (Count_N_Queens (P (11)) = N (2680), "N=11 → 2680");
   Check (Count_N_Queens (P (12)) = N (14200), "N=12 → 14200");

   ---------------------------------------------------------------------------
   Section ("Count_N_Queens — Max_N and Invalid_Argument");
   ---------------------------------------------------------------------------

   Check (Count_Raises (P (Max_N + 1)), "Count N=Max_N+1 raises");
   Check (Count_Raises (P (20)), "Count N=20 raises");
   Check (not Count_Raises (P (Max_N)), "Count N=Max_N does not raise");
   --  N=13,14 are slower but educational; verify known counts.
   Check (Count_N_Queens (P (13)) = N (73712), "N=13 → 73712");
   Check (Count_N_Queens (P (14)) = N (365596), "N=14 → 365596");

   ---------------------------------------------------------------------------
   Section ("Solve_N_Queens — existence and validity");
   ---------------------------------------------------------------------------

   declare
      Place : Queen_Array (1 .. 4);
      Ok    : Boolean;
   begin
      Ok := Solve_N_Queens (P (4), Place);
      Check (Ok, "Solve N=4 finds a solution");
      Check (Is_Safe_Placement (Place, P (4)), "Solve N=4 placement safe");
   end;

   declare
      Place : Queen_Array (1 .. 8);
      Ok    : Boolean;
   begin
      Ok := Solve_N_Queens (P (8), Place);
      Check (Ok, "Solve N=8 finds a solution");
      Check (Is_Safe_Placement (Place, P (8)), "Solve N=8 placement safe");
   end;

   declare
      Place : Queen_Array (1 .. 1);
      Ok    : Boolean;
   begin
      Ok := Solve_N_Queens (P (1), Place);
      Check (Ok, "Solve N=1 finds a solution");
      Check (Place (1) = N (1), "Solve N=1 places at column 1");
   end;

   declare
      Place : Queen_Array (1 .. 2);
      Ok    : Boolean;
   begin
      Ok := Solve_N_Queens (P (2), Place);
      Check (not Ok, "Solve N=2 has no solution");
   end;

   declare
      Place : Queen_Array (1 .. 3);
      Ok    : Boolean;
   begin
      Ok := Solve_N_Queens (P (3), Place);
      Check (not Ok, "Solve N=3 has no solution");
   end;

   for Sz in 5 .. 10 loop
      declare
         Place : Queen_Array (1 .. Sz);
         Ok    : Boolean;
      begin
         Ok := Solve_N_Queens (Sz, Place);
         Check (Ok, "Solve N=" & Sz'Image & " finds a solution");
         Check
           (Is_Safe_Placement (Place, Sz),
            "Solve N=" & Sz'Image & " placement safe");
      end;
   end loop;

   Check (Solve_Raises (P (Max_N + 1)), "Solve N=Max_N+1 raises");
   Check (Solve_Bad_Bounds_Raises, "Solve bad Placement bounds raises");
   Check (Safe_Placement_Raises, "Is_Safe_Placement N>Max_N raises");

   ---------------------------------------------------------------------------
   Section ("Is_Safe_Placement — positive and negative cases");
   ---------------------------------------------------------------------------

   declare
      --  One known N=4 solution: columns 2,4,1,3
      Good4 : constant Queen_Array (1 .. 4) := [2, 4, 1, 3];
      Bad4  : constant Queen_Array (1 .. 4) := [1, 2, 3, 4];
      Dup   : constant Queen_Array (1 .. 4) := [1, 3, 1, 4];
      Off   : constant Queen_Array (1 .. 4) := [0, 2, 4, 1];
   begin
      Check (Is_Safe_Placement (Good4, P (4)), "known N=4 solution safe");
      Check (not Is_Safe_Placement (Bad4, P (4)), "diagonal board unsafe");
      Check (not Is_Safe_Placement (Dup, P (4)), "duplicate column unsafe");
      Check (not Is_Safe_Placement (Off, P (4)), "out-of-range column unsafe");
   end;

   declare
      Good8 : constant Queen_Array (1 .. 8) :=
        [1, 5, 8, 6, 3, 7, 2, 4];
   begin
      Check (Is_Safe_Placement (Good8, P (8)), "known N=8 solution safe");
   end;

   ---------------------------------------------------------------------------
   Section ("Subset_Sum — basics");
   ---------------------------------------------------------------------------

   declare
      A      : constant Element_Array (1 .. 5) := [3, 34, 4, 12, 5];
      Chosen : Boolean_Array (1 .. 5);
      Ok     : Boolean;
   begin
      Ok := Subset_Sum (A, I (9), Chosen);
      Check (Ok, "subset sum 9 exists in [3,34,4,12,5]");
      Check (Sum_Chosen (A, Chosen) = I (9), "chosen sums to 9");

      Ok := Subset_Sum (A, I (8), Chosen);
      Check (Ok, "subset sum 8 exists (3+5)");
      Check (Sum_Chosen (A, Chosen) = I (8), "chosen sums to 8");
      Ok := Subset_Sum (A, I (16), Chosen);
      Check (Ok, "subset sum 16 exists (4+12)");
      Check (Sum_Chosen (A, Chosen) = I (16), "chosen sums to 16");

      Ok := Subset_Sum (A, I (30), Chosen);
      Check (not Ok, "subset sum 30 absent");
      Check
        ((for all J in Chosen'Range => not Chosen (J)),
         "failure clears Chosen");
   end;

   Check
     (Subset_Sum_Exists ([1, 2, 3], I (0)),
      "empty subset sums to 0");
   Check
     (Subset_Sum_Exists ([1, 2, 3], I (6)),
      "full set sums to 6");
   Check
     (not Subset_Sum_Exists ([1, 2, 3], I (7)),
      "7 absent from [1,2,3]");
   Check
     (Subset_Sum_Exists ([5], I (5)),
      "singleton hit");
   Check
     (not Subset_Sum_Exists ([5], I (4)),
      "singleton miss");

   ---------------------------------------------------------------------------
   Section ("Subset_Sum — empty array and zeros");
   ---------------------------------------------------------------------------

   declare
      Empty  : Element_Array (1 .. 0);
      Chosen : Boolean_Array (1 .. 0);
      Ok     : Boolean;
   begin
      Ok := Subset_Sum (Empty, I (0), Chosen);
      Check (Ok, "empty array Target=0");
      Ok := Subset_Sum (Empty, I (1), Chosen);
      Check (not Ok, "empty array Target=1");
   end;

   Check
     (Subset_Sum_Exists ([0, 0, 0], I (0)),
      "zeros Target=0");
   Check
     (not Subset_Sum_Exists ([0, 0, 0], I (1)),
      "zeros Target=1 absent");
   Check
     (Subset_Sum_Exists ([0, 5, 0], I (5)),
      "zeros with 5");

   ---------------------------------------------------------------------------
   Section ("Subset_Sum — negatives and mixed");
   ---------------------------------------------------------------------------

   declare
      A      : constant Element_Array (1 .. 4) := [3, -2, 5, -1];
      Chosen : Boolean_Array (1 .. 4);
      Ok     : Boolean;
   begin
      Ok := Subset_Sum (A, I (5), Chosen);
      Check (Ok, "mixed: sum 5 exists");
      Check (Sum_Chosen (A, Chosen) = I (5), "mixed chosen sums to 5");

      Ok := Subset_Sum (A, I (6), Chosen);
      Check (Ok, "mixed: sum 6 = 3+5-2");
      Check (Sum_Chosen (A, Chosen) = I (6), "mixed chosen sums to 6");

      Ok := Subset_Sum (A, I (-3), Chosen);
      Check (Ok, "mixed: sum -3 = -2+-1");
      Check (Sum_Chosen (A, Chosen) = I (-3), "mixed chosen sums to -3");

      Ok := Subset_Sum (A, I (100), Chosen);
      Check (not Ok, "mixed: 100 impossible");
   end;

   Check
     (Subset_Sum_Exists ([-5, -3, -1], I (-4)),
      "all-negative: -3+-1");
   Check
     (not Subset_Sum_Exists ([-5, -3, -1], I (1)),
      "all-negative cannot make positive");
   Check
     (Subset_Sum_Exists ([-5, -3, -1], I (0)),
      "all-negative empty subset");

   ---------------------------------------------------------------------------
   Section ("Subset_Sum — more known cases");
   ---------------------------------------------------------------------------

   declare
      A : constant Element_Array (1 .. 3) := [1, 2, 3];
   begin
      Check (Subset_Sum_Exists (A, I (6)), "A=[1,2,3] Target=6");
      Check (Subset_Sum_Exists (A, I (1)), "A=[1,2,3] Target=1");
      Check (Subset_Sum_Exists (A, I (4)), "A=[1,2,3] Target=4");
      Check (not Subset_Sum_Exists (A, I (10)), "A=[1,2,3] Target=10 absent");
      Check (Subset_Sum_Exists (A, I (3)), "A=[1,2,3] Target=3");
      Check (Subset_Sum_Exists (A, I (5)), "A=[1,2,3] Target=5");
      Check (not Subset_Sum_Exists (A, I (-1)), "A=[1,2,3] Target=-1 absent");
   end;

   --  Classic DP textbook instance
   Check
     (Subset_Sum_Exists ([2, 3, 7, 8, 10], I (11)),
      "[2,3,7,8,10] → 11");
   Check
     (Subset_Sum_Exists ([2, 3, 7, 8, 10], I (12)),
      "[2,3,7,8,10] → 12");
   Check
     (Subset_Sum_Exists ([2, 3, 7, 8, 10], I (15)),
      "[2,3,7,8,10] → 15");
   Check
     (not Subset_Sum_Exists ([2, 3, 7, 8, 10], I (14)),
      "[2,3,7,8,10] ↛ 14");
   Check
     (not Subset_Sum_Exists ([2, 3, 7, 8, 10], I (1)),
      "[2,3,7,8,10] ↛ 1");

   --  Large-ish positive array still under Max_Subset_N
   declare
      Big : Element_Array (1 .. 20);
   begin
      for J in Big'Range loop
         Big (J) := J;
      end loop;
      Check
        (Subset_Sum_Exists (Big, I (210)),
         "1..20 sums to 210 (full)");
      Check
        (Subset_Sum_Exists (Big, I (55)),
         "1..20 can make 55");
      Check
        (not Subset_Sum_Exists (Big, I (211)),
         "1..20 cannot make 211");
   end;

   ---------------------------------------------------------------------------
   Section ("Subset_Sum — Invalid_Argument");
   ---------------------------------------------------------------------------

   declare
      Too_Long : constant Element_Array (1 .. Max_Subset_N + 1) := [others => 1];
   begin
      Check (Subset_Raises (Too_Long, I (1)), "n>Max_Subset_N raises");
   end;
   Check (Subset_Chosen_Mismatch_Raises, "Chosen length mismatch raises");

   ---------------------------------------------------------------------------
   Section ("Subset_Sum — Chosen contents");
   ---------------------------------------------------------------------------

   declare
      A      : constant Element_Array (1 .. 4) := [10, 20, 30, 40];
      Chosen : Boolean_Array (1 .. 4);
      Ok     : Boolean;
   begin
      Ok := Subset_Sum (A, I (50), Chosen);
      Check (Ok, "10+40 or 20+30 = 50");
      Check (Sum_Chosen (A, Chosen) = I (50), "Chosen sums to 50");
      Check
        (Chosen (1) or Chosen (2) or Chosen (3) or Chosen (4),
         "at least one element chosen for 50");
   end;

   declare
      A      : constant Element_Array (5 .. 7) := [4, 5, 6];
      Chosen : Boolean_Array (5 .. 7);
      Ok     : Boolean;
   begin
      Ok := Subset_Sum (A, I (9), Chosen);
      Check (Ok, "non-1-based A: 4+5=9");
      Check (Sum_Chosen (A, Chosen) = I (9), "non-1-based Chosen sum");
   end;

   ---------------------------------------------------------------------------
   Section ("Color_Graph — small graphs");
   ---------------------------------------------------------------------------

   --  Empty-ish: single vertex
   declare
      Adj    : constant Adjacency_Matrix (1 .. 1, 1 .. 1) := [1 => [1 => False]];
      Colors : Color_Array (1 .. 1);
      Ok     : Boolean;
   begin
      Ok := Color_Graph (Adj, P (1), Colors);
      Check (Ok, "1-vertex 1-colourable");
      Check (Colors (1) = N (1), "single vertex colour 1");
      Check
        (Is_Valid_Colouring (Adj, Colors, P (1)),
         "1-vertex colouring valid");
   end;

   --  Single edge: needs 2 colours
   declare
      Adj    : constant Adjacency_Matrix (1 .. 2, 1 .. 2) :=
        [1 => [False, True],
         2 => [True,  False]];
      Colors : Color_Array (1 .. 2);
      Ok     : Boolean;
   begin
      Ok := Color_Graph (Adj, P (1), Colors);
      Check (not Ok, "K2 not 1-colourable");
      Ok := Color_Graph (Adj, P (2), Colors);
      Check (Ok, "K2 is 2-colourable");
      Check
        (Is_Valid_Colouring (Adj, Colors, P (2)),
         "K2 colouring valid");
      Check (Colors (1) /= Colors (2), "K2 endpoints differ");
   end;

   --  Triangle K3: chromatic number 3
   declare
      Adj    : constant Adjacency_Matrix (1 .. 3, 1 .. 3) :=
        [1 => [False, True,  True],
         2 => [True,  False, True],
         3 => [True,  True,  False]];
      Colors : Color_Array (1 .. 3);
      Ok     : Boolean;
   begin
      Ok := Color_Graph (Adj, P (2), Colors);
      Check (not Ok, "K3 not 2-colourable");
      Ok := Color_Graph (Adj, P (3), Colors);
      Check (Ok, "K3 is 3-colourable");
      Check
        (Is_Valid_Colouring (Adj, Colors, P (3)),
         "K3 colouring valid");
      Check
        (Colors (1) /= Colors (2)
           and then Colors (1) /= Colors (3)
           and then Colors (2) /= Colors (3),
         "K3 all colours distinct");
   end;

   --  Path of 4 vertices: 2-colourable
   declare
      Adj    : Adjacency_Matrix (1 .. 4, 1 .. 4) := [others => [others => False]];
      Colors : Color_Array (1 .. 4);
      Ok     : Boolean;
   begin
      Adj (1, 2) := True; Adj (2, 1) := True;
      Adj (2, 3) := True; Adj (3, 2) := True;
      Adj (3, 4) := True; Adj (4, 3) := True;
      Ok := Color_Graph (Adj, P (2), Colors);
      Check (Ok, "P4 is 2-colourable");
      Check
        (Is_Valid_Colouring (Adj, Colors, P (2)),
         "P4 colouring valid");
   end;

   --  Cycle C5: chromatic number 3
   declare
      Adj    : Adjacency_Matrix (1 .. 5, 1 .. 5) := [others => [others => False]];
      Colors : Color_Array (1 .. 5);
      Ok     : Boolean;
   begin
      for V in 1 .. 5 loop
         declare
            W : constant Positive := (if V = 5 then 1 else V + 1);
         begin
            Adj (V, W) := True;
            Adj (W, V) := True;
         end;
      end loop;
      Ok := Color_Graph (Adj, P (2), Colors);
      Check (not Ok, "C5 not 2-colourable");
      Ok := Color_Graph (Adj, P (3), Colors);
      Check (Ok, "C5 is 3-colourable");
      Check
        (Is_Valid_Colouring (Adj, Colors, P (3)),
         "C5 colouring valid");
   end;

   --  Bipartite complete K2,3 style star: 2-colourable
   declare
      Adj    : Adjacency_Matrix (1 .. 4, 1 .. 4) := [others => [others => False]];
      Colors : Color_Array (1 .. 4);
      Ok     : Boolean;
   begin
      --  Star: center 1 connected to 2,3,4
      for Leaf in 2 .. 4 loop
         Adj (1, Leaf) := True;
         Adj (Leaf, 1) := True;
      end loop;
      Ok := Color_Graph (Adj, P (2), Colors);
      Check (Ok, "star K1,3 is 2-colourable");
      Check
        (Is_Valid_Colouring (Adj, Colors, P (2)),
         "star colouring valid");
      Check
        (Colors (2) = Colors (3) and then Colors (3) = Colors (4),
         "star leaves share a colour");
   end;

   Check (Color_Raises_K, "K_Colors > Max_Colors raises");

   ---------------------------------------------------------------------------
   Section ("Color_Graph — Is_Valid_Colouring negatives");
   ---------------------------------------------------------------------------

   declare
      Adj    : constant Adjacency_Matrix (1 .. 2, 1 .. 2) :=
        [1 => [False, True],
         2 => [True,  False]];
      Bad    : constant Color_Array (1 .. 2) := [1, 1];
      Good   : constant Color_Array (1 .. 2) := [1, 2];
      Zero   : constant Color_Array (1 .. 2) := [0, 1];
   begin
      Check
        (not Is_Valid_Colouring (Adj, Bad, P (2)),
         "same colour on edge invalid");
      Check
        (Is_Valid_Colouring (Adj, Good, P (2)),
         "proper 2-colouring valid");
      Check
        (not Is_Valid_Colouring (Adj, Zero, P (2)),
         "colour 0 invalid");
   end;

   ---------------------------------------------------------------------------
   Section ("N-Queens — Solve matches Count existence");
   ---------------------------------------------------------------------------

   for Sz in 1 .. 10 loop
      declare
         Place : Queen_Array (1 .. Sz);
         Ok    : constant Boolean := Solve_N_Queens (Sz, Place);
         Cnt   : constant Natural := Count_N_Queens (Sz);
      begin
         Check
           (Ok = (Cnt > 0),
            "Solve iff Count>0 for N=" & Sz'Image);
         if Ok then
            Check
              (Is_Safe_Placement (Place, Sz),
               "existence solution safe N=" & Sz'Image);
         end if;
      end;
   end loop;

   ---------------------------------------------------------------------------
   Section ("Subset_Sum — exhaustive cross-check small n");
   ---------------------------------------------------------------------------

   --  For n ≤ 8, compare backtracking decision against full 2^n masks.
   declare
      A : constant Element_Array (1 .. 6) := [4, 7, -2, 9, 1, 3];

      function Brute (Target : Integer) return Boolean is
      begin
         for Mask in 0 .. 2 ** A'Length - 1 loop
            declare
               S    : Integer := 0;
               M    : Natural := Mask;
               Idx  : Positive := A'First;
            begin
               while Idx <= A'Last loop
                  if M mod 2 = 1 then
                     S := S + A (Idx);
                  end if;
                  M := M / 2;
                  Idx := Idx + 1;
               end loop;
               if S = Target then
                  return True;
               end if;
            end;
         end loop;
         return False;
      end Brute;

      Targets : constant array (Positive range <>) of Integer :=
        [-5, -2, 0, 1, 3, 4, 7, 8, 9, 10, 11, 12, 14, 15, 20, 22, 100, -100];
   begin
      for T of Targets loop
         Check
           (Subset_Sum_Exists (A, T) = Brute (T),
            "BT vs brute Target=" & T'Image);
      end loop;
   end;

   ---------------------------------------------------------------------------
   Section ("Subset_Sum — many random-ish fixed vectors");
   ---------------------------------------------------------------------------

   declare
      V1 : constant Element_Array := [1, 1, 1, 1, 1, 1, 1, 1];
      V2 : constant Element_Array := [10, 1, 1, 1, 1, 1];
      V3 : constant Element_Array := [100, 50, 25, 12, 6, 3];
   begin
      Check (Subset_Sum_Exists (V1, I (0)), "eight 1s → 0");
      Check (Subset_Sum_Exists (V1, I (8)), "eight 1s → 8");
      Check (Subset_Sum_Exists (V1, I (4)), "eight 1s → 4");
      Check (not Subset_Sum_Exists (V1, I (9)), "eight 1s ↛ 9");

      Check (Subset_Sum_Exists (V2, I (12)), "10+1+1 → 12");
      Check (Subset_Sum_Exists (V2, I (5)), "five 1s → 5");
      Check (not Subset_Sum_Exists (V2, I (16)), "V2 ↛ 16");

      Check (Subset_Sum_Exists (V3, I (196)), "V3 full sum");
      Check (Subset_Sum_Exists (V3, I (75)), "V3 → 75");
      Check (Subset_Sum_Exists (V3, I (28)), "V3 → 28 = 25+3");
      Check (not Subset_Sum_Exists (V3, I (2)), "V3 ↛ 2");
   end;

   ---------------------------------------------------------------------------
   Section ("Graph colouring — complete graphs");
   ---------------------------------------------------------------------------

   for Order in 2 .. 5 loop
      declare
         Adj    : Adjacency_Matrix (1 .. Order, 1 .. Order) :=
           [others => [others => True]];
         Colors : Color_Array (1 .. Order);
         Ok     : Boolean;
      begin
         for V in 1 .. Order loop
            Adj (V, V) := False;
         end loop;
         Ok := Color_Graph (Adj, P (Order - 1), Colors);
         Check
           (not Ok,
            "K" & Order'Image & " not (χ-1)-colourable");
         Ok := Color_Graph (Adj, Order, Colors);
         Check
           (Ok,
            "K" & Order'Image & " is Order-colourable");
         Check
           (Is_Valid_Colouring (Adj, Colors, Order),
            "K" & Order'Image & " colouring valid");
      end;
   end loop;

   ---------------------------------------------------------------------------
   Section ("Caps and constants");
   ---------------------------------------------------------------------------

   Check (Max_N = P (14), "Max_N = 14");
   Check (Max_Subset_N = P (40), "Max_Subset_N = 40");
   Check (Max_Vertices = P (16), "Max_Vertices = 16");
   Check (Max_Colors = P (8), "Max_Colors = 8");
   Check (B (True), "sanity True");
   Check (I (0) = 0, "sanity I(0)");
   Check (N (92) = 92, "sanity N(92)");

   ---------------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------------

   New_Line;
   Put_Line ("==============================================");
   Put_Line
     ("Passed:" & Pass_Count'Image & "  Failed:" & Fail_Count'Image);
   if Fail_Count = 0 then
      Put_Line ("ALL PASSED");
   else
      Put_Line ("SOME FAILED");
   end if;

end Tests;
