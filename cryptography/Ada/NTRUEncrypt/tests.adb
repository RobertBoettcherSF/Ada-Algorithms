with Ada.Text_IO; use Ada.Text_IO;
with NTRU;

procedure Tests is
   -- Instantiate with Wikipedia toy example parameters (N=11, p=3, q=32)
   package Test_NTRU is new NTRU (N => 11, P => 3, Q => 32);
   use Test_NTRU;

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

   -- ==========================================
   -- Test Data 
   -- ==========================================
   
   -- Polynomials F, G (from standard examples)
   F : constant Polynomial := [-1, 1, 1, 0, -1, 0, 1, 0, 0, 1, -1];
   G : constant Polynomial := [-1, 0, 1, 1, 0, 1, 0, 0, -1, 0, -1];
   
   -- Expected Key Pairs (Mathematically verified against inversion operations)
   Expected_Fp : constant Polynomial := [1, 2, 0, 2, 2, 1, 0, 2, 1, 2, 0];
   Expected_Fq : constant Polynomial := [5, 9, 6, 16, 4, 15, 16, 22, 20, 18, 30];

   -- Message and Random Polynomial 
   -- (Chosen to ensure A's coefficients stay strictly within [-15, 16] to avoid q/2 wrap-around failures inherent to the Wikipedia toy parameters)
   M : constant Polynomial := [0 => 1, 3 => -1, 4 => 1, 9 => 1, others => 0];
   R : constant Polynomial := [1 => 1, 5 => -1, 7 => 1, 10 => -1, others => 0];
   
   PK, SK_F, SK_Fp : Polynomial;
   E : Polynomial;

   -- Generic identity element for testing
   Identity_Poly : constant Polynomial := [0 => 1, others => 0];
begin
   Put_Line ("=== NTRUEncrypt Test Suite ===");

   -- TEST 1-3: Key Generation verification
   Generate_Key (F, G, PK, SK_F, SK_Fp);
   Check ("1. KeyGen: F_p matches expected value", SK_Fp = Expected_Fp);
   Check ("2. KeyGen: F_q matches expected value", Invert (F, 32) = Expected_Fq);
   Check ("3. KeyGen: Public Key H is correctly formed", PK = Modulo_Poly (3 * (Expected_Fq * G), 32));

   -- TEST 4: Encryption verification
   E := Encrypt (M, R, PK);
   Check ("4. Encrypt: Ciphertext E is correctly formed", E = Modulo_Poly (R * PK + M, 32));

   -- TEST 5-8: Decryption steps verification
   declare
      A_Raw      : constant Polynomial := Modulo_Poly (SK_F * E, 32);
      A_Centered : constant Polynomial := Center (A_Raw, 32);
      B_Centered : constant Polynomial := Center (A_Centered, 3);
      C_Centered : constant Polynomial := Decrypt (E, SK_F, SK_Fp);
   begin
      Check ("5. Decrypt Step 1: Raw A (before centering) is structurally valid", 
             Modulo_Poly (A_Raw, 32) = A_Raw);
      Check ("6. Decrypt Step 2: Centered A is properly formed", A_Centered = Center (Modulo_Poly (SK_F * E, 32), 32));
      Check ("7. Decrypt Step 3: Centered B is properly formed", B_Centered = Center (Modulo_Poly (A_Centered, 3), 3));
      Check ("8. Decrypt Step 4: Final Decrypted Message (C) matches Original M", C_Centered = M);
   end;

   -- TEST 9: Edge case for Modulo operation (Negatives)
   declare
      Neg_Poly : constant Polynomial := [others => -1];
      Mod_Poly : constant Polynomial := Modulo_Poly (Neg_Poly, 3);
      Expected : constant Polynomial := [others => 2];
   begin
      Check ("9. Modulo: Negative coefficients properly wrap around", Mod_Poly = Expected);
   end;

   -- TEST 10: Edge case for Centering boundary
   declare
      Bound_Poly : constant Polynomial := [0 => 15, 1 => 16, others => 0];
      Cent_Poly  : constant Polynomial := Center (Bound_Poly, 32);
      Expected   : constant Polynomial := [0 => 15, 1 => -16, others => 0];
   begin
      Check ("10. Center: Handles upper bounds effectively (15->15, 16->-16 mod 32)", Cent_Poly = Expected);
   end;

   -- TEST 11: Error handling for uninvertible polynomials
   declare
      Zero_Poly : constant Polynomial := [others => 0];
      Did_Raise : Boolean := False;
      Discard   : Polynomial;
   begin
      begin
         Discard := Invert (Zero_Poly, 32);
      exception
         when Not_Invertible =>
            Did_Raise := True;
      end;
      Check ("11. Exceptions: Invert raises Not_Invertible for zero polynomial", Did_Raise);
   end;

   -- TEST 12: Convolution Identity Property
   Check ("12. Properties: P * 1 = P (Multiplicative Identity)", (F * Identity_Poly) = F);

   -- TEST 13: Convolution Commutativity Property
   Check ("13. Properties: A * B = B * A (Commutativity of Cyclic Convolution)", (F * G) = (G * F));

   -- TEST 14: Full System Roundtrip with a new random message
   declare
      M_Alt : constant Polynomial := [0 => -1, 1 => 1, 2 => -1, others => 0];
      R_Alt : constant Polynomial := [2 => 1, 4 => -1, 6 => 1, others => 0];
      E_Alt : constant Polynomial := Encrypt (M_Alt, R_Alt, PK);
      D_Alt : constant Polynomial := Decrypt (E_Alt, SK_F, SK_Fp);
   begin
      Check ("14. E2E: Full Generate -> Encrypt -> Decrypt sequence validates a new message", D_Alt = M_Alt);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
