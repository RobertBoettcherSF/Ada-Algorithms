--  Standalone test suite for Long_Division (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Long_Division; use Long_Division;

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

   function Rem_Identity
     (N, D : Digit_Vector; Res : Division_Result) return Boolean
   is
      Prod : constant Digit_Vector :=
        Multiply_Schoolbook (Res.Quotient, D);
      Sum  : constant Digit_Vector := Add (Prod, Res.Remainder);
   begin
      return Equal (Sum, N)
        and then Compare (Res.Remainder, D) < 0;
   end Rem_Identity;

   procedure Check_Long
     (Ns, Ds, Qs, Rs : String; Label : String)
   is
      N   : constant Digit_Vector := From_String (Ns);
      D   : constant Digit_Vector := From_String (Ds);
      Res : constant Division_Result := Divide_Long (N, D);
   begin
      Check (To_String (Res.Quotient) = Qs
               and then To_String (Res.Remainder) = Rs
               and then Rem_Identity (N, D, Res),
             Label);
   end Check_Long;

   procedure Check_Vs_Oracle
     (N, D : Long_Integer; Label : String)
   is
      Res   : constant Division_Result :=
        Divide_Long (From_Long_Integer (N), From_Long_Integer (D));
      Exact : constant Signed_Division_Result := Exact_Divide (N, D);
   begin
      Check (To_Long_Integer (Res.Quotient) = Exact.Quotient
               and then To_Long_Integer (Res.Remainder) = Exact.Remainder
               and then Rem_Identity
                 (From_Long_Integer (N), From_Long_Integer (D), Res),
             Label);
   end Check_Vs_Oracle;

begin
   Ada.Text_IO.Put_Line ("Long_Division test suite");
   Ada.Text_IO.Put_Line ("========================");

   ---------------------------------------------------------------------
   Section ("1. Constants / Zero / One / From_Natural");
   ---------------------------------------------------------------------
   Check (Is_Zero (Zero), "Is_Zero(Zero)");
   Check (not Is_Zero (One), "not Is_Zero(One)");
   Check (Equal (From_Natural (0), Zero), "From_Natural 0");
   Check (Equal (From_Natural (1), One), "From_Natural 1");
   Check (To_Natural (From_Natural (42)) = 42, "To_Natural 42");
   Check (To_Natural (From_Natural (9)) = 9, "To_Natural 9");
   Check (Length (Zero) = 1, "Length Zero");
   Check (Length (From_Natural (10)) = 2, "Length 10");
   Check (Get_Digit (From_Natural (10), 1) = 0, "digit0 of 10");
   Check (Get_Digit (From_Natural (10), 2) = 1, "digit1 of 10");
   Check (Get_Digit (From_Natural (7), 9) = 0, "OOB digit 0");
   Check (Length (From_Natural (1000)) = 4, "Length 1000");
   Check (Digit'Last = 9, "Digit range 0..9");
   Check (Length (From_Natural (10)) = 2, "10 has two limbs");

   ---------------------------------------------------------------------
   Section ("2. From_String / To_String / Long_Integer");
   ---------------------------------------------------------------------
   Check (To_String (Zero) = "0", "To_String 0");
   Check (To_String (One) = "1", "To_String 1");
   Check (To_String (From_String ("0")) = "0", "From_String 0");
   Check (To_String (From_String ("00")) = "0", "From_String 00");
   Check (To_String (From_String ("7")) = "7", "From_String 7");
   Check (To_String (From_String ("850")) = "850", "From_String 850");
   Check (To_String (From_String ("123456789012345678")) =
            "123456789012345678",
          "round-trip 18 digits");
   Check (Equal (From_String ("9999"), From_Natural (9999)),
          "9999 string/nat");
   Check (To_Long_Integer (From_String ("12345")) = 12_345,
          "To_Long_Integer 12345");
   Check (Equal (From_Long_Integer (98765), From_String ("98765")),
          "From_Long_Integer 98765");

   ---------------------------------------------------------------------
   Section ("3. Compare / Equal / Add / Sub / Shift");
   ---------------------------------------------------------------------
   declare
      A : constant Digit_Vector := From_Natural (100);
      B : constant Digit_Vector := From_Natural (40);
      C : constant Digit_Vector := From_String ("100000");
   begin
      Check (Compare (A, A) = 0, "Compare eq");
      Check (Compare (A, B) = 1, "Compare 100>40");
      Check (Compare (A => B, B => A) = -1, "Compare 40<100");
      Check (Equal (A, From_String ("100")), "Equal 100");
      Check (Equal (Add (A, B), From_Natural (140)), "Add 100+40");
      Check (Equal (Sub (A, B), From_Natural (60)), "Sub 100-40");
      Check (Equal (Add (C, One), From_String ("100001")), "Add 100000+1");
      Check (Equal (Sub (C, One), From_String ("99999")), "Sub 100000-1");
      Check (Equal (Shift_Limbs (One, 1), From_Natural (10)),
             "Shift_Limbs 1");
      Check (Equal (Shift_Limbs (Zero, 5), Zero), "Shift zero");
      Check (Equal (Shift_Limbs (From_Natural (25), 2),
                      From_Natural (2500)),
             "Shift 25 by 2");
   end;

   ---------------------------------------------------------------------
   Section ("4. Multiply_By_Digit / Schoolbook");
   ---------------------------------------------------------------------
   Check (Equal (Multiply_By_Digit (From_Natural (25), 0), Zero),
          "25*0");
   Check (Equal (Multiply_By_Digit (From_Natural (25), 1),
                   From_Natural (25)),
          "25*1");
   Check (Equal (Multiply_By_Digit (From_Natural (25), 4),
                   From_Natural (100)),
          "25*4");
   Check (Equal (Multiply_By_Digit (From_Natural (999), 9),
                   From_Natural (8991)),
          "999*9");
   Check (Equal (Multiply_Schoolbook (From_Natural (12), From_Natural (34)),
                   From_Natural (408)),
          "12*34 schoolbook");
   Check (Equal (Multiply_Schoolbook (From_Natural (850), From_Natural (25)),
                   From_Natural (21_250)),
          "850*25 schoolbook");
   Check (Is_Zero (Multiply_Schoolbook (Zero, From_Natural (99))),
          "0*99");
   Check (Equal (Multiply_Schoolbook (From_String ("123"),
                                        From_String ("456")),
                   From_String ("56088")),
          "123*456");

   ---------------------------------------------------------------------
   Section ("5. Classic long division examples");
   ---------------------------------------------------------------------
   --  Wikipedia-style: 500 / 4 = 125 r 0
   Check_Long ("500", "4", "125", "0", "500/4 = 125");
   --  Spec example: 850 / 25 = 34 r 0
   Check_Long ("850", "25", "34", "0", "850/25 = 34");
   Check_Long ("127", "4", "31", "3", "127/4 = 31 r 3");
   Check_Long ("100", "3", "33", "1", "100/3 = 33 r 1");
   Check_Long ("999", "9", "111", "0", "999/9 = 111");
   Check_Long ("1000", "10", "100", "0", "1000/10 = 100");
   Check_Long ("7", "8", "0", "7", "7/8 = 0 r 7");
   Check_Long ("8", "8", "1", "0", "8/8 = 1");
   Check_Long ("81", "9", "9", "0", "81/9 = 9");
   Check_Long ("144", "12", "12", "0", "144/12 = 12");
   Check_Long ("987654", "321", "3076", "258", "987654/321");
   Check_Long ("1", "1", "1", "0", "1/1 = 1");
   Check_Long ("0", "5", "0", "0", "0/5 = 0");
   Check_Long ("999999", "7", "142857", "0", "999999/7");
   Check_Long ("123456789", "12345", "10000", "6789", "123456789/12345");

   ---------------------------------------------------------------------
   Section ("6. Short division (single-digit divisor)");
   ---------------------------------------------------------------------
   declare
      procedure Check_Short
        (Ns : String; D : Digit; Qs, Rs : String; Label : String)
      is
         N   : constant Digit_Vector := From_String (Ns);
         Res : constant Division_Result := Divide_Short (N, D);
         Long_Res : constant Division_Result :=
           Divide_Long (N, From_Natural (Natural (D)));
      begin
         Check (To_String (Res.Quotient) = Qs
                  and then To_String (Res.Remainder) = Rs
                  and then Equal (Res.Quotient, Long_Res.Quotient)
                  and then Equal (Res.Remainder, Long_Res.Remainder),
                Label);
      end Check_Short;
   begin
      Check_Short ("500", 4, "125", "0", "short 500/4");
      Check_Short ("127", 4, "31", "3", "short 127/4");
      Check_Short ("999", 9, "111", "0", "short 999/9");
      Check_Short ("100", 3, "33", "1", "short 100/3");
      Check_Short ("7", 8, "0", "7", "short 7/8");
      Check_Short ("0", 5, "0", "0", "short 0/5");
      Check_Short ("81", 9, "9", "0", "short 81/9");
      Check_Short ("123456789", 9, "13717421", "0", "short 123456789/9");
      Check_Short ("222222", 2, "111111", "0", "short 222222/2");
      Check_Short ("1000001", 7, "142857", "2", "short 1000001/7");
   end;

   ---------------------------------------------------------------------
   Section ("7. Oracle pairs (Long_Integer / rem)");
   ---------------------------------------------------------------------
   Check_Vs_Oracle (850, 25, "oracle 850/25");
   Check_Vs_Oracle (500, 4, "oracle 500/4");
   Check_Vs_Oracle (1, 1, "oracle 1/1");
   Check_Vs_Oracle (0, 9, "oracle 0/9");
   Check_Vs_Oracle (99, 10, "oracle 99/10");
   Check_Vs_Oracle (1_000_000, 7, "oracle 1e6/7");
   Check_Vs_Oracle (9_876_543_210, 12345, "oracle big/12345");
   Check_Vs_Oracle (2**30, 17, "oracle 2^30/17");
   Check_Vs_Oracle (123_456_789, 98765, "oracle 123456789/98765");
   Check_Vs_Oracle (999_999_999, 111_111, "oracle 999999999/111111");

   --  Systematic small grid
   declare
      Count : Natural := 0;
   begin
      for N in Long_Integer range 0 .. 80 loop
         for D in Long_Integer range 1 .. 17 loop
            declare
               Res   : constant Division_Result :=
                 Divide_Long (From_Long_Integer (N), From_Long_Integer (D));
               Exact : constant Signed_Division_Result :=
                 Exact_Divide (N, D);
               OK    : constant Boolean :=
                 To_Long_Integer (Res.Quotient) = Exact.Quotient
                 and then To_Long_Integer (Res.Remainder) = Exact.Remainder;
            begin
               if not OK then
                  Fail_Count := Fail_Count + 1;
                  Ada.Text_IO.Put_Line
                    ("  FAIL: grid N=" & N'Image & " D=" & D'Image);
               else
                  Count := Count + 1;
               end if;
            end;
         end loop;
      end loop;
      Check (Count = 81 * 17, "grid 0..80 x 1..17 all match oracle");
   end;

   ---------------------------------------------------------------------
   Section ("8. Random-ish / larger digit strings");
   ---------------------------------------------------------------------
   declare
      Pairs : constant array (1 .. 20, 1 .. 2) of Long_Integer :=
        [[111111111, 37],
         [222222222, 41],
         [333333333, 43],
         [444444444, 47],
         [555555555, 53],
         [666666666, 59],
         [777777777, 61],
         [888888888, 67],
         [999999999, 71],
         [1234567890, 89],
         [9876543210, 97],
         [3141592653, 101],
         [2718281828, 103],
         [1618033988, 107],
         [1414213562, 109],
         [1732050807, 113],
         [2_000_000_000, 127],
         [1_999_999_999, 131],
         [1_234_567_890, 137],
         [9_876_543_210, 139]];
   begin
      for I in Pairs'Range (1) loop
         Check_Vs_Oracle
           (Pairs (I, 1), Pairs (I, 2),
            "pair" & I'Image);
      end loop;
   end;

   --  Digit-string remainder property without Long_Integer (18+ digits)
   declare
      N : constant Digit_Vector :=
        From_String ("123456789012345678901234");
      D : constant Digit_Vector := From_String ("987654321");
      Res : constant Division_Result := Divide_Long (N, D);
   begin
      Check (Rem_Identity (N, D, Res), "big digit rem identity");
      Check (not Is_Zero (Res.Quotient), "big digit quotient nonzero");
   end;

   declare
      N : constant Digit_Vector :=
        From_String ("999999999999999999999999");
      D : constant Digit_Vector := From_String ("111111111111");
      Res : constant Division_Result := Divide_Long (N, D);
   begin
      Check (Rem_Identity (N, D, Res), "24-nines rem identity");
   end;

   ---------------------------------------------------------------------
   Section ("9. Signed magnitudes / Exact_Divide");
   ---------------------------------------------------------------------
   declare
      S : Signed_Division_Result;
   begin
      S := Divide_Signed_Values (850, 25);
      Check (S.Quotient = 34 and then S.Remainder = 0, "signed +/+");
      S := Divide_Signed_Values (-850, 25);
      Check (S.Quotient = -34 and then S.Remainder = 0, "signed -/+");
      S := Divide_Signed_Values (850, -25);
      Check (S.Quotient = -34 and then S.Remainder = 0, "signed +/-");
      S := Divide_Signed_Values (-850, -25);
      Check (S.Quotient = 34 and then S.Remainder = 0, "signed -/-");
      S := Divide_Signed_Values (-127, 4);
      Check (S.Quotient = -31 and then S.Remainder = -3,
             "signed -127/4 rem");
      S := Exact_Divide (-127, 4);
      Check (S.Quotient = -31 and then S.Remainder = -3, "exact -127/4");
      S := Divide_Signed_Values (100, -7);
      Check (S.Quotient = -14 and then S.Remainder = 2, "signed 100/-7");
      declare
         Mag : constant Division_Result := Divide_Signed (-850, 25);
      begin
         Check (To_String (Mag.Quotient) = "34"
                  and then To_String (Mag.Remainder) = "0",
                "Divide_Signed magnitudes");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("10. Invalid_Argument / edge cases");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
   begin
      Raised := False;
      begin
         declare
            Unused : constant Division_Result :=
              Divide_Long (From_Natural (1), Zero);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Divide_Long zero divisor");

      Raised := False;
      begin
         declare
            Unused : constant Division_Result :=
              Divide_Short (From_Natural (10), 0);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Divide_Short zero digit");

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
      Check (Raised, "From_String empty");

      Raised := False;
      begin
         declare
            Unused : constant Digit_Vector := From_String ("12a3");
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "From_String non-digit");

      Raised := False;
      begin
         declare
            Unused : constant Digit_Vector := From_Long_Integer (-1);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "From_Long_Integer negative");

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
      Check (Raised, "Sub underflow");

      Raised := False;
      begin
         declare
            Unused : constant Signed_Division_Result :=
              Exact_Divide (1, 0);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Exact_Divide zero");

      Raised := False;
      begin
         declare
            Unused : constant Signed_Division_Result :=
              Divide_Signed_Values (1, 0);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Divide_Signed_Values zero");
   end;

   ---------------------------------------------------------------------
   Section ("11. More remainder-property spot checks");
   ---------------------------------------------------------------------
   declare
      procedure Spot (Ns, Ds : String; Label : String) is
         N   : constant Digit_Vector := From_String (Ns);
         D   : constant Digit_Vector := From_String (Ds);
         Res : constant Division_Result := Divide_Long (N, D);
      begin
         Check (Rem_Identity (N, D, Res), Label);
      end Spot;
   begin
      Spot ("10", "2", "spot 10/2");
      Spot ("11", "2", "spot 11/2");
      Spot ("99", "1", "spot 99/1");
      Spot ("100", "99", "spot 100/99");
      Spot ("1000", "999", "spot 1000/999");
      Spot ("2024", "23", "spot 2024/23");
      Spot ("65536", "256", "spot 65536/256");
      Spot ("1000000007", "97", "spot prime-ish");
      Spot ("314159265358", "271828", "spot pi/e digits");
      Spot ("99991", "991", "spot 99991/991");
   end;

   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Result: " & Pass_Count'Image & " passed," & Fail_Count'Image
      & " failed");
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Text_IO.Put_Line ("SOME FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
