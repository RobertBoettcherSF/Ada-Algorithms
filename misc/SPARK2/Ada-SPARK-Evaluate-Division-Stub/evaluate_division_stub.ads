pragma SPARK_Mode (On);

package Evaluate_Division_Stub is
   Variable_Count : constant := 4;
   Equation_Count : constant := 3;
   subtype Variable is Positive range 1 .. Variable_Count;
   subtype Small_Number is Positive range 1 .. 10;
   type Equation is record
      From       : Variable;
      To         : Variable;
      Numerator  : Small_Number;
      Denominator : Small_Number;
   end record;
   type Equation_Array is array (Positive range 1 .. Equation_Count) of Equation;
   type Fraction is record
      Numerator   : Natural range 0 .. 100;
      Denominator : Positive range 1 .. 100;
   end record;

   function Evaluate (Equations : Equation_Array; From, To : Variable) return Fraction;
end Evaluate_Division_Stub;
