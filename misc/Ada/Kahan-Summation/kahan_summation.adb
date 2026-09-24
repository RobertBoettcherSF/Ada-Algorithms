--  Kahan_Summation body — naïve / Kahan / Neumaier / pairwise + Accumulator.

pragma Ada_2022;

package body Kahan_Summation
  with SPARK_Mode => Off
is

   procedure Check_Length (N : Natural) is
   begin
      if N > Max_Length then
         raise Invalid_Argument with "length exceeds Max_Length";
      end if;
   end Check_Length;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Float; Tol : Float := Near_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Abs_Error (A, B : Float) return Float is
   begin
      return abs (A - B);
   end Abs_Error;

   function Abs_Error_Exact (Approx : Float; Exact : Long_Float) return Float is
   begin
      return Float (abs (Long_Float (Approx) - Exact));
   end Abs_Error_Exact;

   ---------------------------------------------------------------------------
   -- Array summation
   ---------------------------------------------------------------------------

   function Sum_Naive (Data : Float_Array) return Float is
      S : Float := 0.0;
   begin
      Check_Length (Data'Length);
      for X of Data loop
         S := S + X;
      end loop;
      return S;
   end Sum_Naive;

   function Sum_Kahan (Data : Float_Array) return Float is
      Sum : Float := 0.0;
      C   : Float := 0.0;
      Y   : Float;
      T   : Float;
   begin
      Check_Length (Data'Length);
      for X of Data loop
         Y := X - C;
         T := Sum + Y;
         C := (T - Sum) - Y;
         Sum := T;
      end loop;
      return Sum;
   end Sum_Kahan;

   function Sum_Neumaier (Data : Float_Array) return Float is
      Sum : Float := 0.0;
      C   : Float := 0.0;
      T   : Float;
   begin
      Check_Length (Data'Length);
      for X of Data loop
         T := Sum + X;
         if abs (Sum) >= abs (X) then
            C := C + ((Sum - T) + X);
         else
            C := C + ((X - T) + Sum);
         end if;
         Sum := T;
      end loop;
      return Sum + C;
   end Sum_Neumaier;

   --  Pairwise: recurse on halves; leaf = naïve of short block.
   Pairwise_Leaf : constant Positive := 16;

   function Sum_Pairwise (Data : Float_Array) return Float is
      N     : constant Natural := Data'Length;
      Mid   : Natural;
      Left  : Float;
      Right : Float;
   begin
      Check_Length (N);
      if N = 0 then
         return 0.0;
      elsif N = 1 then
         return Data (Data'First);
      elsif N <= Pairwise_Leaf then
         return Sum_Naive (Data);
      else
         Mid := N / 2;
         Left := Sum_Pairwise
           (Data (Data'First .. Data'First + Mid - 1));
         Right := Sum_Pairwise
           (Data (Data'First + Mid .. Data'Last));
         return Left + Right;
      end if;
   end Sum_Pairwise;

   ---------------------------------------------------------------------------
   -- Accumulator
   ---------------------------------------------------------------------------

   function Make_Empty return Accumulator is
   begin
      return (Sum => 0.0, C => 0.0, Count => 0);
   end Make_Empty;

   procedure Reset (Acc : in out Accumulator) is
   begin
      Acc.Sum := 0.0;
      Acc.C := 0.0;
      Acc.Count := 0;
   end Reset;

   procedure Add (Acc : in out Accumulator; X : Float) is
      Y : Float;
      T : Float;
   begin
      Y := X - Acc.C;
      T := Acc.Sum + Y;
      Acc.C := (T - Acc.Sum) - Y;
      Acc.Sum := T;
      Acc.Count := Acc.Count + 1;
   end Add;

   procedure Add_Many (Acc : in out Accumulator; Data : Float_Array) is
   begin
      Check_Length (Data'Length);
      for X of Data loop
         Add (Acc, X);
      end loop;
   end Add_Many;

   function Total (Acc : Accumulator) return Float is
   begin
      return Acc.Sum;
   end Total;

   function Count (Acc : Accumulator) return Natural is
   begin
      return Acc.Count;
   end Count;

   function Compensation (Acc : Accumulator) return Float is
   begin
      return Acc.C;
   end Compensation;

   ---------------------------------------------------------------------------
   -- Builders
   ---------------------------------------------------------------------------

   function Make_Constant
     (N : Term_Count; Value : Float) return Float_Array
   is
      Result : Float_Array (1 .. N);
   begin
      for I in Result'Range loop
         Result (I) := Value;
      end loop;
      return Result;
   end Make_Constant;

   function Make_Large_Then_Small
     (N : Term_Count; Large, Small : Float) return Float_Array
   is
      Result : Float_Array (1 .. N);
   begin
      Result (1) := Large;
      for I in 2 .. N loop
         Result (I) := Small;
      end loop;
      return Result;
   end Make_Large_Then_Small;

   function Make_Neumaier_Peters
     (A : Float := 1.0; Huge : Float := 1.0E+20) return Float_Array
   is
      Result : constant Float_Array (1 .. 4) :=
        [A, Huge, A, -Huge];
   begin
      return Result;
   end Make_Neumaier_Peters;

end Kahan_Summation;
