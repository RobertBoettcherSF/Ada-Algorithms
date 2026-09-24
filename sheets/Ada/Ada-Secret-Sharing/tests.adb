with Ada.Text_IO; use Ada.Text_IO;
with Secret_Sharing; use Secret_Sharing;

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
   Put_Line ("Starting Secret Sharing Test Suite...");
   Put_Line ("=====================================");

   --  TEST 1 — Shamir Basic Setup
   Put_Line ("TEST 1 — Shamir Basic Setup (N=5, T=3)");
   declare
      Secret : constant GF_Element := 12345;
      Shares : constant Shamir_Share_Array := Split_Shamir (Secret, 5, 3);
      Subset : Shamir_Share_Array (1 .. 3);
   begin
      Check ("1.1 Split created exactly 5 shares", Shares'Length = 5);
      Subset (1) := Shares (1);
      Subset (2) := Shares (2);
      Subset (3) := Shares (3);
      Check ("1.2 Reconstructed correctly from shares {1, 2, 3}", Reconstruct_Shamir (Subset, 3) = Secret);
      Subset (1) := Shares (3);
      Subset (2) := Shares (4);
      Subset (3) := Shares (5);
      Check ("1.3 Reconstructed correctly from shares {3, 4, 5}", Reconstruct_Shamir (Subset, 3) = Secret);
   end;

   --  TEST 2 — Shamir Trivial Case
   Put_Line ("TEST 2 — Shamir Trivial Case (N=1, T=1)");
   declare
      Secret : constant GF_Element := 777;
      Shares : constant Shamir_Share_Array := Split_Shamir (Secret, 1, 1);
   begin
      Check ("2.1 Split created 1 share", Shares'Length = 1);
      Check ("2.2 Share X coordinate is 1", Shares (1).X = 1);
      Check ("2.3 Reconstruct matches secret", Reconstruct_Shamir (Shares, 1) = Secret);
   end;

   --  TEST 3 — Shamir Full Threshold
   Put_Line ("TEST 3 — Shamir Full Threshold (N=5, T=5)");
   declare
      Secret : constant GF_Element := 42;
      Shares : constant Shamir_Share_Array := Split_Shamir (Secret, 5, 5);
   begin
      Check ("3.1 Split created 5 shares", Shares'Length = 5);
      Check ("3.2 First share X is 1", Shares (1).X = 1);
      Check ("3.3 Reconstructed from all 5 shares", Reconstruct_Shamir (Shares, 5) = Secret);
   end;

   --  TEST 4 — Shamir with Secret = 0
   Put_Line ("TEST 4 — Shamir Edge Case: Secret = 0");
   declare
      Shares : constant Shamir_Share_Array := Split_Shamir (0, 3, 2);
   begin
      Check ("4.1 Length is 3", Shares'Length = 3);
      Check ("4.2 Reconstruct correctly yields 0", Reconstruct_Shamir (Shares, 2) = 0);
      Check ("4.3 Shares have distinct X identities", Shares (1).X /= Shares (2).X);
   end;

   --  TEST 5 — Shamir Error Handling (Duplicate X)
   Put_Line ("TEST 5 — Shamir Error Handling: Duplicate X");
   declare
      S1 : constant Shamir_Share := (X => 1, Y => 100);
      S2 : constant Shamir_Share := (X => 1, Y => 200); -- intentionally duplicate X
      Arr : constant Shamir_Share_Array (1 .. 2) := [1 => S1, 2 => S2];
      Caught : Boolean := False;
   begin
      Check ("5.1 Arr length is 2", Arr'Length = 2);
      Check ("5.2 X values are identical", Arr (1).X = Arr (2).X);
      begin
         if Reconstruct_Shamir (Arr, 2) = 0 then
            Check ("5.3 Should not be reached", False);
         else
            Check ("5.3 Should not be reached", False);
         end if;
      exception
         when Duplicate_Share_X =>
            Caught := True;
            Check ("5.3 Exception Duplicate_Share_X raised correctly", Caught);
         when others =>
            Check ("5.3 Wrong exception raised", False);
      end;
   end;

   --  TEST 6 — XOR Basic Setup
   Put_Line ("TEST 6 — XOR Basic Setup (N=5)");
   declare
      Secret : constant Data_Word := 16#DEADBEEF#;
      Shares : constant XOR_Share_Array := Split_XOR (Secret, 5);
   begin
      Check ("6.1 Split created 5 shares", Shares'Length = 5);
      Check ("6.2 Reconstructed secret matches original", Reconstruct_XOR (Shares) = Secret);
      -- The probability of a random XOR share matching the secret exactly is 1/2^32.
      Check ("6.3 First share is randomized", Shares (1) /= Secret);
   end;

   --  TEST 7 — Shamir Randomness Check
   Put_Line ("TEST 7 — Shamir Randomness Check");
   declare
      Shares1 : constant Shamir_Share_Array := Split_Shamir (111, 3, 2);
      Shares2 : constant Shamir_Share_Array := Split_Shamir (111, 3, 2);
   begin
      Check ("7.1 Shares1 length is 3", Shares1'Length = 3);
      Check ("7.2 Shares2 length is 3", Shares2'Length = 3);
      -- Cryptographically improbable (1/2^31) that two splits yield the same Y for X=1
      Check ("7.3 Different runs yield different polynomial shares", Shares1 (1).Y /= Shares2 (1).Y);
   end;

   --  TEST 8 — XOR Trivial Case
   Put_Line ("TEST 8 — XOR Trivial Case (N=1)");
   declare
      Secret : constant Data_Word := 999;
      Shares : constant XOR_Share_Array := Split_XOR (Secret, 1);
   begin
      Check ("8.1 Length is exactly 1", Shares'Length = 1);
      Check ("8.2 The single share equals the secret", Shares (1) = Secret);
      Check ("8.3 Reconstruct correctly yields secret", Reconstruct_XOR (Shares) = Secret);
   end;

   --  TEST 9 — XOR Randomness Check
   Put_Line ("TEST 9 — XOR Randomness Check");
   declare
      Shares1 : constant XOR_Share_Array := Split_XOR (555, 3);
      Shares2 : constant XOR_Share_Array := Split_XOR (555, 3);
   begin
      Check ("9.1 Split 1 length is 3", Shares1'Length = 3);
      Check ("9.2 Split 2 length is 3", Shares2'Length = 3);
      Check ("9.3 Different runs yield different random XOR shares", Shares1 (1) /= Shares2 (1));
   end;

   --  TEST 10 — XOR with Secret = 0
   Put_Line ("TEST 10 — XOR Edge Case: Secret = 0");
   declare
      Shares : constant XOR_Share_Array := Split_XOR (0, 4);
      Manual : Data_Word := 0;
   begin
      Check ("10.1 Length is 4", Shares'Length = 4);
      Check ("10.2 Reconstruct correctly yields 0", Reconstruct_XOR (Shares) = 0);
      for S of Shares loop
         Manual := Manual xor S;
      end loop;
      Check ("10.3 Manual XOR iteration matches", Manual = 0);
   end;

   --  TEST 11 — XOR with Secret = Max Value
   Put_Line ("TEST 11 — XOR Edge Case: Secret = Max_Value");
   declare
      Max_Val : constant Data_Word := Data_Word'Last;
      Shares  : constant XOR_Share_Array := Split_XOR (Max_Val, 3);
   begin
      Check ("11.1 Length is 3", Shares'Length = 3);
      Check ("11.2 Reconstruct perfectly matches Max_Val", Reconstruct_XOR (Shares) = Max_Val);
      Check ("11.3 Individual share is obfuscated", Shares (1) /= Max_Val);
   end;

   --  TEST 12 — Shamir Subset Variations
   Put_Line ("TEST 12 — Shamir Subset Variations (N=4, T=2)");
   declare
      Secret : constant GF_Element := 8888;
      Shares : constant Shamir_Share_Array := Split_Shamir (Secret, 4, 2);
      Sub1   : constant Shamir_Share_Array (1 .. 2) := [1 => Shares (1), 2 => Shares (4)];
      Sub2   : constant Shamir_Share_Array (1 .. 2) := [1 => Shares (2), 2 => Shares (3)];
      Sub3   : constant Shamir_Share_Array (1 .. 2) := [1 => Shares (3), 2 => Shares (4)];
   begin
      Check ("12.1 Subset {1, 4} reconstructs correctly", Reconstruct_Shamir (Sub1, 2) = Secret);
      Check ("12.2 Subset {2, 3} reconstructs correctly", Reconstruct_Shamir (Sub2, 2) = Secret);
      Check ("12.3 Subset {3, 4} reconstructs correctly", Reconstruct_Shamir (Sub3, 2) = Secret);
   end;

   --  TEST 13 — Shamir Math Correctness bounds
   Put_Line ("TEST 13 — Shamir Math Correctness bounds");
   declare
      Secret : constant GF_Element := GF_Element'Last;
      Shares : constant Shamir_Share_Array := Split_Shamir (Secret, 4, 3);
   begin
      Check ("13.1 Share 1 X mathematically aligns to 1", Shares (1).X = 1);
      Check ("13.2 Share 4 X mathematically aligns to 4", Shares (4).X = 4);
      Check ("13.3 Reconstruct handles large edge-case secret cleanly", Reconstruct_Shamir (Shares, 3) = Secret);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");

   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
