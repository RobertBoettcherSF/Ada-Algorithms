pragma Ada_2022;

package body Ugly_Number_II with SPARK_Mode => On is

   --  P times an entry, with P's exponent raised by one.
   function Times (E : Ugly_Value; P : Positive) return Ugly_Value
   with
     Global => null,
     Pre    => P in 2 | 3 | 5 and then E.Two + E.Three + E.Five < Max_N,
     Post   => Times'Result.Value = To_Big_Integer (P) * E.Value
               and then Times'Result.Two + Times'Result.Three + Times'Result.Five
                        = E.Two + E.Three + E.Five + 1;

   function Times (E : Ugly_Value; P : Positive) return Ugly_Value is
   begin
      case P is
         when 2 =>
            Lemma_Two (E.Two, E.Three, E.Five);
            return (Value => 2 * E.Value, Two => E.Two + 1, Three => E.Three, Five => E.Five,
                    At_2 | At_3 | At_5 => 0);
         when 3 =>
            Lemma_Three (E.Two, E.Three, E.Five);
            return (Value => 3 * E.Value, Two => E.Two, Three => E.Three + 1, Five => E.Five,
                    At_2 | At_3 | At_5 => 0);
         when others =>
            Lemma_Five (E.Two, E.Three, E.Five);
            return (Value => 5 * E.Value, Two => E.Two, Three => E.Three, Five => E.Five + 1,
                    At_2 | At_3 | At_5 => 0);
      end case;
   end Times;

   function First_Ugly (N : N_Index) return Ugly_List is
      One        : constant Ugly_Value := (Value => 1, Two | Three | Five => 0, At_2 | At_3 | At_5 => 0);
      L          : Ugly_List (1 .. N) := [others => One];
      I2, I3, I5 : Positive := 1;
      --  For J < Ip, Ap (J) is the position of p * L (J) (copied into the
      --  At_p fields at the end).
      type Position_List is array (1 .. N) of Natural;
      A2, A3, A5 : Position_List := [others => 0];
      --  The three candidates and their minimum (declared here: SPARK does
      --  not support a non-scalar object declared in the loop body before
      --  the loop invariants).
      C2, C3, C5, M : Big_Integer;
      Src           : Positive;
      P             : Positive;
   begin
      for K in 2 .. N loop
         C2 := 2 * L (I2).Value;
         C3 := 3 * L (I3).Value;
         C5 := 5 * L (I5).Value;
         pragma Assert (C2 > L (K - 1).Value and then C3 > L (K - 1).Value and then C5 > L (K - 1).Value);
         --  The entry multiplied has exponent sum at most Src - 1 <= K - 2.
         if C2 <= C3 and then C2 <= C5 then
            M := C2;
            Src := I2;
            P := 2;
         elsif C3 <= C5 then
            M := C3;
            Src := I3;
            P := 3;
         else
            M := C5;
            Src := I5;
            P := 5;
         end if;
         pragma Assert (M = To_Big_Integer (P) * L (Src).Value and then Src < K);
         pragma Assert (for all J in 1 .. K - 1 => L (J).Two + L (J).Three + L (J).Five <= J - 1);
         L (K) := Times (L (Src), P);
         pragma Assert (for all J in 1 .. K - 1 => L (J).Two + L (J).Three + L (J).Five <= J - 1);
         pragma Assert (M > L (K - 1).Value and then M <= C2 and then M <= C3 and then M <= C5);
         pragma Assert (L (K).Value = M and then L (K).Two + L (K).Three + L (K).Five <= K - 1);
         --  The entries before K are unchanged.
         pragma Assert (L (1).Value = 1 and then (for all J in 2 .. K => L (J - 1).Value < L (J).Value));
         pragma Assert (for all J in 1 .. K => L (J).Two + L (J).Three + L (J).Five <= J - 1);
         if C2 = M then
            A2 (I2) := K;
            I2 := I2 + 1;
         end if;
         if C3 = M then
            A3 (I3) := K;
            I3 := I3 + 1;
         end if;
         if C5 = M then
            A5 (I5) := K;
            I5 := I5 + 1;
         end if;
         pragma Loop_Invariant (L (1).Value = 1 and then (for all J in 2 .. K => L (J - 1).Value < L (J).Value));
         pragma Loop_Invariant (for all J in 1 .. K => L (J).Two + L (J).Three + L (J).Five <= J - 1);
         pragma Loop_Invariant (I2 <= K and then I3 <= K and then I5 <= K);
         pragma Loop_Invariant (2 * L (I2).Value > L (K).Value and then 3 * L (I3).Value > L (K).Value
                                and then 5 * L (I5).Value > L (K).Value);
         pragma Loop_Invariant (for all J in 1 .. I2 - 1 => A2 (J) in 1 .. K and then L (A2 (J)).Value = 2 * L (J).Value);
         pragma Loop_Invariant (for all J in 1 .. I3 - 1 => A3 (J) in 1 .. K and then L (A3 (J)).Value = 3 * L (J).Value);
         pragma Loop_Invariant (for all J in 1 .. I5 - 1 => A5 (J) in 1 .. K and then L (A5 (J)).Value = 5 * L (J).Value);
      end loop;
      --  Closed: below a pointer the multiple is listed (At_p); from the
      --  pointer on it is above the last entry.
      --  From each pointer on, the multiple is above the last entry: by
      --  induction along the increasing entries (ghost loops, O (N ** 2)
      --  comparisons in total with assertions enabled).
      for J in I2 .. N loop
         pragma Loop_Invariant (for all J2 in I2 .. J => 2 * L (J2).Value > L (N).Value);
      end loop;
      for J in I3 .. N loop
         pragma Loop_Invariant (for all J2 in I3 .. J => 3 * L (J2).Value > L (N).Value);
      end loop;
      for J in I5 .. N loop
         pragma Loop_Invariant (for all J2 in I5 .. J => 5 * L (J2).Value > L (N).Value);
      end loop;
      pragma Assert (for all J in I2 .. N => 2 * L (J).Value > L (N).Value);
      pragma Assert (for all J in I3 .. N => 3 * L (J).Value > L (N).Value);
      pragma Assert (for all J in I5 .. N => 5 * L (J).Value > L (N).Value);
      declare
         R : constant Ugly_List (1 .. N) :=
           [for J in 1 .. N => (L (J) with delta At_2 => A2 (J), At_3 => A3 (J), At_5 => A5 (J))];
      begin
         pragma Assert (for all J in 1 .. N => R (J).Value = L (J).Value and then R (J).At_2 = A2 (J)
                          and then R (J).At_3 = A3 (J) and then R (J).At_5 = A5 (J));
         pragma Assert (R (1).Value = 1 and then (for all J in 2 .. N => R (J - 1).Value < R (J).Value));
         pragma Assert (for all J in 1 .. N =>
                          (if 2 * R (J).Value <= R (N).Value
                           then R (J).At_2 in 1 .. N and then R (R (J).At_2).Value = 2 * R (J).Value));
         pragma Assert (for all J in 1 .. N =>
                          (if 3 * R (J).Value <= R (N).Value
                           then R (J).At_3 in 1 .. N and then R (R (J).At_3).Value = 3 * R (J).Value));
         pragma Assert (for all J in 1 .. N =>
                          (if 5 * R (J).Value <= R (N).Value
                           then R (J).At_5 in 1 .. N and then R (R (J).At_5).Value = 5 * R (J).Value));
         return R;
      end;
   end First_Ugly;

   --  The position of V in L.
   function Find (L : Ugly_List; V : Big_Integer) return Positive
   with
     Ghost,
     Global => null,
     Pre    => Has (L, V),
     Post   => Find'Result in L'Range and then L (Find'Result).Value = V;

   function Find (L : Ugly_List; V : Big_Integer) return Positive is
      K : Positive := L'First;   --  L is not empty: Has (L, V)
   begin
      --  Has (L, V) and no match in L'First .. K, so K < L'Last: the scan
      --  stops at a match inside L without a fallback return.
      while L (K).Value /= V loop
         pragma Loop_Invariant
           (K in L'Range and then (for all J in L'First .. K => L (J).Value /= V));
         pragma Loop_Variant (Increases => K);
         K := K + 1;
      end loop;
      return K;
   end Find;

   procedure Lemma_Complete (L : Ugly_List; A, B, C : Natural) is
      V : constant Big_Integer := Val3 (A, B, C);
      P : Positive;
      W : Big_Integer;
   begin
      if A = 0 and then B = 0 and then C = 0 then
         pragma Assert (L (1).Value = V);
         return;
      elsif A > 0 then
         P := 2;
         W := Val3 (A - 1, B, C);
         Lemma_Two (A - 1, B, C);
         Lemma_Complete (L, A - 1, B, C);
      elsif B > 0 then
         P := 3;
         W := Val3 (A, B - 1, C);
         Lemma_Three (A, B - 1, C);
         Lemma_Complete (L, A, B - 1, C);
      else
         P := 5;
         W := Val3 (A, B, C - 1);
         Lemma_Five (A, B, C - 1);
         Lemma_Complete (L, A, B, C - 1);
      end if;
      pragma Assert (To_Big_Integer (P) * W = V);
      declare
         J : constant Positive := Find (L, W);
      begin
         pragma Assert (To_Big_Integer (P) * L (J).Value = V);
         pragma Assert (V <= L (L'Last).Value);
         --  Closed (L) at J gives the position of P times L (J).
         if P = 2 then
            pragma Assert (2 * L (J).Value <= L (L'Last).Value);
            pragma Assert (L (J).At_2 in L'Range and then L (L (J).At_2).Value = V);
         elsif P = 3 then
            pragma Assert (3 * L (J).Value <= L (L'Last).Value);
            pragma Assert (L (J).At_3 in L'Range and then L (L (J).At_3).Value = V);
         else
            pragma Assert (5 * L (J).Value <= L (L'Last).Value);
            pragma Assert (L (J).At_5 in L'Range and then L (L (J).At_5).Value = V);
         end if;
      end;
   end Lemma_Complete;
end Ugly_Number_II;
