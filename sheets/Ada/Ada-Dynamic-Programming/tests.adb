--  Standalone test suite for Dynamic_Programming (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Dynamic_Programming; use Dynamic_Programming;

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
         Ada.Text_IO.Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Ada.Text_IO.Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("=== " & Title & " ===");
   end Section;

begin
   Ada.Text_IO.Put_Line ("Dynamic_Programming test suite");
   Ada.Text_IO.Put_Line ("==============================");

   ---------------------------------------------------------------------
   Section ("1. Taxonomy helpers");
   ---------------------------------------------------------------------
   declare
      Info : Problem_Info;
   begin
      Check (Problem_Count = 9, "Problem_Count = 9");
      Check (Problem_Name (Fibonacci_Seq) = "Fibonacci", "Name Fib");
      Check (Problem_Name (Knapsack_01) = "0/1 Knapsack", "Name KS");
      Check (Problem_Name (Edit_Distance) =
               "Edit Distance (Levenshtein)", "Name edit");
      Check (Strategy_Name (Tabulation) = "Tabulation", "Strat tab");
      Check (Strategy_Name (Memoization) = "Memoization", "Strat memo");

      for K in Problem_Kind loop
         Info := Classify (K);
         Check (Info.Kind = K, "Classify kind " & Problem_Name (K));
         Check (Info.Uses_Optimal_Substructure,
                "Opt substructure " & Problem_Name (K));
         Check (Info.Uses_Overlapping_Subproblems,
                "Overlap " & Problem_Name (K));
         Check (Uses_Optimal_Substructure (K),
                "Uses_Opt helper " & Problem_Name (K));
         Check (Uses_Overlapping_Subproblems (K),
                "Uses_Overlap helper " & Problem_Name (K));
         Check (Info.Typical_Table_Dims in 1 .. 2,
                "Table dims " & Problem_Name (K));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("2. Fibonacci bottom-up and memo");
   ---------------------------------------------------------------------
   declare
      Expected : constant array (0 .. 20) of Fib_Value :=
        [0 => 0, 1 => 1, 2 => 1, 3 => 2, 4 => 3, 5 => 5, 6 => 8,
         7 => 13, 8 => 21, 9 => 34, 10 => 55, 11 => 89, 12 => 144,
         13 => 233, 14 => 377, 15 => 610, 16 => 987, 17 => 1597,
         18 => 2584, 19 => 4181, 20 => 6765];
   begin
      for N in Expected'Range loop
         Check (Fibonacci (N) = Expected (N),
                "Fib(" & N'Image & ") tab");
         Check (Fibonacci_Memo (N) = Expected (N),
                "Fib(" & N'Image & ") memo");
         Check (Fibonacci (N) = Fibonacci_Memo (N),
                "Fib tab=memo " & N'Image);
      end loop;
      Check (Fibonacci (30) = 832_040, "Fib(30)");
      Check (Fibonacci_Memo (30) = 832_040, "Fib_Memo(30)");
      Check (Fibonacci (40) = 102_334_155, "Fib(40)");
      Check (Fibonacci (50) = 12_586_269_025, "Fib(50)");
      Check (Fibonacci (92) = 7_540_113_804_746_346_429, "Fib(92)");
      Check (Fibonacci_Memo (92) = Fibonacci (92), "Fib(92) memo=tab");
      Check (Fibonacci (0) = 0, "Fib(0)");
      Check (Fibonacci (1) = 1, "Fib(1)");
   end;

   ---------------------------------------------------------------------
   Section ("3. 0/1 Knapsack");
   ---------------------------------------------------------------------
   declare
      --  Classic: weights 2,3,4,5 values 3,4,5,6 capacity 5 → 7 (items 1+2)
      W1 : constant Weight_Array := [2, 3, 4, 5];
      V1 : constant Value_Array  := [3, 4, 5, 6];
      R1 : Knapsack_Result;
      --  Textbook: w=[1,2,3] v=[6,10,12] C=5 → 22
      W2 : constant Weight_Array := [1, 2, 3];
      V2 : constant Value_Array  := [6, 10, 12];
      R2 : Knapsack_Result;
      --  Single item that fits
      W3 : constant Weight_Array := [5];
      V3 : constant Value_Array  := [10];
      --  Nothing fits
      W4 : constant Weight_Array := [10, 20];
      V4 : constant Value_Array  := [100, 200];
      Sel_Value : Natural;
   begin
      Check (Knapsack_01 (W1, V1, 5) = 7, "KS classic C=5 → 7");
      Check (Knapsack_01 (W1, V1, 0) = 0, "KS C=0 → 0");
      Check (Knapsack_01 (W2, V2, 5) = 22, "KS textbook → 22");
      Check (Knapsack_01 (W2, V2, 1) = 6, "KS C=1 → 6");
      Check (Knapsack_01 (W2, V2, 2) = 10, "KS C=2 → 10");
      Check (Knapsack_01 (W2, V2, 3) = 16, "KS C=3 → 16");
      Check (Knapsack_01 (W2, V2, 4) = 18, "KS C=4 → 18");
      Check (Knapsack_01 (W3, V3, 5) = 10, "KS single fit");
      Check (Knapsack_01 (W3, V3, 4) = 0, "KS single no fit");
      Check (Knapsack_01 (W4, V4, 5) = 0, "KS none fit");

      R1 := Knapsack_01_With_Selection (W1, V1, 5);
      Check (R1.Success, "KS sel success");
      Check (R1.Max_Value = 7, "KS sel value 7");
      Check (R1.Selected (1) and R1.Selected (2)
               and not R1.Selected (3) and not R1.Selected (4),
             "KS sel items 1+2");

      R2 := Knapsack_01_With_Selection (W2, V2, 5);
      Check (R2.Max_Value = 22, "KS sel textbook 22");
      Sel_Value := 0;
      for I in 1 .. R2.N_Items loop
         if R2.Selected (I) then
            Sel_Value := Sel_Value + V2 (V2'First + I - 1);
         end if;
      end loop;
      Check (Sel_Value = 22, "KS sel reconstruct value");
      Check (R2.Selected (2) and R2.Selected (3),
             "KS sel items 2+3 (wt 2+3)");
   end;

   ---------------------------------------------------------------------
   Section ("4. Unbounded coin change");
   ---------------------------------------------------------------------
   declare
      C1 : constant Coin_Array := [1, 5, 10, 25];
      C2 : constant Coin_Array := [2, 5, 10];
      C3 : constant Coin_Array := [2];
      C4 : constant Coin_Array := [1, 2, 5];
   begin
      Check (Min_Coins (C1, 0) = 0, "Min_Coins amount 0");
      Check (Min_Coins (C1, 30) = 2, "Min_Coins 30 → 2 (25+5)");
      Check (Min_Coins (C1, 40) = 3, "Min_Coins 40 → 3");
      Check (Min_Coins (C1, 11) = 2, "Min_Coins 11 → 2");
      Check (Min_Coins (C1, 3) = 3, "Min_Coins 3 → 3");
      Check (Min_Coins (C3, 3) = -1, "Min_Coins impossible");
      Check (Min_Coins (C2, 3) = -1, "Min_Coins 3 w/ {2,5,10}");
      Check (Min_Coins (C2, 4) = 2, "Min_Coins 4 → 2×2");
      Check (Min_Coins (C4, 11) = 3, "Min_Coins 11 w/ {1,2,5} → 3");

      Check (Coin_Combinations (C1, 0) = 1, "Ways amount 0 → 1");
      Check (Coin_Combinations (C4, 5) = 4, "Ways 5 w/ {1,2,5} → 4");
      --  Combinations for 4 with {1,2,5}: 1+1+1+1, 1+1+2, 2+2 → 3
      Check (Coin_Combinations (C4, 4) = 3, "Ways 4 → 3");
      Check (Coin_Combinations (C3, 3) = 0, "Ways impossible → 0");
      Check (Coin_Combinations (C3, 4) = 1, "Ways 4 w/ {2} → 1");
      Check (Coin_Combinations ([1, 2, 3], 4) = 4, "Ways 4 w/ {1,2,3}");
   end;

   ---------------------------------------------------------------------
   Section ("5. LCS");
   ---------------------------------------------------------------------
   declare
      S1 : constant String := "ABCBDAB";
      S2 : constant String := "BDCABA";
      S3 : constant String := "AGGTAB";
      S4 : constant String := "GXTXAYB";
      L  : constant String := LCS_String (S1, S2);
      L2 : constant String := LCS_String (S3, S4);
   begin
      Check (LCS_Length (S1, S2) = 4, "LCS(ABCBDAB,BDCABA)=4");
      Check (L'Length = 4, "LCS string length 4");
      Check (LCS_Length (L, L) = 4, "LCS(L,L)=|L|");
      --  Known valid LCS strings include BDAB, BCAB, BCBA
      Check (L = "BDAB" or else L = "BCAB" or else L = "BCBA",
             "LCS reconstruct one of BDAB/BCAB/BCBA");

      Check (LCS_Length (S3, S4) = 4, "LCS(AGGTAB,GXTXAYB)=4");
      Check (L2 = "GTAB", "LCS reconstruct GTAB");
      Check (LCS_Length ("", "ABC") = 0, "LCS empty A");
      Check (LCS_Length ("ABC", "") = 0, "LCS empty B");
      Check (LCS_Length ("", "") = 0, "LCS both empty");
      Check (LCS_Length ("ABC", "ABC") = 3, "LCS identical");
      Check (LCS_Length ("ABC", "DEF") = 0, "LCS disjoint");
      Check (LCS_String ("ABC", "ABC") = "ABC", "LCS_String identical");
      Check (LCS_String ("AXYT", "AYZX") = "AY"
                or else LCS_String ("AXYT", "AYZX") = "AX"
                or else LCS_String ("AXYT", "AYZX") = "AT"
                or else LCS_String ("AXYT", "AYZX") = "XY"
                or else LCS_String ("AXYT", "AYZX") = "XT",
             "LCS AXYT/AYZX length-2");
      Check (LCS_Length ("AXYT", "AYZX") = 2, "LCS len AXYT/AYZX=2");
   end;

   ---------------------------------------------------------------------
   Section ("6. Edit distance (Levenshtein)");
   ---------------------------------------------------------------------
   begin
      Check (Edit_Distance ("kitten", "sitting") = 3,
             "edit kitten→sitting = 3");
      Check (Edit_Distance ("saturday", "sunday") = 3,
             "edit saturday→sunday = 3");
      Check (Edit_Distance ("", "") = 0, "edit empty empty");
      Check (Edit_Distance ("", "abc") = 3, "edit insert 3");
      Check (Edit_Distance ("abc", "") = 3, "edit delete 3");
      Check (Edit_Distance ("abc", "abc") = 0, "edit identical");
      Check (Edit_Distance ("abc", "def") = 3, "edit all subst");
      Check (Edit_Distance ("a", "b") = 1, "edit a→b");
      Check (Edit_Distance ("ca", "abc") = 3, "edit ca→abc");
      Check (Edit_Distance ("flaw", "lawn") = 2, "edit flaw→lawn");
      Check (Edit_Distance ("intention", "execution") = 5,
             "edit intention→execution = 5");
   end;

   ---------------------------------------------------------------------
   Section ("7. Matrix-chain order");
   ---------------------------------------------------------------------
   declare
      --  Classic CLRS: dims 30×35, 35×15, 15×5, 5×10, 10×20, 20×25
      --  → min cost 15125
      D1 : constant Dim_Array := [30, 35, 15, 5, 10, 20, 25];
      R1 : Matrix_Chain_Result;
      --  Two matrices 10×20 and 20×30 → cost 6000
      D2 : constant Dim_Array := [10, 20, 30];
      --  Three: 10×20, 20×30, 30×40 — costs: (AB)C=10*20*30+10*30*40=18000
      --  A(BC)=20*30*40+10*20*40=32000 → min 18000
      D3 : constant Dim_Array := [10, 20, 30, 40];
      R3 : Matrix_Chain_Result;
      D4 : constant Dim_Array := [5, 5];  -- single matrix
   begin
      Check (Matrix_Chain_Cost (D1) = 15_125, "MC classic 15125");
      R1 := Matrix_Chain_Order (D1);
      Check (R1.Success, "MC classic success");
      Check (R1.Min_Cost = 15_125, "MC order cost");
      Check (R1.N = 6, "MC N=6 matrices");
      Check (R1.Split (1, 6) = 3, "MC split(1,6)=3 (CLRS)");

      Check (Matrix_Chain_Cost (D2) = 6_000, "MC two mats 6000");
      Check (Matrix_Chain_Cost (D3) = 18_000, "MC three 18000");
      R3 := Matrix_Chain_Order (D3);
      Check (R3.Split (1, 3) = 2, "MC three split at 2");
      Check (Matrix_Chain_Cost (D4) = 0, "MC single = 0");

      --  40×20, 20×30, 30×10, 10×30 → classic alternate 26000
      Check (Matrix_Chain_Cost ([40, 20, 30, 10, 30]) = 26_000,
             "MC 40-20-30-10-30 → 26000");
   end;

   ---------------------------------------------------------------------
   Section ("8. Unique grid paths");
   ---------------------------------------------------------------------
   begin
      Check (Unique_Paths (1, 1) = 1, "paths 1×1");
      Check (Unique_Paths (1, 5) = 1, "paths 1×5");
      Check (Unique_Paths (5, 1) = 1, "paths 5×1");
      Check (Unique_Paths (2, 2) = 2, "paths 2×2");
      Check (Unique_Paths (3, 2) = 3, "paths 3×2");
      Check (Unique_Paths (2, 3) = 3, "paths 2×3");
      Check (Unique_Paths (3, 3) = 6, "paths 3×3");
      Check (Unique_Paths (3, 7) = 28, "paths 3×7");
      Check (Unique_Paths (7, 3) = 28, "paths 7×3");
      --  C(m+n-2, m-1): 4×4 → C(6,3)=20
      Check (Unique_Paths (4, 4) = 20, "paths 4×4");
      Check (Unique_Paths (5, 5) = 70, "paths 5×5");
   end;

   ---------------------------------------------------------------------
   Section ("9. Rod cutting");
   ---------------------------------------------------------------------
   declare
      --  CLRS prices for lengths 1..10
      P : constant Price_Array :=
        [1, 5, 8, 9, 10, 17, 17, 20, 24, 30];
   begin
      Check (Rod_Cutting (P, 0) = 0, "rod L=0");
      Check (Rod_Cutting (P, 1) = 1, "rod L=1 → 1");
      Check (Rod_Cutting (P, 2) = 5, "rod L=2 → 5");
      Check (Rod_Cutting (P, 3) = 8, "rod L=3 → 8");
      Check (Rod_Cutting (P, 4) = 10, "rod L=4 → 10 (2+2)");
      Check (Rod_Cutting (P, 5) = 13, "rod L=5 → 13");
      Check (Rod_Cutting (P, 6) = 17, "rod L=6 → 17");
      Check (Rod_Cutting (P, 7) = 18, "rod L=7 → 18");
      Check (Rod_Cutting (P, 8) = 22, "rod L=8 → 22");
      Check (Rod_Cutting (P, 9) = 25, "rod L=9 → 25");
      Check (Rod_Cutting (P, 10) = 30, "rod L=10 → 30");
   end;

   ---------------------------------------------------------------------
   Section ("10. Cross-checks / edge consistency");
   ---------------------------------------------------------------------
   begin
      Check (LCS_Length ("kitten", "sitting") <=
               Natural'Max (6, 7), "LCS ≤ max len");
      Check (Edit_Distance ("ABCBDAB", "BDCABA") >= 0, "edit ≥ 0");
      --  Fib recurrence spot-check
      Check (Fibonacci (25) = Fibonacci (24) + Fibonacci (23),
             "Fib recurrence 25");
      Check (Fibonacci_Memo (28) = Fibonacci (27) + Fibonacci (26),
             "Fib memo recurrence 28");
      --  Paths recurrence
      Check (Unique_Paths (4, 5) =
               Unique_Paths (3, 5) + Unique_Paths (4, 4),
             "paths recurrence 4×5");
      --  Knapsack empty-ish capacity
      Check (Knapsack_01 ([1, 2, 3], [1, 2, 3], 0) = 0, "KS zero cap");
      Check (Min_Coins ([1], 100) = 100, "Min_Coins all ones");
      Check (Coin_Combinations ([1], 10) = 1, "Ways only ones");
      Check (Edit_Distance ("a", "a") = 0, "edit same char");
      Check (LCS_Length ("a", "a") = 1, "LCS same char");
   end;

   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Pass_Count =" & Pass_Count'Image
      & "  Fail_Count =" & Fail_Count'Image);
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
   else
      Ada.Text_IO.Put_Line ("SOME FAILED");
   end if;

   if Fail_Count /= 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
