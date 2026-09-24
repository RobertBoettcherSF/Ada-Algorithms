package body Inside_Outside is

   --------------------
   -- Compute_Inside --
   --------------------

   function Compute_Inside
     (G     : Grammar;
      O_Raw : Observation_Sequence) return Dynamic_Matrix
   is
      T     : constant Sequence_Index := O_Raw'Length;
      --  Normalize sequence indices to 1 .. T to simplify algorithm logic
      O     : constant Observation_Sequence (1 .. T) := O_Raw;
      Alpha : Dynamic_Matrix (1 .. G.Num_NT, 1 .. T, 1 .. T) :=
                [others => [others => [others => 0.0]]];
   begin
      --  Base cases (Sequence length 1)
      --  Alpha_j(p, p) = e(N_j, o_p)
      for p in 1 .. T loop
         for j in 1 .. G.Num_NT loop
            Alpha (j, p, p) := G.Unary (j, O (p));
         end loop;
      end loop;

      --  Recursive cases (Sequence length L from 2 to T)
      for L in 2 .. T loop
         for p in 1 .. T - L + 1 loop
            declare
               q : constant Sequence_Index := p + L - 1;
            begin
               for j in 1 .. G.Num_NT loop
                  declare
                     Sum : Real := 0.0;
                  begin
                     for r in 1 .. G.Num_NT loop
                        for s in 1 .. G.Num_NT loop
                           declare
                              Prob_Rule : constant Real := G.Binary (j, r, s);
                           begin
                              --  Optimization: Skip zero probability branches
                              if Prob_Rule > 0.0 then
                                 for k in p .. q - 1 loop
                                    Sum := Sum + Prob_Rule * Alpha (r, p, k) * Alpha (s, k + 1, q);
                                 end loop;
                              end if;
                           end;
                        end loop;
                     end loop;
                     Alpha (j, p, q) := Sum;
                  end;
               end loop;
            end;
         end loop;
      end loop;

      return Alpha;
   end Compute_Inside;

   ---------------------
   -- Compute_Outside --
   ---------------------

   function Compute_Outside
     (G     : Grammar;
      O_Raw : Observation_Sequence;
      Alpha : Dynamic_Matrix) return Dynamic_Matrix
   is
      T    : constant Sequence_Index := O_Raw'Length;
      Beta : Dynamic_Matrix (1 .. G.Num_NT, 1 .. T, 1 .. T) :=
               [others => [others => [others => 0.0]]];
   begin
      --  Base case
      --  Beta_Start(1, T) = 1.0, all others 0.0
      Beta (G.Start_Symbol, 1, T) := 1.0;

      --  Recursive cases (Processing span lengths decreasingly from T-1 down to 1)
      for L in reverse 1 .. T - 1 loop
         for p in 1 .. T - L + 1 loop
            declare
               q : constant Sequence_Index := p + L - 1;
            begin
               for j in 1 .. G.Num_NT loop
                  declare
                     Sum : Real := 0.0;
                  begin
                     --  Part 1: j is the LEFT child in a rule f -> j s
                     --  The parent f spans from p to e, split at q.
                     for e in q + 1 .. T loop
                        for f in 1 .. G.Num_NT loop
                           for s in 1 .. G.Num_NT loop
                              declare
                                 Rule_Prob : constant Real := G.Binary (f, j, s);
                              begin
                                 if Rule_Prob > 0.0 then
                                    Sum := Sum + Beta (f, p, e) * Rule_Prob * Alpha (s, q + 1, e);
                                 end if;
                              end;
                           end loop;
                        end loop;
                     end loop;

                     --  Part 2: j is the RIGHT child in a rule f -> r j
                     --  The parent f spans from e to q, split at p-1.
                     for e in 1 .. p - 1 loop
                        for f in 1 .. G.Num_NT loop
                           for r in 1 .. G.Num_NT loop
                              declare
                                 Rule_Prob : constant Real := G.Binary (f, r, j);
                              begin
                                 if Rule_Prob > 0.0 then
                                    Sum := Sum + Beta (f, e, q) * Rule_Prob * Alpha (r, e, p - 1);
                                 end if;
                              end;
                           end loop;
                        end loop;
                     end loop;

                     Beta (j, p, q) := Sum;
                  end;
               end loop;
            end;
         end loop;
      end loop;

      return Beta;
   end Compute_Outside;

   --------------------------
   -- Sequence_Probability --
   --------------------------

   function Sequence_Probability
     (G     : Grammar;
      O_Raw : Observation_Sequence) return Real
   is
      Alpha : constant Dynamic_Matrix := Compute_Inside (G, O_Raw);
   begin
      return Alpha (G.Start_Symbol, 1, O_Raw'Length);
   end Sequence_Probability;

   -------------
   -- EM_Step --
   -------------

   function EM_Step
     (G     : Grammar;
      O_Raw : Observation_Sequence) return Grammar
   is
      T          : constant Sequence_Index := O_Raw'Length;
      O          : constant Observation_Sequence (1 .. T) := O_Raw;
      Alpha      : constant Dynamic_Matrix := Compute_Inside (G, O);
      Beta       : constant Dynamic_Matrix := Compute_Outside (G, O, Alpha);
      Prob_Total : constant Real := Alpha (G.Start_Symbol, 1, T);

      New_G : Grammar (G.Num_NT, G.Num_T) := G;

      type Count_Array_Binary is array (1 .. G.Num_NT, 1 .. G.Num_NT, 1 .. G.Num_NT) of Real;
      type Count_Array_Unary  is array (1 .. G.Num_NT, 1 .. G.Num_T) of Real;
      type Total_Count_Array  is array (1 .. G.Num_NT) of Real;

      Counts_Bin : Count_Array_Binary := [others => [others => [others => 0.0]]];
      Counts_Un  : Count_Array_Unary  := [others => [others => 0.0]];
      Totals     : Total_Count_Array  := [others => 0.0];
   begin
      if Prob_Total = 0.0 then
         raise Computation_Error with "Sequence probability is zero, EM step impossible.";
      end if;

      --  Compute expected counts for binary rules: N_j -> N_r N_s
      for j in 1 .. G.Num_NT loop
         for r in 1 .. G.Num_NT loop
            for s in 1 .. G.Num_NT loop
               declare
                  Expected_Count : Real := 0.0;
                  Prob_Rule      : constant Real := G.Binary (j, r, s);
               begin
                  if Prob_Rule > 0.0 then
                     for p in 1 .. T - 1 loop
                        for q in p + 1 .. T loop
                           for k in p .. q - 1 loop
                              Expected_Count := Expected_Count +
                                (Beta (j, p, q) * Prob_Rule * Alpha (r, p, k) * Alpha (s, k + 1, q)) / Prob_Total;
                           end loop;
                        end loop;
                     end loop;
                     Counts_Bin (j, r, s) := Expected_Count;
                  end if;
               end;
            end loop;
         end loop;
      end loop;

      --  Compute expected counts for unary rules: N_j -> v_m
      for j in 1 .. G.Num_NT loop
         for p in 1 .. T loop
            declare
               m              : constant Terminal_Id := O (p);
               Prob_Rule      : constant Real := G.Unary (j, m);
               Expected_Count : Real;
            begin
               if Prob_Rule > 0.0 then
                  Expected_Count := (Beta (j, p, p) * Prob_Rule) / Prob_Total;
                  Counts_Un (j, m) := Counts_Un (j, m) + Expected_Count;
               end if;
            end;
         end loop;
      end loop;

      --  Accumulate totals to normalize probabilities
      for j in 1 .. G.Num_NT loop
         for r in 1 .. G.Num_NT loop
            for s in 1 .. G.Num_NT loop
               Totals (j) := Totals (j) + Counts_Bin (j, r, s);
            end loop;
         end loop;
         for m in 1 .. G.Num_T loop
            Totals (j) := Totals (j) + Counts_Un (j, m);
         end loop;
      end loop;

      --  Update grammar probabilities using expected counts
      for j in 1 .. G.Num_NT loop
         if Totals (j) > 0.0 then
            for r in 1 .. G.Num_NT loop
               for s in 1 .. G.Num_NT loop
                  New_G.Binary (j, r, s) := Counts_Bin (j, r, s) / Totals (j);
               end loop;
            end loop;
            for m in 1 .. G.Num_T loop
               New_G.Unary (j, m) := Counts_Un (j, m) / Totals (j);
            end loop;
         else
            --  If a non-terminal was unobserved, keep its original distribution to maintain validity.
            null;
         end if;
      end loop;

      return New_G;
   end EM_Step;

   ----------------------
   -- Is_Valid_Grammar --
   ----------------------

   function Is_Valid_Grammar (G : Grammar) return Boolean is
      Sum : Real;
   begin
      for j in 1 .. G.Num_NT loop
         Sum := 0.0;
         for r in 1 .. G.Num_NT loop
            for s in 1 .. G.Num_NT loop
               Sum := Sum + G.Binary (j, r, s);
            end loop;
         end loop;
         for m in 1 .. G.Num_T loop
            Sum := Sum + G.Unary (j, m);
         end loop;

         --  Allow a small floating point tolerance. Strict 1.0 check can fail due to rounding.
         if abs (Sum - 1.0) > 1.0e-5 then
            return False;
         end if;
      end loop;
      return True;
   end Is_Valid_Grammar;

end Inside_Outside;
