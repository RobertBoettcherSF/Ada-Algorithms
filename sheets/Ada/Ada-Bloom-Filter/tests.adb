--  Standalone test suite for Bloom_Filter (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Bloom_Filter; use Bloom_Filter;

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

   function Approx (A, B : Real; Tol : Real := 1.0E-5) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   function Approx_Rel
     (A, B : Real; Tol : Real := 0.15) return Boolean
   is
      Den : Real;
   begin
      Den := abs (B);
      if Den < 1.0E-12 then
         return abs (A) <= Tol;
      end if;
      return abs (A - B) / Den <= Tol;
   end Approx_Rel;

begin
   Put_Line ("Bloom_Filter test suite");
   Put_Line ("=======================");

   ---------------------------------------------------------------------
   Section ("1. Create / Size / Hash_Functions / empty rejects");
   ---------------------------------------------------------------------
   declare
      F : constant Filter := Create (M => 64, K => 3);
   begin
      Check (Size (F) = 64, "Create Size=64");
      Check (Hash_Functions (F) = 3, "Create K=3");
      Check (Insert_Count (F) = 0, "Create Insert_Count=0");
      Check (Bits_Set (F) = 0, "Create Bits_Set=0");
      Check (Approx (Fill_Ratio (F), 0.0), "Empty Fill_Ratio=0");
      Check (not Might_Contain (F, "alice"), "Empty rejects alice");
      Check (not Might_Contain (F, "bob"), "Empty rejects bob");
      Check (not Might_Contain (F, ""), "Empty rejects empty string");
      Check (not Might_Contain (F, 0), "Empty rejects Natural 0");
      Check (not Might_Contain (F, 42), "Empty rejects Natural 42");
      Check (not Probably_Contains (F, "x"), "Probably_Contains empty");
      Check (Approx (Estimated_False_Positive_Rate (F), 0.0),
             "Empty Estimated_FPR=0");
      Check (Approx (Estimated_Cardinality (F), 0.0),
             "Empty Estimated_Cardinality=0");
   end;

   ---------------------------------------------------------------------
   Section ("2. Add then Might_Contain — no false negatives (strings)");
   ---------------------------------------------------------------------
   declare
      F : Filter := Create (M => 256, K => 4);
      Names : constant array (Positive range <>) of String (1 .. 7) :=
        ["alpha  ", "beta   ", "gamma  ", "delta  ", "epsilon",
         "zeta   ", "eta    ", "theta  ", "iota   ", "kappa  "];
      function Trimmed (S : String) return String is
         L : Natural := S'Last;
      begin
         while L >= S'First and then S (L) = ' ' loop
            L := L - 1;
         end loop;
         return S (S'First .. L);
      end Trimmed;
   begin
      for N of Names loop
         Add (F, Trimmed (N));
      end loop;
      Check (Insert_Count (F) = Names'Length, "Insert_Count after 10 adds");
      Check (Bits_Set (F) > 0, "Bits_Set > 0 after adds");
      Check (Fill_Ratio (F) > 0.0, "Fill_Ratio increases after adds");
      for N of Names loop
         Check (Might_Contain (F, Trimmed (N)),
                "Might_Contain added string " & Trimmed (N));
         Check (Probably_Contains (F, Trimmed (N)),
                "Probably_Contains added " & Trimmed (N));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("3. Add Natural keys — no false negatives");
   ---------------------------------------------------------------------
   declare
      F : Filter := Create (M => 512, K => 5);
   begin
      for I in 1 .. 20 loop
         Add (F, I * 7);
      end loop;
      Check (Insert_Count (F) = 20, "20 Natural inserts");
      for I in 1 .. 20 loop
         Check (Might_Contain (F, I * 7),
                "Might_Contain Natural" & Integer'Image (I * 7));
      end loop;
      --  Soft: require that at least some never-inserted keys are absent
      declare
         Absent : Natural := 0;
      begin
         for I in 1 .. 200 loop
            if not Might_Contain (F, 10_000 + I) then
               Absent := Absent + 1;
            end if;
         end loop;
         Check (Absent > 0,
                "Some never-inserted Naturals absent (Absent="
                & Absent'Image & ")");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("4. Clear resets");
   ---------------------------------------------------------------------
   declare
      F : Filter := Create (M => 128, K => 3);
   begin
      Add (F, "reset-me");
      Add (F, 99);
      Check (Might_Contain (F, "reset-me"), "Before Clear: present");
      Check (Insert_Count (F) = 2, "Before Clear: Insert_Count=2");
      Check (Bits_Set (F) > 0, "Before Clear: bits set");
      Clear (F);
      Check (Insert_Count (F) = 0, "After Clear: Insert_Count=0");
      Check (Bits_Set (F) = 0, "After Clear: Bits_Set=0");
      Check (Approx (Fill_Ratio (F), 0.0), "After Clear: Fill_Ratio=0");
      Check (Size (F) = 128, "After Clear: Size unchanged");
      Check (Hash_Functions (F) = 3, "After Clear: K unchanged");
      Check (not Might_Contain (F, "reset-me"), "After Clear: string gone");
      Check (not Might_Contain (F, 99), "After Clear: Natural gone");
   end;

   ---------------------------------------------------------------------
   Section ("5. Optimal_M / Optimal_K formulas");
   ---------------------------------------------------------------------
   declare
      --  For p=0.01, n=1000: m ≈ -1000*ln(0.01)/(ln2)^2 ≈ 9585
      M1 : constant Bit_Count := Optimal_M (1000, 0.01);
      K1 : constant Hash_Count := Optimal_K (M1, 1000);
      K_Rate : constant Hash_Count := Optimal_K_From_Rate (0.01);
      --  For p=0.001, k ≈ -ln(0.001)/ln2 ≈ 9.96 ≈ 10
      K001 : constant Hash_Count := Optimal_K_From_Rate (0.001);
   begin
      Check (M1 > 9000 and then M1 < 10_200,
             "Optimal_M(1000,0.01) near 9585 got" & M1'Image);
      Check (K1 >= 6 and then K1 <= 8,
             "Optimal_K for p~0.01 near 7 got" & K1'Image);
      Check (K_Rate >= 6 and then K_Rate <= 8,
             "Optimal_K_From_Rate(0.01) near 7 got" & K_Rate'Image);
      Check (K001 >= 9 and then K001 <= 11,
             "Optimal_K_From_Rate(0.001) near 10 got" & K001'Image);
      Check (Optimal_M (100, 0.1) < Optimal_M (100, 0.01),
             "Smaller p => larger m");
      Check (Optimal_M (200, 0.01) > Optimal_M (100, 0.01),
             "Larger n => larger m");
      Check (Optimal_K (1000, 100) > Optimal_K (500, 100),
             "Larger m/n => larger k");
   end;

   ---------------------------------------------------------------------
   Section ("6. Create_For_Capacity");
   ---------------------------------------------------------------------
   declare
      F : Filter := Create_For_Capacity (N => 500, False_Positive_Rate => 0.01);
      M_Exp : constant Bit_Count := Optimal_M (500, 0.01);
      K_Exp : constant Hash_Count := Optimal_K (M_Exp, 500);
   begin
      Check (Size (F) = Natural (M_Exp), "Create_For_Capacity Size=Optimal_M");
      Check (Hash_Functions (F) = Natural (K_Exp),
             "Create_For_Capacity K=Optimal_K");
      Check (Insert_Count (F) = 0, "Create_For_Capacity empty");
      for I in 1 .. 50 loop
         Add (F, "item-" & I'Image);
      end loop;
      for I in 1 .. 50 loop
         Check (Might_Contain (F, "item-" & I'Image),
                "Capacity filter holds item-" & I'Image);
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("7. Deterministic hashes");
   ---------------------------------------------------------------------
   declare
      F1 : Filter := Create (M => 1024, K => 4);
      F2 : Filter := Create (M => 1024, K => 4);
   begin
      Add (F1, "deterministic");
      Add (F2, "deterministic");
      Check (Bits_Set (F1) = Bits_Set (F2),
             "Same key => same Bits_Set");
      Check (Might_Contain (F1, "deterministic")
             and then Might_Contain (F2, "deterministic"),
             "Both contain key");
      --  Same Natural
      declare
         G1 : Filter := Create (128, 3);
         G2 : Filter := Create (128, 3);
      begin
         Add (G1, 12345);
         Add (G2, 12345);
         Check (Bits_Set (G1) = Bits_Set (G2),
                "Same Natural => same Bits_Set");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("8. Fill_Ratio monotonicity");
   ---------------------------------------------------------------------
   declare
      F : Filter := Create (M => 2048, K => 4);
      Prev : Unit_Interval := 0.0;
      OK : Boolean := True;
   begin
      for I in 1 .. 30 loop
         Add (F, "mono-" & I'Image);
         if Fill_Ratio (F) + 1.0E-12 < Prev then
            OK := False;
         end if;
         Prev := Fill_Ratio (F);
      end loop;
      Check (OK, "Fill_Ratio non-decreasing over 30 inserts");
      Check (Fill_Ratio (F) > 0.0, "Fill_Ratio positive after inserts");
      Check (Fill_Ratio (F) < 1.0, "Fill_Ratio < 1 for sparse filter");
   end;

   ---------------------------------------------------------------------
   Section ("9. Near / Ln / Exp / Theoretical_FPR helpers");
   ---------------------------------------------------------------------
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (not Near (1.0, 2.0), "Near far");
      Check (Near (1.0, 1.0 + 1.0E-9, 1.0E-8), "Near within tol");
      Check (Approx (Exp (0.0), 1.0), "Exp(0)=1");
      Check (Approx (Exp (1.0), 2.718_281_828, 1.0E-5), "Exp(1)~e");
      Check (Approx (Ln (1.0), 0.0, 1.0E-5), "Ln(1)=0");
      Check (Approx (Ln (Exp (0.5)), 0.5, 1.0E-4), "Ln(Exp(0.5))~0.5");
      Check (Approx (Exp (Ln (2.0)), 2.0, 1.0E-4), "Exp(Ln(2))~2");
      Check (Approx (Theoretical_FPR (1000, 7, 0), 0.0),
             "Theoretical_FPR n=0 is 0");
      Check (Theoretical_FPR (10_000, 7, 1000) < 0.05,
             "Theoretical_FPR(10000,7,1000) < 5%");
      Check (Theoretical_FPR (100, 3, 1000) > Theoretical_FPR (10_000, 3, 1000),
             "Smaller m => higher theoretical FPR");
   end;

   ---------------------------------------------------------------------
   Section ("10. False-positive rate roughly near theory (large m)");
   ---------------------------------------------------------------------
   declare
      N_Ins : constant Positive := 200;
      P_Tgt : constant Probability := 0.01;
      F : Filter := Create_For_Capacity (N_Ins, P_Tgt);
      FP : Natural := 0;
      Trials : constant Positive := 2000;
      Emp : Real;
      Theo : Real;
   begin
      for I in 1 .. N_Ins loop
         Add (F, "ins-" & I'Image);
      end loop;
      --  Confirm no FN on inserted
      declare
         All_Found : Boolean := True;
      begin
         for I in 1 .. N_Ins loop
            if not Might_Contain (F, "ins-" & I'Image) then
               All_Found := False;
            end if;
         end loop;
         Check (All_Found, "No false negatives among 200 inserted");
      end;
      for J in 1 .. Trials loop
         if Might_Contain (F, "probe-xx-" & J'Image) then
            FP := FP + 1;
         end if;
      end loop;
      Emp := Real (FP) / Real (Trials);
      Theo := Real (Estimated_False_Positive_Rate (F));
      Check (Emp < 0.08,
             "Empirical FPR < 8% (got roughly "
             & Integer'Image (Integer (Emp * 1000.0)) & " e-3)");
      Check (Approx_Rel (Emp, Theo, 0.85) or else Emp < Theo + 0.05,
             "Empirical FPR roughly near theory");
      Check (Theo < 0.05, "Estimated_FPR under ~5% for designed filter");
      Check (Estimated_Cardinality (F) > 50.0,
             "Estimated_Cardinality in ballpark after 200 inserts");
      Check (Approx_Rel (Estimated_Cardinality (F), Real (N_Ins), 0.35),
             "Estimated_Cardinality within ~35% of n");
   end;

   ---------------------------------------------------------------------
   Section ("11. Never-inserted strings sometimes absent");
   ---------------------------------------------------------------------
   declare
      F : Filter := Create (M => 1024, K => 4);
      Absent : Natural := 0;
   begin
      for I in 1 .. 40 loop
         Add (F, "keep-" & I'Image);
      end loop;
      for I in 1 .. 40 loop
         Check (Might_Contain (F, "keep-" & I'Image),
                "keep present" & I'Image);
      end loop;
      for I in 1 .. 100 loop
         if not Might_Contain (F, "ghost-" & I'Image) then
            Absent := Absent + 1;
         end if;
      end loop;
      Check (Absent >= 50, "Many never-inserted absent (>=50/100)");
   end;

   ---------------------------------------------------------------------
   Section ("12. Probably_Contains alias + mixed keys");
   ---------------------------------------------------------------------
   declare
      F : Filter := Create (256, 3);
   begin
      Add (F, "s");
      Add (F, 7);
      Check (Probably_Contains (F, "s"), "Probably_Contains string");
      Check (Probably_Contains (F, 7), "Probably_Contains Natural");
      Check (Might_Contain (F, "s") = Probably_Contains (F, "s"),
             "Might/Probably agree on string");
      Check (Might_Contain (F, 7) = Probably_Contains (F, 7),
             "Might/Probably agree on Natural");
   end;

   ---------------------------------------------------------------------
   Section ("13. Copy / Adjust independence");
   ---------------------------------------------------------------------
   declare
      F1 : Filter := Create (128, 3);
      F2 : Filter;
   begin
      Add (F1, "orig");
      F2 := F1;
      Add (F2, "only-in-f2");
      Check (Might_Contain (F1, "orig"), "F1 still has orig");
      Check (Might_Contain (F2, "orig"), "F2 has orig from copy");
      Check (Might_Contain (F2, "only-in-f2"), "F2 has new key");
      --  F1 should not necessarily have only-in-f2 (independent bits)
      Check (Insert_Count (F1) = 1, "F1 Insert_Count stays 1");
      Check (Insert_Count (F2) = 2, "F2 Insert_Count is 2");
   end;

   ---------------------------------------------------------------------
   Section ("14. Batch string membership table");
   ---------------------------------------------------------------------
   declare
      F : Filter := Create (2048, 6);
   begin
      for I in 1 .. 20 loop
         Add (F, "word-" & I'Image);
      end loop;
      for I in 1 .. 20 loop
         Check (Might_Contain (F, "word-" & I'Image),
                "word present:" & I'Image);
      end loop;
      Check (not Might_Contain (F, "xyzzy-not-present-zz"),
             "Unrelated long token absent");
   end;

   ---------------------------------------------------------------------
   Section ("15. Theoretical_FPR matches Estimated after known n");
   ---------------------------------------------------------------------
   declare
      F : Filter := Create (5000, 5);
   begin
      for I in 1 .. 100 loop
         Add (F, I);
      end loop;
      Check
        (Near
           (Estimated_False_Positive_Rate (F),
            Theoretical_FPR (5000, 5, 100),
            1.0E-9),
         "Estimated_FPR = Theoretical_FPR(m,k,n)");
   end;

   New_Line;
   Put_Line ("================================");
   Put_Line ("Passed :" & Pass_Count'Image);
   Put_Line ("Failed :" & Fail_Count'Image);
   Put_Line ("================================");

   if Fail_Count /= 0 then
      raise Program_Error with "Bloom_Filter tests failed";
   end if;
end Tests;
