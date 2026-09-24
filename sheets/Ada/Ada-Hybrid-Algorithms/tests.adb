--  Standalone test suite for Hybrid_Algorithms (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Hybrid_Algorithms; use Hybrid_Algorithms;

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

   function Same_Multiset (A, B : Int_Array) return Boolean is
      --  Educational: copy + sort both via Hybrid_Sort and compare
      X : Int_Array := A;
      Y : Int_Array := B;
      SX, SY : Sort_Stats;
   begin
      if A'Length /= B'Length then
         return False;
      end if;
      Hybrid_Sort (X, SX, 8);
      Hybrid_Sort (Y, SY, 8);
      for I in X'Range loop
         if X (I) /= Y (I) then
            return False;
         end if;
      end loop;
      return True;
   end Same_Multiset;

begin
   Put_Line ("Hybrid_Algorithms test suite");
   Put_Line ("============================");

   ---------------------------------------------------------------------
   Section ("1. Near / Default_Config / RNG");
   ---------------------------------------------------------------------
   declare
      C : Config;
      S : RNG_State;
      U1, U2 : Unit_Interval;
      N1 : Natural;
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Near (0.0, 1.0E-12, 1.0E-9), "Near custom Tol");
      Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom Tol reject");
      Check (Near (-5.0, -5.0), "Near negatives");
      Check (Near (0.0, 0.0), "Near zeros");
      C := Default_Config;
      Check (C.Insertion_Threshold = Default_Insertion_Threshold,
             "Default Insertion_Threshold");
      Check (C.Exact_Threshold = Default_Exact_Threshold,
             "Default Exact_Threshold");
      Check (C.Alpha = 0.3, "Default Alpha");
      Check (C.Max_Iterations = 20, "Default Max_Iterations");
      Check (C.Local_Search_Steps = 50, "Default Local_Search_Steps");
      Check (C.Seed = 1, "Default Seed");
      C := Default_Config
        (Insertion_Threshold => 8, Exact_Threshold => 6,
         Alpha => 0.5, Max_Iterations => 3,
         Local_Search_Steps => 10, Seed => 42);
      Check (C.Insertion_Threshold = 8, "Custom Insertion_Threshold");
      Check (C.Exact_Threshold = 6, "Custom Exact_Threshold");
      Check (C.Alpha = 0.5, "Custom Alpha");
      Check (C.Seed = 42, "Custom Seed");
      Seed_RNG (S, 1);
      U1 := Next_Unit (S);
      Seed_RNG (S, 1);
      U2 := Next_Unit (S);
      Check (Near (U1, U2), "RNG reproducible Next_Unit");
      Seed_RNG (S, 7);
      N1 := Next_Natural (S, 1, 1);
      Check (N1 = 1, "Next_Natural Lo=Hi");
      Seed_RNG (S, 99);
      N1 := Next_Natural (S, 0, 10);
      Check (N1 <= 10, "Next_Natural in range upper");
      Seed_RNG (S, 99);
      declare
         N2 : constant Natural := Next_Natural (S, 3, 7);
      begin
         Check (N2 >= 3 and then N2 <= 7, "Next_Natural mid-range");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("2. Taxonomy Hybrid_Kind");
   ---------------------------------------------------------------------
   declare
      Info : Hybrid_Info;
      Impl_Count : Natural := 0;
      Forth_Count : Natural := 0;
   begin
      for K in Hybrid_Kind loop
         Info := Classify (K);
         Check (Info.Kind = K, "Classify Kind matches " & Hybrid_Name (K));
         Check (Info.Implemented = Implemented (K),
                "Implemented accessor " & Hybrid_Name (K));
         Check (Info.Forthcoming = Forthcoming (K),
                "Forthcoming accessor " & Hybrid_Name (K));
         Check (Info.Implemented /= Info.Forthcoming
                or else (not Info.Implemented and not Info.Forthcoming),
                "Impl/Forth consistent " & Hybrid_Name (K));
         --  Educational survey: each kind is either Implemented or Forthcoming
         Check (Info.Implemented or else Info.Forthcoming,
                "Tagged " & Hybrid_Name (K));
         if Info.Implemented then
            Impl_Count := Impl_Count + 1;
         end if;
         if Info.Forthcoming then
            Forth_Count := Forth_Count + 1;
         end if;
      end loop;
      Check (Hybrid_Name (Switch_By_Size) = "Switch_By_Size",
             "Name Switch_By_Size");
      Check (Hybrid_Name (Portfolio_Select) = "Portfolio_Select",
             "Name Portfolio_Select");
      Check (Hybrid_Name (Memetic_GA_Local) = "Memetic_GA_Local",
             "Name Memetic_GA_Local");
      Check (Hybrid_Name (Grasp_Construct_LS) = "Grasp_Construct_LS",
             "Name Grasp_Construct_LS");
      Check (Hybrid_Name (Exact_Then_Heuristic) = "Exact_Then_Heuristic",
             "Name Exact_Then_Heuristic");
      Check (Implemented (Switch_By_Size), "Switch_By_Size implemented");
      Check (Implemented (Exact_Then_Heuristic),
             "Exact_Then_Heuristic implemented");
      Check (Implemented (Memetic_GA_Local), "Memetic_GA_Local implemented");
      Check (Implemented (Grasp_Construct_LS),
             "Grasp_Construct_LS implemented");
      Check (Implemented (Portfolio_Select), "Portfolio_Select implemented");
      Check (not Forthcoming (Switch_By_Size),
             "Switch_By_Size not forthcoming");
      Check (Classify (Portfolio_Select).Stochastic,
             "Portfolio stochastic");
      Check (Classify (Memetic_GA_Local).Stochastic,
             "Memetic stochastic");
      Check (Classify (Grasp_Construct_LS).Stochastic,
             "Grasp_Construct_LS stochastic");
      Check (not Classify (Switch_By_Size).Stochastic,
             "Switch_By_Size deterministic");
      Check (not Classify (Exact_Then_Heuristic).Stochastic,
             "Exact_Then_Heuristic deterministic");
      Check (Impl_Count = 5, "All five kinds implemented in this survey");
      Check (Forth_Count = 0, "No forthcoming placeholders in this build");
   end;

   ---------------------------------------------------------------------
   Section ("3. Bit helpers / OneMax");
   ---------------------------------------------------------------------
   declare
      Z : constant Bit_String := All_Zeros (8);
      O : constant Bit_String := All_Ones (8);
      R : Bit_String (1 .. 5);
      S : RNG_State;
   begin
      Check (Zero_Count (Z) = 8, "All_Zeros zero count");
      Check (Ones_Count (Z) = 0, "All_Zeros ones count");
      Check (Zero_Count (O) = 0, "All_Ones zero count");
      Check (Ones_Count (O) = 8, "All_Ones ones count");
      Check (Ones_Count (Flip_Bit (Z, 3)) = 1, "Flip_Bit creates one");
      Check (Zero_Count (Flip_Bit (O, 1)) = 1, "Flip_Bit clears one");
      Seed_RNG (S, 3);
      R := Random_Bit_String (S, 5);
      Check (R'Length = 5, "Random_Bit_String length");
      Check (Copy_Bits (O, 4) = All_Ones (4), "Copy_Bits ones");
   end;

   ---------------------------------------------------------------------
   Section ("4. Hybrid_Sort correctness + insertion threshold");
   ---------------------------------------------------------------------
   declare
      Empty : Int_Array (1 .. 0);
      One   : Int_Array := [42];
      Two   : Int_Array := [2, 1];
      Small : Int_Array := [5, 1, 4, 2, 3];
      Dup   : Int_Array := [3, 1, 3, 2, 1, 2];
      Rev   : Int_Array (1 .. 20);
      Big   : Int_Array (1 .. 64);
      Stats : Sort_Stats;
      Sorted_Copy : Int_Array (1 .. 5);
   begin
      Hybrid_Sort (Empty, Stats, 16);
      Check (Stats.Elements = 0, "Empty sort elements");
      Check (Is_Sorted (Empty), "Empty is sorted");

      Hybrid_Sort (One, Stats, 16);
      Check (One (1) = 42 and then Is_Sorted (One), "Singleton sort");

      Hybrid_Sort (Two, Stats, 16);
      Check (Two (1) = 1 and then Two (2) = 2, "Two-element sort");
      Check (Stats.Insertion_Segments >= 1,
             "Tiny array uses insertion");

      Hybrid_Sort (Small, Stats, 16);
      Check (Is_Sorted (Small), "Small array sorted");
      Check (Small (1) = 1 and then Small (5) = 5, "Small endpoints");
      Check (Stats.Insertion_Segments >= 1,
             "n<=threshold uses insertion exclusively");
      Check (Stats.Quick_Partitions = 0,
             "n<=threshold skips quicksort");

      Hybrid_Sort (Dup, Stats, 8);
      Check (Is_Sorted (Dup), "Duplicates sorted");
      Check (Dup (1) = 1 and then Dup (6) = 3, "Dup endpoints");

      for I in Rev'Range loop
         Rev (I) := Integer (Rev'Last - I + 1);
      end loop;
      Hybrid_Sort (Rev, Stats, 4);
      Check (Is_Sorted (Rev), "Reversed 20 sorted");
      Check (Stats.Insertion_Segments >= 1,
             "Hybrid uses insertion on small slices");
      Check (Stats.Quick_Partitions >= 1,
             "Hybrid uses quick partitions for n>thr");

      for I in Big'Range loop
         Big (I) := Integer ((I * 17) rem 97);
      end loop;
      declare
         Before : constant Int_Array := Big;
      begin
         Hybrid_Sort (Big, Stats, 8);
         Check (Is_Sorted (Big), "Big 64 sorted");
         Check (Same_Multiset (Before, Big), "Big preserves multiset");
         Check (Stats.Insertion_Segments >= 1,
                "Big sort invoked insertion below threshold");
      end;

      Sorted_Copy := Hybrid_Sort_Copy ([9, 7, 5, 3, 1], 16);
      Check (Is_Sorted (Sorted_Copy), "Hybrid_Sort_Copy sorted");
      Check (Sorted_Copy (1) = 1 and then Sorted_Copy (5) = 9,
             "Hybrid_Sort_Copy values");

      --  Pure insertion on a range
      declare
         A : Int_Array := [4, 3, 2, 1, 0];
      begin
         Insertion_Sort_Range (A, 1, 5);
         Check (Is_Sorted (A), "Insertion_Sort_Range full");
      end;

      declare
         A : Int_Array := [10, 9, 8, 7, 6, 5];
      begin
         Heap_Sort_Range (A, 1, 6);
         Check (Is_Sorted (A), "Heap_Sort_Range full");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("5. Introsort heap fallback (deep / adversarial)");
   ---------------------------------------------------------------------
   declare
      --  Many equal elements + tiny threshold still sorts; force depth by
      --  using threshold 2 on a larger reverse-sorted array.
      A : Int_Array (1 .. 48);
      Stats : Sort_Stats;
   begin
      for I in A'Range loop
         A (I) := Integer (A'Last - I + 1);
      end loop;
      Hybrid_Sort (A, Stats, 2);
      Check (Is_Sorted (A), "Adversarial reverse sorted with thr=2");
      Check (Stats.Quick_Partitions >= 1, "Adversarial used quick");
      Check (Stats.Insertion_Segments >= 1, "Adversarial used insertion");
      --  Heap fallback may or may not trigger depending on pivots; accept
      --  either path as long as sorted.
      Check (Stats.Elements = 48, "Adversarial element count");
   end;

   ---------------------------------------------------------------------
   Section ("6. Knapsack exhaustive / greedy / size-switch");
   ---------------------------------------------------------------------
   declare
      W : constant Weight_Array := [2, 3, 4, 5];
      V : constant Value_Array  := [3, 4, 5, 6];
      Cap : constant Natural := 5;
      Ex : Knapsack_Result;
      Gr : Knapsack_Result;
      Sw : Knapsack_Result;
      W_Big : Weight_Array (1 .. 14);
      V_Big : Value_Array (1 .. 14);
   begin
      Ex := Knapsack_Exhaustive (W, V, Cap);
      Check (Ex.Exact, "Exhaustive marks Exact");
      Check (not Ex.Used_Greedy, "Exhaustive not greedy");
      Check (Ex.Best_Value = 7, "Exhaustive opt value (2+3 -> 3+4)");
      Check (Ex.Best_Weight = 5, "Exhaustive opt weight");
      Check (Is_Feasible (W, Ex.Selected (1 .. 4), Cap),
             "Exhaustive feasible");

      Gr := Knapsack_Greedy_Density (W, V, Cap);
      Check (Gr.Used_Greedy, "Greedy marks Used_Greedy");
      Check (not Gr.Exact, "Greedy not Exact");
      Check (Is_Feasible (W, Gr.Selected (1 .. 4), Cap), "Greedy feasible");
      Check (Gr.Best_Value <= Ex.Best_Value,
             "Greedy value <= exhaustive (quality tradeoff)");
      Check (Density (6, 5) > 1.0, "Density 6/5 > 1");
      Check (Density (3, 2) > Density (6, 5), "Density 3/2 > 6/5");
      Check (Density (1, 0) > 1.0E8, "Density zero weight large");

      Sw := Size_Switch_Knapsack (W, V, Cap, Exact_Threshold => 12);
      Check (Sw.Exact, "Size-switch exact path for n=4");
      Check (Sw.Best_Value = Ex.Best_Value, "Size-switch matches exhaustive");

      Sw := Size_Switch_Knapsack (W, V, Cap, Exact_Threshold => 2);
      Check (not Sw.Exact, "Size-switch greedy path when n>threshold");
      Check (Sw.Used_Greedy, "Size-switch used greedy");
      Check (Is_Feasible (W, Sw.Selected (1 .. 4), Cap),
             "Size-switch greedy feasible");

      for I in W_Big'Range loop
         W_Big (I) := 1 + (I rem 5);
         V_Big (I) := 2 + (I rem 7);
      end loop;
      Sw := Size_Switch_Knapsack
        (W_Big, V_Big, 20, Exact_Threshold => 8);
      Check (not Sw.Exact, "Large n uses heuristic branch");
      Check (Sw.Used_Greedy, "Large n greedy flag");
      Check (Is_Feasible (W_Big, Sw.Selected (1 .. 14), 20),
             "Large n feasible");
      Check (Total_Value (V_Big, Sw.Selected (1 .. 14)) = Sw.Best_Value,
             "Total_Value matches Best_Value");
      Check (Total_Weight (W_Big, Sw.Selected (1 .. 14)) = Sw.Best_Weight,
             "Total_Weight matches Best_Weight");

      --  Classic greedy-suboptimal instance: capacity 10;
      --  items (w,v)=(7,9),(5,5),(5,5). Density 9/7 > 1 picks first → value
      --  9; optimal is 5+5 → value 10.
      declare
         W2 : constant Weight_Array := [7, 5, 5];
         V2 : constant Value_Array  := [9, 5, 5];
         E2 : constant Knapsack_Result :=
           Knapsack_Exhaustive (W2, V2, 10);
         G2 : constant Knapsack_Result :=
           Knapsack_Greedy_Density (W2, V2, 10);
      begin
         Check (E2.Best_Value = 10, "Tradeoff exhaustive optimum 10");
         Check (G2.Best_Value = 9, "Tradeoff greedy suboptimal 9");
         Check (G2.Best_Value < E2.Best_Value,
                "Documents quality tradeoff greedy < exact");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("7. Memetic one-step OneMax / knapsack");
   ---------------------------------------------------------------------
   declare
      Cfg : constant Config :=
        Default_Config (Seed => 11, Local_Search_Steps => 40);
      R : Bit_Result;
      W : constant Weight_Array := [2, 2, 3, 4, 5];
      V : constant Value_Array  := [3, 4, 5, 7, 8];
      KR : Knapsack_Result;
      Start : constant Bit_String := All_Zeros (10);
      HC : Bit_Result;
   begin
      R := Memetic_One_Step_OneMax (12, Cfg);
      Check (R.N = 12, "Memetic OneMax length");
      Check (Near (R.Best_Cost, 0.0), "Memetic OneMax reaches all ones");
      Check (Ones_Count (R.Best_Bits (1 .. 12)) = 12,
             "Memetic OneMax bits all ones");
      Check (R.Local_Improves >= 1 or else Near (R.Best_Cost, 0.0),
             "Memetic improved or started lucky");

      HC := Hill_Climb_OneMax (Start, 20);
      Check (Near (HC.Best_Cost, 0.0), "Hill climb from zeros");
      Check (HC.Local_Improves = 10, "Hill climb 10 flips from zeros");

      KR := Memetic_One_Step_Knapsack (W, V, 10, Cfg);
      Check (KR.N_Items = 5, "Memetic KS n");
      Check (Is_Feasible (W, KR.Selected (1 .. 5), 10),
             "Memetic KS feasible");
      Check (KR.Best_Weight <= 10, "Memetic KS weight within capacity");
      Check (not KR.Exact, "Memetic KS not exact flag");

      --  Reproducibility
      declare
         R2 : constant Bit_Result :=
           Memetic_One_Step_OneMax (12, Cfg);
      begin
         Check (Near (R.Best_Cost, R2.Best_Cost),
                "Memetic OneMax reproducible cost");
         Check (R.Best_Bits (1 .. 12) = R2.Best_Bits (1 .. 12),
                "Memetic OneMax reproducible bits");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("8. Construct + local search / portfolio");
   ---------------------------------------------------------------------
   declare
      W : constant Weight_Array := [2, 3, 4, 5, 6, 7];
      V : constant Value_Array  := [4, 5, 6, 8, 9, 10];
      Cap : constant Natural := 15;
      Cfg : constant Config := Default_Config
        (Alpha => 0.4, Max_Iterations => 15,
         Local_Search_Steps => 30, Seed => 5);
      CL : Knapsack_Result;
      PF : Knapsack_Result;
      Ex : Knapsack_Result;
      Gr : Knapsack_Result;
   begin
      CL := Construct_Local_Search_Knapsack (W, V, Cap, Cfg);
      Check (CL.N_Items = 6, "Construct+LS n");
      Check (Is_Feasible (W, CL.Selected (1 .. 6), Cap),
             "Construct+LS feasible");
      Check (CL.Best_Value >= 1, "Construct+LS positive value");
      Check (not CL.Exact, "Construct+LS not Exact");

      Ex := Knapsack_Exhaustive (W, V, Cap);
      Check (CL.Best_Value <= Ex.Best_Value,
             "Construct+LS <= exhaustive");

      Gr := Knapsack_Greedy_Density (W, V, Cap);
      PF := Portfolio_Knapsack (W, V, Cap, Cfg);
      Check (Is_Feasible (W, PF.Selected (1 .. 6), Cap),
             "Portfolio feasible");
      Check (PF.Best_Value >= Gr.Best_Value,
             "Portfolio >= greedy alone");
      Check (PF.Best_Value <= Ex.Best_Value,
             "Portfolio <= exhaustive");

      --  Alpha extremes: 0 ~ pure greedy construct; 1 ~ random among feas.
      declare
         C0 : Config := Cfg;
         C1 : Config := Cfg;
         R0, R1 : Knapsack_Result;
      begin
         C0.Alpha := 0.0;
         C1.Alpha := 1.0;
         C0.Max_Iterations := 5;
         C1.Max_Iterations := 5;
         R0 := Construct_Local_Search_Knapsack (W, V, Cap, C0);
         R1 := Construct_Local_Search_Knapsack (W, V, Cap, C1);
         Check (Is_Feasible (W, R0.Selected (1 .. 6), Cap),
                "Alpha=0 feasible");
         Check (Is_Feasible (W, R1.Selected (1 .. 6), Cap),
                "Alpha=1 feasible");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("9. Hill_Climb_Knapsack improves empty / greedy start");
   ---------------------------------------------------------------------
   declare
      W : constant Weight_Array := [1, 1, 1, 1];
      V : constant Value_Array  := [5, 4, 3, 2];
      Empty : constant Selection := [False, False, False, False];
      R : Knapsack_Result;
   begin
      R := Hill_Climb_Knapsack (W, V, 2, Empty, 20);
      Check (R.Best_Value = 9, "HC from empty takes two best (5+4)");
      Check (R.Best_Weight = 2, "HC weight uses capacity");
      Check (R.Local_Improves >= 2, "HC made adds");
   end;

   ---------------------------------------------------------------------
   Section ("10. Is_Sorted / edge arrays");
   ---------------------------------------------------------------------
   declare
      A : constant Int_Array := [1, 2, 2, 3];
      B : constant Int_Array := [1, 3, 2];
      C : constant Int_Array := [7];
   begin
      Check (Is_Sorted (A), "Is_Sorted nondecreasing");
      Check (not Is_Sorted (B), "Is_Sorted rejects out-of-order");
      Check (Is_Sorted (C), "Is_Sorted singleton");
      Check (Is_Sorted (Int_Array'(1 .. 0 => 0)), "Is_Sorted empty");
   end;

   New_Line;
   Put_Line ("============================");
   Put_Line ("Pass_Count =" & Pass_Count'Image);
   Put_Line ("Fail_Count =" & Fail_Count'Image);
   if Fail_Count = 0 and then Pass_Count >= 80 then
      Put_Line ("ALL PASSED");
   elsif Fail_Count = 0 then
      Put_Line ("OK but Pass_Count < 80");
   else
      Put_Line ("FAILED");
   end if;
end Tests;
