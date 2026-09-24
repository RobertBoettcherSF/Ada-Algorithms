-- luhn.adb
-- Implementation of the Luhn algorithm variants.

package body Luhn is

   -- Helper function to convert a character to its integer equivalent
   function To_Integer (C : Character) return Integer is
   begin
      if C in '0' .. '9' then
         return Character'Pos(C) - Character'Pos('0');
      else
         raise Invalid_Format;
      end if;
   end To_Integer;

   -- Helper function to convert an integer to its character equivalent
   function To_Character (I : Integer) return Check_Digit is
   begin
      if I in 0 .. 9 then
         return Character'Val(I + Character'Pos('0'));
      else
         raise Program_Error; -- Should never be reached in correct logic
      end if;
   end To_Character;

   -- Core algorithm: Computes the Luhn checksum
   -- Is_Complete determines the parity (which digits are doubled).
   function Compute_Checksum (S : Luhn_Sequence; Is_Complete : Boolean) return Integer is
      Sum         : Integer := 0;
      -- If the sequence is incomplete, we assume the check digit will be added at the end.
      -- Thus, the rightmost digit of the partial sequence is in an even position from the right
      -- of the *final* sequence, meaning it MUST be doubled.
      Double_Flag : Boolean := not Is_Complete; 
      Digit       : Integer;
      Clean_Len   : Natural := 0;
      Clean_Str   : String (1 .. S'Length);
   begin
      -- Step 1: Pre-process and sanitize the input (allow spaces, strip them out)
      for I in S'Range loop
         if S(I) /= ' ' then
            Clean_Len := Clean_Len + 1;
            Clean_Str(Clean_Len) := Character(S(I));
         end if;
      end loop;

      -- Edge case: Empty input or only spaces
      if Clean_Len = 0 then
         raise Invalid_Format;
      end if;

      -- Step 2: Iterate right-to-left
      for I in reverse 1 .. Clean_Len loop
         Digit := To_Integer (Clean_Str(I));

         if Double_Flag then
            Digit := Digit * 2;
            -- If doubling results in a number > 9, sum its digits (equivalent to subtracting 9)
            if Digit > 9 then
               Digit := Digit - 9;
            end if;
         end if;

         Sum := Sum + Digit;
         Double_Flag := not Double_Flag; -- Alternate the doubling flag
      end loop;

      return Sum;
   end Compute_Checksum;

   function Validate (Number : Luhn_Sequence) return Boolean is
      Sum : Integer;
   begin
      Sum := Compute_Checksum (Number, Is_Complete => True);
      return (Sum mod 10) = 0;
   end Validate;

   function Calculate_Check_Digit (Partial_Number : Luhn_Sequence) return Check_Digit is
      Sum   : Integer;
      Check : Integer;
   begin
      Sum := Compute_Checksum (Partial_Number, Is_Complete => False);
      -- Calculate what digit needs to be added to make (Sum + Check) mod 10 = 0
      Check := (10 - (Sum mod 10)) mod 10;
      return To_Character(Check);
   end Calculate_Check_Digit;

   function Generate_Full_Number (Partial_Number : Luhn_Sequence) return Luhn_Sequence is
      Check  : Check_Digit;
      Result : String (1 .. Partial_Number'Length + 1);
   begin
      Check := Calculate_Check_Digit (Partial_Number);
      Result (1 .. Partial_Number'Length) := String(Partial_Number);
      Result (Result'Last) := Check;
      return Luhn_Sequence(Result);
   end Generate_Full_Number;

end Luhn;
