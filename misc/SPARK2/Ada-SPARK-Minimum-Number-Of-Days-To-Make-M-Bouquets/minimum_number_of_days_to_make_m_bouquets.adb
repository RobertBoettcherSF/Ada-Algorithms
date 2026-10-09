pragma Ada_2022;

package body Minimum_Number_Of_Days_To_Make_M_Bouquets with SPARK_Mode => On is

   --  Step by step the later day is ahead: more bouquets, or as many and
   --  at least as long a run.
   --  S2 is ahead of S1: more bouquets, or as many and at least as long
   --  a run.
   function Ahead (S2, S1 : Progress) return Boolean is
     (S2.Made > S1.Made or else (S2.Made = S1.Made and then S2.Run >= S1.Run))
   with Ghost;

   --  One flower: if it is open for the scan behind, it is open for the
   --  scan ahead, and the scan ahead stays ahead.
   procedure Lemma_Step
     (S1, S2 : Progress; B1, B2 : Boolean; Size : Bouquet_Size)
   with
     Ghost,
     Pre  => Ahead (S2, S1) and then (if B1 then B2)
             and then S1.Run < Size and then S1.Made * Size + S1.Run < Length
             and then S2.Run < Size and then S2.Made * Size + S2.Run < Length,
     Post => Ahead (Step (S2, B2, Size), Step (S1, B1, Size))
   is
   begin
      if not B1 then
         pragma Assert (Step (S1, B1, Size) = (Made => S1.Made, Run => 0));
         pragma Assert (Step (S2, B2, Size).Made >= S2.Made);
      elsif S2.Made > S1.Made then
         pragma Assert (Step (S1, B1, Size).Made <= S1.Made + 1);
         pragma Assert (Step (S2, B2, Size).Made >= S2.Made);
      elsif S1.Run + 1 = Size then
         pragma Assert (S2.Run + 1 = Size);
      else
         pragma Assert (Step (S1, B1, Size) = (Made => S1.Made, Run => S1.Run + 1));
      end if;
   end Lemma_Step;

   procedure Lemma_Monotone
     (Bloom_Days : Bloom_Array; D1, D2 : Day; Size : Bouquet_Size)
   is
      P1, P2 : Progress := (Made => 0, Run => 0);
   begin
      for I in Index loop
         pragma Assert (P1 = Scan (Bloom_Days, D1, Size, I - 1));
         pragma Assert (P2 = Scan (Bloom_Days, D2, Size, I - 1));
         pragma Assert (P1.Run < Size and then P1.Made * Size + P1.Run <= I - 1);
         pragma Assert (P2.Run < Size and then P2.Made * Size + P2.Run <= I - 1);
         Lemma_Step (P1, P2, Bloom_Days (I) <= D1, Bloom_Days (I) <= D2, Size);
         P1 := Step (P1, Bloom_Days (I) <= D1, Size);
         P2 := Step (P2, Bloom_Days (I) <= D2, Size);
         pragma Loop_Invariant (P1 = Scan (Bloom_Days, D1, Size, I));
         pragma Loop_Invariant (P2 = Scan (Bloom_Days, D2, Size, I));
         pragma Loop_Invariant (Ahead (P2, P1));
      end loop;
   end Lemma_Monotone;

   --  On the last day every flower has bloomed: the scan cuts
   --  Length / Size bouquets.
   procedure Lemma_Full (Bloom_Days : Bloom_Array; Size : Bouquet_Size)
   with
     Ghost,
     Post => Count (Bloom_Days, Day'Last, Size) * Size <= Length
             and then Length < (Count (Bloom_Days, Day'Last, Size) + 1) * Size
   is
      P : Progress := (Made => 0, Run => 0);
   begin
      for I in Index loop
         pragma Assert (P = Scan (Bloom_Days, Day'Last, Size, I - 1));
         if P.Run + 1 = Size then
            pragma Assert ((P.Made + 1) * Size = P.Made * Size + P.Run + 1);
         end if;
         P := Step (P, True, Size);
         pragma Loop_Invariant (P = Scan (Bloom_Days, Day'Last, Size, I));
         pragma Loop_Invariant (P.Made * Size + P.Run = I);
      end loop;
      pragma Assert (P.Run < Size);
      pragma Assert ((P.Made + 1) * Size = P.Made * Size + Size);
   end Lemma_Full;

   function Bouquets_By
     (Bloom_Days : Bloom_Array; D : Day; Size : Bouquet_Size) return Prefix
   with Post => Bouquets_By'Result = Count (Bloom_Days, D, Size)
   is
      Made : Prefix := 0;
      Run  : Prefix := 0;
   begin
      for I in Index loop
         if Bloom_Days (I) <= D then
            Run := Run + 1;
            if Run = Size then
               Made := Made + 1;
               Run := 0;
            end if;
         else
            Run := 0;
         end if;
         pragma Loop_Invariant
           (Progress'(Made => Made, Run => Run) = Scan (Bloom_Days, D, Size, I));
      end loop;
      return Made;
   end Bouquets_By;

   function Minimum_Day
     (Bloom_Days : Bloom_Array;
      Bouquets   : Bouquet_Count;
      Size       : Bouquet_Size) return Day_Result
   is
      Lo  : Day := Day'First;
      Hi  : Day := Day'Last;
      Mid : Day;
   begin
      Lemma_Full (Bloom_Days, Size);
      if Bouquets_By (Bloom_Days, Day'Last, Size) < Bouquets then
         pragma Assert
           (Bouquets * Size >= (Count (Bloom_Days, Day'Last, Size) + 1) * Size);
         return (Possible => False, First_Day => Day'Last);
      end if;
      pragma Assert
        (Bouquets * Size <= Count (Bloom_Days, Day'Last, Size) * Size);
      while Lo < Hi loop
         pragma Loop_Invariant (Count (Bloom_Days, Hi, Size) >= Bouquets);
         pragma Loop_Invariant
           (Lo = Day'First or else Count (Bloom_Days, Lo - 1, Size) < Bouquets);
         pragma Loop_Variant (Decreases => Hi - Lo);
         Mid := Lo + (Hi - Lo) / 2;
         if Bouquets_By (Bloom_Days, Mid, Size) >= Bouquets then
            Hi := Mid;
         else
            Lo := Mid + 1;
         end if;
      end loop;
      return (Possible => True, First_Day => Lo);
   end Minimum_Day;
end Minimum_Number_Of_Days_To_Make_M_Bouquets;
