pragma Ada_2022;
package body House_Robber_III_Lite with SPARK_Mode => On is

   --  The best totals of the subtree of a house when it is robbed (Take)
   --  and when it is not (Skip).
   type Pair is record
      Take, Skip : Natural;
   end record;

   function Best (P : Pair) return Natural is (Natural'Max (P.Take, P.Skip));

   function Plan (T : Good_Tree; I : Index) return Pair
   with
     Pre                => I <= T.N,
     Post               => Plan'Result.Take <= Max_Value * (Last_Of (T, I) - I + 1)
                           and then Plan'Result.Skip <= Max_Value * (Last_Of (T, I) - I + 1),
     Subprogram_Variant => (Decreases => T.N - I);

   --  Each child's plan is computed once (a declare expression), so a call
   --  costs O (subtree size).
   function Plan (T : Good_Tree; I : Index) return Pair is
     (declare
        PL : constant Pair := (if T.Left (I) = 0 then (0, 0) else Plan (T, T.Left (I)));
        PR : constant Pair := (if T.Right (I) = 0 then (0, 0) else Plan (T, T.Right (I)));
      begin
        (Take => T.Value (I) + PL.Skip + PR.Skip, Skip => Best (PL) + Best (PR)));

   function Max_Loot (T : Good_Tree) return Natural is
     (if T.N = 0 then 0 else Best (Plan (T, 1)));

   --  Children of houses in the subtree of I stay in the subtree of I.
   procedure Lemma_Closed (T : Good_Tree; I : Index)
   with
     Ghost,
     Global             => null,
     Pre                => I <= T.N,
     Post               => (declare
                              E : constant Index := Last_Of (T, I);
                            begin
                              (for all J in I .. E => T.Left (J) <= E and then T.Right (J) <= E)),
     Subprogram_Variant => (Decreases => T.N - I);

   procedure Lemma_Closed (T : Good_Tree; I : Index) is
   begin
      if T.Left (I) /= 0 then
         Lemma_Closed (T, T.Left (I));
      end if;
      if T.Right (I) /= 0 then
         Lemma_Closed (T, T.Right (I));
      end if;
   end Lemma_Closed;

   --  Loot of the subtree of I only reads the choice inside it.
   procedure Lemma_Loot_Frame (T : Good_Tree; S1, S2 : One_Based_Choice; I : Index)
   with
     Ghost,
     Global             => null,
     Pre                => S1'Last = T.N and then S2'Last = T.N
                           and then I <= T.N
                           and then (for all J in I .. Last_Of (T, I) => S1 (J) = S2 (J)),
     Post               => Loot (T, S1, I) = Loot (T, S2, I),
     Subprogram_Variant => (Decreases => T.N - I);

   procedure Lemma_Loot_Frame (T : Good_Tree; S1, S2 : One_Based_Choice; I : Index) is
   begin
      if T.Left (I) /= 0 then
         Lemma_Loot_Frame (T, S1, S2, T.Left (I));
      end if;
      if T.Right (I) /= 0 then
         Lemma_Loot_Frame (T, S1, S2, T.Right (I));
      end if;
   end Lemma_Loot_Frame;

   --  Mark the subtree of I; Blocked means the parent of I is robbed.
   procedure Mark (T : Good_Tree; I : Index; Blocked : Boolean; Chosen : in out One_Based_Choice)
   with
     Global             => null,
     Pre                => Chosen'Last = T.N and then I <= T.N,
     Post               => (declare
                              E : constant Index := Last_Of (T, I);
                            begin
                              (for all J in 1 .. T.N => (if J < I or else J > E then Chosen (J) = Chosen'Old (J))))
                           and then (if Blocked then not Chosen (I))
                           and then (for all J in I .. Last_Of (T, I) => Local (T, Chosen, J))
                           and then Loot (T, Chosen, I)
                                    = (if Blocked then Plan (T, I).Skip else Best (Plan (T, I))),
     Subprogram_Variant => (Decreases => T.N - I);

   procedure Mark (T : Good_Tree; I : Index; Blocked : Boolean; Chosen : in out One_Based_Choice) is
      P : constant Pair := Plan (T, I);
      L : constant Link := T.Left (I);
      R : constant Link := T.Right (I);
   begin
      Chosen (I) := not Blocked and then P.Take >= P.Skip;
      if L /= 0 then
         Mark (T, L, Chosen (I), Chosen);
         Lemma_Closed (T, L);
      end if;
      declare
         Mid : constant One_Based_Choice := Chosen with Ghost;
      begin
         if R /= 0 then
            Mark (T, R, Chosen (I), Chosen);
            if L /= 0 then
               pragma Assert (for all J in L .. Last_Of (T, L) => Chosen (J) = Mid (J));
               Lemma_Loot_Frame (T, Chosen, Mid, L);
            end if;
         end if;
      end;
   end Mark;

   function Best_Choice (T : Good_Tree) return One_Based_Choice is
      R : One_Based_Choice (1 .. T.N) := [others => False];
   begin
      if T.N > 0 then
         Mark (T, 1, False, R);
      end if;
      return R;
   end Best_Choice;

   --  An independent choice is worth at most Take (I) in the subtree of I
   --  when I is robbed, and at most Skip (I) when it is not.
   procedure Lemma_Opt_Node (T : Good_Tree; S : One_Based_Choice; I : Index)
   with
     Ghost,
     Global             => null,
     Pre                => S'Last = T.N and then I <= T.N and then Independent (T, S),
     Post               => Loot (T, S, I) <= (if S (I) then Plan (T, I).Take else Plan (T, I).Skip),
     Subprogram_Variant => (Decreases => T.N - I);

   procedure Lemma_Opt_Node (T : Good_Tree; S : One_Based_Choice; I : Index) is
   begin
      pragma Assert (Local (T, S, I));
      if T.Left (I) /= 0 then
         Lemma_Opt_Node (T, S, T.Left (I));
      end if;
      if T.Right (I) /= 0 then
         Lemma_Opt_Node (T, S, T.Right (I));
      end if;
   end Lemma_Opt_Node;

   procedure Lemma_Optimal (T : Good_Tree; S : One_Based_Choice) is
   begin
      Lemma_Opt_Node (T, S, 1);
   end Lemma_Optimal;
end House_Robber_III_Lite;
