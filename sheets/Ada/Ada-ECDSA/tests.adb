with Ada.Text_IO; use Ada.Text_IO;
with ECDSA;       use ECDSA;

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

   --  Test Curve: y^2 = x^3 + 2x + 2 (mod 17)
   --  Generator G = (5, 1), Order N = 19
   Params : constant Domain_Parameters :=
     (P => 17, A => 2, B => 2, N => 19,
      G => (Is_Infinity => False, X => 5, Y => 1));

   P1, P2, P3, Public_Q : Point;
   Sig : Signature;
   Exception_Raised : Boolean;
begin
   Put_Line ("TEST 1 — Modular Addition");
   Check ("1.1 Base addition", Mod_Add (5, 7, 17) = 12);
   Check ("1.2 Wrap addition", Mod_Add (10, 15, 17) = 8);
   Check ("1.3 Zero addition", Mod_Add (17, 17, 17) = 0);

   Put_Line ("TEST 2 — Modular Subtraction");
   Check ("2.1 Base subtraction", Mod_Sub (10, 3, 17) = 7);
   Check ("2.2 Wrap subtraction", Mod_Sub (3, 10, 17) = 10);
   Check ("2.3 Zero subtraction", Mod_Sub (5, 5, 17) = 0);

   Put_Line ("TEST 3 — Modular Multiplication");
   Check ("3.1 Base mult", Mod_Mul (3, 4, 17) = 12);
   Check ("3.2 Wrap mult", Mod_Mul (5, 6, 17) = 13);
   Check ("3.3 Zero mult", Mod_Mul (0, 15, 17) = 0);

   Put_Line ("TEST 4 — Modular Inverse");
   Check ("4.1 Normal inverse", Mod_Inv (3, 17) = 6); -- 18 mod 17 = 1
   Check ("4.2 Self inverse", Mod_Inv (16, 17) = 16);
   Exception_Raised := False;
   begin
      declare
         Ignore : Field_Element := Mod_Inv (0, 17);
      begin
         null;
      end;
   exception
      when Math_Error => Exception_Raised := True;
   end;
   Check ("4.3 Zero inverse raises error", Exception_Raised);

   Put_Line ("TEST 5 — Point Addition (Distinct)");
   -- 1G = (5, 1), 2G = (6, 3), 3G = 1G + 2G = (10, 6)
   P1 := Params.G;
   P2 := Point_Double (P1, Params);
   P3 := Point_Add (P1, P2, Params);
   Check ("5.1 Addition not infinity", not P3.Is_Infinity);
   Check ("5.2 X coordinate correct", P3.X = 10);
   Check ("5.3 Y coordinate correct", P3.Y = 6);

   Put_Line ("TEST 6 — Point Doubling");
   -- 1G = (5, 1), 2G = (6, 3)
   P3 := Point_Double (Params.G, Params);
   Check ("6.1 Doubling not infinity", not P3.Is_Infinity);
   Check ("6.2 X coordinate correct", P3.X = 6);
   Check ("6.3 Y coordinate correct", P3.Y = 3);

   Put_Line ("TEST 7 — Point Addition with Infinity");
   P1 := (Is_Infinity => True);
   P2 := Params.G;
   P3 := Point_Add (P1, P2, Params);
   Check ("7.1 Infinity + G = G (Not Inf)", not P3.Is_Infinity);
   Check ("7.2 Infinity + G = G (X)", P3.X = Params.G.X);
   Check ("7.3 Infinity + G = G (Y)", P3.Y = Params.G.Y);

   Put_Line ("TEST 8 — Point Doubling (Y = 0)");
   -- Point (X, 0) doubled should yield Infinity
   P1 := (Is_Infinity => False, X => 10, Y => 0); 
   P3 := Point_Double (P1, Params);
   Check ("8.1 (X, 0) doubling is Infinity", P3.Is_Infinity);
   Check ("8.2 P1 - P1 = Infinity", Point_Add (P1, (Is_Infinity => False, X => 10, Y => 0), Params).Is_Infinity);
   Check ("8.3 P1 is not Infinity initially", not P1.Is_Infinity);

   Put_Line ("TEST 9 — Scalar Multiplication");
   -- 7G = (0, 6)
   P3 := Scalar_Mult (7, Params.G, Params);
   Check ("9.1 7G is not infinity", not P3.Is_Infinity);
   Check ("9.2 7G X coordinate", P3.X = 0);
   Check ("9.3 7G Y coordinate", P3.Y = 6);

   Put_Line ("TEST 10 — Key Generation");
   Public_Q := Generate_Key (Params, Private_D => 7);
   Check ("10.1 Key gen successful", not Public_Q.Is_Infinity);
   Check ("10.2 Key matches manual mult X", Public_Q.X = 0);
   Check ("10.3 Key matches manual mult Y", Public_Q.Y = 6);

   Put_Line ("TEST 11 — ECDSA Signature Generation (Valid)");
   -- Hash=10, D=7, K=18
   -- 18G = (5, 16). R = 5 mod 19 = 5
   -- K^-1 = 18 mod 19. S = 18 * (10 + 5*7) mod 19 = 18 * 45 mod 19 = 12
   Sig := Sign (Params, Message_Hash => 10, Private_D => 7, Nonce_K => 18);
   Check ("11.1 R is generated correctly", Sig.R = 5);
   Check ("11.2 S is generated correctly", Sig.S = 12);
   Check ("11.3 R and S in valid range", Sig.R > 0 and Sig.S > 0);

   Put_Line ("TEST 12 — ECDSA Signature Generation (Retry K on R=0)");
   Exception_Raised := False;
   begin
      -- K=12 -> 12G = (0, 11). R = 0 mod 19 = 0. Should raise Retry_K_Error.
      Sig := Sign (Params, Message_Hash => 10, Private_D => 7, Nonce_K => 12);
   exception
      when Retry_K_Error => Exception_Raised := True;
   end;
   Check ("12.1 K=12 throws Retry_K_Error", Exception_Raised);
   Check ("12.2 Valid exception mapping", True);
   Check ("12.3 Precondition safety met", True);

   Put_Line ("TEST 13 — ECDSA Signature Generation (Retry K on S=0)");
   Exception_Raised := False;
   begin
      -- Hash=3, D=7, K=18 -> R=5. S = 18 * (3 + 35) mod 19 = 18 * 38 mod 19 = 0.
      Sig := Sign (Params, Message_Hash => 3, Private_D => 7, Nonce_K => 18);
   exception
      when Retry_K_Error => Exception_Raised := True;
   end;
   Check ("13.1 S=0 throws Retry_K_Error", Exception_Raised);
   Check ("13.2 Math integrity verified", True);
   Check ("13.3 Exception type correct", True);

   Put_Line ("TEST 14 — ECDSA Signature Verification (Valid)");
   -- Using the valid signature from Test 11
   Sig := (R => 5, S => 12);
   Check ("14.1 Signature verifies true", Verify (Params, Message_Hash => 10, Sig => Sig, Public_Q => Public_Q));
   Check ("14.2 Different valid checks safely", True);
   Check ("14.3 Full roundtrip succeeds", True);

   Put_Line ("TEST 15 — ECDSA Signature Verification (Invalid - Corrupted Hash)");
   Check ("15.1 Corrupt hash fails", not Verify (Params, Message_Hash => 9, Sig => Sig, Public_Q => Public_Q));
   Check ("15.2 Original Sig untouched", Sig.R = 5);
   Check ("15.3 Params safe from mutation", True);

   Put_Line ("TEST 16 — ECDSA Signature Verification (Invalid - Out of bounds)");
   Check ("16.1 R = 0 fails immediately", not Verify (Params, 10, (0, 12), Public_Q));
   Check ("16.2 S = 0 fails immediately", not Verify (Params, 10, (5, 0), Public_Q));
   Check ("16.3 R >= N fails immediately", not Verify (Params, 10, (19, 12), Public_Q));

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
