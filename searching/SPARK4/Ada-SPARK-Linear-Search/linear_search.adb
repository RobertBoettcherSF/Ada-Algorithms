--  Linear_Search body — SPARK Level 4 classic left-to-right sequential
--  scan with Find_From and Contains. Loops are Ada `for` loops over
--  A'Range / Start .. A'Last so termination is immediate for the prover.

package body Linear_Search
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Classic iterative Find (Wikipedia "Basic algorithm")
   ---------------------------------------------------------------------------

   function Find (A : Element_Array; Key : Integer) return Index is
   begin
      if A'Length = 0 then
         return 0;
      end if;

      for I in A'Range loop
         pragma Loop_Invariant
           (for all K in A'First .. I - 1 => A (K) /= Key);
         if A (I) = Key then
            return I;
         end if;
      end loop;

      return 0;
   end Find;

   ---------------------------------------------------------------------------
   -- Find_From — scan from an explicit start index
   ---------------------------------------------------------------------------

   function Find_From
     (A     : Element_Array;
      Key   : Integer;
      Start : Index) return Index
   is
   begin
      if A'Length = 0 then
         return 0;
      end if;

      --  Pre ensures Start in A'Range when A is non-empty.
      pragma Assert (Start in A'Range);

      for I in Start .. A'Last loop
         pragma Loop_Invariant
           (for all K in Start .. I - 1 => A (K) /= Key);
         if A (I) = Key then
            return I;
         end if;
      end loop;

      return 0;
   end Find_From;

   ---------------------------------------------------------------------------
   -- Contains — Boolean membership via Find
   ---------------------------------------------------------------------------

   function Contains (A : Element_Array; Key : Integer) return Boolean is
   begin
      return Find (A, Key) > 0;
   end Contains;

end Linear_Search;
