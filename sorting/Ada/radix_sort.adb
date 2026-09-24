--  Radix_Sort body — LSD radix sort with stable counting-sort digit passes.

pragma Ada_2022;

package body Radix_Sort
  with SPARK_Mode => Off
is

   procedure Check_Length (A : Element_Array) is
   begin
      if A'Length > Max_Length then
         raise Invalid_Argument
           with "array length exceeds Max_Length";
      end if;
   end Check_Length;

   procedure Check_Nonnegative (A : Element_Array) is
   begin
      for I in A'Range loop
         if A (I) < 0 then
            raise Invalid_Argument
              with "radix sort requires nonnegative keys";
         end if;
      end loop;
   end Check_Nonnegative;

   --  Greatest value in A (A nonempty, all nonnegative).
   function Max_Value (A : Element_Array) return Integer is
      M : Integer := A (A'First);
   begin
      for I in A'First + 1 .. A'Last loop
         if A (I) > M then
            M := A (I);
         end if;
      end loop;
      return M;
   end Max_Value;

   --  Digit of Key at power Exp for the given Base:
   --  digit = (Key / Exp) mod Base, with Exp = Base^p.
   function Digit_Of (Key, Exp : Integer; Base : Base_Range) return Natural is
   begin
      return Natural ((Key / Exp) rem Integer (Base));
   end Digit_Of;

   --  One stable counting-sort pass on digit (Key / Exp) mod Base.
   procedure Counting_Sort_Digit
     (A    : in out Element_Array;
      Exp  : Integer;
      Base : Base_Range)
   is
      subtype Digit_Index is Natural range 0 .. Max_Base - 1;
      Count  : array (Digit_Index) of Natural := [others => 0];
      Output : Element_Array (A'Range);
      D      : Natural;
      K      : Natural;
   begin
      --  Histogram of current digits.
      for I in A'Range loop
         D := Digit_Of (A (I), Exp, Base);
         Count (D) := Count (D) + 1;
      end loop;

      --  Prefix sums → exclusive ending positions (1-based counts).
      for I in 1 .. Natural (Base) - 1 loop
         Count (I) := Count (I) + Count (I - 1);
      end loop;

      --  Stable placement: scan from A'Last down to A'First so equal
      --  digits retain their relative order from previous passes.
      for I in reverse A'Range loop
         D := Digit_Of (A (I), Exp, Base);
         K := Count (D);
         --  Map 1-based cumulative count onto A'First .. A'Last.
         Output (A'First + K - 1) := A (I);
         Count (D) := K - 1;
      end loop;

      A := Output;
   end Counting_Sort_Digit;

   procedure Sort_Base (A : in out Element_Array; Base : Base_Range) is
      Max_Key : Integer;
      Exp     : Integer;
   begin
      Check_Length (A);
      Check_Nonnegative (A);

      if A'Length <= 1 then
         return;
      end if;

      Max_Key := Max_Value (A);
      if Max_Key = 0 then
         --  All zeros — already sorted.
         return;
      end if;

      --  Pass over digits: Exp = Base^0, Base^1, ... while Max_Key / Exp > 0.
      Exp := 1;
      while Max_Key / Exp > 0 loop
         Counting_Sort_Digit (A, Exp, Base);
         --  Guard against Integer overflow when Exp * Base would exceed
         --  Integer'Last (e.g. large keys with Base close to 256).
         if Exp > Integer'Last / Integer (Base) then
            exit;
         end if;
         Exp := Exp * Integer (Base);
      end loop;
   end Sort_Base;

   procedure Sort (A : in out Element_Array) is
   begin
      Sort_Base (A, 10);
   end Sort;

   function Is_Sorted (A : Element_Array) return Boolean is
   begin
      if A'Length <= 1 then
         return True;
      end if;
      for I in A'First + 1 .. A'Last loop
         if A (I - 1) > A (I) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Sorted;

end Radix_Sort;
