--  damm_algorithm.adb
--  Implementation of the Damm Algorithm.
--  Uses the quasigroup of order 10 defined by H. Michael Damm.

package body Damm_Algorithm is

   --  The totally anti-symmetric quasigroup 10x10 table.
   type Quasigroup_Table is array (Digit, Digit) of Digit;
   
   Table : constant Quasigroup_Table :=
     (
      (0, 3, 1, 7, 5, 9, 8, 6, 4, 2),
      (7, 0, 9, 2, 1, 5, 4, 8, 6, 3),
      (4, 2, 0, 6, 8, 7, 1, 3, 5, 9),
      (1, 7, 5, 0, 9, 8, 3, 4, 2, 6),
      (6, 1, 2, 3, 0, 4, 5, 9, 7, 8),
      (3, 6, 7, 4, 2, 0, 9, 5, 8, 1),
      (5, 8, 6, 9, 7, 2, 0, 1, 3, 4),
      (8, 9, 4, 5, 3, 6, 2, 0, 1, 7),
      (9, 4, 3, 8, 6, 1, 7, 2, 0, 5),
      (2, 5, 8, 1, 4, 3, 6, 7, 9, 0)
     );

   -------------------------------------------------------------------------
   --  Calculate_Check_Digit
   -------------------------------------------------------------------------
   function Calculate_Check_Digit (Number : Digit_Array) return Digit is
      Interim : Digit := 0;
   begin
      if Number'Length = 0 then
         raise Invalid_Input with
           "Cannot calculate check digit for empty array";
      end if;

      for I in Number'Range loop
         Interim := Table (Interim, Number (I));
      end loop;
      
      return Interim;
   end Calculate_Check_Digit;

   -------------------------------------------------------------------------
   --  Verify_Number
   -------------------------------------------------------------------------
   function Verify_Number (Number : Digit_Array) return Boolean is
      Interim : Digit := 0;
   begin
      if Number'Length < 2 then
         raise Invalid_Input with
           "Number must have at least one digit and a check digit";
      end if;

      for I in Number'Range loop
         Interim := Table (Interim, Number (I));
      end loop;
      
      --  Valid if the final interim value evaluates to 0
      return Interim = 0;
   end Verify_Number;

   -------------------------------------------------------------------------
   --  Append_Check_Digit
   -------------------------------------------------------------------------
   function Append_Check_Digit (Number : Digit_Array) return Digit_Array is
      Check_Digit : constant Digit := Calculate_Check_Digit (Number);
      Result      : Digit_Array (1 .. Number'Length + 1);
   begin
      Result (1 .. Number'Length) := Number;
      Result (Result'Last) := Check_Digit;
      return Result;
   end Append_Check_Digit;

   -------------------------------------------------------------------------
   --  Calculate_Check_Digit_Str (String Variant)
   -------------------------------------------------------------------------
   function Calculate_Check_Digit_Str (Number : String) return Digit is
      Arr : Digit_Array (1 .. Number'Length);
   begin
      if Number'Length = 0 then
         raise Invalid_Input with "String cannot be empty";
      end if;

      for I in Number'Range loop
         if Number (I) not in '0' .. '9' then
            raise Invalid_Input with "String must contain only digits";
         end if;
         Arr (I - Number'First + 1) :=
           Digit'Value (String'(1 => Number (I)));
      end loop;
      
      return Calculate_Check_Digit (Arr);
   end Calculate_Check_Digit_Str;

   -------------------------------------------------------------------------
   --  Verify_Number_Str (String Variant)
   -------------------------------------------------------------------------
   function Verify_Number_Str (Number : String) return Boolean is
      Arr : Digit_Array (1 .. Number'Length);
   begin
      if Number'Length < 2 then
         raise Invalid_Input with
           "String must contain at least 2 characters";
      end if;

      for I in Number'Range loop
         if Number (I) not in '0' .. '9' then
            raise Invalid_Input with "String must contain only digits";
         end if;
         Arr (I - Number'First + 1) :=
           Digit'Value (String'(1 => Number (I)));
      end loop;
      
      return Verify_Number (Arr);
   end Verify_Number_Str;

end Damm_Algorithm;
