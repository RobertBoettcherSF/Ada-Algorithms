--  Standalone test suite for Binary_GCD (SPARK port).
--  Preconditions replace exceptions; only valid call paths are exercised.

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Binary_GCD; use Binary_GCD;

procedure Tests
  with SPARK_Mode => Off
is

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

   --  Non-static views (avoid -gnatwa constant-condition warnings).
   function U (X : U64) return U64 is (X);

   function Img (N : U64) return String is
   begin
      return U64'Image (N);
   end Img;

begin
   Ada.Text_IO.Put_Line ("Binary_GCD (SPARK) tests");
   Ada.Text_IO.Put_Line ("========================");

   ------------------------------------------------------------------
   Section ("1. Trailing_Zeros / shifts / Is_Odd");
   ------------------------------------------------------------------
   Check (Trailing_Zeros (U (0)) = 64, "tz(0)=64");
   Check (Trailing_Zeros (U (1)) = 0, "tz(1)=0");
   Check (Trailing_Zeros (U (2)) = 1, "tz(2)=1");
   Check (Trailing_Zeros (U (4)) = 2, "tz(4)=2");
   Check (Trailing_Zeros (U (8)) = 3, "tz(8)=3");
   Check (Trailing_Zeros (U (16)) = 4, "tz(16)=4");
   Check (Trailing_Zeros (U (12)) = 2, "tz(12)=2");
   Check (Trailing_Zeros (U (48)) = 4, "tz(48)=4");
   Check (Trailing_Zeros (U (7)) = 0, "tz(7)=0");
   Check (Trailing_Zeros (U (1024)) = 10, "tz(1024)=10");

   Check (Shift_Right (U (16), 2) = 4, "shr 16>>2");
   Check (Shift_Right (U (1), 1) = 0, "shr 1>>1");
   Check (Shift_Right (U (255), 8) = 0, "shr 255>>8");
   Check (Shift_Right (U (100), 0) = 100, "shr 100>>0");
   Check (Shift_Right (U (1), 64) = 0, "shr amount>=64");
   Check (Shift_Left (U (3), 2) = 12, "shl 3<<2");
   Check (Shift_Left (U (1), 10) = 1024, "shl 1<<10");
   Check (Shift_Left (U (5), 0) = 5, "shl 5<<0");
   Check (Shift_Left (U (1), 64) = 0, "shl amount>=64");

   Check (Is_Odd (U (1)), "odd 1");
   Check (Is_Odd (U (7)), "odd 7");
   Check (not Is_Odd (U (0)), "not odd 0");
   Check (not Is_Odd (U (8)), "not odd 8");
   Check (Is_Odd (U (99)), "odd 99");

   ------------------------------------------------------------------
   Section ("2. Gcd basics (Stein)");
   ------------------------------------------------------------------
   Check (Gcd (U (0), U (0)) = 0, "gcd(0,0)=0");
   Check (Gcd (U (0), U (7)) = 7, "gcd(0,7)=7");
   Check (Gcd (U (7), U (0)) = 7, "gcd(7,0)=7");
   Check (Gcd (U (1), U (0)) = 1, "gcd(1,0)=1");
   Check (Gcd (U (0), U (1)) = 1, "gcd(0,1)=1");
   Check (Gcd (U (1), U (1)) = 1, "gcd(1,1)=1");
   Check (Gcd (U (54), U (24)) = 6, "gcd(54,24)=6");
   Check (Gcd (U (24), U (54)) = 6, "gcd(24,54)=6");
   Check (Gcd (U (17), U (13)) = 1, "gcd(17,13)=1");
   Check (Gcd (U (100), U (25)) = 25, "gcd(100,25)=25");
   Check (Gcd (U (270), U (192)) = 6, "gcd(270,192)=6");
   Check (Gcd (U (2), U (4)) = 2, "gcd(2,4)=2");
   Check (Gcd (U (12), U (18)) = 6, "gcd(12,18)=6");
   Check (Gcd (U (35), U (15)) = 5, "gcd(35,15)=5");
   Check (Gcd (U (1071), U (462)) = 21, "gcd(1071,462)=21");
   Check (Gcd (U (48), U (18)) = 6, "gcd(48,18)=6");
   Check (Gcd (U (299), U (221)) = 13, "gcd(299,221)=13");
   Check (Gcd (U (91), U (39)) = 13, "gcd(91,39)=13");
   Check (Gcd (U (1001), U (91)) = 91, "gcd(1001,91)=91");
   Check (Gcd (U (128), U (64)) = 64, "gcd(128,64)=64");
   Check (Gcd (U (81), U (27)) = 27, "gcd(81,27)=27");
   Check (Gcd (U (9), U (6)) = 3, "gcd(9,6)=3");
   Check (Gcd (U (Max_Educational), U (1)) = 1, "gcd(Max_Ed,1)");
   Check (Gcd (U (Max_Educational), U (Max_Educational)) = Max_Educational,
          "gcd(Max_Ed,Max_Ed)");

   ------------------------------------------------------------------
   Section ("3. Powers of two / mixed parity");
   ------------------------------------------------------------------
   Check (Gcd (U (16), U (24)) = 8, "gcd(16,24)=8");
   Check (Gcd (U (32), U (48)) = 16, "gcd(32,48)=16");
   Check (Gcd (U (64), U (96)) = 32, "gcd(64,96)=32");
   Check (Gcd (U (7), U (14)) = 7, "gcd(7,14)=7");
   Check (Gcd (U (15), U (25)) = 5, "gcd(15,25)=5");
   Check (Gcd (U (21), U (14)) = 7, "gcd(21,14)=7");
   Check (Gcd (U (33), U (44)) = 11, "gcd(33,44)=11");
   Check (Gcd (U (55), U (89)) = 1, "gcd(55,89)=1 fib");
   Check (Gcd (U (144), U (89)) = 1, "gcd(144,89)=1");
   Check (Gcd (U (1024), U (768)) = 256, "gcd(1024,768)=256");
   Check (Gcd (U (3), U (5)) = 1, "gcd(3,5)=1");
   Check (Gcd (U (8), U (1)) = 1, "gcd(8,1)=1");
   Check (Gcd (U (1), U (8)) = 1, "gcd(1,8)=1");
   Check (Gcd (U (2), U (3)) = 1, "gcd(2,3)=1");
   Check (Gcd (U (6), U (35)) = 1, "gcd(6,35)=1");

   ------------------------------------------------------------------
   Section ("4. Commutativity");
   ------------------------------------------------------------------
   declare
      Pairs : constant array (Positive range <>) of U64 :=
        [0, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144,
         99, 78, 1001, 91, 100, 35, 270, 192, 54, 24,
         1071, 462, 128, 96, 81, 27, 48, 18];
      I, J : Positive;
   begin
      I := Pairs'First;
      while I < Pairs'Last loop
         J := I + 1;
         declare
            A : constant U64 := Pairs (I);
            B : constant U64 := Pairs (J);
            G1 : constant U64 := Gcd (A, B);
            G2 : constant U64 := Gcd (A => B, B => A);
         begin
            Check (G1 = G2,
                   "comm" & Img (A) & "," & Img (B));
         end;
         I := I + 2;
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("5. Gcd_Recursive agrees with Gcd");
   ------------------------------------------------------------------
   declare
      Pairs : constant array (Positive range <>) of U64 :=
        [0, 0, 0, 7, 7, 0, 1, 1, 54, 24, 17, 13,
         100, 25, 270, 192, 35, 15, 1071, 462,
         16, 24, 128, 64, 91, 39, 48, 18, 3, 5,
         1024, 768, 81, 27, 33, 44, 55, 89,
         9, 6, 2, 4, 12, 18, 299, 221];
      I : Positive := Pairs'First;
   begin
      while I < Pairs'Last loop
         declare
            A : constant U64 := Pairs (I);
            B : constant U64 := Pairs (I + 1);
         begin
            Check (Gcd (A, B) = Gcd_Recursive (A, B),
                   "rec vs iter" & Img (A) & "," & Img (B));
         end;
         I := I + 2;
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("6. Stein vs classical Euclidean");
   ------------------------------------------------------------------
   declare
      Pairs : constant array (Positive range <>) of U64 :=
        [0, 0, 0, 1, 1, 0, 54, 24, 17, 13, 100, 25,
         270, 192, 35, 15, 1071, 462, 16, 24, 128, 64,
         91, 39, 48, 18, 3, 5, 1024, 768, 81, 27,
         33, 44, 55, 89, 9, 6, 2, 4, 12, 18, 299, 221,
         1001, 91, 997, 991, 123456, 7890, 999999, 12345,
         2 ** 20, 3 * 5 * 7 * 11, 2 ** 16, 2 ** 10 + 1,
         Max_Educational, 42, Max_Educational, Max_Educational];
      I : Positive := Pairs'First;
   begin
      while I < Pairs'Last loop
         declare
            A : constant U64 := Pairs (I);
            B : constant U64 := Pairs (I + 1);
            Gs : constant U64 := Gcd (A, B);
            Ge : constant U64 := Gcd_Euclidean (A, B);
         begin
            Check (Gs = Ge,
                   "stein=euclid" & Img (A) & "," & Img (B));
         end;
         I := I + 2;
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("7. Exhaustive small grid (Stein = Euclidean)");
   ------------------------------------------------------------------
   declare
      Count_Local : Natural := 0;
   begin
      for A in U64 range 0 .. 40 loop
         for B in U64 range 0 .. 40 loop
            if Gcd (A, B) = Gcd_Euclidean (A, B) then
               Count_Local := Count_Local + 1;
            end if;
         end loop;
      end loop;
      Check (Count_Local = 41 * 41, "grid 0..40 all match (" &
             Natural'Image (Count_Local) & " pairs)");
      Check (Gcd (U (0), U (0)) = Gcd_Euclidean (U (0), U (0)),
             "grid cell 0,0");
      Check (Gcd (U (20), U (30)) = Gcd_Euclidean (U (20), U (30)),
             "grid cell 20,30");
      Check (Gcd (U (40), U (40)) = Gcd_Euclidean (U (40), U (40)),
             "grid cell 40,40");
      Check (Gcd (U (37), U (1)) = 1, "grid gcd(37,1)");
      Check (Gcd (U (36), U (24)) = 12, "grid gcd(36,24)");
   end;

   ------------------------------------------------------------------
   Section ("8. Are_Coprime");
   ------------------------------------------------------------------
   Check (Are_Coprime (U (17), U (13)), "coprime 17,13");
   Check (Are_Coprime (U (1), U (99)), "coprime 1,99");
   Check (Are_Coprime (U (8), U (9)), "coprime 8,9");
   Check (Are_Coprime (U (35), U (18)), "coprime 35,18");
   Check (not Are_Coprime (U (54), U (24)), "not coprime 54,24");
   Check (not Are_Coprime (U (0), U (0)), "not coprime 0,0");
   Check (not Are_Coprime (U (0), U (5)), "not coprime 0,5");
   Check (Are_Coprime (U (1), U (0)), "coprime 1,0");
   Check (Are_Coprime (U (997), U (991)), "coprime primes");

   ------------------------------------------------------------------
   Section ("9. Large / edge U64 values");
   ------------------------------------------------------------------
   declare
      Big1 : constant U64 := 2 ** 63;
      Big2 : constant U64 := 2 ** 62;
      Odd_Big : constant U64 := 2 ** 63 - 1;  --  Mersenne
   begin
      Check (Gcd (Big1, Big2) = Big2, "gcd(2^63,2^62)=2^62");
      Check (Gcd (Big1, U (0)) = Big1, "gcd(2^63,0)");
      Check (Gcd (U (0), Big1) = Big1, "gcd(0,2^63)");
      Check (Gcd (Big1, U (1)) = 1, "gcd(2^63,1)");
      Check (Gcd (Odd_Big, U (1)) = 1, "gcd(2^63-1,1)");
      Check (Gcd (Odd_Big, Odd_Big) = Odd_Big, "gcd(m,m)");
      Check (Gcd (Big1, Odd_Big) = 1, "gcd(2^63,2^63-1)=1");
      Check (Gcd (Big1, Big2) = Gcd_Euclidean (Big1, Big2),
             "stein=euclid large powers");
      Check (Gcd (Odd_Big, U (3)) = Gcd_Euclidean (Odd_Big, U (3)),
             "stein=euclid mersenne,3");
      --  Recursive is Pre-capped at Max_Educational; check educational
      --  large-ish pair instead of full U64 recursive depth.
      Check (Gcd (U (2 ** 16), U (2 ** 10 + 7)) =
             Gcd_Euclidean (U (2 ** 16), U (2 ** 10 + 7)),
             "stein=euclid 2^16 vs 2^10+7");
      Check (Gcd (U (2 ** 16), U (2 ** 10 + 7)) =
             Gcd_Recursive (U (2 ** 16), U (2 ** 10 + 7)),
             "rec 2^16 vs 2^10+7");
      Check (Gcd (U (2 ** 40), U (2 ** 30 + 7)) =
             Gcd_Euclidean (U (2 ** 40), U (2 ** 30 + 7)),
             "stein=euclid 2^40 vs 2^30+7");
   end;

   ------------------------------------------------------------------
   Section ("10. Fibonacci-ish / Wikipedia-style pairs");
   ------------------------------------------------------------------
   Check (Gcd (U (610), U (377)) = 1, "fib F15,F14");
   Check (Gcd (U (987), U (610)) = 1, "fib F16,F15");
   Check (Gcd (U (2584), U (1597)) = 1, "fib F18,F17");
   Check (Gcd (U (240), U (46)) = 2, "wikipedia-ish 240,46");
   Check (Gcd (U (1071), U (462)) = Gcd_Recursive (U (1071), U (462)),
          "rec 1071,462");
   Check (Gcd (U (4096), U (1536)) = 512, "gcd(4096,1536)=512");
   Check (Gcd (U (65536), U (4096)) = 4096, "gcd(2^16,2^12)");
   Check (Are_Coprime (U (610), U (377)), "fib coprime");
   Check (not Are_Coprime (U (240), U (46)), "240,46 not coprime");

   ------------------------------------------------------------------
   -- Summary
   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("================");
   Ada.Text_IO.Put_Line
     ("  Passed:" & Natural'Image (Pass_Count));
   Ada.Text_IO.Put_Line
     ("  Failed:" & Natural'Image (Fail_Count));
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL TESTS PASSED");
   else
      Ada.Text_IO.Put_Line ("SOME TESTS FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;

end Tests;
