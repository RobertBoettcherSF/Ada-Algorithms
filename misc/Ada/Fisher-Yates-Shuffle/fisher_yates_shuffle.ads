--  Fisher_Yates_Shuffle — Ada 2023 educational package for the modern
--  in-place Fisher–Yates shuffle (Durstenfeld / Knuth). Produces an
--  unbiased random permutation of a finite sequence when the RNG is
--  unbiased. Reproducible tests via a seeded 64-bit LCG or an injected
--  access-to-function RNG.
--  Reference: https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle

pragma Ada_2022;

with Interfaces;

package Fisher_Yates_Shuffle
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Shuffle.
   Max_N : constant Positive := 100_000;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_N, when Next is null, or when an
   --  injected draw falls outside A'First .. I.

   ---------------------------------------------------------------------------
   -- RNG injection
   ---------------------------------------------------------------------------

   --  Named access type for storing library-level RNG callbacks.
   --  Shuffle itself takes an anonymous access parameter so nested
   --  test RNGs may also be passed via 'Access.
   type Random_Index is
     access function (Lo, Hi : Natural) return Natural;

   ---------------------------------------------------------------------------
   -- Algorithm sketch (modern in-place Fisher–Yates)
   ---------------------------------------------------------------------------
   --  for i in reverse A'First + 1 .. A'Last loop
   --     j := random integer in A'First .. i
   --     swap A(j), A(i)
   --  end loop
   --
   --  Empty and singleton arrays are no-ops. After n − 1 swaps every
   --  permutation of the n elements is equally likely (when each j is
   --  uniform). Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Shuffle API
   ---------------------------------------------------------------------------

   procedure Shuffle
     (A    : in out Element_Array;
      Seed : in out Interfaces.Unsigned_64);
   --  In-place Fisher–Yates using an internal 64-bit LCG driven by Seed.
   --  Seed is updated so successive Shuffle calls continue the stream.
   --  Raises Invalid_Argument when A'Length > Max_N.

   procedure Shuffle
     (A    : in out Element_Array;
      Next : access function (Lo, Hi : Natural) return Natural);
   --  In-place Fisher–Yates using the injected Next callback for each
   --  index draw (anonymous access: library or nested subprograms OK).
   --  Raises Invalid_Argument when A'Length > Max_N, Next is null, or
   --  a draw is outside A'First .. I.

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Is_Permutation_Of
     (A, Original : Element_Array) return Boolean;
   --  True iff A and Original have the same length and the same multiset
   --  of elements (order ignored). Empty arrays match each other.

end Fisher_Yates_Shuffle;
