--  Ruzzo_Tompa — Ada 2023 educational package for the Ruzzo–Tompa (RT)
--  algorithm: find all non-overlapping contiguous maximal scoring
--  subsequences (positive-score segments) in a sequence of scores in
--  linear time (I-list / stack-based educational formulation).
--  The highest-scoring segment among the RT output is a solution to the
--  maximum subarray problem (when a positive segment exists).
--  Primary sources:
--  https://en.wikipedia.org/wiki/Ruzzo–Tompa_algorithm
--  Ruzzo & Tompa, ISMB 1999, "A Linear Time Algorithm for Finding All
--  Maximal Scoring Subsequences".

pragma Ada_2022;

package Ruzzo_Tompa
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity (Integer scores)
   ---------------------------------------------------------------------------

   --  Element type for integer score sequences and integer segment scores.
   --  Sums of up to Max_Length entries must stay within Integer'Range in
   --  client data; the I-list uses Long_Integer prefix sums internally.
   subtype Element is Integer;

   --  Educational bound on input length. Inputs longer than Max_Length
   --  raise Invalid_Argument.
   Max_Length : constant Positive := 10_000;

   type Element_Array is array (Positive range <>) of Element;

   --  One maximal scoring segment.
   --  First / Last are 1-based logical indices into the sequence
   --  (1 = first element of A, independent of A'First):
   --    A (A'First + First - 1) .. A (A'First + Last - 1).
   --  Score = sum of that window (strictly positive for RT segments).
   type Segment is record
      First : Positive;
      Last  : Positive;
      Score : Element;
   end record;

   type Segment_Array is array (Positive range <>) of Segment;

   ---------------------------------------------------------------------------
   -- Long_Float scores (same algorithm)
   ---------------------------------------------------------------------------

   type Real_Array is array (Positive range <>) of Long_Float;

   type Real_Segment is record
      First : Positive;
      Last  : Positive;
      Score : Long_Float;
   end record;

   type Real_Segment_Array is array (Positive range <>) of Real_Segment;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when A'Length = 0 or when A'Length > Max_Length.

   ---------------------------------------------------------------------------
   -- Ruzzo–Tompa: all maximal positive-score segments
   ---------------------------------------------------------------------------

   function Maximal_Segments (A : Element_Array) return Segment_Array
     with Global => null;
   --  I-list Ruzzo–Tompa scan. Returns every non-overlapping contiguous
   --  maximal scoring subsequence with strictly positive score, left to
   --  right. All-nonpositive input yields an empty Segment_Array (no
   --  positive-score segment exists). Raises Invalid_Argument if A is
   --  empty or oversize.

   function Maximal_Segments (A : Real_Array) return Real_Segment_Array
     with Global => null;
   --  Same algorithm for Long_Float scores. A score is treated as positive
   --  when it is strictly greater than 0.0.

   ---------------------------------------------------------------------------
   -- Max segment (Kadane-equivalent check)
   ---------------------------------------------------------------------------

   function Max_Segment (A : Element_Array) return Segment
     with Global => null;
   --  When Maximal_Segments (A) is nonempty: the segment with the largest
   --  Score (leftmost on ties) — a maximum-subarray witness.
   --  When every entry is nonpositive: Kadane nonempty policy — the
   --  least-negative (largest) singleton, leftmost on ties.
   --  Raises Invalid_Argument if A is empty or oversize.

   function Max_Segment (A : Real_Array) return Real_Segment
     with Global => null;
   --  Long_Float counterpart of Max_Segment.

end Ruzzo_Tompa;
