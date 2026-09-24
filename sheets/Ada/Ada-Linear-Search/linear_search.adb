--  Linear_Search body — classic left-to-right sequential scan (Wikipedia).

pragma Ada_2022;

package body Linear_Search
  with SPARK_Mode => Off
is

   procedure Check_Bounds (A : Element_Array) is
   begin
      if A'Length > Max_N then
         raise Invalid_Argument
           with "array length exceeds Max_N";
      end if;
   end Check_Bounds;

   function Sentinel (A : Element_Array) return Integer is
   begin
      return Integer (A'First) - 1;
   end Sentinel;

   ---------------------------------------------------------------------------
   -- Classic iterative Find (Wikipedia "Basic algorithm")
   ---------------------------------------------------------------------------

   function Find (A : Element_Array; Key : Integer) return Integer is
   begin
      Check_Bounds (A);

      if A'Length = 0 then
         return Sentinel (A);
      end if;

      for I in A'Range loop
         if A (I) = Key then
            return Integer (I);
         end if;
      end loop;

      return Sentinel (A);
   end Find;

   ---------------------------------------------------------------------------
   -- Find_From — scan from an explicit start index
   ---------------------------------------------------------------------------

   function Find_From
     (A     : Element_Array;
      Key   : Integer;
      Start : Natural) return Integer
   is
   begin
      Check_Bounds (A);

      if A'Length = 0 then
         return Sentinel (A);
      end if;

      if Start < A'First or else Start > A'Last then
         raise Invalid_Argument
           with "Start not in A'Range";
      end if;

      for I in Start .. A'Last loop
         if A (I) = Key then
            return Integer (I);
         end if;
      end loop;

      return Sentinel (A);
   end Find_From;

   ---------------------------------------------------------------------------
   -- Contains — Boolean membership
   ---------------------------------------------------------------------------

   function Contains (A : Element_Array; Key : Integer) return Boolean is
   begin
      return Find (A, Key) /= Sentinel (A);
   end Contains;

end Linear_Search;
