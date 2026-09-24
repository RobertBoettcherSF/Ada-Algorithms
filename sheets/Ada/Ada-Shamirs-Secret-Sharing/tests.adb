with Ada.Text_IO; use Ada.Text_IO;
with Shamirs_Secret_Sharing; use Shamirs_Secret_Sharing;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;
begin
   Put_Line ("TEST 1 — Modular Inverse");
   Check ("1.1 Inv(1) = 1", Modular_Inverse (1) = 1);
   Check ("1.2 Inv(P-1) = P-1", Modular_Inverse (Field_Element'Last) = Field_Element'Last);
   Check ("1.3 Inv(123) * 123 = 1", (Modular_Inverse (123) * 123) = 1);

   Put_Line ("TEST 2 — Polynomial Evaluation");
   declare
      C_Empty : constant Coefficient_Array (1 .. 0) := [];
      C_Lin   : constant Coefficient_Array (1 .. 1) := [1 => 2];
      C_Quad  : constant Coefficient_Array (1 .. 2) := [1 => 2, 2 => 3];
   begin
      Check ("2.1 Degree 0 (Const)", Evaluate_Polynomial (10, C_Empty, 5) = 10);
      Check ("2.2 Degree 1 (Linear)", Evaluate_Polynomial (10, C_Lin, 3) = 16);
      Check ("2.3 Degree 2 (Quadratic)", Evaluate_Polynomial (10, C_Quad, 3) = 43);
   end;

   Put_Line ("TEST 3 — Deterministic Split K=1 (Threshold 1)");
   declare
      Shares : constant Share_Array := Split_Secret_Deterministic (77, [1 .. 0 => 0], 3);
   begin
      Check ("3.1 Output length is 3", Shares'Length = 3);
      Check ("3.2 Share 1 is Secret", Shares (1).Value = 77);
      Check ("3.3 Share 2 is Secret", Shares (2).Value = 77);
   end;

   Put_Line ("TEST 4 — Deterministic Split K=3");
   declare
      -- Secret = 42, f(x) = 42 + 1*x + 1*x^2
      Shares : constant Share_Array := Split_Secret_Deterministic (42, [1 => 1, 2 => 1], 3);
   begin
      Check ("4.1 f(1) = 44", Shares (1).Value = 44);
      Check ("4.2 f(2) = 48", Shares (2).Value = 48);
      Check ("4.3 f(3) = 54", Shares (3).Value = 54);
   end;

   Put_Line ("TEST 5 — Reconstruct K=1");
   declare
      Shares_A : constant Share_Array := [1 => (Id => 1, Value => 99)];
      Shares_B : constant Share_Array := [1 => (Id => 5, Value => 99)];
      Shares_C : constant Share_Array := [1 => (Id => 2, Value => 99), 2 => (Id => 4, Value => 99)];
   begin
      Check ("5.1 Single share at X=1", Reconstruct_Secret (Shares_A, 1) = 99);
      Check ("5.2 Single share at X=5", Reconstruct_Secret (Shares_B, 1) = 99);
      Check ("5.3 Reconstruct uses only 1st element", Reconstruct_Secret (Shares_C, 1) = 99);
   end;

   Put_Line ("TEST 6 — Reconstruct K=3 (Exact match)");
   declare
      Shares   : constant Share_Array := Split_Secret_Deterministic (42, [1 => 1, 2 => 1], 3);
      Reversed : constant Share_Array := [1 => Shares (3), 2 => Shares (2), 3 => Shares (1)];
   begin
      Check ("6.1 Correct secret recovered", Reconstruct_Secret (Shares, 3) = 42);
      Check ("6.2 Check threshold bound", Shares'Length = 3);
      Check ("6.3 Recovered invariant of share order", Reconstruct_Secret (Reversed, 3) = 42);
   end;

   Put_Line ("TEST 7 — Reconstruct Oversupply (N=5, K=3)");
   declare
      Shares   : constant Share_Array := Split_Secret_Deterministic (42, [1 => 1, 2 => 1], 5);
      Subset_A : constant Share_Array := [Shares (2), Shares (3), Shares (4), Shares (5)];
      Subset_B : constant Share_Array := [Shares (1), Shares (5), Shares (3), Shares (4)];
   begin
      Check ("7.1 Full array provided (uses first 3)", Reconstruct_Secret (Shares, 3) = 42);
      Check ("7.2 Trailing subset provided", Reconstruct_Secret (Subset_A, 3) = 42);
      Check ("7.3 Jumbled subset provided", Reconstruct_Secret (Subset_B, 3) = 42);
   end;

   Put_Line ("TEST 8 — Reconstruct Different Subsets (N=5, K=3)");
   declare
      Shares   : constant Share_Array := Split_Secret_Deterministic (123, [1 => 4, 2 => 5], 5);
      Subset_1 : constant Share_Array := [Shares (1), Shares (2), Shares (3)];
      Subset_2 : constant Share_Array := [Shares (2), Shares (4), Shares (5)];
      Subset_3 : constant Share_Array := [Shares (1), Shares (3), Shares (5)];
   begin
      Check ("8.1 From {1,2,3}", Reconstruct_Secret (Subset_1, 3) = 123);
      Check ("8.2 From {2,4,5}", Reconstruct_Secret (Subset_2, 3) = 123);
      Check ("8.3 From {1,3,5}", Reconstruct_Secret (Subset_3, 3) = 123);
   end;

   Put_Line ("TEST 9 — Random Dynamic Split (N=5, K=3)");
   declare
      Shares   : constant Share_Array := Split_Secret (777, 3, 5);
      Subset   : constant Share_Array := [Shares (1), Shares (3), Shares (5)];
   begin
      Check ("9.1 Generates expected total count", Shares'Length = 5);
      Check ("9.2 Sequential IDs assigned", Shares (5).Id = 5);
      Check ("9.3 Random shares decode successfully", Reconstruct_Secret (Subset, 3) = 777);
   end;

   Put_Line ("TEST 10 — Integer Variant Split");
   declare
      Shares : constant Integer_Share_Array := Split_Secret_Integer (10, [1 => 2, 2 => 3], 3);
   begin
      -- f(x) = 10 + 2x + 3x^2
      Check ("10.1 Share 1 = 15", Shares (1).Value = 15);
      Check ("10.2 Share 2 = 26", Shares (2).Value = 26);
      Check ("10.3 Share 3 = 43", Shares (3).Value = 43);
   end;

   Put_Line ("TEST 11 — Integer Variant Reconstruct");
   declare
      Shares : constant Integer_Share_Array := Split_Secret_Integer (10, [1 => 2, 2 => 3], 4);
      Sub_1  : constant Integer_Share_Array := [Shares (1), Shares (2), Shares (3)];
      Sub_2  : constant Integer_Share_Array := [Shares (2), Shares (3), Shares (4)];
   begin
      Check ("11.1 Reconstruct from {1,2,3}", Reconstruct_Secret_Integer (Sub_1, 3) = 10);
      Check ("11.2 Reconstruct from {2,3,4}", Reconstruct_Secret_Integer (Sub_2, 3) = 10);
      Check ("11.3 Oversupplied array truncates cleanly", Reconstruct_Secret_Integer (Shares, 3) = 10);
   end;

   Put_Line ("TEST 12 — Error on Duplicate Shares");
   declare
      Shares_Dup     : constant Share_Array := [(Id => 1, Value => 10), (Id => 1, Value => 10)];
      Int_Shares_Dup : constant Integer_Share_Array := [(Id => 1, Value => 10), (Id => 1, Value => 10)];
      Got_Error      : Boolean;
   begin
      Got_Error := False;
      begin
         if Reconstruct_Secret (Shares_Dup, 2) = 0 then null; end if;
      exception
         when Invalid_Share_Error => Got_Error := True;
      end;
      Check ("12.1 Catches duplicate in FF variant", Got_Error);

      Got_Error := False;
      begin
         if Reconstruct_Secret_Integer (Int_Shares_Dup, 2) = 0 then null; end if;
      exception
         when Invalid_Share_Error => Got_Error := True;
      end;
      Check ("12.2 Catches duplicate in Int variant", Got_Error);

      Got_Error := False;
      begin
         declare
            S : constant Share_Array := Split_Secret (10, 5, 3);
            pragma Unreferenced (S);
         begin
            null;
         end;
      exception
         when Threshold_Error => Got_Error := True;
      end;
      Check ("12.3 Split catches bad threshold constraints", Got_Error);
   end;

   Put_Line ("TEST 13 — Error on Insufficient Shares");
   declare
      Shares_One     : constant Share_Array := [1 => (Id => 1, Value => 10)];
      Int_Shares_One : constant Integer_Share_Array := [1 => (Id => 1, Value => 10)];
      Got_Error      : Boolean;
   begin
      Got_Error := False;
      begin
         if Reconstruct_Secret (Shares_One, 2) = 0 then null; end if;
      exception
         when Threshold_Error => Got_Error := True;
      end;
      Check ("13.1 Reconstruct detects lack of FF shares", Got_Error);

      Got_Error := False;
      begin
         if Reconstruct_Secret_Integer (Int_Shares_One, 2) = 0 then null; end if;
      exception
         when Threshold_Error => Got_Error := True;
      end;
      Check ("13.2 Reconstruct detects lack of Int shares", Got_Error);

      Got_Error := False;
      begin
         declare
            Empty_Shares : constant Share_Array (1 .. 0) := [];
         begin
            if Reconstruct_Secret (Empty_Shares, 1) = 0 then null; end if;
         end;
      exception
         when Threshold_Error => Got_Error := True;
      end;
      Check ("13.3 Empty array correctly triggers Threshold_Error", Got_Error);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
