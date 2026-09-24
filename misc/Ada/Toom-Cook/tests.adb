--  Standalone test suite for Toom_Cook (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Toom_Cook; use Toom_Cook;

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

   function Mul_Both_Agree (A, B : Digit_Vector) return Boolean is
      S : constant Digit_Vector := Multiply_Schoolbook (A, B);
      T : constant Digit_Vector := Multiply_Toom3 (A, B);
   begin
      return Equal (S, T);
   end Mul_Both_Agree;

   function Mul_Both_Agree_Th
     (A, B : Digit_Vector; Th : Positive) return Boolean
   is
      S : constant Digit_Vector := Multiply_Schoolbook (A, B);
      T : constant Digit_Vector := Multiply_Toom3 (A, B, Th);
   begin
      return Equal (S, T);
   end Mul_Both_Agree_Th;

begin
   Ada.Text_IO.Put_Line ("Toom_Cook (Toom-3) test suite");
   Ada.Text_IO.Put_Line ("==============================");

   ---------------------------------------------------------------------
   Section ("1. Constants / Zero / One / From_Natural");
   ---------------------------------------------------------------------
   declare
   begin
      Check (Length (From_Natural (Base)) = 2, "Base needs 2 limbs");
      Check (Length (Shift_Limbs (One, Default_Toom3_Threshold))
              = Limb_Count (Default_Toom3_Threshold) + 1,
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
   Section ("3. Compare / Equal / Add / Sub");
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
   end;

   ---------------------------------------------------------------------
   Section ("4. Schoolbook: 0, 1, small, Base powers");
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
   Section ("5. Toom3 vs schoolbook: tiny / threshold edge");
   ---------------------------------------------------------------------
   declare
   begin
      Check (Mul_Both_Agree (Zero, Zero), "T3 0*0");
      Check (Mul_Both_Agree (Zero, One), "T3 0*1");
      Check (Mul_Both_Agree (One, One), "T3 1*1");
      Check (Mul_Both_Agree (From_Natural (12), From_Natural (34)),
             "T3 12*34");
      Check (Mul_Both_Agree (From_Natural (9999), From_Natural (2)),
             "T3 9999*2");
      --  Force a Toom-3 step with low threshold.
      Check (Mul_Both_Agree_Th
               (From_String ("12345678901234567890"),
                From_String ("98765432109876543210"), 2),
             "T3 wiki-sized th=2");
      Check (Mul_Both_Agree_Th
               (From_String ("12345678901234567890"),
                From_String ("98765432109876543210"), 8),
             "T3 wiki-sized th=8");
   end;

   ---------------------------------------------------------------------
   Section ("6. Known products");
   ---------------------------------------------------------------------
   declare
      A : constant Digit_Vector := From_String ("999999999999");
      B : constant Digit_Vector := From_String ("999999999999");
      P : constant Digit_Vector :=
        From_String ("999999999998000000000001");
   begin
      Check (Equal (Multiply_Schoolbook (A, B), P), "SB 12x9^2");
      Check (Equal (Multiply_Toom3 (A, B, 2), P), "T3 12x9^2");
      Check (Equal
               (Multiply_Toom3 (From_String ("2"), From_String ("3"), 1),
                From_String ("6")), "T3 2*3 th=1");
      Check (Equal
               (Multiply_Toom3
                  (From_String ("100000000"), From_String ("100000000"), 2),
                From_String ("10000000000000000")), "T3 (10^8)^2");
   end;

   ---------------------------------------------------------------------
   Section ("7. Powers of Base / uneven lengths");
   ---------------------------------------------------------------------
   declare
      B1 : constant Digit_Vector := Shift_Limbs (One, 1);
      B2 : constant Digit_Vector := Shift_Limbs (One, 2);
      B5 : constant Digit_Vector := Shift_Limbs (One, 5);
      X  : constant Digit_Vector := From_String ("314159265358979");
      Y  : constant Digit_Vector := From_String ("271828");
   begin
      Check (Mul_Both_Agree_Th (B1, B1, 1), "T3 Base*Base");
      Check (Mul_Both_Agree_Th (B2, B5, 1), "T3 Base^2*Base^5");
      Check (Mul_Both_Agree_Th (B5, From_Natural (3), 1), "T3 Base^5*3");
      Check (Mul_Both_Agree_Th (X, Y, 2), "T3 uneven pi*e digits");
      Check (Mul_Both_Agree_Th (Y, X, 2), "T3 commutative check");
   end;

   ---------------------------------------------------------------------
   Section ("8. Larger than threshold (recursive Toom-3)");
   ---------------------------------------------------------------------
   declare
      --  ~60 decimal digits => ~15 limbs > threshold 8
      A : constant Digit_Vector :=
        From_String
          ("123456789012345678901234567890123456789012345678901234567890");
      B : constant Digit_Vector :=
        From_String
          ("987654321098765432109876543210987654321098765432109876543210");
      C : constant Digit_Vector :=
        From_String
          ("111111111111111111111111111111111111111111111111111111111111");
   begin
      Check (Length (A) > Default_Toom3_Threshold, "A above default th");
      Check (Mul_Both_Agree (A, B), "T3 large A*B default th");
      Check (Mul_Both_Agree_Th (A, B, 4), "T3 large A*B th=4");
      Check (Mul_Both_Agree_Th (A, C, 3), "T3 large A*C th=3");
      Check (Mul_Both_Agree_Th (A, One, 2), "T3 large*1");
      Check (Mul_Both_Agree_Th (A, Zero, 2), "T3 large*0");
   end;

   ---------------------------------------------------------------------
   Section ("9. Random-ish pairs vs schoolbook");
   ---------------------------------------------------------------------
   declare
      --  Deterministic LCG-ish decimal strings (no Ada.Numerics needed).
      Seed : Long_Integer := 42;

      procedure Bump is
      begin
         Seed := (Seed * 1103515245 + 12345) mod 2**28;
      end Bump;

      function Next_Digit return Character is
      begin
         Bump;
         return Character'Val
           (Character'Pos ('0') + Integer (Seed mod 10));
      end Next_Digit;

      function Random_String (Len : Positive) return String is
         S : String (1 .. Len);
      begin
         S (1) := Character'Val
           (Character'Pos ('1') + Integer (Seed mod 9));  -- nonzero MSD
         Bump;
         for I in 2 .. Len loop
            S (I) := Next_Digit;
         end loop;
         return S;
      end Random_String;

      All_Ok : Boolean := True;
   begin
      for N in 1 .. 55 loop
         declare
            LA : constant Positive := 1 + (N mod 25);
            LB : constant Positive := 1 + ((N * 3) mod 25);
            SA : constant String := Random_String (LA);
            SB : constant String := Random_String (LB);
            VA : constant Digit_Vector := From_String (SA);
            VB : constant Digit_Vector := From_String (SB);
            Th : constant Positive := 1 + (N mod 6);
         begin
            if not Mul_Both_Agree_Th (VA, VB, Th) then
               All_Ok := False;
               Ada.Text_IO.Put_Line
                 ("  mismatch N=" & Natural'Image (N)
                  & " th=" & Positive'Image (Th));
               Ada.Text_IO.Put_Line ("    A=" & SA);
               Ada.Text_IO.Put_Line ("    B=" & SB);
            end if;
         end;
      end loop;
      Check (All_Ok, "55 random-ish pairs agree (var th)");
   end;

   ---------------------------------------------------------------------
   Section ("10. Exceptions / Invalid_Argument");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
   begin
      Raised := False;
      begin
         declare
            Unused : constant Digit_Vector := From_String ("");
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "From_String empty raises");

      Raised := False;
      begin
         declare
            Unused : constant Digit_Vector := From_String ("12x3");
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "From_String non-digit raises");

      Raised := False;
      begin
         declare
            Unused : constant Digit_Vector :=
              Sub (From_Natural (3), From_Natural (5));
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Sub negative raises");
   end;

   ---------------------------------------------------------------------
   Section ("11. Commutativity / associativity-ish identities");
   ---------------------------------------------------------------------
   declare
      A : constant Digit_Vector := From_String ("123456789");
      B : constant Digit_Vector := From_String ("987654321");
      C : constant Digit_Vector := From_String ("10001");
      AB : constant Digit_Vector := Multiply_Toom3 (A, B, 2);
   begin
      Check (Equal (AB, Multiply_Toom3 (B, A, 2)), "commutative");
      Check
        (Equal
           (Multiply_Toom3 (AB, C, 2),
            Multiply_Schoolbook (Multiply_Schoolbook (A, B), C)),
         " (A*B)*C schoolbook chain");
      Check
        (Equal
           (Add (Multiply_Toom3 (A, B, 2), Multiply_Toom3 (A, C, 2)),
            Multiply_Toom3 (A, Add (B, C), 2)),
         "distributive A*(B+C)");
   end;

   ---------------------------------------------------------------------
   Section ("12. API Length / Compare edge");
   ---------------------------------------------------------------------
   declare
      Big : constant Digit_Vector := Shift_Limbs (From_Natural (3), 10);
   begin
      Check (Length (Big) = 11, "Length shifted");
      Check (Compare (Big, From_Natural (3)) = 1, "shifted > 3");
      Check (Compare (Zero, Zero) = 0, "0 cmp 0");
      Check (Equal (Multiply_Toom3 (Big, Zero), Zero), "big*0");
      Check (Equal (Multiply_Toom3 (Big, One, 2), Big), "big*1 via Toom");
   end;


   ---------------------------------------------------------------------
   Section ("13. Extra schoolbook / Toom-3 matrix");
   ---------------------------------------------------------------------
   declare
      Z40 : constant String := "1" & [1 .. 40 => '0'];
   begin
      Check (Mul_Both_Agree_Th (From_String ("10"), From_String ("10"), 1),
             "10*10");
      Check (Mul_Both_Agree_Th (From_String ("99"), From_String ("99"), 1),
             "99*99");
      Check (Mul_Both_Agree_Th (From_String ("100"), From_String ("100"), 1),
             "100*100");
      Check (Mul_Both_Agree_Th (From_String ("999"), From_String ("1001"), 1),
             "999*1001");
      Check (Mul_Both_Agree_Th (From_String ("65535"), From_String ("65535"), 2),
             "65535^2");
      Check (Mul_Both_Agree_Th (From_String ("2147483647"),
                                From_String ("3"), 2),
             "2^31-1 * 3");
      Check (Mul_Both_Agree_Th (From_String ("1000000007"),
                                From_String ("1000000009"), 2),
             "near-prime product");
      Check (Mul_Both_Agree_Th (From_String ("222222222222222"),
                                From_String ("333333333333333"), 3),
             "repdigit 15x15");
      Check (Mul_Both_Agree_Th (From_String (Z40), From_String (Z40), 4),
             "10^40 * 10^40");
      Check (Mul_Both_Agree_Th (From_String ("99999999999999999999"),
                                From_String ("88888888888888888888"), 3),
             "20-nines * 20-eights");
      Check (Equal
               (Multiply_Toom3 (From_String ("17"), From_String ("19")),
                From_Natural (323)), "17*19 default th");
      Check (Equal
               (Multiply_Schoolbook (From_String ("25"), From_String ("25")),
                From_Natural (625)), "SB 25*25");
      Check (Mul_Both_Agree (From_String ("121"), From_String ("11")),
             "121*11");
      Check (Mul_Both_Agree (From_String ("1024"), From_String ("1024")),
             "1024^2");
      Check (Mul_Both_Agree_Th (Shift_Limbs (From_Natural (9999), 3),
                                Shift_Limbs (From_Natural (9999), 3), 2),
             "shifted 9999^2");
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
