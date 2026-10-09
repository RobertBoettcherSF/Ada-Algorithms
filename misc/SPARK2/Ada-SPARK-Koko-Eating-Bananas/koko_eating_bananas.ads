pragma Ada_2022;

--  Koko eating bananas: at speed S Koko eats up to S bananas from one
--  pile per hour, so pile P takes ceil (P / S) hours. Find the slowest
--  speed that finishes all piles within Hours, by halving the speeds.
package Koko_Eating_Bananas with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Prefix is Natural range 0 .. Length;
   subtype Pile_Size is Positive range 1 .. 100;
   subtype Speed is Positive range 1 .. 100;
   --  At least one hour per pile, so speed 100 always finishes in time.
   subtype Hour_Count is Positive range Length .. 100;
   type Pile_Array is array (Index) of Pile_Size;

   --  Hours for one pile: ceil (Pile / S).
   function Pile_Hours (Pile : Pile_Size; S : Speed) return Pile_Size is
     ((Pile + S - 1) / S);

   --  Hours for piles 1 .. K.
   function Partial_Hours (Piles : Pile_Array; S : Speed; K : Prefix) return Natural
   with
     Subprogram_Variant => (Decreases => K),
     Post => Partial_Hours'Result in K .. K * Pile_Size'Last;

   function Hours_Needed (Piles : Pile_Array; S : Speed) return Natural is
     (Partial_Hours (Piles, S, Length));

   --  Speeds 1 .. 100: at most ceil (log2 100) = 7 speeds tried.
   subtype Probe_Count is Natural range 0 .. 7;
   type Speed_Result is record
      Minimum : Speed;         --  slowest speed that finishes in time
      Probes  : Probe_Count;   --  speeds tried (each costs a pass over Piles)
   end record;

   function Minimum_Speed
     (Piles : Pile_Array; Hours : Hour_Count) return Speed_Result
   with
     Global => null,
     Post   =>
       Hours_Needed (Piles, Minimum_Speed'Result.Minimum) <= Hours
       and then (for all S in 1 .. Minimum_Speed'Result.Minimum - 1 =>
                   Hours_Needed (Piles, S) > Hours);

private
   function Partial_Hours (Piles : Pile_Array; S : Speed; K : Prefix) return Natural is
     (if K = 0 then 0 else Partial_Hours (Piles, S, K - 1) + Pile_Hours (Piles (K), S));
end Koko_Eating_Bananas;
