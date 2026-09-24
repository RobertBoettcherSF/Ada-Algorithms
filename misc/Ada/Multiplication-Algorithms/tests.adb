--  Standalone test suite for Multiplication_Algorithms survey (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Multiplication_Algorithms; use Multiplication_Algorithms;

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

   function All_Digit_Methods_Agree (A, B : Digit_Vector) return Boolean is
      S : constant Digit_Vector := Multiply_Schoolbook (A, B);
      K : constant Digit_Vector := Multiply_Karatsuba (A, B);
      L : constant Digit_Vector := Multiply_Lattice (A, B);
      P : constant Digit_Vector := Multiply_Peasant_Digits (A, B);
   begin
      return Equal (S, K) and then Equal (S, L) and then Equal (S, P);
   end All_Digit_Methods_Agree;

   function Agree_Th
     (A, B : Digit_Vector; Th : Positive) return Boolean
   is
      S : constant Digit_Vector := Multiply_Schoolbook (A, B);
      K : constant Digit_Vector := Multiply_Karatsuba (A, B, Th);
   begin
      return Equal (S, K);
   end Agree_Th;

begin
   Ada.Text_IO.Put_Line ("Multiplication Algorithms survey test suite");
   Ada.Text_IO.Put_Line ("===========================================");

   ---------------------------------------------------------------------
   Section ("1. Constants / Zero / One / From_Natural");
   ---------------------------------------------------------------------
   declare
   begin
      Check (Length (From_Natural (Base)) = 2, "Base needs 2 limbs");
      Check (Length (Shift_Limbs (One, Default_Karatsuba_Threshold))
              = Limb_Count (Default_Karatsuba_Threshold) + 1,
             "threshold usable as shift");
      Check (Is_Zero (Zero), "Is_Zero(Zero)");
      Check (not Is_Zero (One), "not Is_Zero(One)");
      Check (Equal (From_Natural (0), Zero), "From_Natural 0");
      Check (Equal (From_Natural (1), One), "From_Natural 1");
      Check (To_Natural (From_Natural (42)) = 42, "To_Natural 42");
      Check (To_Natural (From_Natural (9999)) = 9999, "To_Natural 9999");
      Check (Length (Zero) = 1, "Length Zero");
      Check (Length (From_Natural (10_000)) = 2, "Length Base");
      Check (Get_Digit (From_Natural (10_000), 1) = 0, "digit0 of Base");
      Check (Get_Digit (From_Natural (10_000), 2) = 1, "digit1 of Base");
      Check (Get_Digit (From_Natural (7), 9) = 0, "OOB digit 0");
   end;

   ---------------------------------------------------------------------
   Section ("2. From_String / To_String round-trip");
   ---------------------------------------------------------------------
   declare
      S : constant String := "12345678901234567890";
   begin
      Check (To_String (Zero) = "0", "To_String 0");
      Check (To_String (One) = "1", "To_String 1");
      Check (To_String (From_String ("0")) = "0", "From_String 0");
      Check (To_String (From_String ("00")) = "0", "From_String 00");
      Check (To_String (From_String ("7")) = "7", "From_String 7");
      Check (To_String (From_String (S)) = S, "round-trip big");
      Check (To_String (From_String ("10000")) = "10000", "string Base");
      Check (Equal (A => From_String ("9999"),
                      B => From_Natural (9999)),
             "9999 string/nat");
   end;

   ---------------------------------------------------------------------
   Section ("3. Compare / Equal / Add / Sub / Double / Halve");
   ---------------------------------------------------------------------
   declare
      A : constant Digit_Vector := From_Natural (100);
      B : constant Digit_Vector := From_Natural (40);
      C : constant Digit_Vector := From_String ("100000000");
   begin
      Check (Compare (A => A, B => A) = 0, "Compare eq");
      Check (Compare (A => A, B => B) = 1, "Compare 100>40");
      Check (Compare (A => B, B => A) = -1, "Compare 40<100");
      Check (Equal (A => A, B => From_String ("100")), "Equal 100");
      Check (Equal (A => Add (A, B), B => From_Natural (140)), "Add 100+40");
      Check (Equal (A => Sub (A, B), B => From_Natural (60)), "Sub 100-40");
      Check (Equal (Add (C, One), From_String ("100000001")),
             "Add across limbs");
      Check (Equal (Sub (C, One), From_String ("99999999")),
             "Sub across limbs");
      Check (Equal (A => Shift_Limbs (One, 1),
                      B => From_Natural (Base)),
             "Shift_Limbs 1");
      Check (Equal (A => Shift_Limbs (Zero, 5), B => Zero), "Shift zero");
      Check (Equal (Double (From_Natural (21)), From_Natural (42)),
             "Double 21");
      Check (Equal (Halve (From_Natural (42)), From_Natural (21)),
             "Halve 42");
      Check (Equal (Halve (From_Natural (43)), From_Natural (21)),
             "Halve 43 floor");
      Check (Equal (Halve (Zero), Zero), "Halve 0");
   end;

   ---------------------------------------------------------------------
   Section ("4. Schoolbook: zeros / ones / small / Base");
   ---------------------------------------------------------------------
   declare
   begin
      Check (Equal (Multiply_Schoolbook (Zero, One), Zero), "SB 0*1");
      Check (Equal (Multiply_Schoolbook (One, One), One), "SB 1*1");
      Check (Equal (Multiply_Schoolbook (From_Natural (7), From_Natural (8)),
                    From_Natural (56)), "SB 7*8");
      Check (Equal (Multiply_Schoolbook (From_Natural (9999),
                                         From_Natural (9999)),
                    From_Natural (9999 * 9999)), "SB 9999^2");
      Check (Equal
               (Multiply_Schoolbook (From_Natural (Base), From_Natural (Base)),
                From_String ("100000000")), "SB Base*Base");
      Check (Equal
               (Multiply_Schoolbook (From_String ("12345"),
                                     From_String ("6789")),
                From_String ("83810205")), "SB 12345*6789");
   end;

   ---------------------------------------------------------------------
   Section ("5. Lattice agrees with schoolbook");
   ---------------------------------------------------------------------
   declare
   begin
      Check (Products_Agree_Schoolbook_Lattice (Zero, One), "Lat 0*1");
      Check (Products_Agree_Schoolbook_Lattice (One, One), "Lat 1*1");
      Check (Products_Agree_Schoolbook_Lattice
               (From_Natural (7), From_Natural (8)), "Lat 7*8");
      Check (Products_Agree_Schoolbook_Lattice
               (From_Natural (9999), From_Natural (9999)), "Lat 9999^2");
      Check (Products_Agree_Schoolbook_Lattice
               (From_String ("12345"), From_String ("6789")),
             "Lat 12345*6789");
      Check (Products_Agree_Schoolbook_Lattice
               (From_String ("99999999"), From_String ("11111111")),
             "Lat 8-nines*8-ones");
      Check (Equal
               (Multiply_Lattice (From_Natural (12), From_Natural (34)),
                From_Natural (408)), "Lat 12*34 value");
   end;

   ---------------------------------------------------------------------
   Section ("6. Karatsuba vs schoolbook");
   ---------------------------------------------------------------------
   declare
   begin
      Check (Products_Agree_Schoolbook_Karatsuba (Zero, Zero), "K 0*0");
      Check (Products_Agree_Schoolbook_Karatsuba (Zero, One), "K 0*1");
      Check (Products_Agree_Schoolbook_Karatsuba (One, Zero), "K 1*0");
      Check (Products_Agree_Schoolbook_Karatsuba (One, One), "K 1*1");
      Check (Products_Agree_Schoolbook_Karatsuba
               (From_Natural (12), From_Natural (34)), "K 12*34");
      Check (Products_Agree_Schoolbook_Karatsuba
               (From_Natural (9999), From_Natural (2)), "K 9999*2");
      Check (Agree_Th (From_String ("123456789"), From_String ("987654321"), 1),
             "K th=1 mid");
      Check (Agree_Th (From_String ("9999999999999999"),
                       From_String ("8888888888888888"), 2),
             "K th=2 16-digit");
      Check (Agree_Th (Shift_Limbs (From_Natural (1234), 10),
                       Shift_Limbs (From_Natural (5678), 10), 4),
             "K shifted limbs");
   end;

   ---------------------------------------------------------------------
   Section ("7. Peasant Long_Integer");
   ---------------------------------------------------------------------
   declare
   begin
      Check (Multiply_Peasant (0, 99) = 0, "P 0*99");
      Check (Multiply_Peasant (1, 1) = 1, "P 1*1");
      Check (Multiply_Peasant (7, 8) = 56, "P 7*8");
      Check (Multiply_Peasant (12, 34) = 408, "P 12*34");
      Check (Multiply_Peasant (9999, 9999) = 9999 * 9999, "P 9999^2");
      Check (Multiply_Peasant (2 ** 20, 2 ** 10) = 2 ** 30, "P powers of 2");
      Check (Multiply_Peasant (123456, 789) = 123456 * 789, "P 123456*789");
      Check (Multiply_Peasant (1, Long_Integer (2 ** 30)) = 2 ** 30,
             "P 1*2^30");
   end;

   ---------------------------------------------------------------------
   Section ("8. Peasant Digit_Vector vs schoolbook");
   ---------------------------------------------------------------------
   declare
   begin
      Check (Products_Agree_Schoolbook_Peasant (Zero, One), "PD 0*1");
      Check (Products_Agree_Schoolbook_Peasant (One, One), "PD 1*1");
      Check (Products_Agree_Schoolbook_Peasant
               (From_Natural (7), From_Natural (8)), "PD 7*8");
      Check (Products_Agree_Schoolbook_Peasant
               (From_Natural (9999), From_Natural (9999)), "PD 9999^2");
      Check (Products_Agree_Schoolbook_Peasant
               (From_String ("12345"), From_String ("6789")),
             "PD 12345*6789");
      Check (Products_Agree_Schoolbook_Peasant
               (From_String ("1000000007"), From_String ("97")),
             "PD near-prime*97");
      Check (Equal
               (Multiply_Peasant_Digits (From_Natural (25), From_Natural (25)),
                From_Natural (625)), "PD 25*25 value");
   end;

   ---------------------------------------------------------------------
   Section ("9. All digit methods agree (zeros/ones/random-ish)");
   ---------------------------------------------------------------------
   declare
      type Pair is record
         A, B : Digit_Vector;
      end record;
      Pairs : constant array (Positive range <>) of Pair :=
        [(From_Natural (0), From_Natural (0)),
         (From_Natural (0), From_Natural (1)),
         (From_Natural (1), From_Natural (0)),
         (From_Natural (1), From_Natural (1)),
         (From_Natural (2), From_Natural (3)),
         (From_Natural (99), From_Natural (99)),
         (From_Natural (256), From_Natural (512)),
         (From_String ("123456789"), From_String ("987654321")),
         (From_String ("111111111111"), From_String ("222222222222")),
         (From_String ("999999999999999999"),
          From_String ("1000000007")),
         (From_String ("314159265358"), From_String ("271828182845")),
         (Shift_Limbs (From_Natural (7), 5),
          Shift_Limbs (From_Natural (9), 5))];
   begin
      for I in Pairs'Range loop
         Check (All_Digit_Methods_Agree (Pairs (I).A, Pairs (I).B),
                "all agree #" & Integer'Image (I));
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("10. Complex Karatsuba 3-mul vs naive 4-mul");
   ---------------------------------------------------------------------
   declare
      function C_Eq (P, Q : Complex_Int) return Boolean is
        (P.Re = Q.Re and then P.Im = Q.Im);

      U1 : constant Complex_Int := (Re => 3, Im => 4);
      V1 : constant Complex_Int := (Re => 5, Im => 6);
      --  (3+4i)(5+6i) = 15+18i+20i+24i^2 = -9 + 38i
      U2 : constant Complex_Int := (Re => -2, Im => 7);
      V2 : constant Complex_Int := (Re => 3, Im => -1);
      U3 : constant Complex_Int := (Re => 0, Im => 1);
      V3 : constant Complex_Int := (Re => 0, Im => 1);  -- i*i = -1
      U4 : constant Complex_Int := (Re => 100, Im => -50);
      V4 : constant Complex_Int := (Re => -3, Im => 4);
   begin
      Check (C_Eq (Multiply_Complex_Naive (U1, V1),
                   Multiply_Complex_Karatsuba (U1, V1)),
             "C 3+4i * 5+6i agree");
      Check (Multiply_Complex_Karatsuba (U1, V1).Re = -9
             and then Multiply_Complex_Karatsuba (U1, V1).Im = 38,
             "C 3+4i * 5+6i value");
      Check (C_Eq (Multiply_Complex_Naive (U2, V2),
                   Multiply_Complex_Karatsuba (U2, V2)),
             "C -2+7i * 3-i agree");
      Check (C_Eq (Multiply_Complex_Naive (U3, V3),
                   Multiply_Complex_Karatsuba (U3, V3)),
             "C i*i agree");
      Check (Multiply_Complex_Karatsuba (U3, V3).Re = -1
             and then Multiply_Complex_Karatsuba (U3, V3).Im = 0,
             "C i*i = -1");
      Check (C_Eq (Multiply_Complex_Naive (U4, V4),
                   Multiply_Complex_Karatsuba (U4, V4)),
             "C 100-50i * -3+4i agree");
      Check (C_Eq (Multiply_Complex_Naive ((0, 0), U1), (0, 0)),
             "C 0 * z = 0 naive");
      Check (C_Eq (Multiply_Complex_Karatsuba ((0, 0), U1), (0, 0)),
             "C 0 * z = 0 karatsuba");
   end;

   ---------------------------------------------------------------------
   Section ("11. Invalid_Argument cases");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
   begin
      Raised := False;
      begin
         declare
            Unused : constant Digit_Vector := From_String ("");
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "empty From_String");

      Raised := False;
      begin
         declare
            Unused : constant Digit_Vector := From_String ("12a3");
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "non-digit From_String");

      Raised := False;
      begin
         declare
            Unused : constant Digit_Vector :=
              Sub (From_Natural (3), From_Natural (5));
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Sub underflow");

      Raised := False;
      begin
         declare
            Unused : constant Long_Integer := Multiply_Peasant (-1, 5);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "peasant negative");

      Raised := False;
      begin
         declare
            Unused : constant Natural :=
              To_Natural (From_String ("999999999999999999999999999999"));
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "To_Natural overflow");
   end;

   ---------------------------------------------------------------------
   Section ("12. Extra matrix / threshold edges");
   ---------------------------------------------------------------------
   declare
      Z30 : constant String := "1" & [1 .. 30 => '0'];
   begin
      Check (Agree_Th (From_String ("10"), From_String ("10"), 1), "10*10");
      Check (Agree_Th (From_String ("99"), From_String ("99"), 1), "99*99");
      Check (Agree_Th (From_String ("65535"), From_String ("65535"), 2),
             "65535^2");
      Check (Agree_Th (From_String ("2147483647"), From_String ("3"), 2),
             "2^31-1 * 3");
      Check (Agree_Th (From_String ("1000000007"),
                       From_String ("1000000009"), 2),
             "near-prime product");
      Check (Agree_Th (From_String ("222222222222222"),
                       From_String ("333333333333333"), 3),
             "repdigit 15x15");
      Check (Agree_Th (From_String (Z30), From_String (Z30), 4),
             "10^30 * 10^30");
      Check (All_Digit_Methods_Agree
               (From_String ("99999999"), From_String ("99999999")),
             "8-nines^2 all");
      Check (All_Digit_Methods_Agree
               (From_String ("121"), From_String ("11")), "121*11 all");
      Check (All_Digit_Methods_Agree
               (From_String ("1024"), From_String ("1024")), "1024^2 all");
      Check (Equal
               (Multiply_Karatsuba (From_String ("17"), From_String ("19")),
                From_Natural (323)), "17*19 default th");
      Check (Equal
               (Multiply_Lattice (From_String ("25"), From_String ("25")),
                From_Natural (625)), "Lat 25*25");
      Check (Multiply_Peasant (17, 19) = 323, "P 17*19");
      Check (Products_Agree_Schoolbook_Lattice
               (From_String (Z30), From_Natural (3)), "Lat 10^30 * 3");
      Check (Products_Agree_Schoolbook_Peasant
               (From_String ("7777777"), From_String ("8888888")),
             "PD repdigit");
   end;

   ---------------------------------------------------------------------
   Section ("13. Peasant LI matches Digit schoolbook (small)");
   ---------------------------------------------------------------------
   declare
      Xs : constant array (Positive range <>) of Long_Integer :=
        [0, 1, 7, 64, 255, 9999];
      Ys : constant array (Positive range <>) of Long_Integer :=
        [0, 1, 8, 99, 256, 9999];
   begin
      for I in Xs'Range loop
         for J in Ys'Range loop
            declare
               LI : constant Long_Integer :=
                 Multiply_Peasant (Xs (I), Ys (J));
               DV : constant Digit_Vector :=
                 Multiply_Schoolbook
                   (From_Natural (Natural (Xs (I))),
                    From_Natural (Natural (Ys (J))));
            begin
               Check (LI = Long_Integer (To_Natural (DV)),
                      "P-LI vs SB " & Long_Integer'Image (Xs (I))
                      & " *" & Long_Integer'Image (Ys (J)));
            end;
         end loop;
      end loop;
   end;

   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Results: " & Natural'Image (Pass_Count) & " passed, "
      & Natural'Image (Fail_Count) & " failed");
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Text_IO.Put_Line ("SOME FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
