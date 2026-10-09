pragma Ada_2022;

package Create_Maximum_Number_Lite with SPARK_Mode => On is
   subtype Length_Type is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   subtype Digit is Natural range 0 .. 9;
   type Digit_Array is array (Index) of Digit;

   function Maximum_Digit (A, B : Digit_Array; Length : Length_Type) return Digit
     with Global => null;
   function Maximum_Prefix (A, B : Digit_Array; Length : Length_Type) return Digit_Array
     with Global => null;

   --  Create Maximum Number: the largest K-digit number (as a digit
   --  sequence) formed from A (1 .. M) and B (1 .. N), keeping the relative
   --  order of the digits taken from each. For every split K = I + (K - I),
   --  take the largest I-digit subsequence of A and (K - I)-digit
   --  subsequence of B (monotonic stack) and merge them greedily (take from
   --  the sequence whose rest is lexicographically larger); keep the best.
   subtype Result_Length is Natural range 0 .. 64;
   subtype Result_Index is Positive range 1 .. 64;
   type Result_Array is array (Result_Index) of Digit;

   function Max_Number
     (A : Digit_Array; M : Length_Type; B : Digit_Array; N : Length_Type; K : Result_Length)
      return Result_Array
     with Global => null,
          Pre    => K <= M + N;
end Create_Maximum_Number_Lite;
