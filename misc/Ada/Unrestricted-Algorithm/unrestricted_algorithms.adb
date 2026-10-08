-- unrestricted_algorithms.adb
-- Implementations of the arbitrary-precision unbounded algorithms.

with Ada.Text_IO; use Ada.Text_IO;

package body Unrestricted_Algorithms is

   -----------------------------------------------------
   -- Helper: Arbitrary Precision Addition
   -----------------------------------------------------
   function Add (A, B : Digit_Array) return Digit_Array is
      Result : Digit_Array(A'Range);
      Carry  : Integer := 0;
      Sum    : Integer;
   begin
      -- Edge Case: Array boundaries must match
      if A'First /= B'First or A'Last /= B'Last then
         raise Precision_Mismatch_Error;
      end if;

      for I in reverse A'Range loop
         Sum := Integer(A(I)) + Integer(B(I)) + Carry;
         Result(I) := Digit(Sum mod 10);
         Carry := Sum / 10;
      end loop;
      
      -- Note: Unrestricted e computes within 2.718..., overflow carry out of index 1 is dropped 
      -- in this specific bounded domain.
      return Result;
   end Add;

   -----------------------------------------------------
   -- Helper: Arbitrary Precision Division by Integer
   -----------------------------------------------------
   function Divide_By_Integer (A : Digit_Array; Divisor : Positive) return Digit_Array is
      Result    : Digit_Array(A'Range);
      Remainder : Integer := 0;
      Temp      : Integer;
   begin
      for I in A'Range loop
         Temp := Remainder * 10 + Integer(A(I));
         Result(I) := Digit(Temp / Divisor);
         Remainder := Temp mod Divisor;
      end loop;
      return Result;
   end Divide_By_Integer;

   -----------------------------------------------------
   -- Helper: Equality and Zero Validation
   -----------------------------------------------------
   function Is_Equal (A, B : Digit_Array) return Boolean is
   begin
      if A'Length /= B'Length then return False; end if;
      for I in A'Range loop
         if A(I) /= B(I) then return False; end if;
      end loop;
      return True;
   end Is_Equal;

   function Is_Zero (A : Digit_Array) return Boolean is
   begin
      for I in A'Range loop
         if A(I) /= 0 then return False; end if;
      end loop;
      return True;
   end Is_Zero;

   -----------------------------------------------------
   -- Variant 1: Iterative Inverse (1 / N)
   -----------------------------------------------------
   function Inverse_Iterative (N : Positive; Precision : Positive) return Digit_Array is
      Result    : Digit_Array(1 .. Precision + 1) := (others => 0);
      Remainder : Integer := 1;
   begin
      Result(1) := Digit(Remainder / N);
      Remainder := Remainder mod N;
      
      for I in 2 .. Precision + 1 loop
         Remainder := Remainder * 10;
         Result(I) := Digit(Remainder / N);
         Remainder := Remainder mod N;
      end loop;
      return Result;
   end Inverse_Iterative;

   -----------------------------------------------------
   -- Variant 2: Recursive Inverse (1 / N)
   -----------------------------------------------------
   function Inverse_Recursive (N : Positive; Precision : Positive) return Digit_Array is
      Result : Digit_Array(1 .. Precision + 1) := (others => 0);

      procedure Process_Digit (Index : Positive; Curr_Rem : Integer) is
      begin
         if Index > Precision + 1 then
            return; -- Base Case: Target precision reached
         end if;
         
         if Index = 1 then
            Result(Index) := Digit(Curr_Rem / N);
            Process_Digit(Index + 1, (Curr_Rem mod N) * 10);
         else
            Result(Index) := Digit(Curr_Rem / N);
            Process_Digit(Index + 1, (Curr_Rem mod N) * 10);
         end if;
      end Process_Digit;

   begin
      Process_Digit(1, 1);
      return Result;
   end Inverse_Recursive;

   -----------------------------------------------------
   -- Core: Unrestricted Algorithm for Euler's Number
   -----------------------------------------------------
   function Compute_E (Precision : Positive) return Digit_Array is
      -- FIXED: Added internal guard digits. Unbounded Taylor Series requires calculation
      -- at a slightly deeper precision than requested to prevent rounding/truncation 
      -- losses from bubbling up into the final targeted decimal space.
      Internal_Size : constant Positive := Precision + 8;
      Internal_Sum  : Digit_Array(1 .. Internal_Size) := (others => 0);
      Term          : Digit_Array(1 .. Internal_Size) := (others => 0);
      Zero          : constant Digit_Array(1 .. Internal_Size) := (others => 0);
      Divisor       : Positive := 1;
      
      Result        : Digit_Array(1 .. Precision + 1);
   begin
      -- Base state: 1.000...
      Internal_Sum(1) := 1; 
      Term(1)       := 1; 

      -- Taylor Series: sum from i=1 to infinity of (Term / i!)
      loop
         Term := Divide_By_Integer(Term, Divisor);
         
         -- Halt unbounded condition
         exit when Is_Equal(Term, Zero);
         
         Internal_Sum := Add(Internal_Sum, Term);
         Divisor := Divisor + 1;
      end loop;
      
      -- Slice off the extra guard digits to return only the requested precision bounds
      for I in Result'Range loop
         Result(I) := Internal_Sum(I);
      end loop;
      
      return Result;
   end Compute_E;

   -----------------------------------------------------
   -- Output Formatting
   -----------------------------------------------------
   procedure Print_Number (Number : Digit_Array) is
   begin
      Put(Character'Val(Character'Pos('0') + Natural(Number(1))));
      Put(".");
      for I in 2 .. Number'Last loop
         Put(Character'Val(Character'Pos('0') + Natural(Number(I))));
      end loop;
   end Print_Number;

end Unrestricted_Algorithms;
