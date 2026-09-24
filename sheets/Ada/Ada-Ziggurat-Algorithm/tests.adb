-- tests.adb
-- Verification & Validation Test Suite for Ziggurat Algorithm

with Ada.Text_IO; use Ada.Text_IO;
with Ziggurat; use Ziggurat;

procedure Tests is
   
   -- Custom assertion utility
   procedure Assert (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Put_Line ("     FAIL: " & Message);
         raise Program_Error with Message;
      end if;
   end Assert;

   N_Samples : constant Integer := 100_000;
   Sum, Sum_Sq, Mean, Variance, Val, Val1, Val2 : Real;
   Pos_Count, Neg_Count, Tail_Count : Integer := 0;

begin
   Put_Line("==============================================");
   Put_Line("Ziggurat V&V Test Suite Execution");
   Put_Line("==============================================");

   -- TEST 1
   Put_Line("TEST 1 - Initialization Robustness");
   Put_Line("  1.1 Assert Initialize completes without raising exception");
   Ziggurat.Initialize(42);
   Assert(True, "Init failed");
   Put_Line("     PASS");

   -- TEST 2
   Put_Line("TEST 2 - Determinism Check");
   Put_Line("  2.1 Assert identical seeds produce identical random outputs");
   Ziggurat.Initialize(100);
   Val1 := Ziggurat.Random_Normal;
   Ziggurat.Initialize(100);
   Val2 := Ziggurat.Random_Normal;
   Assert(Val1 = Val2, "Outputs differ for identical seeds");
   Put_Line("     PASS");

   -- TEST 3
   Put_Line("TEST 3 - State Independence");
   Put_Line("  3.1 Assert sequential calls produce different outputs");
   Val1 := Ziggurat.Random_Normal;
   Val2 := Ziggurat.Random_Normal;
   Assert(Val1 /= Val2, "Sequential outputs are suspiciously identical");
   Put_Line("     PASS");

   -- TEST 4
   Put_Line("TEST 4 - Normal Distribution Mean (Accuracy)");
   Put_Line("  4.1 Assert Mean of 100k Normal samples is near 0.0");
   Sum := 0.0;
   for I in 1 .. N_Samples loop
      Sum := Sum + Ziggurat.Random_Normal;
   end loop;
   Mean := Sum / Real(N_Samples);
   Assert(abs Mean < 0.05, "Mean is mathematically drifting from 0.0");
   Put_Line("     PASS");

   -- TEST 5
   Put_Line("TEST 5 - Normal Distribution Variance");
   Put_Line("  5.1 Assert Variance of 100k Normal samples is near 1.0");
   Sum := 0.0; Sum_Sq := 0.0;
   for I in 1 .. N_Samples loop
      Val := Ziggurat.Random_Normal;
      Sum := Sum + Val;
      Sum_Sq := Sum_Sq + Val * Val;
   end loop;
   Mean := Sum / Real(N_Samples);
   Variance := (Sum_Sq / Real(N_Samples)) - (Mean * Mean);
   Assert(abs (Variance - 1.0) < 0.05, "Variance is not near 1.0");
   Put_Line("     PASS");

   -- TEST 6
   Put_Line("TEST 6 - Normal Distribution Symmetry");
   Put_Line("  6.1 Assert Positive and Negative generation counts are roughly equal");
   Pos_Count := 0; Neg_Count := 0;
   for I in 1 .. N_Samples loop
      if Ziggurat.Random_Normal > 0.0 then 
         Pos_Count := Pos_Count + 1;
      else 
         Neg_Count := Neg_Count + 1; 
      end if;
   end loop;
   Assert(Real(Pos_Count) / Real(N_Samples) > 0.48, "Imbalance: Too few positives");
   Assert(Real(Pos_Count) / Real(N_Samples) < 0.52, "Imbalance: Too many positives");
   Put_Line("     PASS");

   -- TEST 7
   Put_Line("TEST 7 - Normal Distribution Tail Coverage");
   Put_Line("  7.1 Assert Marsaglia tail generator naturally triggers (> 3.654)");
   Tail_Count := 0;
   for I in 1 .. N_Samples loop
      if abs Ziggurat.Random_Normal > 3.654 then
         Tail_Count := Tail_Count + 1;
      end if;
   end loop;
   Assert(Tail_Count > 0, "No extreme tail values generated. Check tail logic.");
   Put_Line("     PASS");

   -- TEST 8
   Put_Line("TEST 8 - Exponential Distribution Mean (Accuracy)");
   Put_Line("  8.1 Assert Mean of 100k Exponential samples is near 1.0");
   Sum := 0.0;
   for I in 1 .. N_Samples loop
      Sum := Sum + Ziggurat.Random_Exponential;
   end loop;
   Mean := Sum / Real(N_Samples);
   Assert(abs (Mean - 1.0) < 0.05, "Exp Mean is not near 1.0");
   Put_Line("     PASS");

   -- TEST 9
   Put_Line("TEST 9 - Exponential Distribution Variance");
   Put_Line("  9.1 Assert Variance of 100k Exponential samples is near 1.0");
   Sum := 0.0; Sum_Sq := 0.0;
   for I in 1 .. N_Samples loop
      Val := Ziggurat.Random_Exponential;
      Sum := Sum + Val;
      Sum_Sq := Sum_Sq + Val * Val;
   end loop;
   Mean := Sum / Real(N_Samples);
   Variance := (Sum_Sq / Real(N_Samples)) - (Mean * Mean);
   Assert(abs (Variance - 1.0) < 0.05, "Exp Variance is not near 1.0");
   Put_Line("     PASS");

   -- TEST 10
   Put_Line("TEST 10 - Exponential Distribution Bounds Verification");
   Put_Line("  10.1 Assert Exponential strictly generates values >= 0.0");
   Neg_Count := 0;
   for I in 1 .. N_Samples loop
      if Ziggurat.Random_Exponential < 0.0 then
         Neg_Count := Neg_Count + 1;
      end if;
   end loop;
   Assert(Neg_Count = 0, "Critical Fault: Exponential returned a negative value");
   Put_Line("     PASS");

   -- TEST 11
   Put_Line("TEST 11 - Exponential Distribution Tail Coverage");
   Put_Line("  11.1 Assert Exponential tail triggers values > 7.697");
   Tail_Count := 0;
   for I in 1 .. N_Samples loop
      if Ziggurat.Random_Exponential > 7.697 then
         Tail_Count := Tail_Count + 1;
      end if;
   end loop;
   Assert(Tail_Count > 0, "No extreme exponential tail values generated.");
   Put_Line("     PASS");

   -- TEST 12
   Put_Line("TEST 12 - Exponential Shape Analysis");
   Put_Line("  12.1 Assert P(X > 1.0) strictly matches 1/e (~36.8%)");
   Pos_Count := 0;
   for I in 1 .. N_Samples loop
      if Ziggurat.Random_Exponential > 1.0 then
         Pos_Count := Pos_Count + 1;
      end if;
   end loop;
   declare
      Ratio : constant Real := Real(Pos_Count) / Real(N_Samples);
   begin
      Assert(abs (Ratio - 0.36787) < 0.015, "Distribution shape deviates heavily from Expected 1/e");
   end;
   Put_Line("     PASS");

   -- TEST 13
   Put_Line("TEST 13 - Load Capacity and Stability");
   Put_Line("  13.1 Assert robust execution for 1,000,000 back-to-back Normal generations");
   for I in 1 .. 1_000_000 loop
      Val := Ziggurat.Random_Normal;
   end loop;
   Assert(True, "Engine crashed under stress test load");
   Put_Line("     PASS");

   Put_Line("==============================================");
   Put_Line("ALL TESTS PASSED: Codebase works as required.");
   Put_Line("==============================================");
end Tests;
