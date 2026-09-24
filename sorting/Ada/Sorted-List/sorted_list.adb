--  Sorted_List body — array-backed ordered multiset with inline binary
--  search for insertion point and membership. Do not `with` Binary_Search.

pragma Ada_2022;

package body Sorted_List
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Inline binary search helpers (no sibling package dependency)
   ---------------------------------------------------------------------------

   --  Leftmost index I in 1 .. L.Len with L.Data (I) >= X, or L.Len + 1
   --  if every element is < X. Overflow-safe midpoint.
   function Lower_Bound (L : List; X : Integer) return Positive is
      Lo  : Natural := 1;
      Hi  : Natural := L.Len + 1;
      Mid : Natural;
   begin
      while Lo < Hi loop
         Mid := Lo + (Hi - Lo) / 2;
         if L.Data (Mid) < X then
            Lo := Mid + 1;
         else
            Hi := Mid;
         end if;
      end loop;
      return Positive (Lo);
   end Lower_Bound;

   --  Leftmost index of an equal key, or 0 if absent.
   function Find_First_Equal (L : List; X : Integer) return Natural is
      Pos : constant Positive := Lower_Bound (L, X);
   begin
      if Pos <= L.Len and then L.Data (Pos) = X then
         return Natural (Pos);
      end if;
      return 0;
   end Find_First_Equal;

   ---------------------------------------------------------------------------
   -- Construction / queries
   ---------------------------------------------------------------------------

   function Empty return List is
      L : List;
   begin
      L.Len := 0;
      return L;
   end Empty;

   function Length (L : List) return Natural is
   begin
      return L.Len;
   end Length;

   function Is_Empty (L : List) return Boolean is
   begin
      return L.Len = 0;
   end Is_Empty;

   function Is_Full (L : List) return Boolean is
   begin
      return L.Len = Max_N;
   end Is_Full;

   procedure Clear (L : in out List) is
   begin
      L.Len := 0;
   end Clear;

   ---------------------------------------------------------------------------
   -- Mutation
   ---------------------------------------------------------------------------

   procedure Insert (L : in out List; X : Integer) is
      Pos : Positive;
   begin
      if L.Len >= Max_N then
         raise Overflow;
      end if;

      Pos := Lower_Bound (L, X);

      --  Shift right tail [Pos .. Len] one slot toward the end.
      for I in reverse Pos .. L.Len loop
         L.Data (I + 1) := L.Data (I);
      end loop;

      L.Data (Pos) := X;
      L.Len := L.Len + 1;
   end Insert;

   procedure Delete (L : in out List; X : Integer) is
      Pos : constant Natural := Find_First_Equal (L, X);
   begin
      if Pos = 0 then
         raise Invalid_Argument;
      end if;

      --  Shift left tail [Pos+1 .. Len] over the removed slot.
      for I in Pos + 1 .. L.Len loop
         L.Data (I - 1) := L.Data (I);
      end loop;

      L.Len := L.Len - 1;
   end Delete;

   procedure Delete_First (L : in out List; X : Integer) is
   begin
      Delete (L, X);
   end Delete_First;

   ---------------------------------------------------------------------------
   -- Search
   ---------------------------------------------------------------------------

   function Contains (L : List; X : Integer) return Boolean is
   begin
      return Find_First_Equal (L, X) /= 0;
   end Contains;

   function Find (L : List; X : Integer) return Natural is
   begin
      return Find_First_Equal (L, X);
   end Find;

   ---------------------------------------------------------------------------
   -- Ends / indexed access
   ---------------------------------------------------------------------------

   function Min (L : List) return Integer is
   begin
      if L.Len = 0 then
         raise Invalid_Argument;
      end if;
      return L.Data (1);
   end Min;

   function Max (L : List) return Integer is
   begin
      if L.Len = 0 then
         raise Invalid_Argument;
      end if;
      return L.Data (L.Len);
   end Max;

   function Element (L : List; Index : Positive) return Integer is
   begin
      if Index > L.Len then
         raise Invalid_Argument;
      end if;
      return L.Data (Index);
   end Element;

end Sorted_List;
