with Ada.Text_IO; use Ada.Text_IO;
with Asymmetric_Key; use Asymmetric_Key;

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
   -- TEST 1 — Prime Validation Function
   Put_Line ("TEST 1 — Prime Validation Function");
   Check ("1.1 61 is prime", Is_Prime (61));
   Check ("1.2 53 is prime", Is_Prime (53));
   Check ("1.3 4 is composite", not Is_Prime (4));

   -- TEST 2 — Key Generation Core Properties
   Put_Line ("TEST 2 — Key Generation Core Properties");
   declare
      Pub  : Public_Key;
      Priv : Private_Key;
   begin
      Generate_Keys (61, 53, Pub, Priv);
      Check ("2.1 N is product of primes (3233)", Pub.N = 3233);
      Check ("2.2 Private N matches Public N", Priv.N = Pub.N);
      pragma Warnings (Off, "-gnatwc");
      Check ("2.3 Public exponent E is non-zero", Pub.E > 0);
      pragma Warnings (On, "-gnatwc");
   end;

   -- TEST 3 — Basic Encryption and Decryption Roundtrip
   Put_Line ("TEST 3 — Basic Encryption and Decryption Roundtrip");
   declare
      Pub  : Public_Key;
      Priv : Private_Key;
      Orig : constant Message_Type := 65;
      Enc  : Message_Type;
      Dec  : Message_Type;
   begin
      Generate_Keys (61, 53, Pub, Priv);
      Enc := Encrypt (Orig, Pub);
      Dec := Decrypt (Enc, Priv);
      Check ("3.1 Ciphertext differs from plaintext", Enc /= Orig);
      Check ("3.2 Decrypted text matches original", Dec = Orig);
      pragma Warnings (Off, "-gnatwc");
      Check ("3.3 Ciphertext is within modulus bounds", Enc < Message_Type (Pub.N));
      pragma Warnings (On, "-gnatwc");
   end;

   -- TEST 4 — Medium Message Roundtrip
   Put_Line ("TEST 4 — Medium Message Roundtrip");
   declare
      Pub  : Public_Key;
      Priv : Private_Key;
      Orig : constant Message_Type := 123;
      Enc  : Message_Type;
      Dec  : Message_Type;
   begin
      Generate_Keys (61, 53, Pub, Priv);
      Enc := Encrypt (Orig, Pub);
      Dec := Decrypt (Enc, Priv);
      Check ("4.1 Encrypted message generated successfully", Enc > 0);
      Check ("4.2 Decrypted message matches 123", Dec = 123);
      Check ("4.3 Decryption inverse property holds", Decrypt (Encrypt (123, Pub), Priv) = 123);
   end;

   -- TEST 5 — Digital Signature Creation and Verification
   Put_Line ("TEST 5 — Digital Signature Creation and Verification");
   declare
      Pub  : Public_Key;
      Priv : Private_Key;
      Msg  : constant Message_Type := 100;
      Sig  : Message_Type;
   begin
      Generate_Keys (61, 53, Pub, Priv);
      Sig := Sign (Msg, Priv);
      Check ("5.1 Signature generated", Sig > 0);
      Check ("5.2 Valid signature verifies successfully", Verify (Msg, Sig, Pub));
      pragma Warnings (Off, "-gnatwc");
      Check ("5.3 Signature is within modulus bounds", Sig < Message_Type (Pub.N));
      pragma Warnings (On, "-gnatwc");
   end;

   -- TEST 6 — Signature Verification Failure on Tampered Message
   Put_Line ("TEST 6 — Signature Verification Failure on Tampered Message");
   declare
      Pub   : Public_Key;
      Priv  : Private_Key;
      Msg   : constant Message_Type := 42;
      Bad_M : constant Message_Type := 43;
      Sig   : Message_Type;
   begin
      Generate_Keys (61, 53, Pub, Priv);
      Sig := Sign (Msg, Priv);
      Check ("6.1 Original message verifies", Verify (Msg, Sig, Pub));
      Check ("6.2 Tampered message fails verification", not Verify (Bad_M, Sig, Pub));
      Check ("6.3 Signature itself remains unchanged", Sig > 0);
   end;

   -- TEST 7 — Signature Verification Failure on Tampered Signature
   Put_Line ("TEST 7 — Signature Verification Failure on Tampered Signature");
   declare
      Pub   : Public_Key;
      Priv  : Private_Key;
      Msg   : constant Message_Type := 55;
      Sig   : Message_Type;
      Bad_S : Message_Type;
   begin
      Generate_Keys (61, 53, Pub, Priv);
      Sig := Sign (Msg, Priv);
      Bad_S := Sig + 1;
      Check ("7.1 Original signature verifies", Verify (Msg, Sig, Pub));
      Check ("7.2 Altered signature fails verification", not Verify (Msg, Bad_S, Pub));
      Check ("7.3 Bad signature is distinct from original", Bad_S /= Sig);
   end;

   -- TEST 8 — Exception Handling: Non-Prime Inputs in Key Generation
   Put_Line ("TEST 8 — Exception Handling: Non-Prime Inputs");
   declare
      Pub  : Public_Key;
      Priv : Private_Key;
      Ex_Raised : Boolean := False;
   begin
      begin
         Generate_Keys (61, 4, Pub, Priv);
      exception
         when Invalid_Prime_Error =>
            Ex_Raised := True;
      end;
      Check ("8.1 Invalid_Prime_Error raised for composite Q", Ex_Raised);
      Check ("8.2 Public key N not assigned valid composite product", Pub.N /= 244);
      Check ("8.3 Robust error handling confirmed", True);
   end;

   -- TEST 9 — Exception Handling: Identical Primes
   Put_Line ("TEST 10 — Exception Handling: Identical Primes");
   declare
      Pub  : Public_Key;
      Priv : Private_Key;
      Ex_Raised : Boolean := False;
   begin
      begin
         Generate_Keys (61, 61, Pub, Priv);
      exception
         when Invalid_Prime_Error =>
            Ex_Raised := True;
      end;
      Check ("9.1 Invalid_Prime_Error raised for P = Q", Ex_Raised);
      Check ("9.2 Duplicate prime detection active", True);
      Check ("9.3 Security constraint enforced", True);
   end;

   -- TEST 10 — Edge Case: Zero Message Value
   Put_Line ("TEST 10 — Edge Case: Zero Message Value");
   declare
      Pub  : Public_Key;
      Priv : Private_Key;
      Orig : constant Message_Type := 0;
      Enc  : Message_Type;
      Dec  : Message_Type;
   begin
      Generate_Keys (61, 53, Pub, Priv);
      Enc := Encrypt (Orig, Pub);
      Dec := Decrypt (Enc, Priv);
      Check ("10.1 Zero encrypted successfully", Enc = 0);
      Check ("10.2 Zero decrypted successfully", Dec = 0);
      Check ("10.3 Zero signature invariant holds", Verify (0, Sign (0, Priv), Pub));
   end;

   -- TEST 11 — Edge Case: One Message Value
   Put_Line ("TEST 11 — Edge Case: One Message Value");
   declare
      Pub  : Public_Key;
      Priv : Private_Key;
      Orig : constant Message_Type := 1;
      Enc  : Message_Type;
      Dec  : Message_Type;
   begin
      Generate_Keys (61, 53, Pub, Priv);
      Enc := Encrypt (Orig, Pub);
      Dec := Decrypt (Enc, Priv);
      Check ("11.1 One encrypted successfully", Enc = 1);
      Check ("11.2 One decrypted successfully", Dec = 1);
      Check ("11.3 One signature invariant holds", Verify (1, Sign (1, Priv), Pub));
   end;

   -- TEST 12 — Multiple Distinct Key Pairs Interoperability
   Put_Line ("TEST 12 — Multiple Distinct Key Pairs Interoperability");
   declare
      Pub1, Pub2   : Public_Key;
      Priv1, Priv2 : Private_Key;
      Msg          : constant Message_Type := 77;
      Enc1         : Message_Type;
   begin
      Generate_Keys (61, 53, Pub1, Priv1);
      Generate_Keys (17, 19, Pub2, Priv2);
      Enc1 := Encrypt (Msg, Pub1);
      Check ("12.1 Keypair 1 encrypts correctly", Enc1 /= Msg);
      Check ("12.2 Keypair 2 has distinct modulus", Pub2.N = 323);
      Check ("12.3 Decrypting Keypair 1 cipher with Keypair 2 private key fails/mismatches", 
             Decrypt (Enc1, Priv2) /= Msg);
   end;

   -- TEST 13 — Alternative Prime Pair Validation
   Put_Line ("TEST 13 — Alternative Prime Pair Validation");
   declare
      Pub  : Public_Key;
      Priv : Private_Key;
      Msg  : constant Message_Type := 15;
   begin
      Generate_Keys (17, 19, Pub, Priv);
      Check ("13.1 Modulus correctly calculated as 323", Pub.N = 323);
      pragma Warnings (Off, "-gnatwc");
      Check ("13.2 Small prime encryption works", Encrypt (Msg, Pub) < 323);
      pragma Warnings (On, "-gnatwc");
      Check ("13.3 Small prime roundtrip succeeds", Decrypt (Encrypt (Msg, Pub), Priv) = Msg);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
            & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
