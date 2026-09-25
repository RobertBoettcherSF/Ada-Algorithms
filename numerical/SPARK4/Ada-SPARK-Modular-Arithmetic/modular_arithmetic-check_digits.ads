--  Version: 0.001
--  Modular_Arithmetic.Check_Digits: check-digit schemes built on the
--  proved ring operations (instances of Modular_Arithmetic.Ring):
--    IBAN        ISO 13616 / ISO 7064 MOD 97-10   (REQ-019)
--    ISBN-10     weights 10..1, mod 11, 'X' = 10  (REQ-020)
--    ISBN-13 /
--    EAN-13      weights 1,3,1,3,..., mod 10      (REQ-021)
--    Luhn        double every second digit from the right, mod 10 (REQ-022)
--  Validators ignore spaces (and hyphens for ISBN/EAN); they never raise.
--  GNATprove proves absence of run-time errors; the functional behaviour
--  is checked by the tests against published examples.

pragma Ada_2022;

package Modular_Arithmetic.Check_Digits
  with SPARK_Mode => On, Pure
is

   --  PROOF-LATER: Importance 1/10, Urgency 1/10, Ada
   function Is_Digit (C : Character) return Boolean is (C in '0' .. '9');
   --  PROOF-LATER: Importance 1/10, Urgency 1/10, Ada
   function Is_Upper (C : Character) return Boolean is (C in 'A' .. 'Z');

   Max_Input : constant := 1_000;
   --  Longest accepted input string (spaces included).

   ----------
   -- IBAN --
   ----------

   --  PROOF-LATER: Importance 6/10, Urgency 4/10, SPARK3
   function Iban_Valid (S : String) return Boolean
     with Global => null;
   --  True iff S (spaces ignored, letters in either case) is 2 letters,
   --  2 digits and up to 30 letters/digits, 5 .. 34 characters in all,
   --  and the rearranged number is 1 mod 97.  Country-specific lengths
   --  are not checked.

   --  PROOF-LATER: Importance 6/10, Urgency 4/10, SPARK3
   function Iban_Check_Digits (Country, Bban : String) return String
     with Global => null,
          Pre  => Country'Length = 2
                  and then (for all C of Country => Is_Upper (C))
                  and then Bban'Length in 1 .. 30
                  and then (for all C of Bban => Is_Digit (C) or else Is_Upper (C)),
          Post => Iban_Check_Digits'Result'Length = 2
                  and then (for all C of Iban_Check_Digits'Result => Is_Digit (C));
   --  The two check digits (02 .. 98) of Country & "??" & Bban.

   -------------
   -- ISBN-10 --
   -------------

   --  PROOF-LATER: Importance 4/10, Urgency 3/10, SPARK3
   function Isbn10_Valid (S : String) return Boolean
     with Global => null;
   --  10 symbols after removing '-' and ' ': nine digits and a final
   --  digit or 'X'/'x', with sum (10-i+1) * d(i) = 0 mod 11.

   --  PROOF-LATER: Importance 4/10, Urgency 3/10, SPARK3
   function Isbn10_Check_Digit (S : String) return Character
     with Global => null,
          Pre  => S'Length = 9 and then (for all C of S => Is_Digit (C)),
          Post => Is_Digit (Isbn10_Check_Digit'Result)
                  or else Isbn10_Check_Digit'Result = 'X';

   --------------------
   -- EAN-13/ISBN-13 --
   --------------------

   --  PROOF-LATER: Importance 4/10, Urgency 3/10, SPARK3
   function Ean13_Valid (S : String) return Boolean
     with Global => null;
   --  13 digits after removing '-' and ' ', weights 1,3,1,3,...,
   --  weighted sum = 0 mod 10.

   --  PROOF-LATER: Importance 3/10, Urgency 2/10, Ada
   function Isbn13_Valid (S : String) return Boolean
     with Global => null;
   --  Ean13_Valid and the prefix is 978 or 979 (Bookland).

   --  PROOF-LATER: Importance 4/10, Urgency 3/10, SPARK3
   function Ean13_Check_Digit (S : String) return Character
     with Global => null,
          Pre  => S'Length = 12 and then (for all C of S => Is_Digit (C)),
          Post => Is_Digit (Ean13_Check_Digit'Result);

   ----------
   -- Luhn --
   ----------

   --  PROOF-LATER: Importance 5/10, Urgency 3/10, SPARK3
   function Luhn_Valid (S : String) return Boolean
     with Global => null;
   --  At least two digits after removing ' ' (and nothing else), and the
   --  Luhn sum is 0 mod 10.

   --  PROOF-LATER: Importance 5/10, Urgency 3/10, SPARK3
   function Luhn_Check_Digit (S : String) return Character
     with Global => null,
          Pre  => S'Length in 1 .. Max_Input
                  and then (for all C of S => Is_Digit (C)),
          Post => Is_Digit (Luhn_Check_Digit'Result);
   --  The digit to append to S to make it Luhn-valid.

end Modular_Arithmetic.Check_Digits;
