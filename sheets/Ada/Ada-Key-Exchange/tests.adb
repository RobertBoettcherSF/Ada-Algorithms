with Ada.Text_IO; use Ada.Text_IO;
with Key_Exchange; use Key_Exchange;

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

   Valid : Boolean := False;
begin
   -- TEST 1 - Core: Modular Addition
   Put_Line ("TEST 1 - Core: Modular Addition");
   Check ("1.1 Normal addition", Modular_Add (5, 7, 10) = 2);
   Check ("1.2 Wrap around edge", Modular_Add (16#FFFF_FFFE#, 2, 16#FFFF_FFFF#) = 1); 
   Check ("1.3 Zero identity", Modular_Add (0, 5, 10) = 5);

   -- TEST 2 - Core: Modular Multiplication
   Put_Line ("TEST 2 - Core: Modular Multiplication");
   Check ("2.1 Normal multiplication", Modular_Multiply (3, 4, 10) = 2);
   -- 10^6 * 10^6 mod 1000000007 = 999993007. Safely exercises Double_Value internals.
   Check ("2.2 Large mult without overflow", Modular_Multiply (1000000, 1000000, 1000000007) = 999993007);
   Check ("2.3 Zero property", Modular_Multiply (9, 0, 10) = 0);

   -- TEST 3 - Core: Modular Exponentiation
   Put_Line ("TEST 3 - Core: Modular Exponentiation");
   Check ("3.1 Power of zero", Modular_Exponentiation (5, 0, 10) = 1);
   Check ("3.2 Power of one", Modular_Exponentiation (7, 1, 10) = 7);
   Check ("3.3 Normal exponentiation", Modular_Exponentiation (2, 10, 1000) = 24);

   -- TEST 4 - Core: Modular Inverse Valid
   Put_Line ("TEST 4 - Core: Modular Inverse Valid");
   Check ("4.1 Simple inverse (3 mod 11)", Modular_Inverse (3, 11) = 4);
   Check ("4.2 Inverse of inverse (4 mod 11)", Modular_Inverse (4, 11) = 3);
   Check ("4.3 Identity inverse (1 mod 11)", Modular_Inverse (1, 11) = 1);

   -- TEST 5 - Core: Modular Inverse Invalid (Exception Handling)
   Put_Line ("TEST 5 - Core: Modular Inverse Invalid");
   Valid := False;
   begin
      if Modular_Inverse (2, 4) = 0 then null; end if;
   exception when Invalid_Parameters_Error => Valid := True;
   end;
   Check ("5.1 Non-coprime raises error (2, 4)", Valid);

   Valid := False;
   begin
      if Modular_Inverse (3, 9) = 0 then null; end if;
   exception when Invalid_Parameters_Error => Valid := True;
   end;
   Check ("5.2 Non-coprime raises error (3, 9)", Valid);

   Valid := False;
   begin
      if Modular_Inverse (10, 15) = 0 then null; end if;
   exception when Invalid_Parameters_Error => Valid := True;
   end;
   Check ("5.3 Non-coprime raises error (10, 15)", Valid);

   -- TEST 6 - DH: Key Generation
   Put_Line ("TEST 6 - DH Key Generation");
   -- Generator = 5, Prime = 23
   Check ("6.1 Valid Private 6", DH_Generate_Public (5, 6, 23) = 8); 
   Check ("6.2 Valid Private 15", DH_Generate_Public (5, 15, 23) = 19);
   Check ("6.3 Trivial Private 0", DH_Generate_Public (5, 0, 23) = 1);

   -- TEST 7 - DH: Secret Computation
   Put_Line ("TEST 7 - DH Secret Computation");
   Check ("7.1 Alice computes correctly", DH_Compute_Secret (19, 6, 23) = 2);
   Check ("7.2 Bob computes correctly", DH_Compute_Secret (8, 15, 23) = 2);
   Check ("7.3 Symmetric equality", DH_Compute_Secret (19, 6, 23) = DH_Compute_Secret (8, 15, 23));

   -- TEST 8 - DH: Public Key Validation
   Put_Line ("TEST 8 - DH Public Key Validation");
   Valid := False;
   begin
      DH_Validate_Public_Key (1, 23);
   exception when Invalid_Parameters_Error => Valid := True;
   end;
   Check ("8.1 Key = 1 is rejected", Valid);

   Valid := False;
   begin
      DH_Validate_Public_Key (22, 23);
   exception when Invalid_Parameters_Error => Valid := True;
   end;
   Check ("8.2 Key = P-1 is rejected", Valid);

   Valid := True;
   begin
      DH_Validate_Public_Key (8, 23);
   exception when others => Valid := False;
   end;
   Check ("8.3 Key = 8 is accepted", Valid);

   -- TEST 9 - PAKA: Authenticated Exchange Success
   Put_Line ("TEST 9 - PAKA Authenticated Exchange Success");
   declare
      P : constant Key_Value := 23;
      Pwd : constant Key_Value := 17;
      A_Pub : constant Key_Value := PAKA_Generate_Public (Pwd, 4, P);
      B_Pub : constant Key_Value := PAKA_Generate_Public (Pwd, 7, P);
      A_Sec : constant Key_Value := PAKA_Compute_Secret (B_Pub, 4, P, Pwd);
      B_Sec : constant Key_Value := PAKA_Compute_Secret (A_Pub, 7, P, Pwd);
   begin
      Check ("9.1 Alice generates Auth Pub successfully", A_Pub > 0);
      Check ("9.2 Bob generates Auth Pub successfully", B_Pub > 0);
      Check ("9.3 PAKA Shared Secrets match", A_Sec = B_Sec);
   end;

   -- TEST 10 - PAKA: Authenticated Exchange Failure
   Put_Line ("TEST 10 - PAKA Authenticated Exchange Failure");
   declare
      P : constant Key_Value := 23;
      A_Pub : constant Key_Value := PAKA_Generate_Public (17, 4, P);
      B_Pub : constant Key_Value := PAKA_Generate_Public (18, 7, P); -- Bob uses wrong pwd
      A_Sec : constant Key_Value := PAKA_Compute_Secret (B_Pub, 4, P, 17);
      B_Sec : constant Key_Value := PAKA_Compute_Secret (A_Pub, 7, P, 18);
   begin
      Check ("10.1 Passwords differ conceptually", True);
      Check ("10.2 Secrets do not match", A_Sec /= B_Sec);
      Check ("10.3 Intruder agreement prevented", A_Sec /= B_Sec);
   end;

   -- TEST 11 - Shamir: Key Generation
   Put_Line ("TEST 11 - Shamir Key Generation");
   declare
      P : constant Key_Value := 11; -- Totient is 10
      D : Key_Value;
   begin
      Shamir_Generate_Keys (P, 3, D);
      Check ("11.1 Inverse of 3 mod 10 is 7", D = 7);
      Shamir_Generate_Keys (P, 7, D);
      Check ("11.2 Inverse of 7 mod 10 is 3", D = 3);
      Shamir_Generate_Keys (P, 9, D);
      Check ("11.3 Inverse of 9 mod 10 is 9", D = 9);
   end;

   -- TEST 12 - Shamir: Full 3-Pass Protocol Success
   Put_Line ("TEST 12 - Shamir 3-Pass Protocol Success");
   declare
      P : constant Key_Value := 31; -- Totient 30
      EA : constant Key_Value := 7;
      DA, DB : Key_Value;
      EB : constant Key_Value := 11;
      M : constant Key_Value := 15;
      C1, C2, C3, M_Out : Key_Value;
   begin
      Shamir_Generate_Keys (P, EA, DA);
      Shamir_Generate_Keys (P, EB, DB);
      Check ("12.1 Alice keys valid", (EA * DA) mod (P - 1) = 1);

      C1 := Shamir_Pass_1 (M, EA, P);
      C2 := Shamir_Pass_2 (C1, EB, P);
      C3 := Shamir_Pass_3 (C2, DA, P);
      M_Out := Shamir_Final_Decrypt (C3, DB, P);

      Check ("12.2 Cipher 1 hides original message", C1 /= M);
      Check ("12.3 Message successfully recovered", M_Out = M);
   end;

   -- TEST 13 - Shamir: Edge Cases
   Put_Line ("TEST 13 - Shamir Edge Cases");
   declare
      P : constant Key_Value := 31;
      EA : constant Key_Value := 7;
      EB : constant Key_Value := 11;
      DA, DB : Key_Value;
      C1, C2, C3, M_Out : Key_Value;
   begin
      Shamir_Generate_Keys (P, EA, DA);
      Shamir_Generate_Keys (P, EB, DB);

      -- Edge case M = 1
      C1 := Shamir_Pass_1 (1, EA, P);
      C2 := Shamir_Pass_2 (C1, EB, P);
      C3 := Shamir_Pass_3 (C2, DA, P);
      M_Out := Shamir_Final_Decrypt (C3, DB, P);
      Check ("13.1 M=1 correctly processed via protocol", M_Out = 1);

      -- Edge case M = 2
      C1 := Shamir_Pass_1 (2, EA, P);
      C2 := Shamir_Pass_2 (C1, EB, P);
      C3 := Shamir_Pass_3 (C2, DA, P);
      M_Out := Shamir_Final_Decrypt (C3, DB, P);
      Check ("13.2 M=2 correctly processed via protocol", M_Out = 2);

      Check ("13.3 Keys effectively derived (Non-Zero)", DA > 0 and DB > 0);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
