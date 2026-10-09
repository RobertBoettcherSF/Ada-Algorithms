pragma Ada_2022;

--  Delete and Earn: pick a number X from the array, earn X, and every copy
--  of X - 1 and X + 1 is deleted; repeat until the array is empty. Once
--  one copy of X is taken, the other copies can be taken for free, so the
--  answer is the best total of Points (X) = X * (copies of X) over a set of
--  values with no two adjacent. Arrays hold up to 100 numbers in 1 .. 100.
package Delete_And_Earn with SPARK_Mode => On is
   subtype Number is Positive range 1 .. 100;
   subtype Index is Positive range 1 .. 100;
   type Num_Array is array (Index range <>) of Number;

   --  Points (X) <= 100 * 100; the best total over values 1 .. K is at
   --  most K * 10_000, so 1_000_000 for K = 100.
   Max_Point : constant := 10_000;
   subtype Point is Natural range 0 .. Max_Point;
   subtype Score is Natural range 0 .. 100 * Max_Point;
   type Point_Array is array (Number) of Point;

   --  Sum of the copies of X in Nums (1 .. Last), that is X times the
   --  number of copies; each copy adds at most 100.
   function Weight (Nums : Num_Array; X : Number; Last : Integer) return Natural
   with
     Ghost,
     Pre                => Nums'First = 1 and then Last <= Nums'Last,
     Post               => Weight'Result <= 100 * Integer'Max (Last, 0),
     Subprogram_Variant => (Decreases => Last);

   function Points_Of (Nums : Num_Array) return Point_Array
   with Ghost, Pre => Nums'First = 1;

   --  Best totals over values 1 .. K (Upto) and 1 .. K - 1 (Before): value
   --  K is either skipped (Best (K - 1)) or taken with value K - 1 left out
   --  (Best (K - 2) + Points (K)).
   subtype Value_Count is Natural range 0 .. 100;
   type Best_Pair is record
      Upto, Before : Score;
   end record;

   function Step (B : Best_Pair; P : Point; K : Number) return Best_Pair is
     ((Upto => Natural'Max (B.Upto, B.Before + P), Before => B.Upto))
   with
     Ghost,
     Pre => B.Before <= (K - 1) * Max_Point and then B.Upto <= (K - 1) * Max_Point;

   function Best (P : Point_Array; K : Value_Count) return Best_Pair
   with
     Ghost,
     Post               =>
       Best'Result.Upto <= K * Max_Point
       and then Best'Result.Before <= Best'Result.Upto
       and then (if K > 0 then Best'Result.Before <= (K - 1) * Max_Point),
     Subprogram_Variant => (Decreases => K);

   function Max_Earn (Nums : Num_Array) return Score
   with
     Global => null,
     Pre    => Nums'First = 1,
     Post   => Max_Earn'Result = Best (Points_Of (Nums), 100).Upto;

   --  Points when each value 1 .. N occurs once.
   function Once_Points (N : Number) return Point_Array is
     ([for X in Number => (if X <= N then X else 0)])
   with Ghost;

   --  Max_Earn on the array 1, 2, .., N (each value once).
   function Maximum (N : Number) return Score
   with
     Global => null,
     Post   => Maximum'Result = Best (Once_Points (N), 100).Upto;

private
   function Weight (Nums : Num_Array; X : Number; Last : Integer) return Natural is
     (if Last < 1 then 0
      else Weight (Nums, X, Last - 1) + (if Nums (Last) = X then X else 0));

   function Points_Of (Nums : Num_Array) return Point_Array is
     ([for X in Number => Weight (Nums, X, Nums'Last)]);

   function Best (P : Point_Array; K : Value_Count) return Best_Pair is
     (if K = 0 then (Upto => 0, Before => 0) else Step (Best (P, K - 1), P (K), K));
end Delete_And_Earn;
