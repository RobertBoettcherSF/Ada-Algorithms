pragma SPARK_Mode (On);
pragma Ada_2022;
package body Word_Break_II is
   --  The original exercise: W (I) = W (I - 1) + (W (I - 2) when the last
   --  two symbols are equal); W (I) <= 2 ** I <= 16, so no clamp is needed.
   function Segmentations (A : Word; N : Length) return Count is
      type Ways is array (Length) of Count;
      W : Ways := [others => 0];
   begin
      W (0) := 1;
      for I in 1 .. N loop
         pragma Loop_Invariant (for all J in 0 .. I - 1 => W (J) <= 2 ** J);
         W (I) := W (I - 1);
         if I >= 2 and then A (I) = A (I - 1) then
            W (I) := W (I) + W (I - 2);
         end if;
      end loop;
      return W (N);
   end Segmentations;

   --  Partial at Q reads only Ways (Q + 1 .. N + 1).
   procedure Lemma_Frame (S : Text; N : Text_Length; D : Dictionary; DC : Word_Count;
                          W1, W2 : Way_Table; Q : Ext_Position; L : Natural)
     with Ghost,
          Pre  => Q <= N and then L <= Max_Here (N, Q)
                  and then (for all R in Q + 1 .. N + 1 => W1 (R) = W2 (R)),
          Post => Partial (S, N, D, DC, W1, Q, L) = Partial (S, N, D, DC, W2, Q, L),
          Subprogram_Variant => (Decreases => L)
   is
   begin
      if L > 0 then
         Lemma_Frame (S, N, D, DC, W1, W2, Q, L - 1);
      end if;
   end Lemma_Frame;

   --  Partial sums grow with L.
   procedure Lemma_Mono (S : Text; N : Text_Length; D : Dictionary; DC : Word_Count;
                         W : Way_Table; P : Ext_Position; L, M : Natural)
     with Ghost,
          Pre  => P <= N and then L <= M and then M <= Max_Here (N, P),
          Post => Partial (S, N, D, DC, W, P, L) <= Partial (S, N, D, DC, W, P, M),
          Subprogram_Variant => (Decreases => M)
   is
   begin
      if M > L then
         Lemma_Mono (S, N, D, DC, W, P, L, M - 1);
      end if;
   end Lemma_Mono;

   function Table (S : Text; N : Text_Length; D : Dictionary; DC : Word_Count) return Way_Table is
      Ways : Way_Table := [others => 0];
      Sum  : Long_Long_Integer;
   begin
      Ways (N + 1) := 1;
      pragma Assert (for all I in 0 .. 12 => Pow2 (I + 1) = 2 * Pow2 (I));
      for P in reverse 1 .. N loop
         pragma Loop_Invariant (Ways (N + 1) = 1);
         pragma Loop_Invariant
           (for all Q in P + 1 .. N + 1 => Long_Long_Integer (Ways (Q)) <= Pow2 (N + 1 - Q));
         pragma Loop_Invariant
           (for all Q in P + 1 .. N =>
              Long_Long_Integer (Ways (Q)) = Partial (S, N, D, DC, Ways, Q, Max_Here (N, Q)));
         declare
            Before : constant Way_Table := Ways with Ghost;
         begin
            Sum := 0;
            for L in 1 .. Max_Here (N, P) loop
               if In_Dict (S, P, L, D, DC) then
                  Sum := Sum + Long_Long_Integer (Ways (P + L));
               end if;
               pragma Loop_Invariant (Sum = Partial (S, N, D, DC, Ways, P, L));
               pragma Loop_Invariant (Sum <= Pow2 (N + 1 - P) - Pow2 (N + 1 - P - L));
            end loop;
            Ways (P) := Sentence_Count (Sum);
            Lemma_Frame (S, N, D, DC, Before, Ways, P, Max_Here (N, P));
            for Q in P + 1 .. N loop
               Lemma_Frame (S, N, D, DC, Before, Ways, Q, Max_Here (N, Q));
               pragma Loop_Invariant
                 (for all R in P + 1 .. Q =>
                    Partial (S, N, D, DC, Ways, R, Max_Here (N, R))
                    = Partial (S, N, D, DC, Before, R, Max_Here (N, R)));
            end loop;
            pragma Assert (Long_Long_Integer (Ways (P)) = Partial (S, N, D, DC, Ways, P, Max_Here (N, P)));
            pragma Assert
              (for all Q in P .. N =>
                 Long_Long_Integer (Ways (Q)) = Partial (S, N, D, DC, Ways, Q, Max_Here (N, Q)));
         end;
      end loop;
      return Ways;
   end Table;

   procedure Sentences
     (S : Text; N : Text_Length; D : Dictionary; DC : Word_Count;
      List : out Sentence_List; Count : out Sentence_Count)
   is
      Ways : constant Way_Table := Table (S, N, D, DC);

      --  Append every split of S (P .. N), after the words in Cur, to List:
      --  exactly Ways (P) sentences (depth-first, shorter first word first).
      procedure Walk (P : Ext_Position; Cur : Break_Set)
        with Pre  => Is_Table (S, N, D, DC, Ways, 1) and then P <= N + 1
                     and then (for all R in P .. Max_Len => not Cur (R))
                     and then Long_Long_Integer (Count) + Long_Long_Integer (Ways (P)) <= Max_Sentences,
             Post => Long_Long_Integer (Count) = Long_Long_Integer (Count'Old) + Long_Long_Integer (Ways (P)),
             Subprogram_Variant => (Increases => P)
      is
         Entry_Count : constant Sentence_Count := Count with Ghost;
      begin
         if P = N + 1 then
            Count := Count + 1;
            List (Count) := Cur;
            return;
         end if;
         for L in 1 .. Max_Here (N, P) loop
            pragma Loop_Invariant
              (Long_Long_Integer (Count) = Long_Long_Integer (Entry_Count) + Partial (S, N, D, DC, Ways, P, L - 1));
            Lemma_Mono (S, N, D, DC, Ways, P, L, Max_Here (N, P));
            if In_Dict (S, P, L, D, DC) then
               declare
                  Next : Break_Set := Cur;
               begin
                  Next (P + L - 1) := True;
                  Walk (P + L, Next);
               end;
            end if;
         end loop;
      end Walk;
   begin
      List := [others => [others => False]];
      Count := 0;
      pragma Assert (Long_Long_Integer (Ways (1)) <= Pow2 (N));
      Walk (1, [others => False]);
   end Sentences;
end Word_Break_II;
