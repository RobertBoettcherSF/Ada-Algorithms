with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics.Big_Numbers.Big_Integers; use Ada.Numerics.Big_Numbers.Big_Integers;
with Eddsa; use Eddsa;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS -- " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL -- " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   Curve    : constant Curve_Parameters := Get_Ed25519_Curve;
   Neutral  : constant Point := (X => To_Big_Integer (0), Y => To_Big_Integer (1));
   Sec_Key  : constant String := "super_secret_key_12345";
   Msg      : constant String := "Hello, EdDSA variant implementations!";
   Context  : constant String := "Test_Environment";
   
   Pub_Key  : Point;
   Sig      : Signature;
   Sig_H    : Signature;
   Sig_C    : Signature;
begin
   Put_Line ("TEST 1 -- Curve Initialization & Structure Validations");
   Check ("1.1 Generator point validates on curve", Is_On_Curve (Curve, Curve.B));
   Check ("1.2 Curve coefficient A mathematically -1 mod P", Curve.A = (Curve.P - To_Big_Integer (1)));
   Check ("1.3 Neutral point (0,1) validates on curve", Is_On_Curve (Curve, Neutral));

   Put_Line ("TEST 2 -- Key Generation Determinism");
   Pub_Key := Generate_Public_Key (Curve, Sec_Key);
   Check ("2.1 Derive public key maps to valid point", Is_On_Curve (Curve, Pub_Key));
   Check ("2.2 Differing secret yields differing public point",
          Pub_Key.X /= Generate_Public_Key (Curve, "other_secret").X);
   Check ("2.3 Same secret yields consistent public point",
          Pub_Key.X = Generate_Public_Key (Curve, Sec_Key).X);

   Put_Line ("TEST 3 -- Pure EdDSA Positive Cases");
   Sig := Sign_Pure (Curve, Msg, Sec_Key);
   Check ("3.1 Output R signature fragment is on curve", Is_On_Curve (Curve, Sig.R));
   Check ("3.2 Generated scalar S falls strictly under order L", Sig.S < Curve.L);
   Check ("3.3 Signature validates mathematically successfully", Verify_Pure (Curve, Msg, Pub_Key, Sig));

   Put_Line ("TEST 4 -- Pure EdDSA Forgery Restrictions");
   Check ("4.1 Signature fails on altered message content", not Verify_Pure (Curve, Msg & "x", Pub_Key, Sig));
   Check ("4.2 Signature fails across differing public key identities", 
          not Verify_Pure (Curve, Msg, Generate_Public_Key (Curve, "other"), Sig));
   Check ("4.3 Signature fails upon manipulated cryptographic S scalar", 
          not Verify_Pure (Curve, Msg, Pub_Key, (R => Sig.R, S => Sig.S + To_Big_Integer(1))));

   Put_Line ("TEST 5 -- Hash EdDSA (EdDSAph) Integration");
   Sig_H := Sign_Hash (Curve, Msg, Sec_Key);
   Check ("5.1 Derived R signature fragment falls cleanly onto curve", Is_On_Curve (Curve, Sig_H.R));
   Check ("5.2 Pre-hashing preserves positive validation", Verify_Hash (Curve, Msg, Pub_Key, Sig_H));
   Check ("5.3 Rejects falsified messages against hash wrapper", not Verify_Hash (Curve, "Wrong!", Pub_Key, Sig_H));

   Put_Line ("TEST 6 -- Context EdDSA (EdDSActx) Integration");
   Sig_C := Sign_Context (Curve, Msg, Context, Sec_Key);
   Check ("6.1 Sign yields valid structure bounded to context string", Is_On_Curve (Curve, Sig_C.R));
   Check ("6.2 Verifies strictly assuming correct Context", Verify_Context (Curve, Msg, Context, Pub_Key, Sig_C));
   Check ("6.3 Explicit failure on context mismatch", not Verify_Context (Curve, Msg, "WrongContext", Pub_Key, Sig_C));

   Put_Line ("TEST 7 -- Point Addition Axioms");
   Check ("7.1 Addition with Neutral Element acts identically (B+O=B)", 
          Point_Add (Curve, Curve.B, Neutral).X = Curve.B.X);
   Check ("7.2 Addition commutes symmetrically (O+B=B)", 
          Point_Add (Curve, Neutral, Curve.B).Y = Curve.B.Y);
   Check ("7.3 Neutral sums accurately (O+O=O)", 
          Point_Add (Curve, Neutral, Neutral).X = To_Big_Integer (0));

   Put_Line ("TEST 8 -- Scalar Multiplication Extrema");
   Check ("8.1 Scalar multiplier 0 outputs neutral element", 
          Point_Multiply (Curve, To_Big_Integer(0), Curve.B).Y = To_Big_Integer(1));
   Check ("8.2 Scalar multiplier 1 echoes point faithfully", 
          Point_Multiply (Curve, To_Big_Integer(1), Curve.B).X = Curve.B.X);
   Check ("8.3 Multiplication distributes over consecutive addition", 
          Point_Multiply (Curve, To_Big_Integer(2), Curve.B).X = Point_Add (Curve, Curve.B, Curve.B).X);

   Put_Line ("TEST 9 -- Bounding and Invalid Points");
   Check ("9.1 Reject absolute zero point coordinate mapping", 
          not Is_On_Curve (Curve, (X => To_Big_Integer (0), Y => To_Big_Integer (0))));
   Check ("9.2 Reject out-of-field bounds points", 
          not Is_On_Curve (Curve, (X => Curve.P, Y => To_Big_Integer (1))));
   Check ("9.3 Internal point add maintains tight curve limits natively", 
          Point_Add (Curve, Curve.B, Curve.B).X < Curve.P);

   Put_Line ("TEST 10 -- Mathematical Determinism Validation");
   declare
      Sig2 : constant Signature := Sign_Pure (Curve, Msg, Sec_Key);
   begin
      Check ("10.1 Deterministic key/message tuple forces uniform R coordinate", Sig.R.X = Sig2.R.X);
      Check ("10.2 Deterministic tuple locks uniform S derivation identically", Sig.S = Sig2.S);
      Check ("10.3 Delineated message shifts cryptographic boundaries strictly", Sig.S /= Sign_Pure (Curve, Msg & "_", Sec_Key).S);
   end;

   Put_Line ("TEST 11 -- Exponentiation Boundary Operations");
   Check ("11.1 Identity limits preserve bounds safely (val^1 = val)", 
          (To_Big_Integer(12345) ** 1) = To_Big_Integer(12345));
   Check ("11.2 Modular operations properly wrap and normalize outputs", 
          ((To_Big_Integer(5) - To_Big_Integer(10)) mod Curve.P) = Curve.P - To_Big_Integer(5));
   Check ("11.3 Neutral Element maintains parity under exponentiation", 
          (To_Big_Integer(0) ** 5) = To_Big_Integer(0));

   Put_Line ("TEST 12 -- Contract Enforcements (Preconditions)");
   declare
      Is_Valid : Boolean;
      Invalid_Point : constant Point := (X => To_Big_Integer(0), Y => To_Big_Integer(0));
   begin
      Is_Valid := Verify_Pure (Curve, Msg, Invalid_Point, Sig);
      Check ("12.1 Bad public key silently accepted (FAIL). Valid: " & Boolean'Image (Is_Valid), False);
   exception
      when others =>
         Check ("12.1 Precondition strictly rejects bad public keys", True);
   end;
   declare
      Is_Valid : Boolean;
      Invalid_Sig : constant Signature := (R => (To_Big_Integer(0), To_Big_Integer(0)), S => Sig.S);
   begin
      Is_Valid := Verify_Pure (Curve, Msg, Pub_Key, Invalid_Sig);
      Check ("12.2 Bad signature 'R' silently accepted (FAIL). Valid: " & Boolean'Image (Is_Valid), False);
   exception
      when others =>
         Check ("12.2 Precondition safely blocks out of bound signatures", True);
   end;

   Put_Line ("TEST 13 -- Subgroup Order Proof (L * B = O)");
   declare
      L_Times_B : constant Point := Point_Multiply (Curve, Curve.L, Curve.B);
   begin
      -- Because L is the order of subgroup generator B, scalar multiplication by L 
      -- must geometrically orbit entirely and yield exactly the neutral element (0,1).
      Check ("13.1 L*B maps absolutely to Neutral X coordinate", L_Times_B.X = Neutral.X);
      Check ("13.2 L*B maps absolutely to Neutral Y coordinate", L_Times_B.Y = Neutral.Y);
      Check ("13.3 Cofactor clears correctly into curve limits", Is_On_Curve (Curve, Point_Multiply(Curve, Curve.C, Curve.B)));
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed," & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed during run.");
end Tests;
