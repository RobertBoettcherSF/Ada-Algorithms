pragma Ada_2022;

package body Binary_Insertion_Sort with SPARK_Mode => On is

   --  B is A with positions J and J + 1 swapped: the count of V is the
   --  same.
   procedure Lemma_Swap_Value (A, B : Input_Array; J : Index; V : Value)
   with
     Ghost,
     Pre  => J < Index'Last
             and then B (J) = A (J + 1) and then B (J + 1) = A (J)
             and then (for all K in Index => (if K /= J and then K /= J + 1 then B (K) = A (K))),
     Post => Occ (B, V, Index'Last) = Occ (A, V, Index'Last)
   is
   begin
      for N in Index loop
         pragma Loop_Invariant
           (if N < J then Occ (B, V, N) = Occ (A, V, N)
            elsif N = J then Occ (B, V, N) = Occ (A, V, J - 1) + (if A (J + 1) = V then 1 else 0)
            else Occ (B, V, N) = Occ (A, V, N));
      end loop;
   end Lemma_Swap_Value;

   procedure Lemma_Swap (A, B : Input_Array; J : Index)
   with
     Ghost,
     Pre  => J < Index'Last
             and then B (J) = A (J + 1) and then B (J + 1) = A (J)
             and then (for all K in Index => (if K /= J and then K /= J + 1 then B (K) = A (K))),
     Post => (for all V in Value => Occ (B, V, Index'Last) = Occ (A, V, Index'Last))
   is
   begin
      for V in Value loop
         Lemma_Swap_Value (A, B, J, V);
         pragma Loop_Invariant
           (for all W in Value'First .. V => Occ (B, W, Index'Last) = Occ (A, W, Index'Last));
      end loop;
   end Lemma_Swap;

   --  Halvings that take a search range of width W to 0.
   function Bits (W : Natural) return Natural is
     (case W is
        when 0 => 0, when 1 => 1, when 2 .. 3 => 2, when others => 3)
   with Ghost, Pre => W <= 7;

   --  Bits (1) + .. + Bits (K): the comparisons for inserting elements
   --  2 .. K + 1.
   function Sum_Bits (K : Natural) return Natural is
     (case K is
        when 0 => 0, when 1 => 1, when 2 => 3, when 3 => 5, when 4 => 8,
        when 5 => 11, when 6 => 14, when others => 17)
   with Ghost, Pre => K <= 7;

   function Sort (Input : Input_Array) return Sort_Result is
      Work   : Input_Array := Input;
      Probes : Probe_Count := 0;
      X      : Value;
      Lo, Hi : Index;
      Mid    : Index;
      Cmps   : Natural range 0 .. 3;
      Tmp    : Value;
   begin
      for I in 2 .. Index'Last loop
         pragma Loop_Invariant (for all K in 1 .. I - 2 => Work (K) <= Work (K + 1));
         pragma Loop_Invariant
           (for all V in Value => Occ (Work, V, Index'Last) = Occ (Input, V, Index'Last));
         pragma Loop_Invariant (Probes <= Sum_Bits (I - 2));
         X := Work (I);

         --  Upper bound of X in Work (1 .. I - 1): the first position
         --  holding a value > X, or I. Equal values stay in front (stable).
         Lo := 1;
         Hi := I;
         Cmps := 0;
         while Lo < Hi loop
            pragma Loop_Invariant (Lo <= Hi and then Hi <= I);
            pragma Loop_Invariant (Lo = 1 or else Work (Lo - 1) <= X);
            pragma Loop_Invariant (Hi = I or else Work (Hi) > X);
            pragma Loop_Invariant (Cmps + Bits (Hi - Lo) <= Bits (I - 1));
            pragma Loop_Variant (Decreases => Hi - Lo);
            Mid := Lo + (Hi - Lo) / 2;
            Cmps := Cmps + 1;
            if Work (Mid) <= X then
               Lo := Mid + 1;
            else
               Hi := Mid;
            end if;
         end loop;
         pragma Assert (Sum_Bits (I - 1) = Sum_Bits (I - 2) + Bits (I - 1));
         Probes := Probes + Cmps;

         --  Move X down to Lo by swapping it with each larger neighbour.
         declare
            Before : constant Input_Array := Work with Ghost;
            P      : constant Index := Lo;
         begin
            pragma Assert (for all K in P .. I - 1 => Before (K) > X);
            for J in reverse P .. I - 1 loop
               pragma Loop_Invariant (Work (J + 1) = X);
               pragma Loop_Invariant (for all K in 1 .. J => Work (K) = Before (K));
               pragma Loop_Invariant (for all K in J + 2 .. I => Work (K) = Before (K - 1));
               pragma Loop_Invariant (for all K in I + 1 .. Index'Last => Work (K) = Before (K));
               pragma Loop_Invariant
                 (for all V in Value => Occ (Work, V, Index'Last) = Occ (Input, V, Index'Last));
               declare
                  Pre_Swap : constant Input_Array := Work with Ghost;
               begin
                  Tmp := Work (J);
                  Work (J) := Work (J + 1);
                  Work (J + 1) := Tmp;
                  Lemma_Swap (Pre_Swap, Work, J);
               end;
            end loop;
            pragma Assert (Work (P) = X);
            pragma Assert (for all K in 1 .. P - 1 => Work (K) = Before (K));
            pragma Assert (for all K in P + 1 .. I => Work (K) = Before (K - 1));
            pragma Assert (P = 1 or else Work (P - 1) <= X);
            pragma Assert (P = I or else X < Work (P + 1));
         end;
      end loop;
      return (Sorted => Work, Probes => Probes);
   end Sort;
end Binary_Insertion_Sort;
