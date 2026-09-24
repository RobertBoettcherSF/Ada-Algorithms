--  Jump_Search body — classic jump / block search with optional Step.

pragma Ada_2022;

package body Jump_Search
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Integer floor square root (binary search). Floor_Sqrt (0) = 0.
   -------------------------------------------------------------------------

   function Floor_Sqrt (N : Natural) return Natural is
      Lo  : Natural := 0;
      Hi  : Natural;
      Mid : Natural;
      Sq  : Long_Long_Integer;
   begin
      if N <= 1 then
         return N;
      end if;

      --  Upper bound: for N <= Max_N, sqrt(N) <= 317; keep it general.
      Hi := N;
      while Lo < Hi loop
         Mid := (Lo + Hi + 1) / 2;
         Sq  := Long_Long_Integer (Mid) * Long_Long_Integer (Mid);
         if Sq <= Long_Long_Integer (N) then
            Lo := Mid;
         else
            Hi := Mid - 1;
         end if;
      end loop;
      return Lo;
   end Floor_Sqrt;

   -------------------------------------------------------------------------
   -- Core search with an explicit positive step size
   -------------------------------------------------------------------------

   function Find_With_Step
     (A    : Element_Array;
      Key  : Integer;
      Step : Positive) return Integer
   is
      N            : constant Natural := A'Length;
      First        : constant Natural := A'First;
      Sentinel     : constant Integer := Integer (First) - 1;
      Prev_Offset  : Natural := 0;
      Curr_Offset  : Natural := Natural (Step);
      Probe_Offset : Natural;
      Idx          : Natural;
      Bound_Offset : Natural;
   begin
      if N = 0 then
         return Sentinel;
      end if;

      --  Jump phase: advance while the last element of the current block
      --  is strictly less than Key (Wikipedia / NIST formulation).
      loop
         if Curr_Offset < N then
            Probe_Offset := Curr_Offset - 1;
         else
            Probe_Offset := N - 1;
         end if;

         exit when not (A (First + Probe_Offset) < Key);

         Prev_Offset := Curr_Offset;
         --  Cap addition so Curr_Offset cannot wrap past Natural'Last.
         if Curr_Offset > Natural'Last - Natural (Step) then
            Curr_Offset := Natural'Last;
         else
            Curr_Offset := Curr_Offset + Natural (Step);
         end if;

         if Prev_Offset >= N then
            return Sentinel;
         end if;
      end loop;

      --  Linear scan of the previous block [Prev_Offset, min(Curr, n)).
      if Curr_Offset < N then
         Bound_Offset := Curr_Offset;
      else
         Bound_Offset := N;
      end if;

      Idx := First + Prev_Offset;
      while Integer (Idx) - Integer (First) < Integer (Bound_Offset) loop
         if A (Idx) = Key then
            return Integer (Idx);
         elsif A (Idx) > Key then
            return Sentinel;
         end if;
         exit when Idx = A'Last;
         Idx := Idx + 1;
      end loop;

      return Sentinel;
   end Find_With_Step;

   -------------------------------------------------------------------------
   -- Public API
   -------------------------------------------------------------------------

   function Find (A : Element_Array; Key : Integer) return Integer is
      N    : constant Natural := A'Length;
      Step : Natural;
   begin
      if N > Max_N then
         raise Invalid_Argument with
           "Find: array length exceeds Max_N";
      end if;

      if N = 0 then
         return Integer (A'First) - 1;
      end if;

      Step := Floor_Sqrt (N);
      --  For N >= 1, Floor_Sqrt (N) >= 1.
      return Find_With_Step (A, Key, Positive (Step));
   end Find;

   function Find
     (A    : Element_Array;
      Key  : Integer;
      Step : Natural) return Integer
   is
   begin
      if A'Length > Max_N then
         raise Invalid_Argument with
           "Find: array length exceeds Max_N";
      end if;

      if Step = 0 then
         raise Invalid_Argument with
           "Find: Step must be positive (non-zero)";
      end if;

      return Find_With_Step (A, Key, Positive (Step));
   end Find;

end Jump_Search;
