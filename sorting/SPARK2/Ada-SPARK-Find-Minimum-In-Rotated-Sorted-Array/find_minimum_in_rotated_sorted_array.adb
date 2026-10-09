pragma Ada_2022;

package body Find_Minimum_In_Rotated_Sorted_Array with SPARK_Mode => On is

   --  The pivot: just after the one descent, or 1 if there is none.
   function Pivot_Of (Data : Data_Array) return Index
   with
     Ghost,
     Pre  => Is_Rotated_Sorted (Data),
     Post => Rotated_At (Data, Pivot_Of'Result)
   is
   begin
      for K in 1 .. Length - 1 loop
         if Data (K) > Data (K + 1) then
            return K + 1;
         end if;
         pragma Loop_Invariant (Data (1) <= Data (K + 1));
      end loop;
      return 1;
   end Pivot_Of;

   --  Inside one part the values increase: A < B there gives
   --  Data (A) < Data (B).
   procedure Lemma_Chain (Data : Data_Array; P, A, B : Index)
   with
     Ghost,
     Pre  => Rotated_At (Data, P) and then A <= B
       and then (P <= A or else B < P),
     Post => A = B or else Data (A) < Data (B)
   is
   begin
      for K in A .. B - 1 loop
         pragma Assert (Data (K) < Data (K + 1));
         pragma Loop_Invariant (Data (A) < Data (K + 1));
      end loop;
   end Lemma_Chain;

   --  Data (P) is the minimum: from the pivot on the values grow, and
   --  before it they are above Data (Length).
   procedure Lemma_Bounds (Data : Data_Array; P : Index; I : Index)
   with
     Ghost,
     Pre  => Rotated_At (Data, P),
     Post => Data (P) <= Data (I)
   is
   begin
      if I < P then
         Lemma_Chain (Data, P, 1, I);
         Lemma_Chain (Data, P, P, Length);
      else
         Lemma_Chain (Data, P, P, I);
      end if;
   end Lemma_Bounds;

   procedure Lemma_Minimum (Data : Data_Array; P : Index)
   with
     Ghost,
     Pre  => Rotated_At (Data, P),
     Post => (for all I in Index => Data (P) <= Data (I))
   is
   begin
      for I in Index loop
         Lemma_Bounds (Data, P, I);
         pragma Loop_Invariant (for all J in 1 .. I => Data (P) <= Data (J));
      end loop;
   end Lemma_Minimum;

   --  For Mid < Hi with the pivot at or before Hi: Data (Mid) > Data (Hi)
   --  exactly when the pivot is after Mid.
   procedure Lemma_Step (Data : Data_Array; P, Mid, Hi : Index)
   with
     Ghost,
     Pre  => Rotated_At (Data, P) and then Mid < Hi and then P <= Hi,
     Post => (if P <= Mid then Data (Mid) < Data (Hi) else Data (Mid) > Data (Hi))
   is
   begin
      if P <= Mid then
         Lemma_Chain (Data, P, Mid, Hi);
      else
         Lemma_Chain (Data, P, 1, Mid);
         Lemma_Chain (Data, P, Hi, Length);
      end if;
   end Lemma_Step;

   --  Largest width of the search range after K probes: 32 / 2 ** K.
   function Width (K : Probe_Count) return Positive is
     (case K is
        when 0 => 32, when 1 => 16, when 2 => 8, when 3 => 4,
        when 4 => 2, when 5 => 1)
   with Ghost;

   function Find_Minimum (Data : Data_Array) return Search_Result is
      Pv     : constant Index := Pivot_Of (Data) with Ghost;
      Lo     : Index := 1;
      Hi     : Index := Length;
      Mid    : Index;
      Probes : Probe_Count := 0;
   begin
      while Lo < Hi loop
         pragma Loop_Invariant (Pv in Lo .. Hi);
         pragma Loop_Invariant (Hi - Lo + 1 <= Width (Probes));
         pragma Loop_Variant (Decreases => Hi - Lo);
         Mid := Lo + (Hi - Lo) / 2;
         Probes := Probes + 1;
         Lemma_Step (Data, Pv, Mid, Hi);
         if Data (Mid) > Data (Hi) then
            --  The descent lies between Mid and Hi.
            Lo := Mid + 1;
         else
            --  Mid .. Hi increases, so the pivot is not after Mid.
            Hi := Mid;
         end if;
      end loop;
      pragma Assert (Lo = Pv);
      Lemma_Minimum (Data, Pv);
      return (Position => Lo, Probes => Probes);
   end Find_Minimum;

   function Minimum (Data : Data_Array) return Value is
      Position : constant Index := Find_Minimum (Data).Position;
   begin
      return Data (Position);
   end Minimum;
end Find_Minimum_In_Rotated_Sorted_Array;
