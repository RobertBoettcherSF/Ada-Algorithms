pragma Ada_2022;

package body Find_Minimum_In_Rotated_Sorted_Array_II with SPARK_Mode => On is

   --  The turn: after the one strict fall, or 1 if Values never falls.
   function Pivot_Of (Values : Rotated_Array) return Index
   with
     Ghost,
     Post => Rotated_At (Values, Pivot_Of'Result)
             and then (if Pivot_Of'Result > 1
                       then Values (Pivot_Of'Result - 1) > Values (Pivot_Of'Result))
   is
   begin
      for K in 1 .. Length - 1 loop
         if Values (K) > Values (K + 1) then
            return K + 1;
         end if;
         pragma Loop_Invariant (for all J in 1 .. K => Values (J) <= Values (J + 1));
      end loop;
      return 1;
   end Pivot_Of;

   --  Inside one sorted part the values never fall.
   procedure Lemma_Chain (Values : Value_Array; P, A, B : Index)
   with
     Ghost,
     Pre  => Rotated_At (Values, P) and then A <= B
             and then (P <= A or else B < P),
     Post => Values (A) <= Values (B)
   is
   begin
      for K in A .. B - 1 loop
         pragma Assert (Values (K) <= Values (K + 1));
         pragma Loop_Invariant (Values (A) <= Values (K + 1));
      end loop;
   end Lemma_Chain;

   --  Before the turn every value is >= the first; from the turn on every
   --  value is <= the last <= the first.
   procedure Lemma_Parts (Values : Value_Array; P, I : Index)
   with
     Ghost,
     Pre  => Rotated_At (Values, P) and then P > 1,
     Post => (if I < P then Values (I) >= Values (1) else Values (I) <= Values (1))
   is
   begin
      if I < P then
         Lemma_Chain (Values, P, 1, I);
      else
         Lemma_Chain (Values, P, I, Length);
      end if;
   end Lemma_Parts;

   --  What one comparison of Mid with Hi says about the turn P in Lo .. Hi.
   procedure Lemma_Step (Values : Value_Array; P, Mid, Hi : Index)
   with
     Ghost,
     Pre  => Rotated_At (Values, P) and then Mid < Hi,
     Post => (if Values (Mid) > Values (Hi) then P in Mid + 1 .. Hi)
             and then (if Values (Mid) < Values (Hi) then P not in Mid + 1 .. Hi)
   is
   begin
      if P <= Mid or else Hi < P then
         Lemma_Chain (Values, P, Mid, Hi);
      else
         Lemma_Parts (Values, P, Mid);
         Lemma_Parts (Values, P, Hi);
      end if;
   end Lemma_Step;

   --  The element at the turn is a smallest one.
   procedure Lemma_Minimum (Values : Value_Array; P : Index)
   with
     Ghost,
     Pre  => Rotated_At (Values, P),
     Post => (for all I in Index => Values (P) <= Values (I))
   is
   begin
      for I in Index loop
         if I < P then
            Lemma_Parts (Values, P, I);
            Lemma_Chain (Values, P, P, Length);
         else
            Lemma_Chain (Values, P, P, I);
         end if;
         pragma Loop_Invariant (for all J in 1 .. I => Values (P) <= Values (J));
      end loop;
   end Lemma_Minimum;

   function Find_Minimum (Values : Rotated_Array) return Search_Result is
      Pv     : constant Index := Pivot_Of (Values) with Ghost;
      Lo     : Index := 1;
      Hi     : Index := Length;
      Mid    : Index;
      Probes : Probe_Count := 0;
   begin
      while Lo < Hi loop
         pragma Loop_Invariant (Pv in Lo .. Hi);
         pragma Loop_Invariant (Probes + 2 * (Hi - Lo) <= 2 * (Length - 1));
         pragma Loop_Variant (Decreases => Hi - Lo);
         Mid := Lo + (Hi - Lo) / 2;
         Probes := Probes + 1;
         Lemma_Step (Values, Pv, Mid, Hi);
         if Values (Mid) > Values (Hi) then
            Lo := Mid + 1;
         elsif Values (Mid) < Values (Hi) then
            Hi := Mid;
         else
            --  Equal ends: a second comparison, Values (Hi - 1) with Values (Hi).
            Probes := Probes + 1;
            if Values (Hi - 1) > Values (Hi) then
               --  Values falls into Hi: Hi is the turn.
               pragma Assert (Pv = Hi);
               Lo := Hi;
            else
               --  No fall into Hi: the turn is below Hi.
               Hi := Hi - 1;
            end if;
         end if;
      end loop;
      Lemma_Minimum (Values, Lo);
      return (Position => Lo, Probes => Probes);
   end Find_Minimum;

   function Minimum (Values : Rotated_Array) return Value is
      Position : constant Index := Find_Minimum (Values).Position;
   begin
      return Values (Position);
   end Minimum;
end Find_Minimum_In_Rotated_Sorted_Array_II;
