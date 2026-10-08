--  Standalone test suite for Chain_Matrix_Multiplication (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Chain_Matrix_Multiplication; use Chain_Matrix_Multiplication;

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
   Ada.Text_IO.Put_Line ("Chain_Matrix_Multiplication test suite");
   Ada.Text_IO.Put_Line ("======================================");

   ---------------------------------------------------------------------
   Section ("1. Single matrix (n=1) → cost 0");
   ---------------------------------------------------------------------
   declare
      D  : constant Dimensions := [5, 5];
      R  : DP_Result;
      R2 : DP_Result;
   begin
      Check (Matrix_Count_Of (D) = 1, "n=1 Matrix_Count_Of");
      Check (Optimal_Cost (D) = 0, "n=1 Optimal_Cost = 0");
      R := Optimal_Order (D);
      Check (R.Success, "n=1 Success");
      Check (R.N = 1, "n=1 N");
      Check (R.Min_Cost = 0, "n=1 Min_Cost");
      Check (R.Cost (1, 1) = 0, "n=1 Cost(1,1)=0");
      Check (Format_Order (R) = "A1", "n=1 Format_Order = A1");
      R2 := Compute_DP (D);
      Check (R2.Min_Cost = R.Min_Cost, "n=1 Compute_DP = Optimal_Order");
      Check (Left_Associative_Cost (D) = 0, "n=1 left assoc 0");
      Check (Right_Associative_Cost (D) = 0, "n=1 right assoc 0");
   end;

   ---------------------------------------------------------------------
   Section ("2. Two matrices — unique order");
   ---------------------------------------------------------------------
   declare
      D : constant Dimensions := [10, 20, 30];
      R : DP_Result;
   begin
      Check (Matrix_Count_Of (D) = 2, "n=2 count");
      Check (Optimal_Cost (D) = 6_000, "n=2 cost 10*20*30=6000");
      R := Optimal_Order (D);
      Check (R.Success, "n=2 success");
      Check (R.N = 2, "n=2 N");
      Check (R.Split (1, 2) = 1, "n=2 split=1");
      Check (Format_Order (R) = "(A1*A2)", "n=2 format (A1*A2)");
      Check (Cost_Of_Split (D, R.Split) = 6_000, "n=2 Cost_Of_Split");
      Check (Left_Associative_Cost (D) = 6_000, "n=2 left=6000");
      Check (Right_Associative_Cost (D) = 6_000, "n=2 right=6000");
      Check (Left_Associative_Cost (D) = Optimal_Cost (D),
             "n=2 left = optimal");
   end;

   ---------------------------------------------------------------------
   Section ("3. Wikipedia A,B,C — associativity matters");
   ---------------------------------------------------------------------
   declare
      --  A 10×30, B 30×5, C 5×60
      D : constant Dimensions := [10, 30, 5, 60];
      R : DP_Result;
      Left_C  : Natural;
      Right_C : Natural;
      Opt_C   : Natural;
   begin
      Left_C  := Left_Associative_Cost (D);   -- (AB)C = 4500
      Right_C := Right_Associative_Cost (D);  -- A(BC) = 27000
      Opt_C   := Optimal_Cost (D);
      Check (Left_C = 4_500, "wiki (AB)C = 4500");
      Check (Right_C = 27_000, "wiki A(BC) = 27000");
      Check (Opt_C = 4_500, "wiki optimal = 4500");
      Check (Left_C < Right_C, "wiki left << right");
      Check (Opt_C = Left_C, "wiki opt picks left assoc");
      R := Optimal_Order (D);
      Check (R.N = 3, "wiki N=3");
      Check (R.Split (1, 3) = 2, "wiki split(1,3)=2 → (AB)C");
      Check (Format_Order (R) = "((A1*A2)*A3)", "wiki format ((A1*A2)*A3)");
      Check (Cost_Of_Split (D, R.Split) = Opt_C, "wiki Cost_Of_Split=opt");
      Check (Cost_Of_Split (D, R.Split, 1, 2) = 10 * 30 * 5,
             "wiki Cost_Of_Split(1,2)=1500");
      Check (R.Cost (1, 2) = 1_500, "wiki Cost(1,2)=1500");
      Check (R.Cost (2, 3) = 30 * 5 * 60, "wiki Cost(2,3)=9000");
      Check (R.Cost (1, 3) = 4_500, "wiki Cost(1,3)=4500");
   end;

   ---------------------------------------------------------------------
   Section ("4. CLRS classic six matrices → 15125");
   ---------------------------------------------------------------------
   declare
      --  30×35, 35×15, 15×5, 5×10, 10×20, 20×25
      D : constant Dimensions := [30, 35, 15, 5, 10, 20, 25];
      R : DP_Result;
      C : DP_Result;
   begin
      Check (Matrix_Count_Of (D) = 6, "CLRS n=6");
      Check (Optimal_Cost (D) = 15_125, "CLRS Optimal_Cost=15125");
      R := Optimal_Order (D);
      Check (R.Success, "CLRS success");
      Check (R.Min_Cost = 15_125, "CLRS Min_Cost");
      Check (R.N = 6, "CLRS N");
      Check (R.Split (1, 6) = 3, "CLRS split(1,6)=3");
      Check (Cost_Of_Split (D, R.Split) = 15_125, "CLRS Cost_Of_Split");
      Check (Cost_Of_Split (D, R.Split, 1, 6) = 15_125,
             "CLRS Cost_Of_Split(1,6)");
      C := Compute_DP (D);
      Check (C.Min_Cost = R.Min_Cost, "CLRS Compute_DP cost");
      Check (C.Split (1, 6) = R.Split (1, 6), "CLRS Compute_DP split");
      Check (C.Cost (1, 6) = R.Cost (1, 6), "CLRS Compute_DP Cost table");
      --  Optimal beats naive associativity
      Check (Left_Associative_Cost (D) >= Optimal_Cost (D),
             "CLRS left >= opt");
      Check (Right_Associative_Cost (D) >= Optimal_Cost (D),
             "CLRS right >= opt");
      Check (Format_Order (R)'Length > 0, "CLRS Format_Order nonempty");
      Check (Format_Order (R) (Format_Order (R)'First) = '(',
             "CLRS Format_Order starts with '('");
   end;

   ---------------------------------------------------------------------
   Section ("5. Three matrices — left vs right costs");
   ---------------------------------------------------------------------
   declare
      D : constant Dimensions := [10, 20, 30, 40];
      R : DP_Result;
      --  (AB)C = 10*20*30 + 10*30*40 = 6000+12000 = 18000
      --  A(BC) = 20*30*40 + 10*20*40 = 24000+8000 = 32000
   begin
      Check (Optimal_Cost (D) = 18_000, "three opt=18000");
      Check (Left_Associative_Cost (D) = 18_000, "three left=18000");
      Check (Right_Associative_Cost (D) = 32_000, "three right=32000");
      R := Optimal_Order (D);
      Check (R.Split (1, 3) = 2, "three split at 2");
      Check (Format_Order (R) = "((A1*A2)*A3)", "three format left");
      Check (Cost_Of_Split (D, R.Split) = 18_000, "three verify split");
   end;

   ---------------------------------------------------------------------
   Section ("6. Alternate classic 40-20-30-10-30 → 26000");
   ---------------------------------------------------------------------
   declare
      D : constant Dimensions := [40, 20, 30, 10, 30];
      R : DP_Result;
   begin
      Check (Optimal_Cost (D) = 26_000, "alt opt=26000");
      R := Optimal_Order (D);
      Check (R.N = 4, "alt N=4");
      Check (R.Min_Cost = 26_000, "alt Min_Cost");
      Check (Cost_Of_Split (D, R.Split) = R.Min_Cost, "alt Cost_Of_Split");
      Check (Left_Associative_Cost (D) >= R.Min_Cost, "alt left>=opt");
      Check (Right_Associative_Cost (D) >= R.Min_Cost, "alt right>=opt");
   end;

   ---------------------------------------------------------------------
   Section ("7. Parenthesize substrings / partial splits");
   ---------------------------------------------------------------------
   declare
      D : constant Dimensions := [30, 35, 15, 5, 10, 20, 25];
      R : DP_Result;
   begin
      R := Optimal_Order (D);
      Check (Parenthesize (R.Split, R.N, 1, 1) = "A1", "paren A1");
      Check (Parenthesize (R.Split, R.N, 6, 6) = "A6", "paren A6");
      Check (Parenthesize (R.Split, R.N, 1, 2)'Length >= 5, "paren 1..2 len");
      Check (Parenthesize (R.Split, R.N, 4, 6)'Length >= 5, "paren 4..6 len");
      Check (Format_Order (R) =
               Parenthesize (R.Split, R.N, 1, 6), "Format = Parenthesize full");
   end;

   ---------------------------------------------------------------------
   Section ("8. Cost tables monotonic / subchain consistency");
   ---------------------------------------------------------------------
   declare
      D : constant Dimensions := [5, 10, 3, 12, 5, 50, 6];
      R : DP_Result;
   begin
      R := Optimal_Order (D);
      Check (R.Success, "mono success");
      Check (R.N = 6, "mono N=6");
      for I in 1 .. R.N loop
         Check (R.Cost (I, I) = 0, "diag Cost=0 @" & I'Image);
      end loop;
      Check (R.Cost (1, R.N) = R.Min_Cost, "Cost(1,n)=Min_Cost");
      Check (Cost_Of_Split (D, R.Split, 2, 4) = R.Cost (2, 4),
             "subchain Cost_Of_Split matches table");
      Check (Cost_Of_Split (D, R.Split, 1, 3) = R.Cost (1, 3),
             "subchain 1..3 matches");
      Check (Optimal_Cost (D) = R.Min_Cost, "Optimal_Cost = result");
   end;

   ---------------------------------------------------------------------
   Section ("9. Identity / square-ish chains");
   ---------------------------------------------------------------------
   declare
      Sq : constant Dimensions := [10, 10, 10, 10, 10];
      R  : DP_Result;
      --  Four 10×10: every parenthesization costs 3 * (10^3) = 3000
   begin
      Check (Optimal_Cost (Sq) = 3_000, "squares opt=3000");
      Check (Left_Associative_Cost (Sq) = 3_000, "squares left=3000");
      Check (Right_Associative_Cost (Sq) = 3_000, "squares right=3000");
      R := Optimal_Order (Sq);
      Check (Cost_Of_Split (Sq, R.Split) = 3_000, "squares verify");
      Check (R.N = 4, "squares N=4");
   end;

   ---------------------------------------------------------------------
   Section ("10. Growing chain / opt never worse than assoc");
   ---------------------------------------------------------------------
   declare
      D2 : constant Dimensions := [2, 3, 4];
      D3 : constant Dimensions := [2, 3, 4, 5];
      D4 : constant Dimensions := [2, 3, 4, 5, 6];
      D5 : constant Dimensions := [2, 3, 4, 5, 6, 7];
   begin
      Check (Optimal_Cost (D2) = 2 * 3 * 4, "grow n=2");
      Check (Optimal_Cost (D3) <= Left_Associative_Cost (D3),
             "grow n=3 opt<=left");
      Check (Optimal_Cost (D3) <= Right_Associative_Cost (D3),
             "grow n=3 opt<=right");
      Check (Optimal_Cost (D4) <= Left_Associative_Cost (D4),
             "grow n=4 opt<=left");
      Check (Optimal_Cost (D4) <= Right_Associative_Cost (D4),
             "grow n=4 opt<=right");
      Check (Optimal_Cost (D5) <= Left_Associative_Cost (D5),
             "grow n=5 opt<=left");
      Check (Optimal_Cost (D5) <= Right_Associative_Cost (D5),
             "grow n=5 opt<=right");
      Check (Optimal_Cost (D5) = Cost_Of_Split
                (D5, Optimal_Order (D5).Split),
             "grow n=5 Cost_Of_Split roundtrip");
   end;

   ---------------------------------------------------------------------
   Section ("11. Skewed dimensions favor specific splits");
   ---------------------------------------------------------------------
   declare
      --  Tiny middle dimension: prefer cutting through the tiny dim.
      D : constant Dimensions := [100, 1, 100, 1, 100];
      R : DP_Result;
   begin
      R := Optimal_Order (D);
      Check (R.Success, "skew success");
      Check (R.Min_Cost = Optimal_Cost (D), "skew cost consistency");
      Check (Cost_Of_Split (D, R.Split) = R.Min_Cost, "skew verify");
      Check (R.Min_Cost < Left_Associative_Cost (D)
             or else R.Min_Cost = Left_Associative_Cost (D),
             "skew opt <= left");
      Check (R.Min_Cost <= Right_Associative_Cost (D), "skew opt<=right");
      Check (Format_Order (R)'Length >= 9, "skew format length");
   end;

   ---------------------------------------------------------------------
   Section ("12. Compute_DP alias / API smoke");
   ---------------------------------------------------------------------
   declare
      D : constant Dimensions := [7, 11, 13, 17];
      A : DP_Result;
      B : DP_Result;
   begin
      A := Optimal_Order (D);
      B := Compute_DP (D);
      Check (A.Success and B.Success, "API both success");
      Check (A.N = B.N, "API N equal");
      Check (A.Min_Cost = B.Min_Cost, "API Min_Cost equal");
      Check (A.Split (1, 3) = B.Split (1, 3), "API Split equal");
      Check (A.Cost (1, 2) = B.Cost (1, 2), "API Cost(1,2)");
      Check (A.Cost (2, 3) = B.Cost (2, 3), "API Cost(2,3)");
      Check (A.Cost (1, 3) = B.Cost (1, 3), "API Cost(1,3)");
      Check (Optimal_Cost (D) = A.Min_Cost, "API Optimal_Cost");
      Check (Matrix_Count_Of (D) = 3, "API Matrix_Count_Of");
   end;

   ---------------------------------------------------------------------
   Section ("13. Longer educational chain (n=8)");
   ---------------------------------------------------------------------
   declare
      D : constant Dimensions :=
        [5, 10, 3, 12, 5, 50, 6, 8, 15];
      R : DP_Result;
   begin
      R := Optimal_Order (D);
      Check (R.N = 8, "long N=8");
      Check (R.Success, "long success");
      Check (R.Min_Cost = Cost_Of_Split (D, R.Split), "long verify");
      Check (R.Min_Cost = Optimal_Cost (D), "long Optimal_Cost");
      Check (R.Min_Cost <= Left_Associative_Cost (D), "long <=left");
      Check (R.Min_Cost <= Right_Associative_Cost (D), "long <=right");
      Check (Format_Order (R)'Length > 10, "long format");
      --  All proper subchains finite
      Check (R.Cost (1, 4) <= R.Cost (1, 8), "long subcost 1..4 <= full");
      Check (R.Cost (5, 8) <= R.Cost (1, 8), "long subcost 5..8 <= full");
   end;

   ---------------------------------------------------------------------
   Section ("14. Explicit left-assoc split verification");
   ---------------------------------------------------------------------
   declare
      D : constant Dimensions := [10, 30, 5, 60];
      --  Hand-built left-associative split: s(i,j)=j-1 for j>i
      S : Split_Table := [others => [others => 0]];
   begin
      for Len in 2 .. 3 loop
         for I in 1 .. 3 - Len + 1 loop
            declare
               J : constant Matrix_Index := I + Len - 1;
            begin
               S (I, J) := J - 1;
            end;
         end loop;
      end loop;
      Check (Cost_Of_Split (D, S) = 4_500, "hand left split = 4500");
      --  Hand-built right-associative: s(i,j)=i
      declare
         S2 : Split_Table := [others => [others => 0]];
      begin
         for Len in 2 .. 3 loop
            for I in 1 .. 3 - Len + 1 loop
               declare
                  J : constant Matrix_Index := I + Len - 1;
               begin
                  S2 (I, J) := I;
               end;
            end loop;
         end loop;
         Check (Cost_Of_Split (D, S2) = 27_000, "hand right split = 27000");
      end;
   end;

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("======================================");
   Ada.Text_IO.Put_Line
     ("Passed:" & Pass_Count'Image & "  Failed:" & Fail_Count'Image);
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Text_IO.Put_Line ("SOME FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
