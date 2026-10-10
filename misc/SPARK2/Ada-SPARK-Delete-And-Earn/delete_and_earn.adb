pragma Ada_2022;

package body Delete_And_Earn with SPARK_Mode => On is

   --  Best depends only on the entries of P (array "=" is element-wise,
   --  which the prover does not carry through function calls by itself).
   procedure Lemma_Best_Same (P1, P2 : Point_Array; K : Value_Count)
   with
     Ghost,
     Global             => null,
     Pre                => (for all X in Number => P1 (X) = P2 (X)),
     Post               => Best (P1, K) = Best (P2, K),
     Subprogram_Variant => (Decreases => K);

   procedure Lemma_Best_Same (P1, P2 : Point_Array; K : Value_Count) is
   begin
      if K > 0 then
         Lemma_Best_Same (P1, P2, K - 1);
      end if;
   end Lemma_Best_Same;

   function Max_Earn (Nums : Num_Array) return Score is
      Points : Point_Array := [others => 0];
      B      : Best_Pair := (Upto => 0, Before => 0);
   begin
      --  Points (X) = X * copies of X, summed copy by copy.
      for I in Nums'Range loop
         pragma Loop_Invariant
           (for all X in Number => Points (X) = Weight (Nums, X, I - 1));
         Points (Nums (I)) := Points (Nums (I)) + Nums (I);
      end loop;
      pragma Assert (for all X in Number => Points (X) = Points_Of (Nums) (X));

      --  Values 1 .. 100 in order: skip X, or take it and leave out X - 1.
      for X in Number loop
         pragma Loop_Invariant (B = Best (Points, X - 1));
         B := (Upto => Natural'Max (B.Upto, B.Before + Points (X)), Before => B.Upto);
      end loop;
      Lemma_Best_Same (Points, Points_Of (Nums), 100);
      return B.Upto;
   end Max_Earn;

   --  In 1, 2, .., N, value X occurs once at position X when X <= Last.
   procedure Lemma_Once_Weight (Nums : Num_Array; Last : Natural)
   with
     Ghost,
     Global             => null,
     Pre                =>
       Nums'First = 1 and then Nums'Length > 0 and then Last <= Nums'Last
       and then (for all I in Nums'Range => Nums (I) = I),
     Post               =>
       (for all X in Number => Weight (Nums, X, Last) = (if X <= Last then X else 0)),
     Subprogram_Variant => (Decreases => Last);

   procedure Lemma_Once_Weight (Nums : Num_Array; Last : Natural) is
   begin
      if Last > 0 then
         Lemma_Once_Weight (Nums, Last - 1);
      end if;
   end Lemma_Once_Weight;

   function Maximum (N : Number) return Score is
      Nums : constant Num_Array (1 .. N) := [for I in 1 .. N => I];
   begin
      Lemma_Once_Weight (Nums, N);
      Lemma_Best_Same (Points_Of (Nums), Once_Points (N), 100);
      return Max_Earn (Nums);
   end Maximum;
end Delete_And_Earn;
