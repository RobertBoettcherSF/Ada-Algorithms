pragma SPARK_Mode (On);

package body Letter_Combinations_Of_A_Phone_Number is
   --  Rank (Number, R, I) reads only R (I .. Number'Last).
   procedure Lemma_Rank_Frame (Number : Digit_String; R1, R2 : String; I : Positive)
   with
     Ghost,
     Global             => null,
     Pre                => I <= Number'Last + 1
                           and then Spells_From (Number, R1, I)
                           and then Spells_From (Number, R2, I)
                           and then (for all P in I .. Number'Last => R1 (P) = R2 (P)),
     Post               => Rank (Number, R1, I) = Rank (Number, R2, I),
     Subprogram_Variant => (Increases => I);

   procedure Lemma_Rank_Frame (Number : Digit_String; R1, R2 : String; I : Positive) is
   begin
      if I <= Number'Last then
         Lemma_Rank_Frame (Number, R1, R2, I + 1);
      end if;
   end Lemma_Rank_Frame;

   --  A product of numbers up to 2 ** 31 and 2 ** 30 fits Long_Long_Integer.
   procedure Lemma_Mul_Bound (A, B : Long_Long_Integer)
   with
     Ghost,
     Global => null,
     Pre    => A in 0 .. 2 ** 31 and then B in 0 .. 2 ** 30,
     Post   => A * B in 0 .. 2 ** 61;

   procedure Lemma_Mul_Bound (A, B : Long_Long_Integer) is null;

   --  One step of Rank: letter J at position I, then the rest.
   procedure Lemma_Rank_Step (Number : Digit_String; R : String; I : Positive; J : Natural)
   with
     Ghost,
     Global => null,
     Pre    => I <= Number'Last
               and then Spells_From (Number, R, I)
               and then Character'Pos (R (I)) - Character'Pos (First_Letter (Number (I))) = J,
     Post   => Rank (Number, R, I) = Long_Long_Integer (J) * Suffix_Count (Number, I + 1) + Rank (Number, R, I + 1);

   procedure Lemma_Rank_Step (Number : Digit_String; R : String; I : Positive; J : Natural) is null;

   --  Q0 = Q * L + J gives Q0 * S1 = Q * S0 + J * S1 when S0 = L * S1.
   procedure Lemma_Decode (Q0, Q, J : Natural; L : Letter_Count; S1, S0 : Long_Long_Integer)
   with
     Ghost,
     Global => null,
     Pre    => Long_Long_Integer (Q0) = Long_Long_Integer (Q) * Long_Long_Integer (L) + Long_Long_Integer (J)
               and then J < L
               and then S1 in 1 .. 2 ** 30 and then S0 in 1 .. 2 ** 30
               and then S0 = Long_Long_Integer (L) * S1,
     Post   => Long_Long_Integer (Q0) * S1 = Long_Long_Integer (Q) * S0 + Long_Long_Integer (J) * S1;

   procedure Lemma_Decode (Q0, Q, J : Natural; L : Letter_Count; S1, S0 : Long_Long_Integer) is
   begin
      pragma Assert (Long_Long_Integer (Q) * Long_Long_Integer (L) <= Long_Long_Integer (Q0));
      pragma Assert (Long_Long_Integer (Q) * S0 = Long_Long_Integer (Q) * Long_Long_Integer (L) * S1);
      pragma Assert
        (Long_Long_Integer (Q0) * S1
         = Long_Long_Integer (Q) * Long_Long_Integer (L) * S1 + Long_Long_Integer (J) * S1);
   end Lemma_Decode;

   function Count (Number : Digit_String) return Positive is
      C : Positive := 1;
   begin
      for I in reverse Number'Range loop
         pragma Loop_Invariant (Long_Long_Integer (C) = Suffix_Count (Number, I + 1));
         C := C * Letters (Number (I));
      end loop;
      return C;
   end Count;

   function Combination (Number : Digit_String; K : Natural) return String is
      R : String (1 .. Number'Last) := [others => 'a'];
      Q : Natural := K;     --  the part of K not yet decoded
      J : Natural;
      L : Letter_Count;
   begin
      for I in reverse Number'Range loop
         Lemma_Mul_Bound (Long_Long_Integer (Q), Suffix_Count (Number, I + 1));
         pragma Loop_Invariant (Spells_From (Number, R, I + 1));
         pragma Loop_Invariant
           (Long_Long_Integer (K)
            = Long_Long_Integer (Q) * Suffix_Count (Number, I + 1) + Rank (Number, R, I + 1));
         L := Letters (Number (I));
         J := Q mod L;
         declare
            Old_R : constant String (1 .. Number'Last) := R with Ghost;
            Old_Q : constant Natural := Q with Ghost;
            SC1   : constant Long_Long_Integer := Suffix_Count (Number, I + 1) with Ghost;
            SC0   : constant Long_Long_Integer := Suffix_Count (Number, I) with Ghost;
         begin
            R (I) := Letter (Number (I), J);
            Q := Q / L;
            Lemma_Rank_Frame (Number, R, Old_R, I + 1);
            pragma Assert (Character'Pos (R (I)) - Character'Pos (First_Letter (Number (I))) = J);
            pragma Assert (Spells_From (Number, R, I));
            Lemma_Rank_Step (Number, R, I, J);
            pragma Assert (SC1 = Suffix_Count (Number, I + 1));
            Lemma_Mul_Bound (Long_Long_Integer (J), SC1);
            Lemma_Mul_Bound (Long_Long_Integer (Old_Q), SC1);
            pragma Assert (Rank (Number, R, I) = Long_Long_Integer (J) * SC1 + Rank (Number, R, I + 1));
            pragma Assert (SC0 = Long_Long_Integer (L) * SC1);
            pragma Assert
              (Long_Long_Integer (Old_Q) = Long_Long_Integer (Q) * Long_Long_Integer (L) + Long_Long_Integer (J));
            Lemma_Decode (Old_Q, Q, J, L, SC1, SC0);
            pragma Assert (Long_Long_Integer (K) = Long_Long_Integer (Old_Q) * SC1 + Rank (Number, Old_R, I + 1));
            pragma Assert (Rank (Number, R, I + 1) = Rank (Number, Old_R, I + 1));
            pragma Assert (Rank (Number, R, I) = Long_Long_Integer (J) * SC1 + Rank (Number, Old_R, I + 1));
            pragma Assert (Long_Long_Integer (K) = Long_Long_Integer (Q) * SC0 + Rank (Number, R, I));
         end;
      end loop;
      pragma Assert (Long_Long_Integer (Q) * Suffix_Count (Number, 1) <= Long_Long_Integer (K));
      pragma Assert (Q = 0);
      return R;
   end Combination;
end Letter_Combinations_Of_A_Phone_Number;
