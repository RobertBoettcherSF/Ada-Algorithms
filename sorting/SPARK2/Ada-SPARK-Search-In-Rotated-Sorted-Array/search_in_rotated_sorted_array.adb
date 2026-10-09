pragma Ada_2022;

package body Search_In_Rotated_Sorted_Array with SPARK_Mode => On is

   --  The turn, for the proof.
   function Pivot_Of (Data : Rotated_Array) return Index
   with
     Ghost,
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

   --  Inside one sorted part (both before the turn, or both from it on)
   --  the values rise strictly.
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

   --  Comparing Mid with Hi tells which side of Mid the turn is on.
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

   --  Inside the sorted part First .. Last, the two neighbours of L
   --  (below Target, above Target) rule Target out everywhere.
   procedure Lemma_Absent (Data : Data_Array; P, First, Last : Index; L : Positive; Target : Value)
   with
     Ghost,
     Pre  => Rotated_At (Data, P) and then First <= Last
             and then (P <= First or else Last < P)
             and then L in First .. Last + 1
             and then (L = First or else Data (L - 1) < Target)
             and then (L = Last + 1 or else Data (L) > Target),
     Post => (for all I in First .. Last => Data (I) /= Target)
   is
   begin
      for I in First .. Last loop
         if I < L then
            Lemma_Chain (Data, P, I, L - 1);
         else
            Lemma_Chain (Data, P, L, I);
         end if;
         pragma Loop_Invariant (for all J in First .. I => Data (J) /= Target);
      end loop;
   end Lemma_Absent;

   --  Before the turn every value is >= Data (1); from the turn on every
   --  value is < Data (1). So the part not searched cannot hold Target.
   procedure Lemma_Other_Part (Data : Data_Array; P : Index; Target : Value)
   with
     Ghost,
     Pre  => Rotated_At (Data, P) and then P > 1,
     Post => (if Target >= Data (1)
              then (for all I in P .. Length => Data (I) /= Target)
              else (for all I in 1 .. P - 1 => Data (I) /= Target))
   is
   begin
      for I in Index loop
         if I >= P then
            Lemma_Chain (Data, P, I, Length);
         else
            Lemma_Chain (Data, P, 1, I);
         end if;
         pragma Loop_Invariant
           (for all J in 1 .. I =>
              (if J >= P then Data (J) < Data (1) else Data (J) >= Data (1)));
      end loop;
   end Lemma_Other_Part;

   --  Largest Hi - Lo + 1 after K comparisons while finding the turn.
   function Turn_Width (K : Natural) return Positive is
     (case K is
        when 0 => 32, when 1 => 16, when 2 => 8, when 3 => 4,
        when 4 => 2, when others => 1)
   with Ghost;

   --  Largest H - L after K comparisons in a sorted part.
   function Part_Width (K : Natural) return Natural is
     (case K is
        when 0 => 32, when 1 => 16, when 2 => 8, when 3 => 4,
        when 4 => 2, when 5 => 1, when others => 0)
   with Ghost;

   function Contains (Data : Rotated_Array; Target : Value) return Search_Result is
      Pv        : constant Index := Pivot_Of (Data) with Ghost;
      Lo        : Index := 1;
      Hi        : Index := Length;
      Mid       : Index;
      Turn_Cmps : Natural range 0 .. 5 := 0;   --  comparisons finding the turn
      Pick_Cmps : Natural range 0 .. 1 := 0;   --  comparison picking the part
      Part_Cmps : Natural range 0 .. 6 := 0;   --  comparisons halving the part
      Last_Cmps : Natural range 0 .. 1 := 0;   --  comparison of the element found
      First     : Index;                       --  the part searched is
      Last      : Index;                       --  First .. Last
      L         : Positive;                    --  the lower bound of Target
      H         : Positive;                    --  in First .. Last is in L .. H
      Found     : Boolean;
   begin
      --  Find the turn (the smallest element).
      while Lo < Hi loop
         pragma Loop_Invariant (Pv in Lo .. Hi);
         pragma Loop_Invariant (Hi - Lo + 1 <= Turn_Width (Turn_Cmps));
         pragma Loop_Variant (Decreases => Hi - Lo);
         Mid := Lo + (Hi - Lo) / 2;
         Turn_Cmps := Turn_Cmps + 1;
         Lemma_Step (Data, Pv, Mid, Hi);
         if Data (Mid) > Data (Hi) then
            Lo := Mid + 1;
         else
            Hi := Mid;
         end if;
      end loop;
      pragma Assert (Lo = Pv);

      --  Pick the sorted part that can hold Target.
      if Lo = 1 then
         First := 1;
         Last := Length;
      else
         Pick_Cmps := 1;
         if Target >= Data (1) then
            First := 1;
            Last := Lo - 1;
         else
            First := Lo;
            Last := Length;
         end if;
      end if;

      --  Lower bound of Target in Data (First .. Last).
      L := First;
      H := Last + 1;
      while L < H loop
         pragma Loop_Invariant (First <= L and then L <= H and then H <= Last + 1);
         pragma Loop_Invariant (L = First or else Data (L - 1) < Target);
         pragma Loop_Invariant (H = Last + 1 or else Data (H) >= Target);
         pragma Loop_Invariant (H - L <= Part_Width (Part_Cmps));
         pragma Loop_Variant (Decreases => H - L);
         Mid := L + (H - L) / 2;
         Part_Cmps := Part_Cmps + 1;
         if Data (Mid) < Target then
            L := Mid + 1;
         else
            H := Mid;
         end if;
      end loop;

      if L <= Last then
         Last_Cmps := 1;
         Found := Data (L) = Target;
      else
         Found := False;
      end if;

      if not Found then
         Lemma_Absent (Data, Lo, First, Last, L, Target);
         if Lo > 1 then
            Lemma_Other_Part (Data, Lo, Target);
         end if;
         pragma Assert (for all I in Index => Data (I) /= Target);
      end if;
      return (Found => Found, Probes => Turn_Cmps + Pick_Cmps + Part_Cmps + Last_Cmps);
   end Contains;
end Search_In_Rotated_Sorted_Array;
