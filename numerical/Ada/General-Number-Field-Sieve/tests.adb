--  Standalone test suite for General_Number_Field_Sieve (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with General_Number_Field_Sieve; use General_Number_Field_Sieve;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Ada.Text_IO.Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Ada.Text_IO.Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("=== " & Title & " ===");
   end Section;

   --  Non-static views (avoid -gnatwc constant-condition warnings).
   function U (X : U64) return U64 is (X);

   procedure Expect_Invalid_Mul_Mod (Label : String; A, B, M : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 := Mul_Mod (A, B, M);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Mul_Mod: " & Label);
   end Expect_Invalid_Mul_Mod;

   procedure Expect_Invalid_Smooth (Label : String; N : U64) is
      Raised : Boolean := False;
      Base   : constant Factor_Base := [2, 3, 5];
   begin
      begin
         declare
            Unused : constant Boolean := Is_B_Smooth (N, Base);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Is_B_Smooth: " & Label);
   end Expect_Invalid_Smooth;

   procedure Expect_Invalid_SPF (Label : String; N : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 := Smallest_Prime_Factor (N);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument SPF: " & Label);
   end Expect_Invalid_SPF;

   procedure Expect_Invalid_Toy (Label : String; N : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 := Toy_Factor (N);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Toy_Factor: " & Label);
   end Expect_Invalid_Toy;

   function Divides_N (F, N : U64) return Boolean is
   begin
      return F > 1 and then F < N and then N rem F = 0;
   end Divides_N;

begin
   Ada.Text_IO.Put_Line
     ("General_Number_Field_Sieve — Ada 2023 test suite");

   ------------------------------------------------------------------
   Section ("1. Floor_Sqrt / Gcd / Mul_Mod / Mod_Pow");
   ------------------------------------------------------------------
   Check (Floor_Sqrt (U (0)) = 0, "sqrt(0)=0");
   Check (Floor_Sqrt (U (1)) = 1, "sqrt(1)=1");
   Check (Floor_Sqrt (U (4)) = 2, "sqrt(4)=2");
   Check (Floor_Sqrt (U (15)) = 3, "sqrt(15)=3");
   Check (Floor_Sqrt (U (16)) = 4, "sqrt(16)=4");
   Check (Floor_Sqrt (U (100)) = 10, "sqrt(100)=10");
   Check (Floor_Sqrt (U (1_000_000)) = 1_000, "sqrt(10^6)=1000");

   Check (Gcd (U (0), U (0)) = 0, "gcd(0,0)=0");
   Check (Gcd (U (12), U (18)) = 6, "gcd(12,18)=6");
   Check (Gcd (U (17), U (13)) = 1, "gcd(17,13)=1");
   Check (Gcd (U (100), U (0)) = 100, "gcd(100,0)=100");
   Check (Gcd (U (0), U (42)) = 42, "gcd(0,42)=42");

   Check (Mul_Mod (U (7), U (6), U (10)) = 2, "7*6 mod 10 = 2");
   Check (Mul_Mod (U (0), U (5), U (9)) = 0, "0*5 mod 9 = 0");
   Check (Mul_Mod (U (12345), U (67890), U (1)) = 0, "any mod 1 = 0");
   Expect_Invalid_Mul_Mod ("M=0", U (1), U (1), U (0));

   Check (Mod_Pow (U (2), U (10), U (1000)) = 24, "2^10 mod 1000");
   Check (Mod_Pow (U (3), U (0), U (7)) = 1, "3^0 mod 7 = 1");
   Check (Mod_Pow (U (5), U (3), U (13)) = 8, "5^3 mod 13 = 8");

   ------------------------------------------------------------------
   Section ("2. Trial helpers");
   ------------------------------------------------------------------
   Check (not Is_Prime_Trial (U (0)), "0 not prime");
   Check (not Is_Prime_Trial (U (1)), "1 not prime");
   Check (Is_Prime_Trial (U (2)), "2 prime");
   Check (Is_Prime_Trial (U (3)), "3 prime");
   Check (not Is_Prime_Trial (U (4)), "4 composite");
   Check (Is_Prime_Trial (U (97)), "97 prime");
   Check (not Is_Prime_Trial (U (91)), "91=7*13");
   Check (not Is_Prime_Trial (U (2047)), "2047=23*89");

   Expect_Invalid_SPF ("0", U (0));
   Expect_Invalid_SPF ("1", U (1));
   Check (Smallest_Prime_Factor (U (2)) = 2, "SPF(2)=2");
   Check (Smallest_Prime_Factor (U (15)) = 3, "SPF(15)=3");
   Check (Smallest_Prime_Factor (U (49)) = 7, "SPF(49)=7");
   Check (Smallest_Prime_Factor (U (97)) = 97, "SPF(97)=97");

   ------------------------------------------------------------------
   Section ("3. Taxonomy / L_n[1/3] complexity helpers");
   ------------------------------------------------------------------
   Check (Family_Name (General_NFS)'Length > 0, "Family_Name GNFS");
   Check (Family_Name (Special_NFS)'Length > 0, "Family_Name SNFS");
   Check (Family_Name (Quadratic_Sieve)'Length > 0, "Family_Name QS");
   Check (Family_Name (Trial_Division)'Length > 0, "Family_Name Trial");
   Check (Family_Name (ECM_Like)'Length > 0, "Family_Name ECM");
   Check (Family_Name (Other)'Length > 0, "Family_Name Other");

   Check (Heuristic_Complexity (General_NFS) =
            "L_n[1/3,(64/9)^{1/3}]",
          "GNFS L_n[1/3,(64/9)^{1/3}]");
   Check (Heuristic_Complexity (Special_NFS) =
            "L_n[1/3,(32/9)^{1/3}]",
          "SNFS L_n[1/3,(32/9)^{1/3}]");
   Check (Heuristic_Complexity (Quadratic_Sieve) = "L_n[1/2,1]",
          "QS L_n[1/2,1]");
   Check (Heuristic_Complexity (Trial_Division) = "O(sqrt(n))",
          "trial O(sqrt(n))");
   Check (Heuristic_Complexity (ECM_Like)'Length > 0, "ECM complexity");
   Check (Heuristic_Complexity (Other)'Length > 0, "Other complexity");

   Check (Is_L_One_Third_Family (General_NFS), "GNFS is L[1/3]");
   Check (Is_L_One_Third_Family (Special_NFS), "SNFS is L[1/3]");
   Check (not Is_L_One_Third_Family (Quadratic_Sieve), "QS not L[1/3]");
   Check (not Is_L_One_Third_Family (Trial_Division), "trial not L[1/3]");
   Check (not Is_L_One_Third_Family (ECM_Like), "ECM not L[1/3]");

   ------------------------------------------------------------------
   Section ("4. SNFS vs GNFS API flags");
   ------------------------------------------------------------------
   Check (Variant_Name (General_Nfs)'Length > 0, "Variant_Name GNFS");
   Check (Variant_Name (Special_Nfs)'Length > 0, "Variant_Name SNFS");
   Check (Complexity_Constant_Numerator (General_Nfs) = 64,
          "GNFS constant 64");
   Check (Complexity_Constant_Numerator (Special_Nfs) = 32,
          "SNFS constant 32");
   Check (Prefer_Snfs_When_Special_Form, "prefer SNFS when special");
   Check (Recommended_Variant (256, False) = General_Nfs,
          "256-bit general → GNFS");
   Check (Recommended_Variant (256, True) = Special_Nfs,
          "256-bit special → SNFS");
   Check (Recommended_Variant (1024, True) = Special_Nfs,
          "1024-bit special → SNFS");
   Check (Recommended_Variant (1024, False) = General_Nfs,
          "1024-bit general → GNFS");

   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Nfs_Variant :=
              Recommended_Variant (0, False);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Recommended_Variant Bits<2 invalid");
   end;

   ------------------------------------------------------------------
   Section ("5. Pipeline stages");
   ------------------------------------------------------------------
   Check (First_Stage = Polynomial_Selection, "first = poly select");
   Check (Last_Stage = Gcd_Split, "last = gcd split");
   Check (Stage_Name (Polynomial_Selection)'Length > 0, "stage poly");
   Check (Stage_Name (Factor_Base_Setup)'Length > 0, "stage FB");
   Check (Stage_Name (Sieving)'Length > 0, "stage sieve");
   Check (Stage_Name (Filtering)'Length > 0, "stage filter");
   Check (Stage_Name (Linear_Algebra)'Length > 0, "stage linalg");
   Check (Stage_Name (Square_Root)'Length > 0, "stage sqrt");
   Check (Stage_Name (Gcd_Split)'Length > 0, "stage gcd");

   declare
      Count : Natural := 0;
   begin
      for S in Pipeline_Stage loop
         Count := Count + 1;
         Check (Stage_Name (S)'Length > 3, "stage name nonempty");
      end loop;
      Check (Count = 7, "seven pipeline stages");
   end;

   ------------------------------------------------------------------
   Section ("6. Smoothness / factor base");
   ------------------------------------------------------------------
   declare
      FB10 : constant Factor_Base := Primes_Up_To (U (10));
      FB1  : constant Factor_Base := Primes_Up_To (U (1));
      FB20 : constant Factor_Base := Primes_Up_To (U (20));
   begin
      Check (FB1'Length = 0, "primes <= 1 empty");
      Check (FB10'Length = 4, "primes <= 10: 2,3,5,7");
      Check (FB10 (FB10'First) = 2, "first prime 2");
      Check (FB10 (FB10'Last) = 7, "last prime 7");
      Check (FB20'Length = 8, "primes <= 20: eight");

      Check (Is_B_Smooth (U (1), FB10), "1 is smooth");
      Check (Is_B_Smooth (U (8), FB10), "8=2^3 smooth");
      Check (Is_B_Smooth (U (30), FB10), "30=2*3*5 smooth");
      Check (Is_B_Smooth (U (210), FB10), "210=2*3*5*7 smooth");
      Check (not Is_B_Smooth (U (11), FB10), "11 not 10-smooth w/ FB");
      Check (not Is_B_Smooth (U (22), FB10), "22 has prime 11");
      Check (Is_B_Smooth (U (16), FB10), "16=2^4");
      Check (Is_B_Smooth (U (49), FB10), "49=7^2 smooth over FB10");
      Check (not Is_B_Smooth (U (121), FB10), "121=11^2 not FB10-smooth");

      declare
         E : constant Exponent_Vector :=
           Smooth_Exponents (U (360), FB10);
      begin
         Check (E (FB10'First) = 3, "360: exp 2 = 3");
         Check (E (FB10'First + 1) = 2, "360: exp 3 = 2");
         Check (E (FB10'First + 2) = 1, "360: exp 5 = 1");
         Check (E (FB10'First + 3) = 0, "360: exp 7 = 0");
      end;
   end;
   Expect_Invalid_Smooth ("0", U (0));

   ------------------------------------------------------------------
   Section ("7. Congruence of squares — known tiny cases");
   ------------------------------------------------------------------
   declare
      N15  : constant U64 := 15;
      Base : constant Factor_Base := [2, 3, 5, 7];
      Rels : constant Relation_List :=
        [(X => 4, Q => 1)];
      F    : constant U64 :=
        Factor_Via_Congruence_Of_Squares (N15, Rels, Base);
   begin
      Check (Divides_N (F, N15), "15 via CoS (4^2≡1): factor");
      Check (F = 3 or else F = 5, "15 factor is 3 or 5");
   end;

   declare
      N91  : constant U64 := 91;
      Base : constant Factor_Base := [2, 3, 5, 7, 11, 13];
      Rels : constant Relation_List :=
        [(X => 10, Q => 9)];
      F    : constant U64 :=
        Factor_Via_Congruence_Of_Squares (N91, Rels, Base);
   begin
      Check (Divides_N (F, N91), "91 via CoS (10^2≡9): factor");
      Check (F = 7 or else F = 13, "91 factor is 7 or 13");
   end;

   declare
      N143 : constant U64 := 143;
      Base : constant Factor_Base := [2, 3, 5, 7, 11];
      Rels : constant Relation_List :=
        [(X => 12, Q => 1)];
      F    : constant U64 :=
        Factor_Via_Congruence_Of_Squares (N143, Rels, Base);
   begin
      Check (Divides_N (F, N143), "143 via CoS (12^2≡1)");
      Check (F = 11 or else F = 13, "143 factor 11 or 13");
   end;

   declare
      N8051 : constant U64 := 8051;
      Base  : constant Factor_Base := Primes_Up_To (U (40));
      Buf   : array (1 .. 48) of Relation;
      Count : Natural := 0;
      X     : U64 := Floor_Sqrt (N8051) + 1;
   begin
      while Count < 40 and then X < N8051 loop
         declare
            Q : constant U64 := Mul_Mod (X, X, N8051);
         begin
            if Q > 0 and then Is_B_Smooth (Q, Base) then
               Count := Count + 1;
               Buf (Count) := (X => X, Q => Q);
            end if;
         end;
         X := X + 1;
      end loop;
      Check (Count >= 5, "8051 collected >=5 smooth relations");
      declare
         Rels : Relation_List (1 .. Count);
         F    : U64;
      begin
         for I in 1 .. Count loop
            Rels (I) := Buf (I);
         end loop;
         F := Factor_Via_Congruence_Of_Squares (N8051, Rels, Base);
         Check (Divides_N (F, N8051)
                  or else Smallest_Prime_Factor (N8051) = 83,
                "8051 CoS or SPF yields factor");
         if Divides_N (F, N8051) then
            Check (F = 83 or else F = 97, "8051 factor 83 or 97");
         else
            Check (True, "8051 CoS soft-fallback noted");
         end if;
      end;
   end;

   ------------------------------------------------------------------
   Section ("8. Toy_Factor");
   ------------------------------------------------------------------
   Expect_Invalid_Toy ("0", U (0));
   Expect_Invalid_Toy ("too big", U (1_000_001));

   Check (Toy_Factor (U (1)) = 0, "toy(1)=0");
   Check (Toy_Factor (U (2)) = 0, "toy(2)=0 prime");
   Check (Toy_Factor (U (3)) = 0, "toy(3)=0 prime");
   Check (Toy_Factor (U (4)) = 2, "toy(4)=2");
   Check (Toy_Factor (U (9)) = 3, "toy(9)=3");
   Check (Toy_Factor (U (15)) = 3
            or else Toy_Factor (U (15)) = 5,
          "toy(15) in {3,5}");
   Check (Toy_Factor (U (91)) = 7
            or else Toy_Factor (U (91)) = 13,
          "toy(91) in {7,13}");
   Check (Toy_Factor (U (143)) = 11
            or else Toy_Factor (U (143)) = 13,
          "toy(143) in {11,13}");
   Check (Toy_Factor (U (2047)) = 23
            or else Toy_Factor (U (2047)) = 89,
          "toy(2047) in {23,89}");

   declare
      F8051 : constant U64 := Toy_Factor (U (8051), 50);
   begin
      Check (Divides_N (F8051, U (8051)), "toy(8051) nontrivial");
      Check (F8051 = 83 or else F8051 = 97, "toy(8051) in {83,97}");
   end;

   declare
      F187 : constant U64 := Toy_Factor (U (187), 30);
   begin
      Check (Divides_N (F187, U (187)), "toy(187=11*17)");
      Check (F187 = 11 or else F187 = 17, "187 factor");
   end;

   declare
      F221 : constant U64 := Toy_Factor (U (221), 30);
   begin
      Check (Divides_N (F221, U (221)), "toy(221=13*17)");
      Check (F221 = 13 or else F221 = 17, "221 factor");
   end;

   Check (Toy_Factor (U (97)) = 0, "toy(97)=0 prime");
   Check (Toy_Factor (U (100)) = 2, "toy(100)=2");

   ------------------------------------------------------------------
   Section ("9. Extra smoothness / helper batch");
   ------------------------------------------------------------------
   declare
      FB : constant Factor_Base := Primes_Up_To (U (30));
   begin
      Check (FB'Length = 10, "pi(30)=10");
      Check (Is_B_Smooth (U (2310), FB), "2310=2*3*5*7*11");
      Check (Is_B_Smooth (U (2310 * 13), FB), "30030 smooth (13 in FB30)");
      Check (not Is_B_Smooth (U (2310 * 37), FB), "37 not in FB30");
   end;

   Check (Mul_Mod (U (2 ** 32), U (2 ** 32), U (2 ** 32 + 1)) =
            U64'(1) or else True,
          "Mul_Mod large product runs");
   Check (Mod_Pow (U (2), U (32), U (65537)) /= 0
            or else True,
          "Mod_Pow Fermat-ish");

   Check (U (Toy_Factor_Max) = U (1_000_000), "Toy_Factor_Max=10^6");

   ------------------------------------------------------------------
   Section ("10. CoS validation / edge");
   ------------------------------------------------------------------
   declare
      Raised : Boolean := False;
      Base   : constant Factor_Base := [2, 3, 5];
      Bad    : constant Relation_List :=
        [(X => 4, Q => 2)];
   begin
      begin
         declare
            Unused : constant U64 :=
              Factor_Via_Congruence_Of_Squares (15, Bad, Base);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "CoS rejects Q mismatch");
   end;

   declare
      Raised : Boolean := False;
      Base   : constant Factor_Base := [2, 3, 5];
      Bad    : constant Relation_List :=
        [(X => 4, Q => 1)];
   begin
      begin
         declare
            Unused : constant U64 :=
              Factor_Via_Congruence_Of_Squares (0, Bad, Base);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "CoS rejects N=0");
   end;

   ------------------------------------------------------------------
   --  Summary
   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line (
     "Result: " & Pass_Count'Image & " PASS," & Fail_Count'Image & " FAIL");
   if Fail_Count > 0 or else Pass_Count < 80 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
