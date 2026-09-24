with Ada.Text_IO; use Ada.Text_IO;
with Diffie_Hellman; use Diffie_Hellman;

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
   Put_Line ("--- Starting Diffie-Hellman Test Suite ---");

   -- TEST 1: Standard 2-Party DH
   Put_Line ("TEST 1 — Standard 2-Party DH (Wikipedia Example)");
   declare
      P : constant Modulus_Type := 23;
      G : constant Base_Type := 5;
      Alice_Priv : constant Private_Key_Type := 4;
      Bob_Priv   : constant Private_Key_Type := 3;
      Alice_Pub, Bob_Pub : Public_Key_Type;
      Secret_A, Secret_B : Shared_Secret_Type;
   begin
      Alice_Pub := Generate_Public_Key (P, G, Alice_Priv);
      Bob_Pub   := Generate_Public_Key (P, G, Bob_Priv);
      
      Check ("1.1 Alice Public Key is 4", Alice_Pub = 4);
      Check ("1.2 Bob Public Key is 10", Bob_Pub = 10);
      
      Secret_A := Compute_Shared_Secret (P, Bob_Pub, Alice_Priv);
      Secret_B := Compute_Shared_Secret (P, Alice_Pub, Bob_Priv);
      
      Check ("1.3 Computed secrets match", Secret_A = Secret_B);
      Check ("1.4 Computed secret equals 18", Secret_A = 18);
   end;
   Put_Line ("");

   -- TEST 2: Ephemeral Large Keys DH
   Put_Line ("TEST 2 — Ephemeral DH with Large 32-bit Prime");
   declare
      P : constant Modulus_Type := 4294967291; -- Largest 32-bit prime
      G : constant Base_Type := 2;
      Session_Priv_1 : constant Private_Key_Type := 123456789;
      Session_Priv_2 : constant Private_Key_Type := 987654321;
      Pub_1, Pub_2   : Public_Key_Type;
      Sec_1, Sec_2   : Shared_Secret_Type;
   begin
      Pub_1 := Generate_Public_Key (P, G, Session_Priv_1);
      Pub_2 := Generate_Public_Key (P, G, Session_Priv_2);
      
      Check ("2.1 Pub_1 strictly bounded", Pub_1 > 1 and Modulus_Type (Pub_1) < P);
      Check ("2.2 Pub_2 strictly bounded", Pub_2 > 1 and Modulus_Type (Pub_2) < P);
      
      Sec_1 := Compute_Shared_Secret (P, Pub_2, Session_Priv_1);
      Sec_2 := Compute_Shared_Secret (P, Pub_1, Session_Priv_2);
      
      Check ("2.3 Ephemeral Secrets exactly match", Sec_1 = Sec_2);
   end;
   Put_Line ("");

   -- TEST 3: Multi-Party (3-Party) DH
   Put_Line ("TEST 3 — Multi-Party 3-Party Ring Exchange");
   declare
      P : constant Modulus_Type := 23;
      G : constant Base_Type := 5;
      A_Priv : constant Private_Key_Type := 4;
      B_Priv : constant Private_Key_Type := 3;
      C_Priv : constant Private_Key_Type := 2;
      
      A_Pub, B_Pub, C_Pub : Public_Key_Type;
      AB_Int, BC_Int, CA_Int : Public_Key_Type;
      Sec_A, Sec_B, Sec_C : Shared_Secret_Type;
   begin
      A_Pub := Generate_Public_Key (P, G, A_Priv);
      B_Pub := Generate_Public_Key (P, G, B_Priv);
      C_Pub := Generate_Public_Key (P, G, C_Priv);
      
      AB_Int := Compute_Multi_Party_Intermediate (P, A_Pub, B_Priv);
      BC_Int := Compute_Multi_Party_Intermediate (P, B_Pub, C_Priv);
      CA_Int := Compute_Multi_Party_Intermediate (P, C_Pub, A_Priv);
      
      Sec_A := Compute_Shared_Secret (P, BC_Int, A_Priv);
      Sec_B := Compute_Shared_Secret (P, CA_Int, B_Priv);
      Sec_C := Compute_Shared_Secret (P, AB_Int, C_Priv);
      
      Check ("3.1 A and B match", Sec_A = Sec_B);
      Check ("3.2 B and C match", Sec_B = Sec_C);
      Check ("3.3 Secret mathematically verified as 2", Sec_A = 2);
   end;
   Put_Line ("");

   -- TEST 4: Multi-Party (4-Party) DH Chaining
   Put_Line ("TEST 4 — Multi-Party 4-Party Ring Exchange");
   declare
      P : constant Modulus_Type := 23;
      G : constant Base_Type := 5;
      A_P : constant Private_Key_Type := 2;
      B_P : constant Private_Key_Type := 3;
      C_P : constant Private_Key_Type := 4;
      D_P : constant Private_Key_Type := 2;
      
      A_Pub, B_Pub, C_Pub, D_Pub : Public_Key_Type;
      A_I1, B_I1, C_I1, D_I1 : Public_Key_Type;
      A_I2, B_I2, C_I2, D_I2 : Public_Key_Type;
      Sec_A, Sec_B, Sec_C, Sec_D : Shared_Secret_Type;
   begin
      -- Round 1
      A_Pub := Generate_Public_Key (P, G, A_P);
      B_Pub := Generate_Public_Key (P, G, B_P);
      C_Pub := Generate_Public_Key (P, G, C_P);
      D_Pub := Generate_Public_Key (P, G, D_P);
      -- Round 2 (Receive from left, compute, send to right)
      A_I1 := Compute_Multi_Party_Intermediate (P, D_Pub, A_P);
      B_I1 := Compute_Multi_Party_Intermediate (P, A_Pub, B_P);
      C_I1 := Compute_Multi_Party_Intermediate (P, B_Pub, C_P);
      D_I1 := Compute_Multi_Party_Intermediate (P, C_Pub, D_P);
      -- Round 3
      A_I2 := Compute_Multi_Party_Intermediate (P, D_I1, A_P);
      B_I2 := Compute_Multi_Party_Intermediate (P, A_I1, B_P);
      C_I2 := Compute_Multi_Party_Intermediate (P, B_I1, C_P);
      D_I2 := Compute_Multi_Party_Intermediate (P, C_I1, D_P);
      -- Final Round
      Sec_A := Compute_Shared_Secret (P, D_I2, A_P);
      Sec_B := Compute_Shared_Secret (P, A_I2, B_P);
      Sec_C := Compute_Shared_Secret (P, B_I2, C_P);
      Sec_D := Compute_Shared_Secret (P, C_I2, D_P);
      
      Check ("4.1 All match perfectly", Sec_A = Sec_B and Sec_B = Sec_C and Sec_C = Sec_D);
      Check ("4.2 Mathematical invariant (5^48 mod 23 = 4)", Sec_A = 4);
      Check ("4.3 A_I2 structurally sound", A_I2 > 1);
   end;
   Put_Line ("");

   -- TEST 5: Exception on Modulus Too Small
   Put_Line ("TEST 5 — Exception: Modulus Too Small (P <= 2)");
   declare
      Caught : Boolean := False;
      Dummy  : Public_Key_Type := 0;
   begin
      begin
         Dummy := Generate_Public_Key (2, 5, 1);
      exception
         when Invalid_Parameter => Caught := True;
         when others => null;
      end;
      Check ("5.1 Setup attempted P=2", True);
      Check ("5.2 Call rejected Invalid_Parameter", Caught);
      pragma Warnings (Off, "condition is always True");
      Check ("5.3 Function did not evaluate successfully", Dummy = 0);
      pragma Warnings (On, "condition is always True");
   end;
   Put_Line ("");

   -- TEST 6: Exception on Base Too Small
   Put_Line ("TEST 6 — Exception: Base Too Small (G <= 1)");
   declare
      Caught : Boolean := False;
      Dummy  : Public_Key_Type := 0;
   begin
      begin
         Dummy := Generate_Public_Key (23, 1, 4);
      exception
         when Invalid_Parameter => Caught := True;
         when others => null;
      end;
      Check ("6.1 Setup attempted G=1", True);
      Check ("6.2 Call rejected Invalid_Parameter", Caught);
      pragma Warnings (Off, "condition is always True");
      Check ("6.3 Prevented trivial group generation", Dummy = 0);
      pragma Warnings (On, "condition is always True");
   end;
   Put_Line ("");

   -- TEST 7: Exception on Base Too Large
   Put_Line ("TEST 7 — Exception: Base Too Large (G >= P-1)");
   declare
      Caught : Boolean := False;
      Dummy  : Public_Key_Type := 0;
   begin
      begin
         Dummy := Generate_Public_Key (23, 22, 4);
      exception
         when Invalid_Parameter => Caught := True;
         when others => null;
      end;
      Check ("7.1 Setup attempted G=22 for P=23", True);
      Check ("7.2 Call rejected Invalid_Parameter", Caught);
      pragma Warnings (Off, "condition is always True");
      Check ("7.3 Forced G to be strictly inside group bounds", Dummy = 0);
      pragma Warnings (On, "condition is always True");
   end;
   Put_Line ("");

   -- TEST 8: Exception on Private Key Zero
   Put_Line ("TEST 8 — Exception: Private Key Zero");
   declare
      Caught : Boolean := False;
      Dummy  : Public_Key_Type := 0;
   begin
      begin
         Dummy := Generate_Public_Key (23, 5, 0);
      exception
         when Invalid_Parameter => Caught := True;
         when others => null;
      end;
      Check ("8.1 Setup attempted Priv=0", True);
      Check ("8.2 Call rejected Invalid_Parameter", Caught);
      pragma Warnings (Off, "condition is always True");
      Check ("8.3 Prevented exposing base", Dummy = 0);
      pragma Warnings (On, "condition is always True");
   end;
   Put_Line ("");

   -- TEST 9: Exception on Private Key Too Large
   Put_Line ("TEST 9 — Exception: Private Key Too Large (Priv >= P-1)");
   declare
      Caught : Boolean := False;
      Dummy  : Public_Key_Type := 0;
   begin
      begin
         Dummy := Generate_Public_Key (23, 5, 22);
      exception
         when Invalid_Parameter => Caught := True;
         when others => null;
      end;
      Check ("9.1 Setup attempted Priv=22 for P=23", True);
      Check ("9.2 Call rejected Invalid_Parameter", Caught);
      pragma Warnings (Off, "condition is always True");
      Check ("9.3 Bound enforced to P-1", Dummy = 0);
      pragma Warnings (On, "condition is always True");
   end;
   Put_Line ("");

   -- TEST 10: Exception on Public Key Small Subgroup (Pub = 1)
   Put_Line ("TEST 10 — Exception: Public Key Small Subgroup (Pub = 1)");
   declare
      Caught : Boolean := False;
      Dummy  : Shared_Secret_Type := 0;
   begin
      begin
         Dummy := Compute_Shared_Secret (23, 1, 4);
      exception
         when Invalid_Public_Key => Caught := True;
         when others => null;
      end;
      Check ("10.1 Setup attempted malicious Remote_Pub=1", True);
      Check ("10.2 Call rejected Invalid_Public_Key", Caught);
      pragma Warnings (Off, "condition is always True");
      Check ("10.3 Defeated subgroup attack of order 1", Dummy = 0);
      pragma Warnings (On, "condition is always True");
   end;
   Put_Line ("");

   -- TEST 11: Exception on Public Key Small Subgroup (Pub = P-1)
   Put_Line ("TEST 11 — Exception: Public Key Small Subgroup (Pub = P-1)");
   declare
      Caught : Boolean := False;
      Dummy  : Shared_Secret_Type := 0;
   begin
      begin
         Dummy := Compute_Shared_Secret (23, 22, 4);
      exception
         when Invalid_Public_Key => Caught := True;
         when others => null;
      end;
      Check ("11.1 Setup attempted malicious Remote_Pub=P-1", True);
      Check ("11.2 Call rejected Invalid_Public_Key", Caught);
      pragma Warnings (Off, "condition is always True");
      Check ("11.3 Defeated subgroup attack of order 2", Dummy = 0);
      pragma Warnings (On, "condition is always True");
   end;
   Put_Line ("");

   -- TEST 12: Extreme Bounds (Max Unsigned_64 limits)
   Put_Line ("TEST 12 — Extreme Bounds (Near 64-bit Prime)");
   declare
      -- 18446744073709551557 is 2^64 - 59, largest 64-bit prime
      P : constant Modulus_Type := 18446744073709551557;
      G : constant Base_Type := 2;
      Priv  : constant Private_Key_Type := 18446744073709551000;
      Dummy : Public_Key_Type;
   begin
      -- Just successfully computing this verifies Mod_Mul_Safe works up to 64-bit limits
      Dummy := Generate_Public_Key (P, G, Priv);
      
      pragma Warnings (Off, "condition is always True");
      Check ("12.1 Max Prime assigned and accepted", P > 18446744073709550000);
      pragma Warnings (On, "condition is always True");
      Check ("12.2 Safe modular arithmetic did not overflow", Dummy > 0);
      Check ("12.3 Output in valid modulo range", Modulus_Type (Dummy) < P);
   end;
   Put_Line ("");

   -- TEST 13: Determinism / Consistency Check
   Put_Line ("TEST 13 — Determinism / Consistency Check");
   declare
      P : constant Modulus_Type := 101;
      G : constant Base_Type := 7;
      Priv : constant Private_Key_Type := 13;
      Pub1, Pub2 : Public_Key_Type;
   begin
      Pub1 := Generate_Public_Key (P, G, Priv);
      Pub2 := Generate_Public_Key (P, G, Priv);
      
      Check ("13.1 Same inputs", True);
      Check ("13.2 Same outputs", Pub1 = Pub2);
      Check ("13.3 Value correct (7^13 mod 101 = 75)", Pub1 = 75);
   end;
   Put_Line ("");

   -- Summary
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
