pragma Ada_2022;
package body Subsets_II with SPARK_Mode => On is

   function Big (V : Integer) return Big_Integer renames To_Big_Integer;

   function Pow2_Facts return Boolean is
     ((for all K in 1 .. Max_Items => Pow2 (K) = 2 * Pow2 (K - 1))
      and then (for all K in Length => K + 1 <= Pow2 (K) and then Pow2 (K) <= Pow2 (Max_Items)))
   with Ghost;

   procedure Lemma_Pow2
   with Ghost, Global => null, Post => Pow2_Facts;
   procedure Lemma_Pow2 is
   begin
      for K in Length loop
         pragma Loop_Invariant (for all J in 1 .. K - 1 => Pow2 (J) = 2 * Pow2 (J - 1));
         pragma Loop_Invariant (for all J in 0 .. K - 1 => J + 1 <= Pow2 (J) and then Pow2 (J) <= Pow2 (Max_Items));
         pragma Assert (if K >= 1 then Pow2 (K) = 2 * Pow2 (K - 1));
         pragma Assert (K + 1 <= Pow2 (K) and then Pow2 (K) <= Pow2 (Max_Items));
      end loop;
   end Lemma_Pow2;

   --  2 ** A * 2 ** B = 2 ** (A + B).
   procedure Lemma_Pow2_Add (A, B : Length)
   with
     Ghost,
     Global             => null,
     Pre                => A + B <= Max_Items and then Pow2_Facts,
     Post               => Big (Pow2 (A)) * Big (Pow2 (B)) = Big (Pow2 (A + B)),
     Subprogram_Variant => (Decreases => B);
   procedure Lemma_Pow2_Add (A, B : Length) is
   begin
      if B > 0 then
         Lemma_Pow2_Add (A, B - 1);
         pragma Assert (Big (Pow2 (B)) = 2 * Big (Pow2 (B - 1)));
         pragma Assert (Big (Pow2 (A + B)) = 2 * Big (Pow2 (A + B - 1)));
      end if;
   end Lemma_Pow2_Add;

   procedure Lemma_Mul_Mono (X, XX, Y, YY : Big_Integer)
   with
     Ghost,
     Global => null,
     Pre    => X >= 0 and then X <= XX and then Y >= 0 and then Y <= YY,
     Post   => X * Y <= XX * YY;
   procedure Lemma_Mul_Mono (X, XX, Y, YY : Big_Integer) is
   begin
      pragma Assert (X * Y <= XX * Y);
      pragma Assert (XX * Y <= XX * YY);
   end Lemma_Mul_Mono;

   procedure Lemma_Total_Mono (A : Count_List; I, K : Natural)
   with
     Ghost,
     Global             => null,
     Pre                => A'First = 1 and then I <= K and then K <= A'Last and then K <= Max_Items,
     Post               => Total (A, I) <= Total (A, K),
     Subprogram_Variant => (Decreases => K);
   procedure Lemma_Total_Mono (A : Count_List; I, K : Natural) is
   begin
      if K > I then
         Lemma_Total_Mono (A, I, K - 1);
      end if;
   end Lemma_Total_Mono;

   --  One more factor: P <= 2 ** T gives P * (C + 1) <= 2 ** (T + C).
   procedure Lemma_Product_Step (P : Big_Integer; T, C : Length)
   with
     Ghost,
     Global => null,
     Pre    => P >= 1 and then P <= Big (Pow2 (T)) and then T + C <= Max_Items and then Pow2_Facts,
     Post   => P * Big (C + 1) >= 1 and then P * Big (C + 1) <= Big (Pow2 (T + C));
   procedure Lemma_Product_Step (P : Big_Integer; T, C : Length) is
   begin
      Lemma_Pow2_Add (T, C);
      Lemma_Mul_Mono (P, Big (Pow2 (T)), Big (C + 1), Big (Pow2 (C)));
   end Lemma_Product_Step;

   function Count (C : Choice) return Positive is
      R : Positive := 1;
   begin
      Lemma_Pow2;
      for I in 1 .. C.N loop
         pragma Loop_Invariant (Big (R) = Product (C.Copies, I - 1));
         pragma Loop_Invariant (Total (C.Copies, I - 1) <= Max_Items);
         pragma Loop_Invariant (Big (R) <= Big (Pow2 (Total (C.Copies, I - 1))));
         Lemma_Total_Mono (C.Copies, I, C.N);
         Lemma_Product_Step (Big (R), Total (C.Copies, I - 1), C.Copies (I));
         pragma Assert (Product (C.Copies, I) = Big (R) * Big (C.Copies (I) + 1));
         pragma Assert (Product (C.Copies, I) <= Big (Pow2 (Max_Items)));
         R := R * (C.Copies (I) + 1);
      end loop;
      return R;
   end Count;

   procedure Next_Choice (C : in out Choice; Found : out Boolean) is
      N : constant Length := C.N;
      T : Count_List (1 .. N) := C.Take;
      I : Positive := 1;
   begin
      --  Full digits at the bottom roll over to 0.
      while I <= C.N and then T (I) = C.Copies (I) loop
         pragma Loop_Invariant (I <= C.N);
         pragma Loop_Invariant (for all K in 1 .. I - 1 => T (K) = 0 and then C.Take (K) = C.Copies (K));
         pragma Loop_Invariant (for all K in I .. C.N => T (K) = C.Take (K));
         pragma Loop_Variant (Increases => I);
         T (I) := 0;
         I := I + 1;
      end loop;

      if I > C.N then
         --  Everything was taken: wrap around to the empty subset.
         C := (N => C.N, Copies => C.Copies, Take => T);
         Found := False;
         return;
      end if;

      T (I) := T (I) + 1;
      pragma Assert (C.Take (I) < T (I));
      C := (N => C.N, Copies => C.Copies, Take => T);
      Found := True;
   end Next_Choice;


   function Subset (Values : Item_List; C : Choice) return Item_List is
      Len : constant Natural := Total (C.Take, C.N);
      R   : Item_List (1 .. Len) := [others => 0];
      P   : Natural := 0;
   begin
      for I in 1 .. C.N loop
         pragma Loop_Invariant (P = Total (C.Take, I - 1) and then P <= Len);
         pragma Loop_Invariant (for all M in 1 .. P => R (M) = Values (Group (C.Take, M, I - 1)));
         Lemma_Total_Mono (C.Take, I, C.N);
         pragma Assert (P + C.Take (I) = Total (C.Take, I));
         for J in 1 .. C.Take (I) loop
            pragma Loop_Invariant (for all M in 1 .. P => R (M) = Values (Group (C.Take, M, I - 1)));
            pragma Loop_Invariant (for all M in P + 1 .. P + J - 1 => R (M) = Values (I));
            R (P + J) := Values (I);
         end loop;
         pragma Assert (for all M in 1 .. P => Group (C.Take, M, I) = Group (C.Take, M, I - 1));
         pragma Assert (for all M in P + 1 .. P + C.Take (I) => Group (C.Take, M, I) = I);
         P := P + C.Take (I);
      end loop;
      return R;
   end Subset;
end Subsets_II;
