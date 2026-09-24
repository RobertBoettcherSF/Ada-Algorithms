--  Standalone test suite for Fermat_Factorization (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Fermat_Factorization; use Fermat_Factorization;

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

   procedure Expect_Invalid_Factor (Label : String; N : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Factor_Pair := Factor (N);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Factor: " & Label);
   end Expect_Invalid_Factor;

   function Product_OK (P : Factor_Pair; N : U64) return Boolean is
   begin
      if P.F1 = 0 and then P.F2 = 0 then
         return False;
      end if;
      return P.F1 <= P.F2
        and then P.F1 >= 1
        and then N rem P.F1 = 0
        and then N / P.F1 = P.F2;
   end Product_OK;

   function Is_Failure (P : Factor_Pair) return Boolean is
   begin
      return P.F1 = 0 and then P.F2 = 0;
   end Is_Failure;

   P : Factor_Pair;

begin
   Ada.Text_IO.Put_Line ("Fermat_Factorization — Ada 2023 test suite");

   ------------------------------------------------------------------
   Section ("1. Gcd");
   ------------------------------------------------------------------
   Check (Gcd (U (0), U (0)) = 0, "Gcd(0,0)=0");
   Check (Gcd (U (0), U (5)) = 5, "Gcd(0,5)=5");
   Check (Gcd (U (5), U (0)) = 5, "Gcd(5,0)=5");
   Check (Gcd (U (12), U (18)) = 6, "Gcd(12,18)=6");
   Check (Gcd (U (17), U (19)) = 1, "Gcd(17,19)=1");
   Check (Gcd (U (100), U (25)) = 25, "Gcd(100,25)=25");
   Check (Gcd (U (7), U (7)) = 7, "Gcd(7,7)=7");
   Check (Gcd (U (54), U (24)) = 6, "Gcd(54,24)=6");
   Check (Gcd (U (1071), U (462)) = 21, "Gcd(1071,462)=21");
   Check (Gcd (U (1), U (1)) = 1, "Gcd(1,1)=1");

   ------------------------------------------------------------------
   Section ("2. Floor_Sqrt / Ceil_Sqrt / Is_Perfect_Square");
   ------------------------------------------------------------------
   Check (Floor_Sqrt (U (0)) = 0, "Floor_Sqrt 0");
   Check (Floor_Sqrt (U (1)) = 1, "Floor_Sqrt 1");
   Check (Floor_Sqrt (U (2)) = 1, "Floor_Sqrt 2");
   Check (Floor_Sqrt (U (3)) = 1, "Floor_Sqrt 3");
   Check (Floor_Sqrt (U (4)) = 2, "Floor_Sqrt 4");
   Check (Floor_Sqrt (U (8)) = 2, "Floor_Sqrt 8");
   Check (Floor_Sqrt (U (9)) = 3, "Floor_Sqrt 9");
   Check (Floor_Sqrt (U (15)) = 3, "Floor_Sqrt 15");
   Check (Floor_Sqrt (U (16)) = 4, "Floor_Sqrt 16");
   Check (Floor_Sqrt (U (455839)) = 675, "Floor_Sqrt 455839");
   Check (Floor_Sqrt (U (5959)) = 77, "Floor_Sqrt 5959");
   Check (Floor_Sqrt (U (10_000)) = 100, "Floor_Sqrt 10000");

   Check (Ceil_Sqrt (U (0)) = 0, "Ceil_Sqrt 0");
   Check (Ceil_Sqrt (U (1)) = 1, "Ceil_Sqrt 1");
   Check (Ceil_Sqrt (U (2)) = 2, "Ceil_Sqrt 2");
   Check (Ceil_Sqrt (U (3)) = 2, "Ceil_Sqrt 3");
   Check (Ceil_Sqrt (U (4)) = 2, "Ceil_Sqrt 4");
   Check (Ceil_Sqrt (U (5)) = 3, "Ceil_Sqrt 5");
   Check (Ceil_Sqrt (U (9)) = 3, "Ceil_Sqrt 9");
   Check (Ceil_Sqrt (U (10)) = 4, "Ceil_Sqrt 10");
   Check (Ceil_Sqrt (U (5959)) = 78, "Ceil_Sqrt 5959 (wiki)");
   Check (Ceil_Sqrt (U (455839)) = 676, "Ceil_Sqrt 455839");

   Check (Is_Perfect_Square (U (0)), "square 0");
   Check (Is_Perfect_Square (U (1)), "square 1");
   Check (Is_Perfect_Square (U (4)), "square 4");
   Check (Is_Perfect_Square (U (9)), "square 9");
   Check (Is_Perfect_Square (U (16)), "square 16");
   Check (Is_Perfect_Square (U (100)), "square 100");
   Check (not Is_Perfect_Square (U (2)), "not square 2");
   Check (not Is_Perfect_Square (U (3)), "not square 3");
   Check (not Is_Perfect_Square (U (8)), "not square 8");
   Check (not Is_Perfect_Square (U (15)), "not square 15");
   Check (not Is_Perfect_Square (U (455839)), "not square 455839");

   ------------------------------------------------------------------
   Section ("3. Is_Prime_Trial");
   ------------------------------------------------------------------
   Check (not Is_Prime_Trial (U (0)), "not prime 0");
   Check (not Is_Prime_Trial (U (1)), "not prime 1");
   Check (Is_Prime_Trial (U (2)), "prime 2");
   Check (Is_Prime_Trial (U (3)), "prime 3");
   Check (not Is_Prime_Trial (U (4)), "not prime 4");
   Check (Is_Prime_Trial (U (5)), "prime 5");
   Check (not Is_Prime_Trial (U (9)), "not prime 9");
   Check (Is_Prime_Trial (U (17)), "prime 17");
   Check (Is_Prime_Trial (U (97)), "prime 97");
   Check (Is_Prime_Trial (U (599)), "prime 599");
   Check (Is_Prime_Trial (U (761)), "prime 761");
   Check (not Is_Prime_Trial (U (91)), "not prime 91");
   Check (not Is_Prime_Trial (U (143)), "not prime 143");
   Check (not Is_Prime_Trial (U (8051)), "not prime 8051");
   Check (not Is_Prime_Trial (U (455839)), "not prime 455839");
   Check (Is_Prime_Trial (U (10007)), "prime 10007");
   Check (Is_Prime_Trial (U (10009)), "prime 10009");

   ------------------------------------------------------------------
   Section ("4. Invalid_Argument (N < 2)");
   ------------------------------------------------------------------
   Expect_Invalid_Factor ("0", U (0));
   Expect_Invalid_Factor ("1", U (1));

   ------------------------------------------------------------------
   Section ("5. Even N peel");
   ------------------------------------------------------------------
   P := Factor (U (2));
   Check (P.F1 = 1 and then P.F2 = 2, "Factor 2 → (1,2)");
   P := Factor (U (4));
   Check (P.F1 = 2 and then P.F2 = 2, "Factor 4 → (2,2)");
   P := Factor (U (6));
   Check (P.F1 = 2 and then P.F2 = 3, "Factor 6 → (2,3)");
   P := Factor (U (100));
   Check (P.F1 = 2 and then P.F2 = 50, "Factor 100 → (2,50)");
   P := Factor (U (14));
   Check (P.F1 = 2 and then P.F2 = 7, "Factor 14 → (2,7)");

   ------------------------------------------------------------------
   Section ("6. Wikipedia / classic examples");
   ------------------------------------------------------------------
   --  5959 = 59 × 101 (Wikipedia basic method)
   P := Factor (U (5959));
   Check (Product_OK (P, U (5959)), "5959 product");
   Check (P.F1 = 59 and then P.F2 = 101, "5959 → 59×101");

   --  455839 = 599 × 761
   P := Factor (U (455839));
   Check (Product_OK (P, U (455839)), "455839 product");
   Check (P.F1 = 599 and then P.F2 = 761, "455839 → 599×761");

   --  8051 = 83 × 97 (also Pollard's rho wiki example)
   P := Factor (U (8051));
   Check (Product_OK (P, U (8051)), "8051 product");
   Check (P.F1 = 83 and then P.F2 = 97, "8051 → 83×97");

   ------------------------------------------------------------------
   Section ("7. Small semiprimes / close factors");
   ------------------------------------------------------------------
   P := Factor (U (9));
   Check (P.F1 = 3 and then P.F2 = 3, "9 → 3×3");
   P := Factor (U (15));
   Check (P.F1 = 3 and then P.F2 = 5, "15 → 3×5");
   P := Factor (U (21));
   Check (P.F1 = 3 and then P.F2 = 7, "21 → 3×7");
   P := Factor (U (25));
   Check (P.F1 = 5 and then P.F2 = 5, "25 → 5×5");
   P := Factor (U (35));
   Check (P.F1 = 5 and then P.F2 = 7, "35 → 5×7");
   P := Factor (U (49));
   Check (P.F1 = 7 and then P.F2 = 7, "49 → 7×7");
   P := Factor (U (77));
   Check (P.F1 = 7 and then P.F2 = 11, "77 → 7×11");
   P := Factor (U (91));
   Check (P.F1 = 7 and then P.F2 = 13, "91 → 7×13");
   P := Factor (U (143));
   Check (P.F1 = 11 and then P.F2 = 13, "143 → 11×13");
   P := Factor (U (187));
   Check (P.F1 = 11 and then P.F2 = 17, "187 → 11×17");
   P := Factor (U (209));
   Check (P.F1 = 11 and then P.F2 = 19, "209 → 11×19");
   P := Factor (U (319));
   Check (P.F1 = 11 and then P.F2 = 29, "319 → 11×29");
   P := Factor (U (667));
   Check (P.F1 = 23 and then P.F2 = 29, "667 → 23×29");
   P := Factor (U (1147));
   Check (P.F1 = 31 and then P.F2 = 37, "1147 → 31×37");
   P := Factor (U (11413));
   Check (P.F1 = 101 and then P.F2 = 113, "11413 → 101×113");

   --  Very close factors (Fermat's sweet spot)
   P := Factor (U (1_022_117));  -- 1009 × 1013
   Check (P.F1 = 1009 and then P.F2 = 1013, "1009×1013");
   Check (Product_OK (P, U (1_022_117)), "1009×1013 product");

   P := Factor (U (100_160_063));  -- 10007 × 10009
   Check (P.F1 = 10_007 and then P.F2 = 10_009, "10007×10009");
   Check (Product_OK (P, U (100_160_063)), "10007×10009 product");

   P := Factor (U (9_999_399_973));  -- 99991 × 100003
   Check (P.F1 = 99_991 and then P.F2 = 100_003, "99991×100003");
   Check (Product_OK (P, U (9_999_399_973)), "99991×100003 product");

   P := Factor (U (10_002_200_057));  -- 100003 × 100019
   Check (P.F1 = 100_003 and then P.F2 = 100_019, "100003×100019");
   Check (Product_OK (P, U (10_002_200_057)), "100003×100019 product");

   --  2345678901-style (odd composite; Fermat finds a split)
   P := Factor (U (2_345_678_901));
   Check (Product_OK (P, U (2_345_678_901)), "2345678901 product");
   Check (P.F1 > 1 and then P.F2 > P.F1, "2345678901 nontrivial");

   ------------------------------------------------------------------
   Section ("8. Perfect squares");
   ------------------------------------------------------------------
   P := Factor (U (121));
   Check (P.F1 = 11 and then P.F2 = 11, "121 → 11×11");
   P := Factor (U (169));
   Check (P.F1 = 13 and then P.F2 = 13, "169 → 13×13");
   P := Factor (U (289));
   Check (P.F1 = 17 and then P.F2 = 17, "289 → 17×17");
   P := Factor (U (1681));
   Check (P.F1 = 41 and then P.F2 = 41, "1681 → 41×41");
   P := Factor (U (10_000));
   Check (P.F1 = 2 and then P.F2 = 5_000, "10000 even → peel 2");

   ------------------------------------------------------------------
   Section ("9. Primes (trivial 1 × N with enough steps)");
   ------------------------------------------------------------------
   P := Factor (U (3), 10);
   Check (Product_OK (P, U (3)) and then P.F1 = 1, "prime 3 → 1×3");
   P := Factor (U (5), 10);
   Check (Product_OK (P, U (5)) and then P.F1 = 1, "prime 5 → 1×5");
   P := Factor (U (7), 20);
   Check (Product_OK (P, U (7)) and then P.F1 = 1, "prime 7 → 1×7");
   P := Factor (U (11), 30);
   Check (Product_OK (P, U (11)) and then P.F1 = 1, "prime 11 → 1×11");
   P := Factor (U (13), 40);
   Check (Product_OK (P, U (13)) and then P.F1 = 1, "prime 13 → 1×13");
   P := Factor (U (17), 50);
   Check (Product_OK (P, U (17)) and then P.F1 = 1, "prime 17 → 1×17");
   P := Factor (U (19), 50);
   Check (Product_OK (P, U (19)) and then P.F1 = 1, "prime 19 → 1×19");
   P := Factor (U (97), 200);
   Check (Product_OK (P, U (97)) and then P.F1 = 1, "prime 97 → 1×97");

   ------------------------------------------------------------------
   Section ("10. Max_Steps exhaustion");
   ------------------------------------------------------------------
   --  91 = 7×13 needs a few steps; Max_Steps = 0 → fail immediately
   --  after first non-square check increments... actually Steps starts 0,
   --  first miss increments to 1, so Max_Steps=0 fails on first miss.
   P := Factor (U (91), 0);
   Check (Is_Failure (P) or else Product_OK (P, U (91)),
          "91 Max_Steps=0 fail or lucky hit");
   P := Factor (U (91), 1);
   Check (Is_Failure (P) or else Product_OK (P, U (91)),
          "91 Max_Steps=1");
   P := Factor (U (91), 50);
   Check (Product_OK (P, U (91)), "91 Max_Steps=50 finds");
   --  Distant factors / prime with tiny budget → failure sentinel
   P := Factor (U (599), 1);
   Check (Is_Failure (P) or else (P.F1 = 1 and then P.F2 = 599),
          "prime 599 tiny budget");

   ------------------------------------------------------------------
   Section ("11. More products / regression");
   ------------------------------------------------------------------
   P := Factor (U (33));
   Check (P.F1 = 3 and then P.F2 = 11, "33 → 3×11");
   P := Factor (U (39));
   Check (P.F1 = 3 and then P.F2 = 13, "39 → 3×13");
   P := Factor (U (51));
   Check (P.F1 = 3 and then P.F2 = 17, "51 → 3×17");
   P := Factor (U (55));
   Check (P.F1 = 5 and then P.F2 = 11, "55 → 5×11");
   P := Factor (U (57));
   Check (P.F1 = 3 and then P.F2 = 19, "57 → 3×19");
   P := Factor (U (65));
   Check (P.F1 = 5 and then P.F2 = 13, "65 → 5×13");
   P := Factor (U (69));
   Check (P.F1 = 3 and then P.F2 = 23, "69 → 3×23");
   P := Factor (U (85));
   Check (P.F1 = 5 and then P.F2 = 17, "85 → 5×17");
   P := Factor (U (87));
   Check (P.F1 = 3 and then P.F2 = 29, "87 → 3×29");
   P := Factor (U (93));
   Check (P.F1 = 3 and then P.F2 = 31, "93 → 3×31");
   P := Factor (U (95));
   Check (P.F1 = 5 and then P.F2 = 19, "95 → 5×19");
   P := Factor (U (119));
   Check (P.F1 = 7 and then P.F2 = 17, "119 → 7×17");
   P := Factor (U (121));
   Check (P.F1 = 11 and then P.F2 = 11, "121 square again");
   P := Factor (U (133));
   Check (P.F1 = 7 and then P.F2 = 19, "133 → 7×19");
   P := Factor (U (161));
   Check (P.F1 = 7 and then P.F2 = 23, "161 → 7×23");
   P := Factor (U (183));
   Check (P.F1 = 3 and then P.F2 = 61, "183 → 3×61");
   P := Factor (U (221));
   Check (P.F1 = 13 and then P.F2 = 17, "221 → 13×17");
   P := Factor (U (247));
   Check (P.F1 = 13 and then P.F2 = 19, "247 → 13×19");
   P := Factor (U (299));
   Check (P.F1 = 13 and then P.F2 = 23, "299 → 13×23");
   P := Factor (U (323));
   Check (P.F1 = 17 and then P.F2 = 19, "323 → 17×19");
   P := Factor (U (391));
   Check (P.F1 = 17 and then P.F2 = 23, "391 → 17×23");
   P := Factor (U (437));
   Check (P.F1 = 19 and then P.F2 = 23, "437 → 19×23");
   P := Factor (U (529));
   Check (P.F1 = 23 and then P.F2 = 23, "529 → 23×23");
   P := Factor (U (899));
   Check (P.F1 = 29 and then P.F2 = 31, "899 → 29×31");
   P := Factor (U (1073));
   Check (P.F1 = 29 and then P.F2 = 37, "1073 → 29×37");
   P := Factor (U (1517));
   --  1517 = 37 × 41 (close factors)
   Check (P.F1 = 37 and then P.F2 = 41, "1517 → 37×41");
   Check (Product_OK (P, U (1517)), "1517 product OK");

   ------------------------------------------------------------------
   Section ("12. Ordered pair invariant");
   ------------------------------------------------------------------
   for K in U64 range 3 .. 80 loop
      if K rem 2 = 1 then
         P := Factor (K, 5_000);
         if not Is_Failure (P) then
            Check (P.F1 <= P.F2, "ordered F1≤F2 for N=" & K'Image);
            Check (Product_OK (P, K), "product for N=" & K'Image);
         end if;
      end if;
   end loop;

   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Result: " & Pass_Count'Image & " PASS," & Fail_Count'Image & " FAIL");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
