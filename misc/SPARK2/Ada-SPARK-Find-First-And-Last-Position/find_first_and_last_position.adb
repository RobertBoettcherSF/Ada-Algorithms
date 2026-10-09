pragma Ada_2022;

package body Find_First_And_Last_Position with SPARK_Mode => On is

   subtype Insertion_Index is Positive range 1 .. Length + 1;
   subtype Search_Probes is Natural range 0 .. 6;

   --  In a sorted array A <= B gives Data (A) <= Data (B).
   procedure Lemma_Chain (Data : Sorted_Array; A, B : Index)
   with
     Ghost,
     Pre  => A <= B,
     Post => Data (A) <= Data (B)
   is
   begin
      for K in A .. B - 1 loop
         pragma Assert (Data (K) <= Data (K + 1));
         pragma Loop_Invariant (Data (A) <= Data (K + 1));
      end loop;
   end Lemma_Chain;

   --  Is Data (I) past the boundary? Above (Data (I) > Target) when
   --  Strict, else Data (I) >= Target.
   function Past (X : Value; Target : Value; Strict : Boolean) return Boolean is
     (if Strict then X > Target else X >= Target);

   --  The two neighbours of P decide every element.
   procedure Lemma_Split
     (Data : Sorted_Array; Target : Value; Strict : Boolean; P : Insertion_Index)
   with
     Ghost,
     Pre  => (P = 1 or else not Past (Data (P - 1), Target, Strict))
             and then (P = Length + 1 or else Past (Data (P), Target, Strict)),
     Post => (for all I in Index => Past (Data (I), Target, Strict) = (I >= P))
   is
   begin
      for I in Index loop
         if I < P then
            Lemma_Chain (Data, I, P - 1);
         else
            Lemma_Chain (Data, P, I);
         end if;
         pragma Loop_Invariant
           (for all J in 1 .. I => Past (Data (J), Target, Strict) = (J >= P));
      end loop;
   end Lemma_Split;

   --  Largest Hi - Lo after K reads: 32 / 2 ** K, and 0 after 6.
   function Width (K : Search_Probes) return Natural is
     (case K is
        when 0 => 32, when 1 => 16, when 2 => 8, when 3 => 4,
        when 4 => 2, when 5 => 1, when 6 => 0)
   with Ghost;

   --  First position past the boundary (Length + 1 if none).
   procedure Boundary_Search
     (Data     : Sorted_Array;
      Target   : Value;
      Strict   : Boolean;
      Position : out Insertion_Index;
      Probes   : out Search_Probes)
   with
     Post => (for all I in Index => Past (Data (I), Target, Strict) = (I >= Position))
   is
      Lo  : Insertion_Index := 1;            --  candidates are Lo .. Hi
      Hi  : Insertion_Index := Length + 1;
      Mid : Index;
   begin
      Probes := 0;
      while Lo < Hi loop
         pragma Loop_Invariant (Lo = 1 or else not Past (Data (Lo - 1), Target, Strict));
         pragma Loop_Invariant (Hi = Length + 1 or else Past (Data (Hi), Target, Strict));
         pragma Loop_Invariant (Hi - Lo <= Width (Probes));
         pragma Loop_Variant (Decreases => Hi - Lo);
         Mid := Lo + (Hi - Lo) / 2;
         Probes := Probes + 1;
         if Past (Data (Mid), Target, Strict) then
            Hi := Mid;
         else
            Lo := Mid + 1;
         end if;
      end loop;
      Lemma_Split (Data, Target, Strict, Lo);
      Position := Lo;
   end Boundary_Search;

   function Locate (Data : Sorted_Array; Target : Value) return Match_Range is
      Low, High       : Insertion_Index;   --  first >= Target, first > Target
      Reads1, Reads2  : Search_Probes;
   begin
      Boundary_Search (Data, Target, False, Low, Reads1);
      Boundary_Search (Data, Target, True, High, Reads2);
      --  Low <= High: an element above Target is also >= Target.
      if High <= Length then
         pragma Assert (Past (Data (High), Target, True));
         pragma Assert (Past (Data (High), Target, False));
      end if;
      pragma Assert (Low <= High);
      if Low = High then
         return (First => 0, Last => 0, Probes => Reads1 + Reads2);
      else
         return (First => Low, Last => High - 1, Probes => Reads1 + Reads2);
      end if;
   end Locate;
end Find_First_And_Last_Position;
