with Ada.Text_IO; use Ada.Text_IO;
with Elliptic_Curve_Cryptography; use Elliptic_Curve_Cryptography;

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

   --  Test configuration: Curve C1: y^2 = x^3 + 2x + 2 mod 17
   C1 : constant Curve_Parameters := (P => 17, A => 2, B => 2);
   P1 : constant Point := (Kind => Affine, X => 0, Y => 6);
   P2 : constant Point := (Kind => Affine, X => 9, Y => 1);
   P3 : constant Point := (Kind => Affine, X => 6, Y => 3);
   Inf : constant Point := (Kind => Infinity);
   Bad_Pt : constant Point := (Kind => Affine, X => 0, Y => 5);

   --  Test configuration: Curve C2: y^2 = x^3 - x mod 11 => x^3 + 10x + 0 mod 11
   C2 : constant Curve_Parameters := (P => 11, A => 10, B => 0);
   C2_Pt1 : constant Point := (Kind => Affine, X => 1, Y => 0);

   --  Test configuration: Invalid Curve
   Bad_C : constant Curve_Parameters := (P => 17, A => 0, B => 0);

begin
   -- TEST 1 — Curve Validation
   Put_Line ("TEST 1 — Curve Validation");
   Check ("1.1 Valid curve C1 is accepted", Is_Valid_Curve (C1));
   Check ("1.2 Valid curve C2 is accepted", Is_Valid_Curve (C2));
   Check ("1.3 Invalid curve Bad_C is rejected", not Is_Valid_Curve (Bad_C));

   -- TEST 2 — Point on Curve Verification
   Put_Line ("TEST 2 — Point on Curve Verification");
   Check ("2.1 Inf is always on curve", Is_On_Curve (C1, Inf));
   Check ("2.2 Valid point P1 is on C1", Is_On_Curve (C1, P1));
   Check ("2.3 Invalid point Bad_Pt is not on C1", not Is_On_Curve (C1, Bad_Pt));

   -- TEST 3 — Modular Inverse Positive Cases
   Put_Line ("TEST 3 — Modular Inverse Positive Cases");
   Check ("3.1 Inv(12, 17) = 10", Modular_Inverse (12, 17) = 10);
   Check ("3.2 Inv(9, 17) = 2", Modular_Inverse (9, 17) = 2);
   Check ("3.3 Inv(1, 17) = 1", Modular_Inverse (1, 17) = 1);

   -- TEST 4 — Modular Inverse Exceptions
   Put_Line ("TEST 4 — Modular Inverse Exceptions");
   declare
      Failed : Boolean := False;
   begin
      begin
         if Modular_Inverse (17, 17) = 0 then
            null;
         end if;
      exception
         when Not_Invertible_Error => Failed := True;
      end;
      Check ("4.1 Inv(17, 17) raises error", Failed);

      Failed := False;
      begin
         if Modular_Inverse (2, 4) = 0 then
            null;
         end if;
      exception
         when Not_Invertible_Error => Failed := True;
      end;
      Check ("4.2 Inv(2, 4) raises error", Failed);

      Failed := False;
      begin
         if Modular_Inverse (0, 11) = 0 then
            null;
         end if;
      exception
         when Not_Invertible_Error => Failed := True;
      end;
      Check ("4.3 Inv(0, 11) raises error", Failed);
   end;

   -- TEST 5 — Point Addition with Infinity (Identity)
   Put_Line ("TEST 5 — Point Addition with Infinity (Identity)");
   Check ("5.1 P1 + Inf = P1", Point_Add (C1, P1, Inf) = P1);
   Check ("5.2 Inf + P1 = P1", Point_Add (C1, Inf, P1) = P1);
   Check ("5.3 Inf + Inf = Inf", Point_Add (C1, Inf, Inf) = Inf);

   -- TEST 6 — Point Addition of Inverses (P + (-P) = O)
   Put_Line ("TEST 6 — Point Addition of Inverses");
   declare
      Neg_P1 : constant Point := (Kind => Affine, X => 0, Y => 11); -- 17 - 6 = 11
   begin
      Check ("6.1 Neg_P1 is on curve", Is_On_Curve (C1, Neg_P1));
      Check ("6.2 P1 + Neg_P1 = Inf", Point_Add (C1, P1, Neg_P1) = Inf);
      Check ("6.3 Neg_P1 + P1 = Inf", Point_Add (C1, Neg_P1, P1) = Inf);
   end;

   -- TEST 7 — Point Addition of Distinct Points
   Put_Line ("TEST 7 — Point Addition of Distinct Points");
   Check ("7.1 P1 + P2 = P3", Point_Add (C1, P1, P2) = P3);
   Check ("7.2 P2 + P1 = P3", Point_Add (C1, P2, P1) = P3);
   Check ("7.3 P3 + Inf = P3", Point_Add (C1, P3, Inf) = P3);

   -- TEST 8 — Point Doubling
   Put_Line ("TEST 8 — Point Doubling");
   Check ("8.1 Double(Inf) = Inf", Point_Double (C1, Inf) = Inf);
   Check ("8.2 Double(P1) = P2", Point_Double (C1, P1) = P2);
   declare
      P4 : constant Point := Point_Double (C1, P2);
   begin
      Check ("8.3 Double(P2) is on curve", Is_On_Curve (C1, P4));
   end;

   -- TEST 9 — Point Doubling with Y = 0
   Put_Line ("TEST 9 — Point Doubling with Y = 0");
   Check ("9.1 C2_Pt1 is on C2", Is_On_Curve (C2, C2_Pt1));
   Check ("9.2 C2_Pt1 has Y = 0", C2_Pt1.Y = 0);
   Check ("9.3 Double(C2_Pt1) = Inf", Point_Double (C2, C2_Pt1) = Inf);

   -- TEST 10 — Scalar Multiplication (Base Cases)
   Put_Line ("TEST 10 — Scalar Multiplication (Base Cases)");
   Check ("10.1 0 * P1 = Inf", Scalar_Multiply (C1, 0, P1) = Inf);
   Check ("10.2 1 * P1 = P1", Scalar_Multiply (C1, 1, P1) = P1);
   Check ("10.3 2 * P1 = Double(P1)", Scalar_Multiply (C1, 2, P1) = P2);

   -- TEST 11 — Scalar Multiplication (Chain Validation)
   Put_Line ("TEST 11 — Scalar Multiplication (Chain Validation)");
   Check ("11.1 3 * P1 = P3", Scalar_Multiply (C1, 3, P1) = P3);
   declare
      P4 : constant Point := Scalar_Multiply (C1, 4, P1);
   begin
      Check ("11.2 4 * P1 is on curve", Is_On_Curve (C1, P4));
      Check ("11.3 4 * P1 = P1 + P3", P4 = Point_Add (C1, P1, P3));
   end;

   -- TEST 12 — Diffie-Hellman Key Exchange Simulation
   Put_Line ("TEST 12 — Diffie-Hellman Key Exchange Simulation");
   declare
      Alice_Priv : constant Field_Element := 5;
      Bob_Priv   : constant Field_Element := 7;
      Alice_Pub  : constant Point := Scalar_Multiply (C1, Alice_Priv, P1);
      Bob_Pub    : constant Point := Scalar_Multiply (C1, Bob_Priv, P1);
      Alice_Shared : constant Point := Scalar_Multiply (C1, Alice_Priv, Bob_Pub);
      Bob_Shared   : constant Point := Scalar_Multiply (C1, Bob_Priv, Alice_Pub);
   begin
      Check ("12.1 Alice and Bob public keys are on curve",
             Is_On_Curve (C1, Alice_Pub) and Is_On_Curve (C1, Bob_Pub));
      Check ("12.2 Shared secrets are on curve",
             Is_On_Curve (C1, Alice_Shared));
      Check ("12.3 Shared secrets match", Alice_Shared = Bob_Shared);
   end;

   -- TEST 13 — Large/Random Scalar Multiplier Integrity
   Put_Line ("TEST 13 — High Scalar Multiplication Validation");
   declare
      Large_Scalar : constant Field_Element := 18;
      Pt : constant Point := Scalar_Multiply (C1, Large_Scalar, P1);
      Double_Pt : constant Point := Point_Double (C1, Pt);
      Add_Pt : constant Point := Point_Add (C1, Pt, Pt);
   begin
      Check ("13.1 Point remains on curve for large scalar", Is_On_Curve (C1, Pt));
      Check ("13.2 Double(k*P) = (k*P) + (k*P)", Double_Pt = Add_Pt);
      Check ("13.3 Result is valid under curve params",
             Pt.Kind = Infinity or else (Pt.X < C1.P and Pt.Y < C1.P));
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
