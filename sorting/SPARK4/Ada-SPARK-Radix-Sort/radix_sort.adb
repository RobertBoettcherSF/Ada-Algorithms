pragma Ada_2022;
--  Run-time cost: the ghost lemmas, loop invariants and assertions
--  quantify over all 256 keys with recursive counts; all are proved
--  (make prove) and skipped at run time. The spec Posts of Pass and Sort
--  still execute.
pragma Assertion_Policy (Ghost => Ignore, Loop_Invariant => Ignore, Assert => Ignore);

--  Radix_Sort body: two stable distribution passes. Each pass sweeps the
--  input once per digit value D = 0 .. 15 and appends the keys with digit
--  D in input order (stable by construction). Ghost counts of the keys
--  with a digit below D / equal to D show that the writes stay inside B
--  and fill it.

package body Radix_Sort
  with SPARK_Mode => On
is
   --  Keys of A (A'First .. Last) with digit P below D.
   function Cnt_Less (A : Element_Array; P : Pass_Index; D : Natural; Last : Natural) return Natural
   is (if Last < A'First then 0
       else Cnt_Less (A, P, D, Last - 1) + (if Digit_Of (A (Last), P) < D then 1 else 0))
   with Ghost, Global => null,
        Pre  => In_Bounds (A) and then Last <= A'Last,
        Post => Cnt_Less'Result <= (if Last < A'First then 0 else Last - A'First + 1),
        Subprogram_Variant => (Decreases => Last);

   --  Keys of A (A'First .. Last) with digit P equal to D.
   function Cnt_Eq (A : Element_Array; P : Pass_Index; D : Natural; Last : Natural) return Natural
   is (if Last < A'First then 0
       else Cnt_Eq (A, P, D, Last - 1) + (if Digit_Of (A (Last), P) = D then 1 else 0))
   with Ghost, Global => null,
        Pre  => In_Bounds (A) and then Last <= A'Last,
        Post => Cnt_Eq'Result <= (if Last < A'First then 0 else Last - A'First + 1),
        Subprogram_Variant => (Decreases => Last);

   procedure Lemma_Step (A : Element_Array; P : Pass_Index; D : Digit; Last : Natural)
   with Ghost, Global => null,
        Pre  => In_Bounds (A) and then Last <= A'Last,
        Post => Cnt_Less (A, P, D, Last) + Cnt_Eq (A, P, D, Last) = Cnt_Less (A, P, D + 1, Last),
        Subprogram_Variant => (Decreases => Last)
   is
   begin
      if Last >= A'First then
         Lemma_Step (A, P, D, Last - 1);
      end if;
   end Lemma_Step;

   procedure Lemma_Zero (A : Element_Array; P : Pass_Index; Last : Natural)
   with Ghost, Global => null,
        Pre  => In_Bounds (A) and then Last <= A'Last,
        Post => Cnt_Less (A, P, 0, Last) = 0,
        Subprogram_Variant => (Decreases => Last)
   is
   begin
      if Last >= A'First then
         Lemma_Zero (A, P, Last - 1);
      end if;
   end Lemma_Zero;

   procedure Lemma_All (A : Element_Array; P : Pass_Index; Last : Natural)
   with Ghost, Global => null,
        Pre  => In_Bounds (A) and then Last <= A'Last and then Last + 1 >= A'First,
        Post => Cnt_Less (A, P, Digit_Base, Last) = Last + 1 - A'First,
        Subprogram_Variant => (Decreases => Last)
   is
   begin
      if Last >= A'First then
         Lemma_All (A, P, Last - 1);
      end if;
   end Lemma_All;

   procedure Lemma_Mono (A : Element_Array; P : Pass_Index; D : Natural; I, Last : Natural)
   with Ghost, Global => null,
        Pre  => In_Bounds (A) and then Last <= A'Last and then I <= Last,
        Post => Cnt_Eq (A, P, D, I) <= Cnt_Eq (A, P, D, Last),
        Subprogram_Variant => (Decreases => Last)
   is
   begin
      if Last > I then
         Lemma_Mono (A, P, D, I, Last - 1);
      end if;
   end Lemma_Mono;

   --  Counts over A'First .. Last only see A'First .. Last.
   procedure Lemma_Occ_Frame (X, Y : Element_Array; Last : Natural)
   with Ghost, Global => null,
        Pre  => In_Bounds (X) and then In_Bounds (Y) and then X'First = Y'First
                and then Last <= X'Last and then Last <= Y'Last
                and then (for all K in X'First .. Last => X (K) = Y (K)),
        Post => (for all V in Element => Occ (X, V, Last) = Occ (Y, V, Last)),
        Subprogram_Variant => (Decreases => Last)
   is
   begin
      if Last >= X'First then
         Lemma_Occ_Frame (X, Y, Last - 1);
      end if;
   end Lemma_Occ_Frame;

   procedure Pass
     (A : Element_Array; P : Pass_Index; B : out Element_Array; Src : out Source_Map)
   is
      K    : Positive := A'First;          --  next free slot of B
      Prev : Element_Array (B'Range) with Ghost;
   begin
      B   := [others => 0];
      Src := [others => A'First];
      if A'Length = 0 then
         return;
      end if;
      Lemma_Zero (A, P, A'Last);
      for D in Digit loop
         pragma Loop_Invariant (K = A'First + Cnt_Less (A, P, D, A'Last) and then K <= A'Last + 1);
         pragma Loop_Invariant (for all J in A'First .. K - 1 => Src (J) in A'Range and then B (J) = A (Src (J)));
         pragma Loop_Invariant (for all J in A'First .. K - 1 => Digit_Of (B (J), P) < D);
         pragma Loop_Invariant
           (for all J1 in A'First .. K - 1 =>
              (for all J2 in J1 + 1 .. K - 1 =>
                 Digit_Of (B (J1), P) <= Digit_Of (B (J2), P)
                 and then (if Digit_Of (B (J1), P) = Digit_Of (B (J2), P) then Src (J1) < Src (J2))));
         pragma Loop_Invariant
           (for all V in Element =>
              Occ (B, V, K - 1) = (if Digit_Of (V, P) < D then Occ (A, V, A'Last) else 0));
         for I in A'Range loop
            pragma Loop_Invariant (K = A'First + Cnt_Less (A, P, D, A'Last) + Cnt_Eq (A, P, D, I - 1));
            pragma Loop_Invariant (K <= A'Last + 1);
            pragma Loop_Invariant (for all J in A'First .. K - 1 => Src (J) in A'Range and then B (J) = A (Src (J)));
            pragma Loop_Invariant (for all J in A'First .. K - 1 => Digit_Of (B (J), P) <= D);
            pragma Loop_Invariant
              (for all J in A'First .. K - 1 => (if Digit_Of (B (J), P) = D then Src (J) < I));
            pragma Loop_Invariant
              (for all J1 in A'First .. K - 1 =>
                 (for all J2 in J1 + 1 .. K - 1 =>
                    Digit_Of (B (J1), P) <= Digit_Of (B (J2), P)
                    and then (if Digit_Of (B (J1), P) = Digit_Of (B (J2), P) then Src (J1) < Src (J2))));
            pragma Loop_Invariant
              (for all V in Element =>
                 Occ (B, V, K - 1) = (if Digit_Of (V, P) < D then Occ (A, V, A'Last)
                                      elsif Digit_Of (V, P) = D then Occ (A, V, I - 1)
                                      else 0));
            if Digit_Of (A (I), P) = D then
               Lemma_Mono (A, P, D, I, A'Last);
               Lemma_Step (A, P, D, A'Last);
               Lemma_All (A, P, A'Last);
               pragma Assert (Cnt_Less (A, P, D + 1, A'Last) <= Cnt_Less (A, P, Digit_Base, A'Last));
               Prev := B;
               B (K) := A (I);
               Src (K) := I;
               Lemma_Occ_Frame (Prev, B, K - 1);
               K := K + 1;
            end if;
         end loop;
         Lemma_Step (A, P, D, A'Last);
      end loop;
      Lemma_All (A, P, A'Last);
      pragma Assert (K = A'Last + 1);
   end Pass;

   procedure Sort (A : in out Element_Array) is
      B1, B2 : Element_Array (A'Range);
      S1, S2 : Source_Map (A'Range);
   begin
      Pass (A, 1, B1, S1);
      Pass (B1, 2, B2, S2);
      pragma Assert
        (for all J in A'First .. A'Last - 1 =>
           Digit_Of (B2 (J), 2) < Digit_Of (B2 (J + 1), 2)
           or else (Digit_Of (B2 (J), 2) = Digit_Of (B2 (J + 1), 2)
                    and then Digit_Of (B2 (J), 1) <= Digit_Of (B2 (J + 1), 1)));
      pragma Assert (for all J in A'First .. A'Last - 1 => B2 (J) <= B2 (J + 1));
      pragma Assert (for all J in A'Range => B1 (J) = A (S1 (J)) and then B2 (J) = B1 (S2 (J)));
      A := B2;
   end Sort;

end Radix_Sort;
