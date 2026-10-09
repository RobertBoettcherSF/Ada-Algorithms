pragma Ada_2022;

package body Capacity_To_Ship_Packages with SPARK_Mode => On is

   --  A larger capacity never needs more days. After every prefix the
   --  larger capacity has started fewer days, or as many with a load no
   --  heavier (so whatever fits on C1's day fits on C2's).
   procedure Lemma_Monotone (Weights : Weight_Array; C1, C2 : Capacity)
   with
     Ghost,
     Pre  => C1 <= C2,
     Post => Days_Needed (Weights, C2) <= Days_Needed (Weights, C1)
   is
   begin
      for K in Index loop
         pragma Loop_Invariant
           (Greedy (Weights, C2, K).Days < Greedy (Weights, C1, K).Days
            or else (Greedy (Weights, C2, K).Days = Greedy (Weights, C1, K).Days
                     and then Greedy (Weights, C2, K).Load <= Greedy (Weights, C1, K).Load));
      end loop;
   end Lemma_Monotone;

   --  At Capacity'Last everything ships on day one.
   procedure Lemma_Largest (Weights : Weight_Array)
   with
     Ghost,
     Post => Days_Needed (Weights, Capacity'Last) = 1
   is
   begin
      for K in Index loop
         pragma Loop_Invariant (Greedy (Weights, Capacity'Last, K).Days = 1);
      end loop;
   end Lemma_Largest;

   --  Largest Hi - Lo after K capacities tried: 799 halved K times.
   function Width (K : Probe_Count) return Natural is
     (case K is
        when 0 => 799, when 1 => 399, when 2 => 199, when 3 => 99,
        when 4 => 49, when 5 => 24, when 6 => 12, when 7 => 6,
        when 8 => 3, when 9 => 1, when 10 => 0)
   with Ghost;

   function Minimum_Capacity_Counted
     (Weights : Weight_Array; Days : Day_Count) return Capacity_Result is
      Max_Weight : Weight := Weights (Index'First);
      Max_At     : Index := Index'First with Ghost;
      Lo         : Capacity;               --  the answer is in Lo .. Hi
      Hi         : Capacity := Capacity'Last;
      Mid        : Capacity;
      Probes     : Probe_Count := 0;
   begin
      for I in Index loop
         if Weights (I) > Max_Weight then
            Max_Weight := Weights (I);
            Max_At := I;
         end if;
         pragma Loop_Invariant (for all J in 1 .. I => Weights (J) <= Max_Weight);
         pragma Loop_Invariant (Weights (Max_At) = Max_Weight);
      end loop;

      Lemma_Largest (Weights);
      Lo := Max_Weight;
      while Lo < Hi loop
         pragma Loop_Invariant (Max_Weight <= Lo);
         pragma Loop_Invariant (Fits (Weights, Hi, Days));
         pragma Loop_Invariant (Lo = Max_Weight or else not Fits (Weights, Lo - 1, Days));
         pragma Loop_Invariant (Hi - Lo <= Width (Probes));
         pragma Loop_Variant (Decreases => Hi - Lo);
         Mid := Lo + (Hi - Lo) / 2;
         Probes := Probes + 1;
         --  Mid >= Lo >= Max_Weight, so every package fits on its own.
         if Days_Needed (Weights, Mid) <= Days then
            Hi := Mid;
         else
            Lo := Mid + 1;
         end if;
      end loop;

      --  Below Max_Weight the heaviest package does not fit; from
      --  Max_Weight to Lo - 1 a smaller capacity needs no fewer days
      --  than Lo - 1, which already needs too many.
      for C in 1 .. Lo - 1 loop
         if C >= Max_Weight then
            Lemma_Monotone (Weights, C, Lo - 1);
         end if;
         pragma Loop_Invariant (for all T in 1 .. C => not Fits (Weights, T, Days));
      end loop;
      return (Minimum => Lo, Probes => Probes);
   end Minimum_Capacity_Counted;
end Capacity_To_Ship_Packages;
