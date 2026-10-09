pragma Ada_2022;

--  Ship packages in their given order over at most Days days, with the
--  same capacity every day: find the smallest capacity that works. A
--  day takes packages greedily until the next one would not fit; the
--  smallest capacity is found by halving Max_Weight .. Capacity'Last
--  (binary search on the answer, one greedy pass per capacity tried).
package Capacity_To_Ship_Packages with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Prefix is Natural range 0 .. Length;
   subtype Weight is Positive range 1 .. 100;
   --  Capacity'Last = Length * Weight'Last always ships in one day.
   subtype Capacity is Positive range 1 .. Length * Weight'Last;
   subtype Day_Count is Positive range 1 .. Length;
   subtype Day_Total is Positive range 1 .. Length + 1;
   type Weight_Array is array (Index) of Weight;

   --  Greedy loading state: days started so far, load of the current day.
   type Load_State is record
      Days : Day_Total;
      Load : Natural;
   end record;

   --  Load one more package: a new day if it does not fit on this one.
   function Step (S : Load_State; W : Weight; C : Capacity) return Load_State is
     (if S.Load + W > C then (Days => S.Days + 1, Load => W)
      else (Days => S.Days, Load => S.Load + W))
   with Pre => S.Days <= Length and then S.Load <= Capacity'Last - Weight'Last;

   --  Greedy state after packages 1 .. K.
   function Greedy (Weights : Weight_Array; C : Capacity; K : Prefix) return Load_State
   with
     Subprogram_Variant => (Decreases => K),
     Post => Greedy'Result.Days <= K + 1 and then Greedy'Result.Load <= K * Weight'Last;

   function Days_Needed (Weights : Weight_Array; C : Capacity) return Day_Total is
     (Greedy (Weights, C, Length).Days);

   --  C ships everything within Days days.
   function Fits (Weights : Weight_Array; C : Capacity; Days : Day_Count) return Boolean is
     ((for all I in Index => Weights (I) <= C) and then Days_Needed (Weights, C) <= Days);

   --  Capacities 1 .. 800: Hi - Lo <= 799 halves to 0 in 10 tries.
   subtype Probe_Count is Natural range 0 .. 10;
   type Capacity_Result is record
      Minimum : Capacity;      --  smallest capacity that fits
      Probes  : Probe_Count;   --  capacities tried (each a greedy pass)
   end record;

   function Minimum_Capacity_Counted
     (Weights : Weight_Array; Days : Day_Count) return Capacity_Result
   with
     Global => null,
     Post   =>
       Fits (Weights, Minimum_Capacity_Counted'Result.Minimum, Days)
       and then (for all C in 1 .. Minimum_Capacity_Counted'Result.Minimum - 1 =>
                   not Fits (Weights, C, Days));

   function Minimum_Capacity
     (Weights : Weight_Array; Days : Day_Count) return Capacity
   is (Minimum_Capacity_Counted (Weights, Days).Minimum)
   with
     Global => null,
     Post   =>
       Fits (Weights, Minimum_Capacity'Result, Days)
       and then (for all C in 1 .. Minimum_Capacity'Result - 1 =>
                   not Fits (Weights, C, Days));

private
   function Greedy (Weights : Weight_Array; C : Capacity; K : Prefix) return Load_State is
     (if K = 0 then (Days => 1, Load => 0)
      else Step (Greedy (Weights, C, K - 1), Weights (K), C));
end Capacity_To_Ship_Packages;
