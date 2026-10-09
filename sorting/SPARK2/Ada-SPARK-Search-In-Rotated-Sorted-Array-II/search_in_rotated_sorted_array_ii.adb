pragma Ada_2022;

package body Search_In_Rotated_Sorted_Array_II with SPARK_Mode => On is

   --  The turn: after the one strict fall, or 1 if Data never falls.
   function Pivot_Of (Data : Rotated_Array) return Index
   with
     Ghost,
     Post => Rotated_At (Data, Pivot_Of'Result)
             and then (if Pivot_Of'Result > 1
                       then Data (Pivot_Of'Result - 1) > Data (Pivot_Of'Result))
   is
   begin
      for K in 1 .. Length - 1 loop
         if Data (K) > Data (K + 1) then
            return K + 1;
         end if;
         pragma Loop_Invariant (for all J in 1 .. K => Data (J) <= Data (J + 1));
      end loop;
      return 1;
   end Pivot_Of;

   --  Inside one sorted part the values never fall.
   procedure Lemma_Chain (Data : Data_Array; P, A, B : Index)
   with
     Ghost,
     Pre  => Rotated_At (Data, P) and then A <= B
             and then (P <= A or else B < P),
     Post => Data (A) <= Data (B)
   is
   begin
      for K in A .. B - 1 loop
         pragma Assert (Data (K) <= Data (K + 1));
         pragma Loop_Invariant (Data (A) <= Data (K + 1));
      end loop;
   end Lemma_Chain;

   --  Before the turn every value is >= the first; from the turn on every
   --  value is <= the last <= the first.
   procedure Lemma_Parts (Data : Data_Array; P, I : Index)
   with
     Ghost,
     Pre  => Rotated_At (Data, P) and then P > 1,
     Post => (if I < P then Data (I) >= Data (1) else Data (I) <= Data (1))
   is
   begin
      if I < P then
         Lemma_Chain (Data, P, 1, I);
      else
         Lemma_Chain (Data, P, I, Length);
      end if;
   end Lemma_Parts;

   --  What one comparison of Mid with Hi says about the turn P.
   procedure Lemma_Step (Data : Data_Array; P, Mid, Hi : Index)
   with
     Ghost,
     Pre  => Rotated_At (Data, P) and then Mid < Hi,
     Post => (if Data (Mid) > Data (Hi) then P in Mid + 1 .. Hi)
             and then (if Data (Mid) < Data (Hi) then P not in Mid + 1 .. Hi)
   is
   begin
      if P <= Mid or else Hi < P then
         Lemma_Chain (Data, P, Mid, Hi);
      else
         Lemma_Parts (Data, P, Mid);
         Lemma_Parts (Data, P, Hi);
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

   --  The part not searched cannot hold a Target that differs from the
   --  first element.
   procedure Lemma_Other_Part (Data : Data_Array; P : Index; Target : Value)
   with
     Ghost,
     Pre  => Rotated_At (Data, P) and then P > 1,
     Post => (if Target > Data (1) then (for all I in P .. Length => Data (I) /= Target))
             and then (if Target < Data (1) then (for all I in 1 .. P - 1 => Data (I) /= Target))
   is
   begin
      for I in Index loop
         Lemma_Parts (Data, P, I);
         pragma Loop_Invariant
           (for all J in 1 .. I =>
              (if J >= P then Data (J) <= Data (1) else Data (J) >= Data (1)));
      end loop;
   end Lemma_Other_Part;

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
      Turn_Cmps : Natural range 0 .. 2 * (Length - 1) := 0;   --  finding the turn
      Pick_Cmps : Natural range 0 .. 1 := 0;            --  picking the part
      Part_Cmps : Natural range 0 .. 6 := 0;            --  halving the part
      Last_Cmps : Natural range 0 .. 1 := 0;            --  the element found
      First     : Index;                                --  the part searched
      Last      : Index;                                --  is First .. Last
      L         : Positive;                             --  the lower bound of
      H         : Positive;                             --  Target is in L .. H
      Found     : Boolean;
   begin
      --  Find the turn.
      while Lo < Hi loop
         pragma Loop_Invariant (Pv in Lo .. Hi);
         pragma Loop_Invariant (Turn_Cmps + 2 * (Hi - Lo) <= 2 * (Length - 1));
         pragma Loop_Variant (Decreases => Hi - Lo);
         Mid := Lo + (Hi - Lo) / 2;
         Turn_Cmps := Turn_Cmps + 1;
         Lemma_Step (Data, Pv, Mid, Hi);
         if Data (Mid) > Data (Hi) then
            Lo := Mid + 1;
         elsif Data (Mid) < Data (Hi) then
            Hi := Mid;
         else
            --  Equal ends: a second comparison, Data (Hi - 1) with Data (Hi).
            Turn_Cmps := Turn_Cmps + 1;
            if Data (Hi - 1) > Data (Hi) then
               --  Data falls into Hi: Hi is the turn.
               Lo := Hi;
            else
               --  No fall into Hi: the turn is below Hi.
               Hi := Hi - 1;
            end if;
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
end Search_In_Rotated_Sorted_Array_II;
