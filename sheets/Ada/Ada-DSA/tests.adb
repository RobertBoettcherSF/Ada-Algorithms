with Ada.Text_IO; use Ada.Text_IO;
with DSA;         use DSA;

-- The Tests procedure acts as both test suite and main entry point.
-- It demonstrates full usage of the package API.
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

   -- Standard sample configuration for testing
   -- P=23, Q=11, G=4 (Valid bounds since 11 divides 22)
   Test_Params : constant DSA_Parameters := (P => 23, Q => 11, G => 4);
   
   -- Larger mock config to ensure bounds function well
   Large_Params : constant DSA_Parameters := (P => 283, Q => 47, G => 64);
   
   K_Pair : Key_Pair;
   Sig, Sig2 : Signature;
   Result_Val : DSA_Value;
   pragma Warnings (Off, Result_Val);
   Got_Exception : Boolean;

begin
   Put_Line ("--- Starting DSA Implementation Tests ---");

   -- TEST 1 — Math Core: Mod_Exp Correctness
   Put_Line ("TEST 1 — Modular Exponentiation Core");
   Check ("1.1 Standard: 4^7 mod 23 = 8", Mod_Exp (4, 7, 23) = 8);
   Check ("1.2 Large Prime: 64^47 mod 283 = 1", Mod_Exp (64, 47, 283) = 1);
   Check ("1.3 Simple Exponent: 5^3 mod 13 = 8", Mod_Exp (5, 3, 13) = 8);

   -- TEST 2 — Math Core: Mod_Inverse Correctness
   Put_Line ("TEST 2 — Modular Inverse Core");
   Check ("2.1 Inverse of 3 mod 11 is 4", Mod_Inverse (3, 11) = 4);
   Check ("2.2 Inverse of 7 mod 11 is 8", Mod_Inverse (7, 11) = 8);
   Check ("2.3 Inverse of 2 mod 5 is 3", Mod_Inverse (2, 5) = 3);

   -- TEST 3 — Math Core: Mod_Inverse Exception Handling
   Put_Line ("TEST 3 — Modular Inverse Edge Cases");
   Got_Exception := False;
   begin
      Result_Val := Mod_Inverse (2, 4); -- Non-coprime
   exception
      when Invalid_Parameter_Error => Got_Exception := True;
   end;
   Check ("3.1 Non-invertible raises Invalid_Parameter_Error", Got_Exception);
   
   Got_Exception := False;
   begin
      Result_Val := Mod_Inverse (0, 5); -- Zero value
   exception
      when Invalid_Parameter_Error => Got_Exception := True;
   end;
   Check ("3.2 Zero value raises Invalid_Parameter_Error", Got_Exception);

   Got_Exception := False;
   begin
      Result_Val := Mod_Inverse (5, 0); -- Zero modulus
   exception
      when Invalid_Parameter_Error => Got_Exception := True;
   end;
   Check ("3.3 Zero modulus raises Invalid_Parameter_Error", Got_Exception);

   -- TEST 4 — Key Generation Correctness
   Put_Line ("TEST 4 — Key_Pair Generation");
   K_Pair := Generate_Key_Pair (Test_Params, 7);
   Check ("4.1 Retains parameters properly", K_Pair.Params.P = 23);
   Check ("4.2 Private key X is set correctly", K_Pair.X = 7);
   Check ("4.3 Public key Y matches calculation (4^7 mod 23 = 8)", K_Pair.Y = 8);

   -- TEST 5 — Key Generation Invalid Boundaries
   Put_Line ("TEST 5 — Key Generation Exceptions");
   Got_Exception := False;
   begin
      K_Pair := Generate_Key_Pair (Test_Params, 0);
   exception
      when Invalid_Parameter_Error => Got_Exception := True;
   end;
   Check ("5.1 Disallows X = 0", Got_Exception);
   
   Got_Exception := False;
   begin
      K_Pair := Generate_Key_Pair (Test_Params, 11);
   exception
      when Invalid_Parameter_Error => Got_Exception := True;
   end;
   Check ("5.2 Disallows X >= Q", Got_Exception);

   Got_Exception := False;
   begin
      K_Pair := Generate_Key_Pair ((P => 0, Q => 11, G => 4), 7);
   exception
      when Invalid_Parameter_Error => Got_Exception := True;
   end;
   Check ("5.3 Disallows P = 0", Got_Exception);

   -- TEST 6 — Sign Standard Variant Correctness
   Put_Line ("TEST 6 — Standard Signature Generation");
   -- Test case: H = 5, X = 7, K = 3
   -- R = (4^3 mod 23) mod 11 = 64 mod 23 mod 11 = 18 mod 11 = 7.
   -- S = 3^-1 * (5 + 7 * 7) mod 11 = 4 * (54) mod 11 = 216 mod 11 = 7.
   Sig := Sign_Standard (Test_Params, X => 7, K => 3, Hash => 5);
   Check ("6.1 Generated R matches manual calculation", Sig.R = 7);
   Check ("6.2 Generated S matches manual calculation", Sig.S = 7);
   Sig2 := Sign_Standard (Test_Params, X => 7, K => 2, Hash => 5);
   Check ("6.3 Allows signing with different K producing valid distinct R", Sig2.R /= Sig.R);

   -- TEST 7 — Sign Standard Variant Edge Cases
   Put_Line ("TEST 7 — Standard Signature Exceptions");
   Got_Exception := False;
   begin
      Sig := Sign_Standard (Test_Params, X => 7, K => 0, Hash => 5);
   exception
      when Invalid_Parameter_Error => Got_Exception := True;
   end;
   Check ("7.1 Signature rejects K = 0", Got_Exception);

   Got_Exception := False;
   begin
      Sig := Sign_Standard (Test_Params, X => 7, K => 12, Hash => 5);
   exception
      when Invalid_Parameter_Error => Got_Exception := True;
   end;
   Check ("7.2 Signature rejects K >= Q", Got_Exception);

   Got_Exception := False;
   begin
      Sig := Sign_Standard (Test_Params, X => 0, K => 3, Hash => 5);
   exception
      when Invalid_Parameter_Error => Got_Exception := True;
   end;
   Check ("7.3 Signature rejects X = 0", Got_Exception);

   -- TEST 8 — Deterministic Signature (RFC 6979 Mock) Correctness
   Put_Line ("TEST 8 — Deterministic Signature Generation");
   Sig := Sign_Deterministic (Test_Params, X => 7, Hash => 9);
   Check ("8.1 Generates valid non-zero R", Sig.R > 0);
   Check ("8.2 Generates valid non-zero S", Sig.S > 0);
   Sig2 := Sign_Deterministic (Test_Params, X => 7, Hash => 9);
   Check ("8.3 Identical Hash + X produces identical signature", Sig.R = Sig2.R and Sig.S = Sig2.S);

   -- TEST 9 — Verification Correctness (Valid Sigs)
   Put_Line ("TEST 9 — Signature Verification (Valid)");
   K_Pair := Generate_Key_Pair (Test_Params, 7);
   Sig := Sign_Standard (Test_Params, X => 7, K => 3, Hash => 5);
   Check ("9.1 Verifies Standard valid signature correctly", Verify (Test_Params, K_Pair.Y, 5, Sig));
   
   Sig2 := Sign_Deterministic (Test_Params, X => 7, Hash => 9);
   Check ("9.2 Verifies Deterministic valid signature correctly", Verify (Test_Params, K_Pair.Y, 9, Sig2));
   
   Sig := Sign_Standard (Test_Params, X => 7, K => 4, Hash => 2);
   Check ("9.3 Verifies alternative K/Hash valid signature", Verify (Test_Params, K_Pair.Y, 2, Sig));

   -- TEST 10 — Verification Correctness (Invalid Sigs - Mutations)
   Put_Line ("TEST 10 — Signature Verification (Rejects Mutations)");
   Sig := Sign_Standard (Test_Params, X => 7, K => 3, Hash => 5);
   Check ("10.1 Rejects modified R component", not Verify (Test_Params, K_Pair.Y, 5, (R => Sig.R + 1, S => Sig.S)));
   Check ("10.2 Rejects modified S component", not Verify (Test_Params, K_Pair.Y, 5, (R => Sig.R, S => Sig.S + 1)));
   Check ("10.3 Rejects signature over wrong Hash", not Verify (Test_Params, K_Pair.Y, 8, Sig));

   -- TEST 11 — Verification Correctness (Invalid Bounds)
   Put_Line ("TEST 11 — Signature Verification (Boundary Conditions)");
   Check ("11.1 Immediately rejects R = 0", not Verify (Test_Params, K_Pair.Y, 5, (R => 0, S => Sig.S)));
   Check ("11.2 Immediately rejects S = 0", not Verify (Test_Params, K_Pair.Y, 5, (R => Sig.R, S => 0)));
   Check ("11.3 Immediately rejects R >= Q", not Verify (Test_Params, K_Pair.Y, 5, (R => 12, S => Sig.S)));

   -- TEST 12 — Verification Wrong Domain / Keys
   Put_Line ("TEST 12 — Signature Verification (Key/Parameter mismatches)");
   Sig := Sign_Standard (Test_Params, X => 7, K => 3, Hash => 5);
   Check ("12.1 Rejects valid signature under wrong public key (Y)", not Verify (Test_Params, 2, 5, Sig));
   Check ("12.2 Rejects with corrupted modulus P", not Verify ((P => 29, Q => 11, G => 4), K_Pair.Y, 5, Sig));
   Check ("12.3 Rejects with corrupted modulus Q", not Verify ((P => 23, Q => 5, G => 4), K_Pair.Y, 5, Sig));

   -- TEST 13 — Integration: Large Parameters End-to-End
   Put_Line ("TEST 13 — Large Parameters Integration");
   K_Pair := Generate_Key_Pair (Large_Params, X => 15);
   Check ("13.1 Key pair generation functions correctly with large moduli", K_Pair.Y > 0);
   
   Sig := Sign_Standard (Large_Params, X => 15, K => 19, Hash => 123);
   Check ("13.2 Signs correctly with large moduli (R, S within bounds)", Sig.R > 0 and Sig.S > 0);
   
   Check ("13.3 Successfully verifies large parameter signature", Verify (Large_Params, K_Pair.Y, 123, Sig));

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
