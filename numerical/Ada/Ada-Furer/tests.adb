--  Standalone test suite for Furer (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Furer; use Furer;

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

   function Mul_Agree (A, B : Digit_Vector) return Boolean is
      S : constant Digit_Vector := Multiply_Schoolbook (A, B);
      N : constant Digit_Vector := Multiply_NTT (A, B);
      T : constant Digit_Vector := Multiply_Furer (A, B);
   begin
      return Equal (S, N) and then Equal (S, T);
   end Mul_Agree;

   function Mul_Agree_Th
     (A, B : Digit_Vector; Th : Positive) return Boolean
   is
      S : constant Digit_Vector := Multiply_Schoolbook (A, B);
      T : constant Digit_Vector := Multiply_Furer (A, B, Th);
   begin
      return Equal (S, T);
   end Mul_Agree_Th;

   Seed : Long_Integer := 42;

   function Next_Rand return Natural is
   begin
      Seed := (Seed * 1_103_515_245 + 12_345) mod 2**28;
      return Natural (Seed);
   end Next_Rand;

   function Random_Digits (Num_Digits : Positive) return Digit_Vector is
      Buf : String (1 .. Num_Digits);
      D   : Natural;
   begin
      for I in Buf'Range loop
         D := Next_Rand mod 10;
         if I = 1 and then D = 0 then
            D := 1 + (Next_Rand mod 9);
         end if;
         Buf (I) := Character'Val (Character'Pos ('0') + D);
      end loop;
      return From_String (Buf);
   end Random_Digits;

begin
   Ada.Text_IO.Put_Line ("Furer (NTT teaching sketch) test suite");
   Ada.Text_IO.Put_Line ("=====================================");

   Section ("1. Constants / Zero / One / From_Natural");
   declare
   begin
      Check (Length (From_Natural (Base)) = 2, "Base needs 2 limbs");
      Check (Length (Shift_Limbs (One, Default_Furer_Threshold))
              = Limb_Count (Default_Furer_Threshold) + 1,
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
      Check (Length (Shift_Limbs (One, Max_Operand_Limbs - 1))
              = Limb_Count (Max_Operand_Limbs),
             "Max_Operand_Limbs reachable");
      Check (Length (Shift_Limbs (One, Default_Furer_Threshold))
              > Limb_Count (Default_Furer_Threshold / 2),
             "threshold mid-point");
   end;

   Section ("2. From_String / To_String round-trip");
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

   Section ("3. Compare / Equal / Add / Sub");
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

   Section ("4. Schoolbook: 0, 1, small, Base powers");
   declare
      A : constant Digit_Vector := From_Natural (1234);
      B : constant Digit_Vector := From_Natural (5678);
      P : constant Digit_Vector :=
        Multiply_Schoolbook (From_Natural (Base), From_Natural (Base));
   begin
      Check (Equal (Multiply_Schoolbook (Zero, A), Zero), "SB 0*x");
      Check (Equal (Multiply_Schoolbook (A, Zero), Zero), "SB x*0");
      Check (Equal (Multiply_Schoolbook (One, A), A), "SB 1*x");
      Check (Equal (Multiply_Schoolbook (A, One), A), "SB x*1");
      Check (Equal (Multiply_Schoolbook (A, B), From_Natural (7_006_652)),
             "SB 1234*5678");
      Check (Equal (P, From_String ("100000000")), "SB Base*Base");
      Check (Equal (Multiply_Schoolbook (Shift_Limbs (One, 3),
                                           From_Natural (2)),
                      From_String ("2000000000000")),
             "SB Base^3 * 2");
   end;

   Section ("5. NTT vs schoolbook: zero / one / small");
   declare
      A : constant Digit_Vector := From_Natural (9999);
      B : constant Digit_Vector := From_Natural (9999);
   begin
      Check (Equal (Multiply_NTT (Zero, A), Zero), "NTT 0*x");
      Check (Equal (Multiply_NTT (One, A), A), "NTT 1*x");
      Check (Equal (Multiply_NTT (A, One), A), "NTT x*1");
      Check (Mul_Agree (A, B), "NTT=SB 9999*9999");
      Check (Mul_Agree (From_Natural (2), From_Natural (3)), "NTT=SB 2*3");
      Check (Mul_Agree (From_Natural (Base), From_Natural (Base)),
             "NTT=SB Base*Base");
      Check (Mul_Agree (From_String ("123456789"), From_String ("987654321")),
             "NTT=SB 9-digit");
   end;

   Section ("6. Multiply_Furer threshold / schoolbook fallback");
   declare
      A : constant Digit_Vector := From_String ("12345678901234567890");
      B : constant Digit_Vector := From_String ("98765432109876543210");
   begin
      Check (Mul_Agree_Th (A, B, 100), "Furer threshold 100 => schoolbook");
      Check (Mul_Agree_Th (A, B, 1), "Furer threshold 1 => NTT");
      Check (Mul_Agree (A, B), "Furer default agrees");
      Check (Equal (Multiply_Furer (Zero, A), Zero), "Furer 0*x");
      Check (Equal (Multiply_Furer (One, B), B), "Furer 1*x");
   end;

   Section ("7. Powers of Base");
   declare
   begin
      for K in 1 .. 8 loop
         declare
            Bk : constant Digit_Vector := Shift_Limbs (One, K);
            Bn : constant Digit_Vector := Shift_Limbs (One, K + 2);
         begin
            Check (Mul_Agree (Bk, From_Natural (7)),
                   "Base^" & Integer'Image (K) & " * 7");
            Check (Mul_Agree (Bk, Bn),
                   "Base^" & Integer'Image (K)
                   & " * Base^" & Integer'Image (K + 2));
         end;
      end loop;
   end;

   Section ("8. Random-ish pairs within cap");
   declare
   begin
      for Trial in 1 .. 20 loop
         declare
            DA : constant Positive := 1 + (Next_Rand mod 48);
            DB : constant Positive := 1 + (Next_Rand mod 48);
            A  : constant Digit_Vector := Random_Digits (DA);
            B  : constant Digit_Vector := Random_Digits (DB);
         begin
            Check (Mul_Agree (A, B),
                   "random " & Integer'Image (DA)
                   & "d x" & Integer'Image (DB) & "d");
         end;
      end loop;
   end;

   Section ("9. Near-cap limb products");
   declare
      A : constant Digit_Vector :=
        From_String ("9999999999999999999999999999");
      B : constant Digit_Vector :=
        From_String ("8888888888888888888888888888");
      C : constant Digit_Vector := Shift_Limbs (From_Natural (9999), 10);
      D : constant Digit_Vector := Shift_Limbs (From_Natural (1234), 12);
   begin
      Check (Mul_Agree (A, B), "near-full 28-digit");
      Check (Mul_Agree (C, D), "shifted limbs product");
      Check (Mul_Agree (A, One), "near-full * 1");
      Check (Mul_Agree (C, From_Natural (Base)), "shift * Base");
   end;

   Section ("10. Invalid_Argument");
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
      Check (Raised, "empty From_String");

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
      Check (Raised, "non-digit From_String");

      Raised := False;
      begin
         declare
            Unused : constant Digit_Vector :=
              Sub (From_Natural (1), From_Natural (2));
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Sub underflow");
   end;

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line (
     "Result: " & Natural'Image (Pass_Count) & " passed,"
     & Natural'Image (Fail_Count) & " failed");
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Text_IO.Put_Line ("SOME FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
