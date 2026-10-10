pragma Ada_2022;
package body Subsets with SPARK_Mode => On is

   procedure Lemma_Pow2 is
   begin
      for K in 1 .. Max_Items loop
         pragma Loop_Invariant (for all J in 1 .. K - 1 => Pow2 (J) = 2 * Pow2 (J - 1));
         pragma Assert (Pow2 (K) = 2 * Pow2 (K - 1));
      end loop;
   end Lemma_Pow2;

   --  A run of True items in the first L positions stands for 2 ** L - 1.
   procedure Lemma_All_True (S : Small_Selection; L : Natural)
   with
     Ghost,
     Global             => null,
     Pre                => L <= S'Length and then Pow2_Doubles
                           and then (for all K in S'First .. S'First - 1 + L => S (K)),
     Post               => Rank (S, L) = Pow2 (L) - 1,
     Subprogram_Variant => (Decreases => L);
   procedure Lemma_All_True (S : Small_Selection; L : Natural) is
   begin
      if L > 0 then
         Lemma_All_True (S, L - 1);
      end if;
   end Lemma_All_True;

   procedure Lemma_All_False (S : Small_Selection; L : Natural)
   with
     Ghost,
     Global             => null,
     Pre                => L <= S'Length and then Pow2_Doubles
                           and then (for all K in S'First .. S'First - 1 + L => not S (K)),
     Post               => Rank (S, L) = 0,
     Subprogram_Variant => (Decreases => L);
   procedure Lemma_All_False (S : Small_Selection; L : Natural) is
   begin
      if L > 0 then
         Lemma_All_False (S, L - 1);
      end if;
   end Lemma_All_False;

   --  Items above I contribute the same to both ranks if they agree.
   procedure Lemma_Frame (A, B : Small_Selection; I, L : Natural)
   with
     Ghost,
     Global             => null,
     Pre                => A'First = B'First and then A'Last = B'Last and then I <= L
                           and then L <= A'Length and then Pow2_Doubles
                           and then (for all K in A'First .. A'First - 1 + L =>
                                       (if K - A'First >= I then A (K) = B (K))),
     Post               => Rank (A, L) - Rank (A, I) = Rank (B, L) - Rank (B, I),
     Subprogram_Variant => (Decreases => L);
   procedure Lemma_Frame (A, B : Small_Selection; I, L : Natural) is
   begin
      if L > I then
         Lemma_Frame (A, B, I, L - 1);
      end if;
   end Lemma_Frame;

   procedure Lemma_Count_Mono (S : Selection; I, L : Natural)
   with
     Ghost,
     Global             => null,
     Pre                => I in S'First - 1 .. S'Last and then L in I .. S'Last,
     Post               => Count_True (S, I) <= Count_True (S, L),
     Subprogram_Variant => (Decreases => L);
   procedure Lemma_Count_Mono (S : Selection; I, L : Natural) is
   begin
      if L > I then
         Lemma_Count_Mono (S, I, L - 1);
      end if;
   end Lemma_Count_Mono;

   function Count (N : Item_Count) return Positive is
      R : Positive := 1;
   begin
      Lemma_Pow2;
      for I in 1 .. N loop
         pragma Loop_Invariant (R = Pow2 (I - 1));
         R := 2 * R;
      end loop;
      return R;
   end Count;

   procedure Next_Subset (S : in out Small_Selection; Found : out Boolean) is
      S0 : constant Small_Selection := S with Ghost;
      N  : constant Natural := S'Length;
      P  : Positive := 1;   --  position: S (S'First + P - 1)
   begin
      Lemma_Pow2;
      --  Clear the run of True items at the bottom.
      while P <= N and then S (S'First + (P - 1)) loop
         pragma Loop_Invariant (P <= N);
         pragma Loop_Invariant
           (for all K in S'First .. S'First + (P - 2) => S0 (K) and then not S (K));
         pragma Loop_Invariant (for all K in S'First + (P - 1) .. S'Last => S (K) = S0 (K));
         pragma Loop_Variant (Increases => P);
         S (S'First + (P - 1)) := False;
         P := P + 1;
      end loop;

      if P > N then
         --  Every item was selected: wrap around to the empty subset.
         Lemma_All_True (S0, N);
         pragma Assert (for all K in S'Range => not S (K));
         Found := False;
         return;
      end if;

      S (S'First + (P - 1)) := True;
      Found := True;
      Lemma_All_True (S0, P - 1);
      Lemma_All_False (S, P - 1);
      pragma Assert (Rank (S, P) = Rank (S0, P) + 1);
      Lemma_Frame (S, S0, P, N);
   end Next_Subset;

   function Selected (S : Selection) return Natural
   with Pre => S'Length > 0, Post => Selected'Result = Count_True (S, S'Last);
   function Selected (S : Selection) return Natural is
      N : Natural := 0;
   begin
      for I in S'Range loop
         pragma Loop_Invariant (N = Count_True (S, I - 1));
         if S (I) then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Selected;

   function Subset (Items : Item_List; S : Selection) return Item_List is
   begin
      if S'Length = 0 then
         return [];
      end if;

      declare
         N : constant Natural := Selected (S);
         R : Item_List (1 .. N) := [others => 0];
         J : Natural := 0;
      begin
         for I in S'Range loop
            pragma Loop_Invariant (J = Count_True (S, I - 1) and then J <= N);
            pragma Loop_Invariant
              (for all K in S'First .. I - 1 =>
                 (if S (K) then Count_True (S, K) in 1 .. J
                                and then R (Count_True (S, K)) = Items (Items'First + (K - S'First))));
            if S (I) then
               Lemma_Count_Mono (S, I, S'Last);
               J := J + 1;
               R (J) := Items (Items'First + (I - S'First));
            end if;
         end loop;
         return R;
      end;
   end Subset;
end Subsets;
