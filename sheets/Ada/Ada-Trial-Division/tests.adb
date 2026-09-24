--  Standalone test suite for Trial_Division (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Trial_Division; use Trial_Division;

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

   function Factors_Equal
     (Got      : Factor_List;
      Expected : Factor_List) return Boolean
   is
   begin
      if Got'Length /= Expected'Length then
         return False;
      end if;
      for I in Expected'Range loop
         declare
            G : constant Prime_Power := Got (Got'First + (I - Expected'First));
            E : constant Prime_Power := Expected (I);
         begin
            if G.Prime /= E.Prime or else G.Exponent /= E.Exponent then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Factors_Equal;

   function Product_Of (F : Factor_List) return U64 is
      P : U64 := 1;
   begin
      for PP of F loop
         for K in 1 .. PP.Exponent loop
            P := P * PP.Prime;
         end loop;
      end loop;
      return P;
   end Product_Of;

   procedure Expect_Invalid_Is_Prime (Label : String; N : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Boolean := Is_Prime (N);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Is_Prime: " & Label);
   end Expect_Invalid_Is_Prime;

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

   procedure Expect_Invalid_Factorize (Label : String; N : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Factor_List := Factorize (N);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Factorize: " & Label);
   end Expect_Invalid_Factorize;

begin
   Ada.Text_IO.Put_Line ("Trial_Division — Ada 2023 test suite");

   ------------------------------------------------------------------
   Section ("1. Floor_Sqrt");
   ------------------------------------------------------------------
   Check (Floor_Sqrt (U (0)) = 0, "sqrt(0)=0");
   Check (Floor_Sqrt (U (1)) = 1, "sqrt(1)=1");
   Check (Floor_Sqrt (U (2)) = 1, "sqrt(2)=1");
   Check (Floor_Sqrt (U (3)) = 1, "sqrt(3)=1");
   Check (Floor_Sqrt (U (4)) = 2, "sqrt(4)=2");
   Check (Floor_Sqrt (U (8)) = 2, "sqrt(8)=2");
   Check (Floor_Sqrt (U (9)) = 3, "sqrt(9)=3");
   Check (Floor_Sqrt (U (15)) = 3, "sqrt(15)=3");
   Check (Floor_Sqrt (U (16)) = 4, "sqrt(16)=4");
   Check (Floor_Sqrt (U (100)) = 10, "sqrt(100)=10");
   Check (Floor_Sqrt (U (101)) = 10, "sqrt(101)=10");
   Check (Floor_Sqrt (U (10_000)) = 100, "sqrt(10000)=100");
   Check (Floor_Sqrt (U (1_000_000)) = 1_000, "sqrt(10^6)=1000");
   Check (Floor_Sqrt (U (2 ** 32)) = U64 (2 ** 16), "sqrt(2^32)=2^16");
   Check (Floor_Sqrt (U (2 ** 60)) = U64 (2 ** 30), "sqrt(2^60)=2^30");

   ------------------------------------------------------------------
   Section ("2. Invalid_Argument (N=0) and N=1 special");
   ------------------------------------------------------------------
   Expect_Invalid_Is_Prime ("0", U (0));
   Expect_Invalid_SPF ("0", U (0));
   Expect_Invalid_Factorize ("0", U (0));
   Expect_Invalid_SPF ("1", U (1));
   Check (not Is_Prime (U (1)), "1 is not prime");
   declare
      F1 : constant Factor_List := Factorize (U (1));
   begin
      Check (F1'Length = 0, "Factorize(1) empty");
   end;

   ------------------------------------------------------------------
   Section ("3. Is_Prime — small primes / composites");
   ------------------------------------------------------------------
   Check (Is_Prime (U (2)), "prime 2");
   Check (Is_Prime (U (3)), "prime 3");
   Check (Is_Prime (U (5)), "prime 5");
   Check (Is_Prime (U (7)), "prime 7");
   Check (Is_Prime (U (11)), "prime 11");
   Check (Is_Prime (U (13)), "prime 13");
   Check (Is_Prime (U (17)), "prime 17");
   Check (Is_Prime (U (19)), "prime 19");
   Check (Is_Prime (U (23)), "prime 23");
   Check (Is_Prime (U (29)), "prime 29");
   Check (Is_Prime (U (31)), "prime 31");
   Check (Is_Prime (U (37)), "prime 37");
   Check (Is_Prime (U (41)), "prime 41");
   Check (Is_Prime (U (43)), "prime 43");
   Check (Is_Prime (U (47)), "prime 47");
   Check (Is_Prime (U (53)), "prime 53");
   Check (Is_Prime (U (59)), "prime 59");
   Check (Is_Prime (U (61)), "prime 61");
   Check (Is_Prime (U (67)), "prime 67");
   Check (Is_Prime (U (71)), "prime 71");
   Check (Is_Prime (U (73)), "prime 73");
   Check (Is_Prime (U (79)), "prime 79");
   Check (Is_Prime (U (83)), "prime 83");
   Check (Is_Prime (U (89)), "prime 89");
   Check (Is_Prime (U (97)), "prime 97");

   Check (not Is_Prime (U (4)), "composite 4");
   Check (not Is_Prime (U (6)), "composite 6");
   Check (not Is_Prime (U (8)), "composite 8");
   Check (not Is_Prime (U (9)), "composite 9");
   Check (not Is_Prime (U (15)), "composite 15");
   Check (not Is_Prime (U (21)), "composite 21");
   Check (not Is_Prime (U (25)), "composite 25");
   Check (not Is_Prime (U (27)), "composite 27");
   Check (not Is_Prime (U (33)), "composite 33");
   Check (not Is_Prime (U (35)), "composite 35");
   Check (not Is_Prime (U (49)), "composite 49");
   Check (not Is_Prime (U (51)), "composite 51");
   Check (not Is_Prime (U (55)), "composite 55");
   Check (not Is_Prime (U (77)), "composite 77");
   Check (not Is_Prime (U (91)), "composite 91=7*13");
   Check (not Is_Prime (U (100)), "composite 100");
   Check (not Is_Prime (U (121)), "composite 121");
   Check (not Is_Prime (U (143)), "composite 143");
   Check (not Is_Prime (U (169)), "composite 169");

   ------------------------------------------------------------------
   Section ("4. Smallest_Prime_Factor");
   ------------------------------------------------------------------
   Check (Smallest_Prime_Factor (U (2)) = 2, "SPF(2)=2");
   Check (Smallest_Prime_Factor (U (3)) = 3, "SPF(3)=3");
   Check (Smallest_Prime_Factor (U (4)) = 2, "SPF(4)=2");
   Check (Smallest_Prime_Factor (U (9)) = 3, "SPF(9)=3");
   Check (Smallest_Prime_Factor (U (15)) = 3, "SPF(15)=3");
   Check (Smallest_Prime_Factor (U (25)) = 5, "SPF(25)=5");
   Check (Smallest_Prime_Factor (U (35)) = 5, "SPF(35)=5");
   Check (Smallest_Prime_Factor (U (49)) = 7, "SPF(49)=7");
   Check (Smallest_Prime_Factor (U (70)) = 2, "SPF(70)=2");
   Check (Smallest_Prime_Factor (U (97)) = 97, "SPF(97)=97");
   Check (Smallest_Prime_Factor (U (91)) = 7, "SPF(91)=7");
   Check (Smallest_Prime_Factor (U (121)) = 11, "SPF(121)=11");
   Check (Smallest_Prime_Factor (U (143)) = 11, "SPF(143)=11");
   Check (Smallest_Prime_Factor (U (1001)) = 7, "SPF(1001)=7");

   ------------------------------------------------------------------
   Section ("5. Factorize — wiki / classic examples");
   ------------------------------------------------------------------
   declare
      F70 : constant Factor_List := Factorize (U (70));
      E70 : constant Factor_List :=
        [(Prime => 2, Exponent => 1),
         (Prime => 5, Exponent => 1),
         (Prime => 7, Exponent => 1)];
   begin
      Check (Factors_Equal (F70, E70), "70 = 2·5·7");
      Check (Product_Of (F70) = 70, "product(70 factors)=70");
   end;

   declare
      F100 : constant Factor_List := Factorize (U (100));
      E100 : constant Factor_List :=
        [(Prime => 2, Exponent => 2),
         (Prime => 5, Exponent => 2)];
   begin
      Check (Factors_Equal (F100, E100), "100 = 2²·5²");
      Check (Product_Of (F100) = 100, "product(100)=100");
   end;

   declare
      F97 : constant Factor_List := Factorize (U (97));
   begin
      Check (F97'Length = 1 and then F97 (1).Prime = 97
             and then F97 (1).Exponent = 1,
             "97 is prime power 97^1");
   end;

   declare
      F8 : constant Factor_List := Factorize (U (8));
      E8 : constant Factor_List := [(Prime => 2, Exponent => 3)];
   begin
      Check (Factors_equal (F8, E8), "8 = 2³");
   end;

   declare
      F12 : constant Factor_List := Factorize (U (12));
      E12 : constant Factor_List :=
        [(Prime => 2, Exponent => 2),
         (Prime => 3, Exponent => 1)];
   begin
      Check (Factors_equal (F12, E12), "12 = 2²·3");
   end;

   declare
      F360 : constant Factor_List := Factorize (U (360));
      E360 : constant Factor_List :=
        [(Prime => 2, Exponent => 3),
         (Prime => 3, Exponent => 2),
         (Prime => 5, Exponent => 1)];
   begin
      Check (Factors_Equal (F360, E360), "360 = 2³·3²·5");
   end;

   declare
      F2310 : constant Factor_List := Factorize (U (2310));
      E2310 : constant Factor_List :=
        [(Prime => 2, Exponent => 1),
         (Prime => 3, Exponent => 1),
         (Prime => 5, Exponent => 1),
         (Prime => 7, Exponent => 1),
         (Prime => 11, Exponent => 1)];
   begin
      Check (Factors_Equal (F2310, E2310), "2310 = 2·3·5·7·11");
   end;

   ------------------------------------------------------------------
   Section ("6. Cross-check Is_Prime for all N in 1 .. 1000");
   ------------------------------------------------------------------
   declare
      --  Known primes ≤ 100 (and extend via trial reference below).
      function Ref_Is_Prime (N : U64) return Boolean is
         D : U64;
      begin
         if N < 2 then
            return False;
         end if;
         if N = 2 or else N = 3 then
            return True;
         end if;
         if (N and 1) = 0 or else N rem 3 = 0 then
            return False;
         end if;
         D := 5;
         while D * D <= N loop
            if N rem D = 0 or else N rem (D + 2) = 0 then
               return False;
            end if;
            D := D + 6;
         end loop;
         return True;
      end Ref_Is_Prime;

      Mismatches : Natural := 0;
      Checked    : Natural := 0;
   begin
      for N in U64 range 1 .. 1_000 loop
         Checked := Checked + 1;
         if Is_Prime (N) /= Ref_Is_Prime (N) then
            Mismatches := Mismatches + 1;
         end if;
      end loop;
      Check (Mismatches = 0, "Is_Prime matches ref for N=1..1000");
      Check (Checked = 1_000, "checked 1000 values");
   end;

   ------------------------------------------------------------------
   Section ("7. Factorize product identity for N=2..500");
   ------------------------------------------------------------------
   declare
      Bad : Natural := 0;
   begin
      for N in U64 range 2 .. 500 loop
         declare
            F : constant Factor_List := Factorize (N);
         begin
            if Product_Of (F) /= N then
               Bad := Bad + 1;
            end if;
            --  Each prime power should itself be "prime-looking"
            for PP of F loop
               if not Is_Prime (PP.Prime) or else PP.Exponent = 0 then
                  Bad := Bad + 1;
               end if;
            end loop;
            --  Strictly increasing primes
            for I in F'First .. F'Last - 1 loop
               if F (I).Prime >= F (I + 1).Prime then
                  Bad := Bad + 1;
               end if;
            end loop;
         end;
      end loop;
      Check (Bad = 0, "Factorize product+prime+order for N=2..500");
   end;

   ------------------------------------------------------------------
   Section ("8. SPF consistency with Factorize");
   ------------------------------------------------------------------
   declare
      Bad : Natural := 0;
   begin
      for N in U64 range 2 .. 300 loop
         declare
            F : constant Factor_List := Factorize (N);
            S : constant U64 := Smallest_Prime_Factor (N);
         begin
            if F'Length = 0 or else F (F'First).Prime /= S then
               Bad := Bad + 1;
            end if;
         end;
      end loop;
      Check (Bad = 0, "SPF = first Factorize prime for N=2..300");
   end;

   ------------------------------------------------------------------
   Section ("9. Larger known values");
   ------------------------------------------------------------------
   Check (Is_Prime (U (1_000_003)), "1000003 prime");
   Check (not Is_Prime (U (1_000_001)), "1000001 composite");
   Check (Is_Prime (U (999_983)), "999983 prime");
   Check (Is_Prime (U (65_537)), "Fermat F4=65537 prime");
   Check (not Is_Prime (U (65_535)), "65535 composite");
   Check (Smallest_Prime_Factor (U (1_000_001)) = 101,
          "SPF(1000001)=101");
   Check (Smallest_Prime_Factor (U (2047)) = 23, "SPF(2047)=23");
   declare
      F2047 : constant Factor_List := Factorize (U (2047));
      E2047 : constant Factor_List :=
        [(Prime => 23, Exponent => 1),
         (Prime => 89, Exponent => 1)];
   begin
      Check (Factors_Equal (F2047, E2047), "2047 = 23·89");
   end;

   declare
      F : constant Factor_List := Factorize (U (2 ** 10));
   begin
      Check (F'Length = 1 and then F (1).Prime = 2
             and then F (1).Exponent = 10,
             "2^10 = 2^10");
   end;

   Check (Floor_Sqrt (U (2 ** 50)) = U64 (2 ** 25), "sqrt(2^50)=2^25");
   Check (Is_Prime (U (1_000_000_007)), "10^9+7 prime");
   Check (not Is_Prime (U (1_000_000_011)), "10^9+11 composite");

   ------------------------------------------------------------------
   Section ("10. More composites / primes ≤ 200 sample");
   ------------------------------------------------------------------
   Check (not Is_Prime (U (111)), "111=3·37");
   Check (not Is_Prime (U (119)), "119=7·17");
   Check (not Is_Prime (U (121)), "121=11^2");
   Check (not Is_Prime (U (123)), "123=3·41");
   Check (not Is_Prime (U (125)), "125=5^3");
   Check (not Is_Prime (U (133)), "133=7·19");
   Check (not Is_Prime (U (143)), "143=11·13");
   Check (Is_Prime (U (101)), "101");
   Check (Is_Prime (U (103)), "103");
   Check (Is_Prime (U (107)), "107");
   Check (Is_Prime (U (109)), "109");
   Check (Is_Prime (U (113)), "113");
   Check (Is_Prime (U (127)), "127");
   Check (Is_Prime (U (131)), "131");
   Check (Is_Prime (U (137)), "137");
   Check (Is_Prime (U (139)), "139");
   Check (Is_Prime (U (149)), "149");
   Check (Is_Prime (U (151)), "151");
   Check (Is_Prime (U (157)), "157");
   Check (Is_Prime (U (163)), "163");
   Check (Is_Prime (U (167)), "167");
   Check (Is_Prime (U (173)), "173");
   Check (Is_Prime (U (179)), "179");
   Check (Is_Prime (U (181)), "181");
   Check (Is_Prime (U (191)), "191");
   Check (Is_Prime (U (193)), "193");
   Check (Is_Prime (U (197)), "197");
   Check (Is_Prime (U (199)), "199");

   ------------------------------------------------------------------
   Section ("11. Factorize squares / cubes");
   ------------------------------------------------------------------
   declare
      F49 : constant Factor_List := Factorize (U (49));
   begin
      Check (F49'Length = 1 and then F49 (1).Prime = 7
             and then F49 (1).Exponent = 2, "49=7²");
   end;
   declare
      F121 : constant Factor_List := Factorize (U (121));
   begin
      Check (F121'Length = 1 and then F121 (1).Prime = 11
             and then F121 (1).Exponent = 2, "121=11²");
   end;
   declare
      F125 : constant Factor_List := Factorize (U (125));
   begin
      Check (F125'Length = 1 and then F125 (1).Prime = 5
             and then F125 (1).Exponent = 3, "125=5³");
   end;
   declare
      F720 : constant Factor_List := Factorize (U (720));
      E720 : constant Factor_List :=
        [(Prime => 2, Exponent => 4),
         (Prime => 3, Exponent => 2),
         (Prime => 5, Exponent => 1)];
   begin
      Check (Factors_equal (F720, E720), "720=2⁴·3²·5");
   end;

   ------------------------------------------------------------------
   --  Summary
   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("================================");
   Ada.Text_IO.Put_Line
     ("Result: " & Pass_Count'Image & " PASS," & Fail_Count'Image & " FAIL");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
