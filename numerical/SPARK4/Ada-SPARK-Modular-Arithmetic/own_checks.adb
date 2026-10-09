pragma Ada_2022;
--  Own checks for Modular-Arithmetic (V&V sweep, agent A3, 2026-10-09; see
--  tests/SOURCES.txt). No expected value comes from the program or from a
--  published example:
--  * check digits (Luhn, ISBN-10, EAN-13, IBAN) of seeded random inputs,
--    each found by trying every candidate symbol and keeping the one that
--    makes the scheme's defining weighted sum come out right (a search,
--    not the closed formula); the generated code must be that symbol, the
--    completed string must be valid, and every other final symbol invalid;
--  * Extended_Gcd on seeded random 63-bit pairs: G against Stein's binary
--    gcd (shifts and subtractions only, no division), and the Bezout
--    identity A * X + B * Y = G in a 128-bit integer type of its own.
--  Seeded: Park-Miller minimal standard generator; default seed = FNV-1a
--  (32-bit) of the folder name folded into 1 .. 2 ** 31 - 2, printed;
--  AA_SEED=<n> overrides it.
with Ada.Text_IO;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with Modular_Arithmetic;              use Modular_Arithmetic;
with Modular_Arithmetic.Check_Digits; use Modular_Arithmetic.Check_Digits;

procedure Own_Checks with SPARK_Mode => Off is
   Failures : Natural := 0;
   Checked  : Natural := 0;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   function Name_Hash return Long_Long_Integer is
      Name : constant String := "Ada-SPARK-Modular-Arithmetic";
      H    : Unsigned_32 := 2_166_136_261;
   begin
      for C of Name loop
         H := (H xor Unsigned_32 (Character'Pos (C))) * 16_777_619;
      end loop;
      return Long_Long_Integer (H) mod 2_147_483_646 + 1;
   end Name_Hash;

   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : constant Long_Long_Integer :=
        (if V = "" then Default
         else 1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646);
   begin
      Ada.Text_IO.Put_Line
        ("AA_SEED =" & S'Image
         & (if V = "" then " (default: FNV-1a of the folder name)"
            else " (from AA_SEED)"));
      return S;
   end AA_Seed;

   Seed : Long_Long_Integer := AA_Seed (Name_Hash);
   function Next return Natural is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Natural (Seed);
   end Next;

   function Digit (D : Natural) return Character is
     (Character'Val (Character'Pos ('0') + D));
   function Val (C : Character) return Natural is
     (Character'Pos (C) - Character'Pos ('0'));

   function Random_Digits (Len : Positive) return String is
      S : String (1 .. Len);
   begin
      for C of S loop
         C := Digit (Next mod 10);
      end loop;
      return S;
   end Random_Digits;

   --  Luhn: a full code is valid when, counting from the right starting at
   --  1, the digits in even places are doubled and every product's two
   --  decimal digits are added up, and the total is a multiple of 10.
   function Luhn_Total (S : String) return Natural is
      T : Natural := 0;
      P : Natural := 0;
   begin
      for I in reverse S'Range loop
         P := P + 1;
         if P mod 2 = 0 then
            T := T + (2 * Val (S (I))) / 10 + (2 * Val (S (I))) mod 10;
         else
            T := T + Val (S (I));
         end if;
      end loop;
      return T;
   end Luhn_Total;

   --  ISBN-10: weights 10, 9, .., 1 from the left, 'X' = 10, total mod 11 = 0.
   function Isbn_Total (S : String) return Natural is
      T : Natural := 0;
      W : Natural := 10;
   begin
      for C of S loop
         T := T + W * (if C = 'X' then 10 else Val (C));
         W := W - 1;
      end loop;
      return T;
   end Isbn_Total;

   --  EAN-13: weights 1, 3, 1, 3, .. from the left, total mod 10 = 0.
   function Ean_Total (S : String) return Natural is
      T : Natural := 0;
   begin
      for I in S'Range loop
         T := T + (if (I - S'First) mod 2 = 0 then 1 else 3) * Val (S (I));
      end loop;
      return T;
   end Ean_Total;

   --  IBAN (ISO 13616 rule): move the first four characters to the end,
   --  replace A .. Z by 10 .. 35, read the result as one decimal number;
   --  valid when it is 1 mod 97. Here the number is written out as a
   --  decimal string first and then reduced 4 digits at a time.
   function Iban_Rem (S : String) return Natural is
      T : constant String := S (S'First + 4 .. S'Last) & S (S'First .. S'First + 3);
      Num : String (1 .. 2 * T'Length);
      L   : Natural := 0;
      R   : Natural := 0;
      I   : Positive := 1;
   begin
      for C of T loop
         if C in '0' .. '9' then
            L := L + 1; Num (L) := C;
         else
            L := L + 1; Num (L) := Digit ((Character'Pos (C) - 55) / 10);
            L := L + 1; Num (L) := Digit ((Character'Pos (C) - 55) mod 10);
         end if;
      end loop;
      while I <= L loop
         declare
            J : constant Positive := Positive'Min (I + 3, L);
         begin
            R := (R * 10 ** (J - I + 1) + Natural'Value (Num (I .. J))) mod 97;
            I := J + 1;
         end;
      end loop;
      return R;
   end Iban_Rem;

   --  Stein's binary gcd: shifts and subtractions only.
   function Stein (A0, B0 : Natural_64) return Natural_64 is
      A : Natural_64 := A0;
      B : Natural_64 := B0;
      K : Natural := 0;
   begin
      if A = 0 then return B; end if;
      if B = 0 then return A; end if;
      while A mod 2 = 0 and then B mod 2 = 0 loop
         A := A / 2; B := B / 2; K := K + 1;
      end loop;
      while A mod 2 = 0 loop A := A / 2; end loop;
      loop
         while B mod 2 = 0 loop B := B / 2; end loop;
         if A > B then
            declare T : constant Natural_64 := A; begin A := B; B := T; end;
         end if;
         B := B - A;
         exit when B = 0;
      end loop;
      return A * 2 ** K;
   end Stein;

   type I128 is range -(2 ** 127) .. 2 ** 127 - 1;

   function Random_63 return Natural_64 is
     (Natural_64 (Next) * 2 ** 32 + Natural_64 (Next) * 2 + Natural_64 (Next mod 2));
begin
   --  Luhn
   for T in 1 .. 2_000 loop
      declare
         S     : constant String := Random_Digits (1 + Next mod 40);
         Found : Natural := 10;
      begin
         for D in 0 .. 9 loop
            if Luhn_Total (S & Digit (D)) mod 10 = 0 then
               Report (Found = 10, "Luhn: two check digits fit " & S);
               Found := D;
            end if;
         end loop;
         Report (Found < 10 and then Luhn_Check_Digit (S) = Digit (Found),
                 "Luhn_Check_Digit " & S);
         for D in 0 .. 9 loop
            Report (Luhn_Valid (S & Digit (D)) = (D = Found),
                    "Luhn_Valid " & S & Digit (D));
         end loop;
      end;
   end loop;

   --  ISBN-10
   for T in 1 .. 2_000 loop
      declare
         S     : constant String := Random_Digits (9);
         Found : Character := ' ';
      begin
         for C of String'("0123456789X") loop
            if Isbn_Total (S & C) mod 11 = 0 then
               Report (Found = ' ', "ISBN-10: two check symbols fit " & S);
               Found := C;
            end if;
         end loop;
         Report (Found /= ' ' and then Isbn10_Check_Digit (S) = Found,
                 "Isbn10_Check_Digit " & S);
         for C of String'("0123456789X") loop
            Report (Isbn10_Valid (S & C) = (C = Found),
                    "Isbn10_Valid " & S & C);
         end loop;
      end;
   end loop;

   --  EAN-13 / ISBN-13
   for T in 1 .. 2_000 loop
      declare
         S     : constant String :=
           (case T mod 3 is when 0 => "978" & Random_Digits (9),
                            when 1 => "979" & Random_Digits (9),
                            when others => Random_Digits (12));
         Found : Natural := 10;
      begin
         for D in 0 .. 9 loop
            if Ean_Total (S & Digit (D)) mod 10 = 0 then
               Report (Found = 10, "EAN-13: two check digits fit " & S);
               Found := D;
            end if;
         end loop;
         Report (Found < 10 and then Ean13_Check_Digit (S) = Digit (Found),
                 "Ean13_Check_Digit " & S);
         for D in 0 .. 9 loop
            Report (Ean13_Valid (S & Digit (D)) = (D = Found),
                    "Ean13_Valid " & S & Digit (D));
            Report (Isbn13_Valid (S & Digit (D))
                    = (D = Found and then S (1 .. 2) = "97"
                       and then S (3) in '8' | '9'),
                    "Isbn13_Valid " & S & Digit (D));
         end loop;
      end;
   end loop;

   --  IBAN: check digits 02 .. 98 (exactly one of them gives remainder 1)
   for T in 1 .. 1_000 loop
      declare
         Len  : constant Positive := 1 + Next mod 30;
         Bban : String (1 .. Len);
         Cty  : constant String :=
           [Character'Val (65 + Next mod 26), Character'Val (65 + Next mod 26)];
         Found : Natural := 0;
      begin
         for C of Bban loop
            C := (if Next mod 3 = 0 then Character'Val (65 + Next mod 26)
                  else Digit (Next mod 10));
         end loop;
         for K in 2 .. 98 loop
            if Iban_Rem (Cty & Digit (K / 10) & Digit (K mod 10) & Bban) = 1 then
               Report (Found = 0, "IBAN: two check pairs fit " & Cty & Bban);
               Found := K;
            end if;
         end loop;
         Report (Found /= 0
                 and then Iban_Check_Digits (Cty, Bban)
                          = [Digit (Found / 10), Digit (Found mod 10)],
                 "Iban_Check_Digits " & Cty & " " & Bban);
         for K in 0 .. 99 loop
            Report (Iban_Valid (Cty & Digit (K / 10) & Digit (K mod 10) & Bban)
                    = (Iban_Rem (Cty & Digit (K / 10) & Digit (K mod 10) & Bban) = 1),
                    "Iban_Valid " & Cty & K'Image & " " & Bban);
         end loop;
      end;
   end loop;

   --  Extended_Gcd on random 63-bit pairs (with shared factors half the time)
   for T in 1 .. 3_000 loop
      declare
         F : constant Natural_64 := (if T mod 2 = 0 then 1 + Natural_64 (Next mod 100_000) else 1);
         A : constant Natural_64 := (if T mod 7 = 0 then 0 else Random_63 / F * F);
         B : constant Natural_64 := (if T mod 11 = 0 then 0 else Random_63 / F * F);
         E : constant Bezout := Extended_Gcd (A, B);
      begin
         Report (E.G = Stein (A, B), "Gcd vs Stein" & A'Image & B'Image);
         Report (I128 (A) * I128 (E.X) + I128 (B) * I128 (E.Y) = I128 (E.G),
                 "Bezout" & A'Image & B'Image);
      end;
   end loop;

   Ada.Text_IO.Put_Line ("own checks:" & Checked'Image & " checks," & Failures'Image & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
