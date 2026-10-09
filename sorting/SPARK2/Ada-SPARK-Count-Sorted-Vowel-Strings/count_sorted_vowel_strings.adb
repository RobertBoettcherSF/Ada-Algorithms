pragma Ada_2022;
package body Count_Sorted_Vowel_Strings with SPARK_Mode => On is

   function Big (V : Integer) return Big_Integer renames To_Big_Integer;

   --  Weight (V) = Mult (V) * Weight (V + 1).
   function Mult (V : Vowel) return Big_Integer is (Big (4 - Vowel'Pos (V))) with Ghost;

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

   subtype Below_U is Vowel range A .. O;   --  the vowels with a successor

   --  One step of the program in closed form:
   --  Mult (V) * Rising (K, V + 1) + Rising (K - 1, V) = Rising (K, V).
   procedure Lemma_Step (K : Positive; V : Below_U)
   with
     Ghost,
     Global => null,
     Post   => Mult (V) * Rising (K, Vowel'Succ (V)) + Rising (K - 1, V) = Rising (K, V)
               and then Weight (V) = Mult (V) * Weight (Vowel'Succ (V));
   procedure Lemma_Step (K : Positive; V : Below_U) is
      M : constant Big_Integer := Big (K);
   begin
      pragma Assert (Big (K - 1) + 1 = M);
      case V is
         when A =>
            pragma Assert (Rising (K, A) = (M + 1) * (M + 2) * (M + 3) * (M + 4));
            pragma Assert (Rising (K - 1, A) = M * (M + 1) * (M + 2) * (M + 3));
            pragma Assert (Rising (K, E) = (M + 1) * (M + 2) * (M + 3));
            pragma Assert (4 * ((M + 1) * (M + 2) * (M + 3)) + M * ((M + 1) * (M + 2) * (M + 3))
                           = ((M + 1) * (M + 2) * (M + 3)) * (M + 4));
         when E =>
            pragma Assert (Rising (K, E) = (M + 1) * (M + 2) * (M + 3));
            pragma Assert (Rising (K - 1, E) = M * (M + 1) * (M + 2));
            pragma Assert (3 * ((M + 1) * (M + 2)) + M * ((M + 1) * (M + 2)) = ((M + 1) * (M + 2)) * (M + 3));
         when I =>
            pragma Assert (Rising (K - 1, I) = M * (M + 1));
            pragma Assert (2 * (M + 1) + M * (M + 1) = (M + 1) * (M + 2));
         when O =>
            pragma Assert (Rising (K - 1, O) = M);
      end case;
   end Lemma_Step;

   procedure Lemma_Closed_Form (N : Natural; From : Vowel) is
   begin
      if N > 0 and then From /= U then
         Lemma_Closed_Form (N, Vowel'Succ (From));
         Lemma_Closed_Form (N - 1, From);
         Lemma_Step (N, From);
         pragma Assert (Sorted_Count (N, From) = Sorted_Count (N, Vowel'Succ (From)) + Sorted_Count (N - 1, From));
         declare
            W  : constant Big_Integer := Weight (From);
            WS : constant Big_Integer := Weight (Vowel'Succ (From));
            X  : constant Big_Integer := Mult (From);
            S1 : constant Big_Integer := Sorted_Count (N, Vowel'Succ (From));
            S2 : constant Big_Integer := Sorted_Count (N - 1, From);
         begin
            pragma Assert (W = X * WS);
            pragma Assert (W * (S1 + S2) = W * S1 + W * S2);
            pragma Assert (W * S1 = X * (WS * S1));
            pragma Assert (W * Sorted_Count (N, From) = X * Rising (N, Vowel'Succ (From)) + Rising (N - 1, From));
         end;
      end if;
   end Lemma_Closed_Form;

   --  Each count is at most the count over all five vowels:
   --  24 * Rising (K, V) <= Weight (V) * Rising (K, A).
   procedure Lemma_Below_A (K : Natural; V : Vowel)
   with
     Ghost,
     Global => null,
     Post   => 24 * Rising (K, V) <= Weight (V) * Rising (K, A);
   procedure Lemma_Below_A (K : Natural; V : Vowel) is
      M  : constant Big_Integer := Big (K);
      P1 : constant Big_Integer := M + 1;
      P2 : constant Big_Integer := (M + 1) * (M + 2);
      P3 : constant Big_Integer := (M + 1) * (M + 2) * (M + 3);
   begin
      pragma Assert (Rising (K, A) = P3 * (M + 4));
      case V is
         when A => null;
         when E =>
            Lemma_Mul_Mono (P3, P3, Big (4), M + 4);
            pragma Assert (24 * P3 = 6 * (P3 * 4));
         when I =>
            Lemma_Mul_Mono (Big (3), M + 3, Big (4), M + 4);
            pragma Assert (P3 * (M + 4) = P2 * ((M + 3) * (M + 4)));
            Lemma_Mul_Mono (P2, P2, Big (12), (M + 3) * (M + 4));
         when O | U =>
            Lemma_Mul_Mono (Big (2), M + 2, Big (3), M + 3);
            Lemma_Mul_Mono (Big (6), (M + 2) * (M + 3), Big (4), M + 4);
            pragma Assert (P3 * (M + 4) = P1 * ((M + 2) * (M + 3) * (M + 4)));
            Lemma_Mul_Mono (P1, P1, Big (24), (M + 2) * (M + 3) * (M + 4));
            pragma Assert (P1 >= 1);
      end case;
   end Lemma_Below_A;

   --  Rising (K, A) <= Rising (Max_Length, A) = 24 * 2_130_031_575.
   procedure Lemma_Top (K : Length)
   with
     Ghost,
     Global => null,
     Post   => Rising (K, A) <= 24 * To_Big_Integer (2_130_031_575);
   procedure Lemma_Top (K : Length) is
      M : constant Big_Integer := Big (K);
   begin
      Lemma_Mul_Mono (M + 1, Big (474), M + 2, Big (475));
      Lemma_Mul_Mono ((M + 1) * (M + 2), Big (474) * Big (475), M + 3, Big (476));
      Lemma_Mul_Mono ((M + 1) * (M + 2) * (M + 3), Big (474) * Big (475) * Big (476), M + 4, Big (477));
      pragma Assert (Big (474) * Big (475) * Big (476) * Big (477) = 24 * To_Big_Integer (2_130_031_575));
   end Lemma_Top;

   function Number_Of_Strings (N : Length; From : Vowel := A) return Natural is
      type Table is array (Vowel) of Natural;
      --  D (V): sorted strings of the current length over V .. U.
      D : Table := [others => 1];
   begin
      for K in 1 .. N loop
         pragma Loop_Invariant (for all V in Vowel => Weight (V) * Big (D (V)) = Rising (K - 1, V));
         Lemma_Top (K);
         for V in reverse A .. O loop
            pragma Loop_Invariant
              (for all W in Vowel => Weight (W) * Big (D (W)) = (if W > V then Rising (K, W) else Rising (K - 1, W)));
            Lemma_Step (K, V);
            Lemma_Below_A (K, V);
            pragma Assert (Weight (V) * (Big (D (Vowel'Succ (V))) + Big (D (V))) = Rising (K, V));
            pragma Assert (Big (D (Vowel'Succ (V))) + Big (D (V)) <= To_Big_Integer (2_130_031_575));
            D (V) := D (Vowel'Succ (V)) + D (V);
         end loop;
      end loop;
      return D (From);
   end Number_Of_Strings;
end Count_Sorted_Vowel_Strings;
