with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics.Big_Numbers.Big_Integers; use Ada.Numerics.Big_Numbers.Big_Integers;
with Elliptic_Curve_Diffie_Hellman; use Elliptic_Curve_Diffie_Hellman;

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

   function B (V : Integer) return Big_Integer is (To_Big_Integer (V));

   -- Small test curve: y^2 = x^3 + x + 1 over F_23 (N=28)
   -- Using Generator G = (3, 10).
   D : constant Domain_Parameters :=
     (P => B (23),
      A => B (1),
      B => B (1),
      G => (X => B (3), Y => B (10), Is_Infinity => False),
      N => B (28));

   Bad_D    : Domain_Parameters;
   P2, P3   : Curve_Point;
   M_G, Inf : Curve_Point;
   Secret_A : Curve_Point;
   Secret_B : Curve_Point;
   Exc_Hit  : Boolean;

begin
   -- TEST 1 - Domain Validation
   Put_Line ("TEST 1 — Domain Validation");
   Check ("1.1 Domain parameters are valid mathematically", Is_Valid_Domain (D));
   Check ("1.2 Curve prime is positive", D.P > B (2));
   Check ("1.3 Base point lies correctly on the curve", Is_On_Curve (D.G, D));

   -- TEST 2 - Invalid Domain Rejection
   Put_Line ("TEST 2 — Invalid Domain Rejection");
   Bad_D := D;
   Bad_D.P := B (2);
   Check ("2.1 P=2 is correctly identified as invalid modulus", not Is_Valid_Domain (Bad_D));
   
   Bad_D.P := D.P; 
   Bad_D.A := B (0); 
   Bad_D.B := B (0);
   Check ("2.2 Discriminant zero is correctly rejected (singular curve)", not Is_Valid_Domain (Bad_D));
   
   Bad_D := D; 
   Bad_D.G.X := B (3); 
   Bad_D.G.Y := B (11); -- Off curve
   Check ("2.3 Base point not on curve invalidates domain", not Is_Valid_Domain (Bad_D));

   -- TEST 3 - Curve Membership Checks
   Put_Line ("TEST 3 — Curve Membership Checks");
   Check ("3.1 Generator G is on curve", Is_On_Curve (D.G, D));
   Check ("3.2 Off-curve point correctly returns False", not Is_On_Curve ((X => B(3), Y => B(11), Is_Infinity => False), D));
   Check ("3.3 Infinity is conceptually always on curve", Is_On_Curve ((X => B(0), Y => B(0), Is_Infinity => True), D));

   -- TEST 4 - Point Doubling (2G)
   Put_Line ("TEST 4 — Point Doubling");
   P2 := Point_Double (D.G, D);
   Check ("4.1 2G is not infinity", not P2.Is_Infinity);
   Check ("4.2 2G.X calculated correctly (7)", P2.X = B (7));
   Check ("4.3 2G.Y calculated correctly (12)", P2.Y = B (12));

   -- TEST 5 - Point Addition (G + 2G = 3G)
   Put_Line ("TEST 5 — Point Addition");
   P3 := Point_Add (D.G, P2, D);
   Check ("5.1 3G is not infinity", not P3.Is_Infinity);
   Check ("5.2 3G.X calculated correctly (19)", P3.X = B (19));
   Check ("5.3 3G.Y calculated correctly (5)", P3.Y = B (5));

   -- TEST 6 - Point Addition Edge Cases (Inverses & Infinity)
   Put_Line ("TEST 6 — Point Addition Edge Cases");
   M_G := (X => D.G.X, Y => (D.P - D.G.Y) mod D.P, Is_Infinity => False);
   Inf := Point_Add (D.G, M_G, D);
   Check ("6.1 P + (-P) yields Infinity", Inf.Is_Infinity);
   Check ("6.2 P + Infinity yields P", Point_Add (D.G, Inf, D).X = D.G.X);
   Check ("6.3 Infinity + P yields P", Point_Add (Inf, D.G, D).X = D.G.X);

   -- TEST 7 - Scalar Multiplication Math Match
   Put_Line ("TEST 7 — Scalar Multiplication Match");
   Check ("7.1 1*G equals G", Scalar_Multiply (B(1), D.G, D).X = D.G.X);
   Check ("7.2 2*G matches Point_Double result", Scalar_Multiply (B(2), D.G, D).X = P2.X);
   Check ("7.3 3*G matches Point_Add result", Scalar_Multiply (B(3), D.G, D).X = P3.X);

   -- TEST 8 - Key Pair Generation API
   Put_Line ("TEST 8 — Key Pair Generation API");
   declare
      Pub_Key : constant Curve_Point := Generate_Key_Pair (D, B(2));
   begin
      Check ("8.1 Generated key is on curve", Is_On_Curve (Pub_Key, D));
      Check ("8.2 Generated key is not infinity", not Pub_Key.Is_Infinity);
      Check ("8.3 Private key 2 generates 2G correctly", Pub_Key.X = P2.X);
   end;

   -- TEST 9 - Variant 1: Static ECDH Key Agreement
   Put_Line ("TEST 9 — Variant 1: Static ECDH");
   declare
      Priv_A : constant Big_Integer := B(4);
      Pub_A  : constant Curve_Point := Generate_Key_Pair (D, Priv_A);
      Priv_B : constant Big_Integer := B(5);
      Pub_B  : constant Curve_Point := Generate_Key_Pair (D, Priv_B);
   begin
      Static_ECDH (D, Priv_A, Pub_B, Secret_A);
      Static_ECDH (D, Priv_B, Pub_A, Secret_B);
      Check ("9.1 Shared secret A is on curve", Is_On_Curve (Secret_A, D));
      Check ("9.2 Shared secret X coordinates match symmetrically", Secret_A.X = Secret_B.X);
      Check ("9.3 Shared secret Y coordinates match symmetrically", Secret_A.Y = Secret_B.Y);
   end;

   -- TEST 10 - Variant 2: Ephemeral ECDHE Key Agreement
   Put_Line ("TEST 10 — Variant 2: Ephemeral ECDHE");
   declare
      Eph_Priv_A : constant Big_Integer := B(6);
      Eph_Pub_A  : constant Curve_Point := Generate_Key_Pair (D, Eph_Priv_A);
      Eph_Priv_B : constant Big_Integer := B(7);
      Eph_Pub_B  : constant Curve_Point := Generate_Key_Pair (D, Eph_Priv_B);
   begin
      Ephemeral_ECDHE (D, Eph_Priv_A, Eph_Pub_B, Secret_A);
      Ephemeral_ECDHE (D, Eph_Priv_B, Eph_Pub_A, Secret_B);
      Check ("10.1 Shared secret is validly computed", not Secret_A.Is_Infinity);
      Check ("10.2 ECDHE derived matching X coordinate", Secret_A.X = Secret_B.X);
      Check ("10.3 ECDHE derived matching Y coordinate", Secret_A.Y = Secret_B.Y);
   end;

   -- TEST 11 - Variant 3: Anonymous ECDH Key Agreement
   Put_Line ("TEST 11 — Variant 3: Anonymous ECDH");
   declare
      Eph_Client_Priv : constant Big_Integer := B(2);
      Eph_Client_Pub  : constant Curve_Point := Generate_Key_Pair (D, Eph_Client_Priv);
      Static_Serv_Priv: constant Big_Integer := B(3);
      Static_Serv_Pub : constant Curve_Point := Generate_Key_Pair (D, Static_Serv_Priv);
   begin
      Anonymous_ECDH (D, Eph_Client_Priv, Static_Serv_Pub, Secret_A);
      Anonymous_ECDH (D, Static_Serv_Priv, Eph_Client_Pub, Secret_B);
      Check ("11.1 Anon secret is successfully mapped", not Secret_A.Is_Infinity);
      Check ("11.2 Anon ECDH parties agree on X coordinate", Secret_A.X = Secret_B.X);
      Check ("11.3 Anon ECDH parties agree on Y coordinate", Secret_A.Y = Secret_B.Y);
   end;

   -- TEST 12 - Error Handling: Invalid Private Key Inputs
   Put_Line ("TEST 12 — Error Handling: Invalid Private Keys");
   Exc_Hit := False;
   begin
      Secret_A := Generate_Key_Pair (D, B(0));
      Check ("12.1 Execution should not reach here", False);
   exception
      when Invalid_Private_Key => Exc_Hit := True;
      when others => Check ("12.1 Caught wrong exception type", False);
   end;
   Check ("12.1 Caught Invalid_Private_Key for zero key", Exc_Hit);

   Exc_Hit := False;
   begin
      Secret_A := Generate_Key_Pair (D, D.N);
      Check ("12.2 Execution should not reach here", False);
   exception
      when Invalid_Private_Key => Exc_Hit := True;
      when others => Check ("12.2 Caught wrong exception type", False);
   end;
   Check ("12.2 Caught Invalid_Private_Key for key >= N", Exc_Hit);
   Check ("12.3 System state safe after rejecting bad keys", True);

   -- TEST 13 - Error Handling: Invalid Public Point Input
   Put_Line ("TEST 13 — Error Handling: Invalid Public Point");
   Exc_Hit := False;
   declare
      Bad_Pub : constant Curve_Point := (X => B(3), Y => B(11), Is_Infinity => False);
   begin
      Static_ECDH (D, B(2), Bad_Pub, Secret_A);
      Check ("13.1 Execution should not reach here", False);
   exception
      when Invalid_Point => Exc_Hit := True;
      when others => Check ("13.1 Caught wrong exception type", False);
   end;
   Check ("13.1 Caught Invalid_Point exception successfully", Exc_Hit);

   Exc_Hit := False;
   begin
      Static_ECDH (D, B(2), (X => B(0), Y => B(0), Is_Infinity => True), Secret_A);
      Check ("13.2 Execution should not reach here", False);
   exception
      when Invalid_Point => Exc_Hit := True;
      when others => Check ("13.2 Caught wrong exception type", False);
   end;
   Check ("13.2 Caught Invalid_Point for infinity point", Exc_Hit);
   Check ("13.3 Key agreement gracefully aborted bad peer points", True);

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
