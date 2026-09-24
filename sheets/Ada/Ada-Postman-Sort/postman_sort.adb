--  Postman_Sort body — MSD postal pigeonhole distribution sort.
--  Scatter by most significant digit, recurse on each bucket, gather.

pragma Ada_2022;

package body Postman_Sort
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
              with "postman sort requires nonnegative keys";
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

   --  Highest power Exp = Base^p such that Exp <= Max_Key (and Exp fits
   --  in Integer). For Max_Key = 0 the caller skips sorting.
   function Highest_Exp (Max_Key : Integer; Base : Base_Range) return Integer
   is
      Exp  : Integer := 1;
      B    : constant Integer := Integer (Base);
   begin
      while Max_Key / Exp >= B loop
         if Exp > Integer'Last / B then
            exit;
         end if;
         Exp := Exp * B;
      end loop;
      return Exp;
   end Highest_Exp;

   --  MSD recurse on A (Lo .. Hi) at digit significance Exp.
   --  Stable: left-to-right scatter into digit buckets, then recurse.
   procedure MSD_Range
     (A    : in out Element_Array;
      Lo   : Natural;
      Hi   : Natural;
      Exp  : Integer;
      Base : Base_Range)
   is
      subtype Digit_Index is Natural range 0 .. Max_Base - 1;
      Count  : array (Digit_Index) of Natural := [others => 0];
      Start  : array (Digit_Index) of Natural := [others => 0];
      Output : Element_Array (Lo .. Hi);
      D      : Natural;
      B      : constant Natural := Natural (Base);
      Pos    : Natural;
      Next_Exp : Integer;
      Bucket_Lo : Natural;
      Bucket_Hi : Natural;
      Len       : Natural;
   begin
      Len := Hi - Lo + 1;
      if Len <= 1 or else Exp < 1 then
         return;
      end if;

      --  Histogram of current MSD digits on the subrange.
      for I in Lo .. Hi loop
         D := Digit_Of (A (I), Exp, Base);
         Count (D) := Count (D) + 1;
      end loop;

      --  Exclusive starting offsets within Output (0-based relative).
      Start (0) := 0;
      for I in 1 .. B - 1 loop
         Start (I) := Start (I - 1) + Count (I - 1);
      end loop;

      --  Stable scatter: left → right so equal digits keep relative order.
      for I in Lo .. Hi loop
         D := Digit_Of (A (I), Exp, Base);
         Pos := Start (D);
         Output (Lo + Pos) := A (I);
         Start (D) := Pos + 1;
      end loop;

      --  Gather back into A.
      for I in Lo .. Hi loop
         A (I) := Output (I);
      end loop;

      --  Restore Start to exclusive beginnings for bucket ranges:
      --  after scatter, Start (D) is the exclusive end; rebuild from Count.
      Start (0) := 0;
      for I in 1 .. B - 1 loop
         Start (I) := Start (I - 1) + Count (I - 1);
      end loop;

      if Exp = 1 then
         --  Units digit done; keys in each bucket share all examined digits.
         return;
      end if;

      Next_Exp := Exp / Integer (Base);

      for D in 0 .. B - 1 loop
         if Count (D) > 1 then
            Bucket_Lo := Lo + Start (D);
            Bucket_Hi := Bucket_Lo + Count (D) - 1;
            MSD_Range (A, Bucket_Lo, Bucket_Hi, Next_Exp, Base);
         end if;
      end loop;
   end MSD_Range;

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

      Exp := Highest_Exp (Max_Key, Base);
      MSD_Range (A, A'First, A'Last, Exp, Base);
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

end Postman_Sort;
