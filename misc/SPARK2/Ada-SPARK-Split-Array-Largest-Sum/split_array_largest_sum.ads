pragma Ada_2022;

--  Split array largest sum: cut Input into at most Parts contiguous
--  parts so that the largest part sum is as small as possible. For a
--  limit L the greedy scan (start a new part only when the next element
--  does not fit) uses the fewest parts; halve the limits to find the
--  least L whose greedy split fits in Parts.
package Split_Array_Largest_Sum with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Prefix is Natural range 0 .. Length;
   subtype Element is Positive range 1 .. 100;
   subtype Limit is Positive range 1 .. 800;
   subtype Sum is Natural range 0 .. Limit'Last;
   subtype Part_Count is Positive range 1 .. Length;
   type Input_Array is array (Index) of Element;

   --  Sum of Input (1 .. K).
   function Prefix_Sum (Input : Input_Array; K : Prefix) return Sum
   with
     Subprogram_Variant => (Decreases => K),
     Post => Prefix_Sum'Result in K .. K * Element'Last;

   --  Largest of Input (1 .. K) (0 when K = 0).
   function Prefix_Max (Input : Input_Array; K : Prefix) return Natural
   with
     Subprogram_Variant => (Decreases => K),
     Post => Prefix_Max'Result <= Prefix_Sum (Input, K)
             and then (if K > 0 then Prefix_Max'Result >= 1)
             and then (for all I in 1 .. K => Input (I) <= Prefix_Max'Result);

   function Max_Element (Input : Input_Array) return Limit is
     (Prefix_Max (Input, Length));

   function Total (Input : Input_Array) return Limit is
     (Prefix_Sum (Input, Length));

   --  State of the greedy scan: parts started so far, sum of the last.
   type Progress is record
      Parts : Positive range 1 .. Length + 1;
      Load  : Sum;
   end record;

   function Step (S : Progress; X : Element; L : Limit) return Progress is
     (if S.Load + X > L then (Parts => S.Parts + 1, Load => X)
      else (Parts => S.Parts, Load => S.Load + X))
   with Pre => S.Parts <= Length and then S.Load + X <= Sum'Last;

   --  The greedy scan over Input (1 .. K) with limit L.
   function Scan (Input : Input_Array; L : Limit; K : Prefix) return Progress
   with
     Subprogram_Variant => (Decreases => K),
     Post => Scan'Result.Parts <= K + 1
             and then Scan'Result.Load <= Prefix_Sum (Input, K);

   --  Parts the greedy split uses with limit L.
   function Greedy_Parts (Input : Input_Array; L : Limit) return Positive is
     (Scan (Input, L, Length).Parts);

   --  Limits Max_Element .. Total, at most 800 of them: at most
   --  ceil (log2 800) = 10 limits tried.
   subtype Probe_Count is Natural range 0 .. 10;
   type Sum_Result is record
      Largest : Limit;         --  smallest possible largest part sum
      Probes  : Probe_Count;   --  limits tried (each costs a pass over Input)
   end record;

   --  The least limit, no smaller than the largest element, whose greedy
   --  split fits in Parts.
   function Largest_Sum
     (Input : Input_Array; Parts : Part_Count) return Sum_Result
   with
     Global => null,
     Post   =>
       Largest_Sum'Result.Largest in Max_Element (Input) .. Total (Input)
       and then Greedy_Parts (Input, Largest_Sum'Result.Largest) <= Parts
       and then (for all L in Max_Element (Input) .. Largest_Sum'Result.Largest - 1 =>
                   Greedy_Parts (Input, L) > Parts);

private
   function Prefix_Sum (Input : Input_Array; K : Prefix) return Sum is
     (if K = 0 then 0 else Prefix_Sum (Input, K - 1) + Input (K));

   function Prefix_Max (Input : Input_Array; K : Prefix) return Natural is
     (if K = 0 then 0 else Natural'Max (Prefix_Max (Input, K - 1), Input (K)));

   function Scan (Input : Input_Array; L : Limit; K : Prefix) return Progress is
     (if K = 0 then (Parts => 1, Load => 0)
      else Step (Scan (Input, L, K - 1), Input (K), L));
end Split_Array_Largest_Sum;
