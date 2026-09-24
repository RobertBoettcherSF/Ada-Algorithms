--  Uniform_Binary_Search — Ada 2023 educational package for Knuth /
--  Chandra uniform binary search (TAOCP Vol. 3, Algorithm C).
--  Precomputes a delta lookup table so each search step updates a single
--  index by table lookup instead of recomputing (lo+hi)/2.
--  Primary source:
--  https://en.wikipedia.org/wiki/Uniform_binary_search
--  Results match classic binary search on the same sorted ascending array
--  (any matching index when duplicates exist; not necessarily leftmost).

pragma Ada_2022;

package Uniform_Binary_Search
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   --  Sorted ascending integer sequence. Indices are Natural; the array
   --  may start at any Natural bound (0-based or 1-based).
   type Element_Array is array (Natural range <>) of Integer;

   --  Educational capacity: arrays longer than Max_N raise Invalid_Argument.
   Max_N : constant Positive := 100_000;

   --  Delta table holds at most floor(log2 Max_N)+2 nonzero steps plus a
   --  terminating 0, well under this pool size.
   Max_Delta_Entries : constant Positive := 64;

   type Delta_Table is private;

   Invalid_Argument : exception;

   ---------------------------------------------------------------------------
   -- Delta table construction
   ---------------------------------------------------------------------------

   --  Build Knuth deltas for length N:
   --    delta[i] = floor( (N + 2^i) / 2^(i+1) )
   --  until a 0 terminator is stored (Wikipedia / TAOCP formula).
   --  Raises Invalid_Argument if N > Max_N.
   procedure Build_Table (N : Positive; Table : out Delta_Table);

   --  Length for which Table was built (0 if default / unbuilt).
   function Table_Length (Table : Delta_Table) return Natural;

   --  Number of stored entries including the terminating 0.
   function Table_Entry_Count (Table : Delta_Table) return Natural;

   --  Delta value at 0-based slot Index (including the final 0).
   --  Raises Invalid_Argument if Index is out of the built range.
   function Delta_At (Table : Delta_Table; Index : Natural) return Natural;

   ---------------------------------------------------------------------------
   -- Search
   ---------------------------------------------------------------------------

   --  Uniform binary search for Key in A.
   --  Precondition: A is sorted in nondecreasing (ascending) order.
   --  Returns the index of some occurrence of Key, or the sentinel
   --  Integer (A'First) - 1 when absent (for an empty A, that sentinel
   --  is still Integer (A'First) - 1).
   --  Raises Invalid_Argument if A'Length > Max_N.
   --  Builds a fresh delta table for A'Length on each call.
   function Find (A : Element_Array; Key : Integer) return Integer;

   --  Same contract as Find, using a precomputed Table for A'Length.
   --  Raises Invalid_Argument if A'Length > Max_N, or if Table was not
   --  built for exactly A'Length (including empty A requiring no table).
   function Find
     (A     : Element_Array;
      Key   : Integer;
      Table : Delta_Table) return Integer;

   ---------------------------------------------------------------------------
   -- Classic binary search (local reference oracle for tests / README)
   ---------------------------------------------------------------------------

   --  Standard iterative binary search on sorted ascending A.
   --  Same result contract as Find (any hit index, or A'First-1).
   --  Raises Invalid_Argument if A'Length > Max_N.
   function Classic_Binary_Search
     (A : Element_Array; Key : Integer) return Integer;

   --  True iff A is sorted in nondecreasing order (vacuously true if
   --  A'Length < 2). Useful for debug / tests; Find does not call this.
   function Is_Sorted_Ascending (A : Element_Array) return Boolean;

private

   type Delta_Storage is
     array (0 .. Max_Delta_Entries - 1) of Natural;

   type Delta_Table is record
      Length : Natural := 0;           -- N for which deltas were built
      Count  : Natural := 0;           -- entries used, including final 0
      Deltas : Delta_Storage := [others => 0];
   end record;

end Uniform_Binary_Search;
