--  Version: 0.001
--  Modular_Arithmetic.Check_Digits body.

pragma Ada_2022;

with Modular_Arithmetic.Ring;

package body Modular_Arithmetic.Check_Digits
  with SPARK_Mode => On
is

   package Z97 is new Modular_Arithmetic.Ring (97);
   package Z11 is new Modular_Arithmetic.Ring (11);
   package Z10 is new Modular_Arithmetic.Ring (10);

   subtype Digit is Natural_64 range 0 .. 9;

   function Value (C : Character) return Digit is
     (Character'Pos (C) - Character'Pos ('0'))
     with Pre => Is_Digit (C);

   function To_Char (D : Digit) return Character is
     (Character'Val (Character'Pos ('0') + Integer (D)));

   function Upper (C : Character) return Character is
     (if C in 'a' .. 'z'
      then Character'Val (Character'Pos (C) - 32)
      else C);

   --  Characters of S without the separators Sep1 / Sep2, in Buf (1 .. Len).
   --  Ok is False if more than Buf'Length characters remain.
   procedure Compact
     (S : String; Sep1, Sep2 : Character;
      Buf : out String; Len : out Natural; Ok : out Boolean)
     with Pre  => Buf'First = 1 and then Buf'Length <= Max_Input,
          Post => Len <= Buf'Length
   is
   begin
      Buf := [others => ' '];
      Len := 0;
      Ok  := True;
      for I in S'Range loop
         pragma Loop_Invariant (Len <= Buf'Length);
         if S (I) /= Sep1 and then S (I) /= Sep2 then
            if Len = Buf'Length then
               Ok := False;
               return;
            end if;
            Len := Len + 1;
            Buf (Len) := S (I);
         end if;
      end loop;
   end Compact;

   ----------
   -- IBAN --
   ----------

   --  Feed one IBAN character (digit or upper-case letter) into the
   --  running remainder: digits shift by 10, letters (A = 10 .. Z = 35)
   --  by 100.
   function Feed (Acc : Z97.Residue; C : Character) return Z97.Residue is
     (if Is_Digit (C) then Z97.Add (Z97.Mul (Acc, 10), Value (C))
      else Z97.Add (Z97.Mul (Acc, Z97.Reduce (100)),
                    Natural_64 (Character'Pos (C) - Character'Pos ('A') + 10)))
     with Pre => Is_Digit (C) or else Is_Upper (C);

   function Iban_Valid (S : String) return Boolean is
      Buf : String (1 .. 34);
      Len : Natural;
      Ok  : Boolean;
      Acc : Z97.Residue := 0;
   begin
      Compact (S, ' ', ' ', Buf, Len, Ok);
      if not Ok or else Len < 5 then
         return False;
      end if;
      for I in 1 .. Len loop
         Buf (I) := Upper (Buf (I));
      end loop;
      if not (Is_Upper (Buf (1)) and then Is_Upper (Buf (2))
              and then Is_Digit (Buf (3)) and then Is_Digit (Buf (4)))
      then
         return False;
      end if;
      for I in 5 .. Len loop
         if not (Is_Digit (Buf (I)) or else Is_Upper (Buf (I))) then
            return False;
         end if;
         Acc := Feed (Acc, Buf (I));
      end loop;
      for I in 1 .. 4 loop
         Acc := Feed (Acc, Buf (I));
      end loop;
      return Acc = 1;
   end Iban_Valid;

   function Iban_Check_Digits (Country, Bban : String) return String is
      Acc   : Z97.Residue := 0;
      Check : Natural_64;
   begin
      for C of Bban loop
         Acc := Feed (Acc, C);
      end loop;
      for C of Country loop
         Acc := Feed (Acc, C);
      end loop;
      Acc := Feed (Acc, '0');
      Acc := Feed (Acc, '0');
      Check := 98 - Acc;     --  2 .. 98
      return [To_Char (Check / 10), To_Char (Check mod 10)];
   end Iban_Check_Digits;

   -------------
   -- ISBN-10 --
   -------------

   function Isbn10_Valid (S : String) return Boolean is
      Buf : String (1 .. 10);
      Len : Natural;
      Ok  : Boolean;
      Sum : Z11.Residue := 0;
      D   : Z11.Residue;
   begin
      Compact (S, '-', ' ', Buf, Len, Ok);
      if not Ok or else Len /= 10 then
         return False;
      end if;
      for I in 1 .. 10 loop
         if Is_Digit (Buf (I)) then
            D := Value (Buf (I));
         elsif I = 10 and then (Buf (I) = 'X' or else Buf (I) = 'x') then
            D := 10;
         else
            return False;
         end if;
         Sum := Z11.Add (Sum, Z11.Mul (Natural_64 (11 - I), D));
      end loop;
      return Sum = 0;
   end Isbn10_Valid;

   function Isbn10_Check_Digit (S : String) return Character is
      Sum : Z11.Residue := 0;
      C   : Z11.Residue;
   begin
      for I in S'Range loop
         Sum := Z11.Add
           (Sum, Z11.Mul (Natural_64 (10 - (I - S'First)), Value (S (I))));
      end loop;
      C := Z11.Neg (Sum);    --  weight of the check digit is 1
      return (if C = 10 then 'X' else To_Char (C));
   end Isbn10_Check_Digit;

   --------------------
   -- EAN-13/ISBN-13 --
   --------------------

   function Ean_Weight (I : Positive) return Z10.Residue is
     (if I mod 2 = 1 then 1 else 3);

   function Ean13_Valid (S : String) return Boolean is
      Buf : String (1 .. 13);
      Len : Natural;
      Ok  : Boolean;
      Sum : Z10.Residue := 0;
   begin
      Compact (S, '-', ' ', Buf, Len, Ok);
      if not Ok or else Len /= 13 then
         return False;
      end if;
      for I in 1 .. 13 loop
         if not Is_Digit (Buf (I)) then
            return False;
         end if;
         Sum := Z10.Add (Sum, Z10.Mul (Ean_Weight (I), Value (Buf (I))));
      end loop;
      return Sum = 0;
   end Ean13_Valid;

   function Isbn13_Valid (S : String) return Boolean is
      Buf : String (1 .. 13);
      Len : Natural;
      Ok  : Boolean;
   begin
      Compact (S, '-', ' ', Buf, Len, Ok);
      return Ok and then Len = 13
        and then (Buf (1 .. 3) = "978" or else Buf (1 .. 3) = "979")
        and then Ean13_Valid (S);
   end Isbn13_Valid;

   function Ean13_Check_Digit (S : String) return Character is
      Sum : Z10.Residue := 0;
   begin
      for I in S'Range loop
         Sum := Z10.Add
           (Sum, Z10.Mul (Ean_Weight (I - S'First + 1), Value (S (I))));
      end loop;
      return To_Char (Z10.Neg (Sum));
   end Ean13_Check_Digit;

   ----------
   -- Luhn --
   ----------

   --  Luhn contribution of digit D: doubled digits above 9 lose 9.
   function Luhn_Term (D : Digit; Double : Boolean) return Z10.Residue is
     (if not Double then D
      elsif 2 * D > 9 then Z10.Reduce (2 * D - 9)
      else 2 * D);

   function Luhn_Valid (S : String) return Boolean is
      Buf    : String (1 .. Max_Input);
      Len    : Natural;
      Ok     : Boolean;
      Sum    : Z10.Residue := 0;
      Double : Boolean := False;   --  the rightmost digit is not doubled
   begin
      Compact (S, ' ', ' ', Buf, Len, Ok);
      if not Ok or else Len < 2 then
         return False;
      end if;
      for I in reverse 1 .. Len loop
         if not Is_Digit (Buf (I)) then
            return False;
         end if;
         Sum := Z10.Add (Sum, Luhn_Term (Value (Buf (I)), Double));
         Double := not Double;
      end loop;
      return Sum = 0;
   end Luhn_Valid;

   function Luhn_Check_Digit (S : String) return Character is
      Sum    : Z10.Residue := 0;
      Double : Boolean := True;    --  the check digit will be rightmost
   begin
      for I in reverse S'Range loop
         Sum := Z10.Add (Sum, Luhn_Term (Value (S (I)), Double));
         Double := not Double;
      end loop;
      return To_Char (Z10.Neg (Sum));
   end Luhn_Check_Digit;

end Modular_Arithmetic.Check_Digits;
