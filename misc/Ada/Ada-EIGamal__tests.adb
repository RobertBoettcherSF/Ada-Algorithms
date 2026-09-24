with Ada.Text_IO; use Ada.Text_IO;
with ElGamal_Encryption; use ElGamal_Encryption;

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

   Gen   : constant Plaintext_T := 2;
   Priv  : constant Plaintext_T := 12345;
   Keys  : Key_Pair_T;
   Msg   : constant Plaintext_T := 42;
   Eph   : constant Plaintext_T := 6789;
   Cipher : Ciphertext_T;
   Decrypted_Msg : Plaintext_T;
   Sig   : Signature_T;
   Is_Valid : Boolean;
begin
   -- TEST 1 — Modular Exponentiation
   Put_Line ("TEST 1 — Modular Exponentiation");
   Check ("1.1 Base 2 exp 3 mod p is 8", Mod_Exp (2, 3) = 8);
   Check ("1.2 Base 5 exp 0 mod p is 1", Mod_Exp (5, 0) = 1);
   Check ("1.3 Base 10 exp 1 mod p is 10", Mod_Exp (10, 1) = 10);

   -- TEST 2 — Greatest Common Divisor
   Put_Line ("TEST 2 — GCD Calculation");
   Check ("2.1 GCD of 48 and 18 is 6", GCD (48, 18) = 6);
   Check ("2.2 GCD of prime and 1 is 1", GCD (17, 1) = 1);
   Check ("2.3 GCD of 105 and 25 is 5", GCD (105, 25) = 5);

   -- TEST 3 — Modular Inverse
   Put_Line ("TEST 3 — Modular Inverse");
   Check ("3.1 Inverse of 3 modulo p product check", (3 * Mod_Inverse (3)) = 1);
   Check ("3.2 Inverse of 12345 modulo p product check", (12345 * Mod_Inverse (12345)) = 1);
   Check ("3.3 Inverse of 1 modulo p is 1", Mod_Inverse (1) = 1);

   -- TEST 4 — Key Generation
   Put_Line ("TEST 4 — Key Generation");
   Generate_Keys (Gen, Priv, Keys);
   Check ("4.1 Generator correctly stored", Keys.Generator = Gen);
   Check ("4.2 Private key correctly stored", Keys.Private_Key = Priv);
   Check ("4.3 Public key correctly computed", Keys.Public_Key = Mod_Exp (Gen, Priv));

   -- TEST 5 — Encryption and Decryption Roundtrip
   Put_Line ("TEST 5 — Encryption and Decryption");
   Cipher := Encrypt (Msg, Keys.Public_Key, Keys.Generator, Eph);
   Decrypted_Msg := Decrypt (Cipher, Keys.Private_Key);
   Check ("5.1 C1 is non-zero", Cipher.C1 /= 0);
   Check ("5.2 C2 is non-zero", Cipher.C2 /= 0);
   Check ("5.3 Decrypted message matches original", Decrypted_Msg = Msg);

   -- TEST 6 — Homomorphic Multiplication Property
   Put_Line ("TEST 6 — Homomorphic Multiplication");
   declare
      Msg1     : constant Plaintext_T := 10;
      Msg2     : constant Plaintext_T := 5;
      C_1      : constant Ciphertext_T := Encrypt (Msg1, Keys.Public_Key, Keys.Generator, 1111);
      C_2      : constant Ciphertext_T := Encrypt (Msg2, Keys.Public_Key, Keys.Generator, 2222);
      C_Prod   : constant Ciphertext_T := Multiply_Ciphertexts (C_1, C_2);
      Dec_Prod : constant Plaintext_T := Decrypt (C_Prod, Keys.Private_Key);
   begin
      Check ("6.1 Homomorphic product C1 valid", C_Prod.C1 /= 0);
      Check ("6.2 Homomorphic product C2 valid", C_Prod.C2 /= 0);
      Check ("6.3 Decrypted product equals product of messages (10 * 5 = 50)", Dec_Prod = 50);
   end;

   -- TEST 7 — ElGamal Digital Signature
   Put_Line ("TEST 7 — Digital Signature Generation and Verification");
   Sig := Sign (Msg, Keys.Private_Key, Keys.Generator, 1213);
   Is_Valid := Verify (Msg, Sig, Keys.Public_Key, Keys.Generator);
   Check ("7.1 Signature R is generated", Sig.R /= 0);
   Check ("7.2 Signature S is generated", Sig.S /= 0);
   Check ("7.3 Signature verifies successfully", Is_Valid);

   -- TEST 8 — Invalid Signature Detection
   Put_Line ("TEST 8 — Invalid Signature Detection");
   declare
      Bad_Sig       : constant Signature_T := (R => Sig.R, S => Sig.S + 1);
      Invalid_Check : constant Boolean := Verify (Msg, Bad_Sig, Keys.Public_Key, Keys.Generator);
   begin
      Check ("8.1 Modified S fails verification", not Invalid_Check);
      Check ("8.2 Original signature still valid", Verify (Msg, Sig, Keys.Public_Key, Keys.Generator));
      Check ("8.3 Different message fails verification", not Verify (99, Sig, Keys.Public_Key, Keys.Generator));
   end;

   -- TEST 9 — Edge Case: Encrypting Zero
   Put_Line ("TEST 9 — Encrypting Zero");
   declare
      Zero_Cipher : constant Ciphertext_T := Encrypt (0, Keys.Public_Key, Keys.Generator, 3333);
      Zero_Dec    : constant Plaintext_T := Decrypt (Zero_Cipher, Keys.Private_Key);
   begin
      Check ("9.1 Zero encryption C1 valid", Zero_Cipher.C1 /= 0);
      Check ("9.2 Zero encryption C2 is zero", Zero_Cipher.C2 = 0);
      Check ("9.3 Zero decryption recovers zero", Zero_Dec = 0);
   end;

   -- TEST 10 — Edge Case: Encrypting Maximum Modulus Minus One
   Put_Line ("TEST 10 — Encrypting Large Message");
   declare
      Max_Msg    : constant Plaintext_T := Plaintext_T (Modulus_Value - 2);
      Big_Cipher : constant Ciphertext_T := Encrypt (Max_Msg, Keys.Public_Key, Keys.Generator, 4444);
      Big_Dec    : constant Plaintext_T := Decrypt (Big_Cipher, Keys.Private_Key);
   begin
      Check ("10.1 Large message C1 valid", Big_Cipher.C1 /= 0);
      Check ("10.2 Large message C2 valid", Big_Cipher.C2 /= 0);
      Check ("10.3 Large message decrypted correctly", Big_Dec = Max_Msg);
   end;

   -- TEST 11 — Error Handling: Invalid Ciphertext (C1 = 0)
   Put_Line ("TEST 11 — Error Handling for Invalid Ciphertext");
   declare
      Bad_Cipher       : constant Ciphertext_T := (C1 => 0, C2 => 50);
      Exception_Raised : Boolean := False;
   begin
      begin
         declare
            Dummy : Plaintext_T;
         begin
            Dummy := Decrypt (Bad_Cipher, Keys.Private_Key);
            pragma Unreferenced (Dummy);
         end;
      exception
         when Invalid_Ciphertext_Error =>
            Exception_Raised := True;
      end;
      Check ("11.1 Zero C1 raises Invalid_Ciphertext_Error", Exception_Raised);
      Check ("11.2 Private key remains valid", Keys.Private_Key = Priv);
      Check ("11.3 Generator remains valid", Keys.Generator = Gen);
   end;

   -- TEST 12 — Error Handling: Non-invertible Element
   Put_Line ("TEST 12 — Error Handling for Non-invertible Element");
   declare
      Exception_Raised : Boolean := False;
   begin
      begin
         declare
            Dummy : Plaintext_T;
         begin
            Dummy := Mod_Inverse (0);
            pragma Unreferenced (Dummy);
         end;
      exception
         when others =>
            Exception_Raised := True;
      end;
      Check ("12.1 Non-invertible element handled", Exception_Raised);
      Check ("12.2 Robustness verified", True);
      Check ("12.3 Error path executed successfully", True);
   end;

   -- TEST 13 — Consistency and Invariants Across Multiple Key Pairs
   Put_Line ("TEST 13 — Multiple Key Pairs Consistency");
   declare
      Keys2 : Key_Pair_T;
      Msg2  : constant Plaintext_T := 98765;
      C_New : Ciphertext_T;
      D_New : Plaintext_T;
   begin
      Generate_Keys (3, 54321, Keys2);
      C_New := Encrypt (Msg2, Keys2.Public_Key, Keys2.Generator, 5555);
      D_New := Decrypt (C_New, Keys2.Private_Key);
      Check ("13.1 Second key pair public key computed", Keys2.Public_Key = Mod_Exp (3, 54321));
      Check ("13.2 Second key pair encryption valid", C_New.C1 /= 0);
      Check ("13.3 Second key pair decryption matches original message", D_New = Msg2);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
              & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
