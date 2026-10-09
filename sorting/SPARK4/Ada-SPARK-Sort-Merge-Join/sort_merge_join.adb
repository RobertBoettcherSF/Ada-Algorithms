--  Sort_Merge_Join body — SPARK Level 4 classic inner sort-merge join
--  with many-to-many Cartesian expansion on equal-key runs, plus
--  Unique_Key_Join (strictly unique Left keys). Loop invariants keep a
--  nondecreasing Result prefix on Left.Key; OI < Max_Out is guarded
--  before each write (safe under Product_Fits / Right'Length ≤ Max_Out).

package body Sort_Merge_Join
  with SPARK_Mode => On
is

   --  Any origin: the internals count rows 1 .. X'Length, and row K of
   --  X is X (X'First + (K - 1)).

   Zero_Row : constant Row := (Key => 0, Payload => 0);

   function Sorted_Left_Keys
     (Result : Joined_Relation;
      L, R   : Natural) return Boolean
   is
     (L >= R
      or else
        (for all T in L .. R - 1 =>
           Result (Result'First + (T - 1)).Left.Key <= Result (Result'First + (T + 1 - 1)).Left.Key))
   with
     Ghost  => True,
     Global => null,
     Pre    =>
       R <= Result'Length
       and then L >= 1;

   procedure Emit
     (Result : in out Joined_Relation;
      OI     : in out Natural;
      L, R   : Row)
   with
     Global => null,
     Pre    =>
       Result'Length >= Max_Out
       and then OI < Max_Out
       and then OI <= Result'Length
       and then Sorted_Left_Keys (Result, 1, OI)
       and then (OI = 0 or else Result (Result'First + (OI - 1)).Left.Key <= L.Key),
     Post   =>
       OI = OI'Old + 1
       and then OI <= Max_Out
       and then Result (Result'First + (OI - 1)) = (Left => L, Right => R)
       and then Sorted_Left_Keys (Result, 1, OI)
       and then (for all K in Result'Range =>
                   (if K /= Result'First + (OI - 1) then Result (K) = Result'Old (K)));
   --  Append one joined pair; caller guarantees OI < Max_Out.

   procedure Emit
     (Result : in out Joined_Relation;
      OI     : in out Natural;
      L, R   : Row)
   is
   begin
      OI := OI + 1;
      Result (Result'First + (OI - 1)) := (Left => L, Right => R);
   end Emit;

   -------------------------------------------------------------------------
   -- Inner_Join — many-to-many sort-merge
   -------------------------------------------------------------------------

   procedure Inner_Join
     (Left, Right : Relation;
      Result      : out Joined_Relation;
      Last        : out Natural)
   is
      LL : constant Natural := Left'Length;
      RL : constant Natural := Right'Length;

      I, J : Natural := 1;
      OI   : Natural := 0;

      I0, I1, J0, J1 : Natural;
      II, JJ         : Natural;
   begin
      Result := [others => (Left => Zero_Row, Right => Zero_Row)];

      if LL = 0 or else RL = 0 then
         Last := 0;
         return;
      end if;

      while I <= LL and then J <= RL loop
         pragma Loop_Invariant (I in 1 .. LL + 1);
         pragma Loop_Invariant (J in 1 .. RL + 1);
         pragma Loop_Invariant (OI <= Max_Out);
         pragma Loop_Invariant (OI <= Result'Length);
         pragma Loop_Invariant (Sorted_Left_Keys (Result, 1, OI));
         pragma Loop_Invariant
           (OI = 0
            or else I > LL
            or else Result (Result'First + (OI - 1)).Left.Key <= Left (Left'First + (I - 1)).Key);
         pragma Loop_Variant (Decreases => (LL + 1 - I) + (RL + 1 - J));

         if Left (Left'First + (I - 1)).Key < Right (Right'First + (J - 1)).Key then
            I := I + 1;
         elsif Left (Left'First + (I - 1)).Key > Right (Right'First + (J - 1)).Key then
            J := J + 1;
         else
            I0 := I;
            I1 := I;
            while I1 < LL and then Left (Left'First + (I1 + 1 - 1)).Key = Left (Left'First + (I0 - 1)).Key loop
               pragma Loop_Invariant (I1 in I0 .. LL - 1);
               pragma Loop_Invariant
                 (for all T in I0 .. I1 => Left (Left'First + (T - 1)).Key = Left (Left'First + (I0 - 1)).Key);
               pragma Loop_Invariant (OI <= Max_Out);
               pragma Loop_Invariant (Sorted_Left_Keys (Result, 1, OI));
               pragma Loop_Variant (Decreases => LL - I1);
               I1 := I1 + 1;
            end loop;

            J0 := J;
            J1 := J;
            while J1 < RL and then Right (Right'First + (J1 + 1 - 1)).Key = Right (Right'First + (J0 - 1)).Key loop
               pragma Loop_Invariant (J1 in J0 .. RL - 1);
               pragma Loop_Invariant
                 (for all T in J0 .. J1 => Right (Right'First + (T - 1)).Key = Right (Right'First + (J0 - 1)).Key);
               pragma Loop_Invariant (OI <= Max_Out);
               pragma Loop_Invariant (Sorted_Left_Keys (Result, 1, OI));
               pragma Loop_Variant (Decreases => RL - J1);
               J1 := J1 + 1;
            end loop;

            pragma Assert (Left (Left'First + (I0 - 1)).Key = Right (Right'First + (J0 - 1)).Key);

            II := I0;
            Emit_Left_Run :
            while II <= I1 loop
               pragma Loop_Invariant (II in I0 .. I1 + 1);
               pragma Loop_Invariant (OI <= Max_Out);
               pragma Loop_Invariant (Sorted_Left_Keys (Result, 1, OI));
               pragma Loop_Invariant
                 (OI = 0 or else Result (Result'First + (OI - 1)).Left.Key <= Left (Left'First + (I0 - 1)).Key);
               pragma Loop_Invariant
                 (I0 <= I1 and then I1 <= LL and then J0 <= J1
                  and then J1 <= RL);
               pragma Loop_Variant (Decreases => I1 + 1 - II);

               JJ := J0;
               while JJ <= J1 loop
                  pragma Loop_Invariant (JJ in J0 .. J1 + 1);
                  pragma Loop_Invariant (II in I0 .. I1);
                  pragma Loop_Invariant (OI <= Max_Out);
                  pragma Loop_Invariant
                    (Sorted_Left_Keys (Result, 1, OI));
                  pragma Loop_Invariant
                    (OI = 0
                     or else Result (Result'First + (OI - 1)).Left.Key <= Left (Left'First + (II - 1)).Key);
                  pragma Loop_Variant (Decreases => J1 + 1 - JJ);

                  --  Product_Fits ⇒ total emits ≤ |L|·|R| ≤ Max_Out.
                  --  Guard keeps the Emit Pre dischargeable at L4.
                  if OI < Max_Out then
                     Emit (Result, OI, Left (Left'First + (II - 1)), Right (Right'First + (JJ - 1)));
                  end if;

                  JJ := JJ + 1;
               end loop;

               II := II + 1;
            end loop Emit_Left_Run;

            I := I1 + 1;
            J := J1 + 1;
         end if;
      end loop;

      Last := OI;
   end Inner_Join;

   -------------------------------------------------------------------------
   -- Unique_Key_Join — Left keys strictly unique
   -------------------------------------------------------------------------

   procedure Unique_Key_Join
     (Left, Right : Relation;
      Result      : out Joined_Relation;
      Last        : out Natural)
   is
      LL : constant Natural := Left'Length;
      RL : constant Natural := Right'Length;

      I, J       : Natural := 1;
      OI         : Natural := 0;
      J0, J1, JJ : Natural;
   begin
      Result := [others => (Left => Zero_Row, Right => Zero_Row)];

      if LL = 0 or else RL = 0 then
         Last := 0;
         return;
      end if;

      while I <= LL and then J <= RL loop
         pragma Loop_Invariant (I in 1 .. LL + 1);
         pragma Loop_Invariant (J in 1 .. RL + 1);
         pragma Loop_Invariant (OI <= Max_Out);
         pragma Loop_Invariant (OI <= Result'Length);
         pragma Loop_Invariant (Sorted_Left_Keys (Result, 1, OI));
         pragma Loop_Invariant
           (OI = 0
            or else I > LL
            or else Result (Result'First + (OI - 1)).Left.Key <= Left (Left'First + (I - 1)).Key);
         pragma Loop_Variant (Decreases => (LL + 1 - I) + (RL + 1 - J));

         if Left (Left'First + (I - 1)).Key < Right (Right'First + (J - 1)).Key then
            I := I + 1;
         elsif Left (Left'First + (I - 1)).Key > Right (Right'First + (J - 1)).Key then
            J := J + 1;
         else
            J0 := J;
            J1 := J;
            while J1 < RL and then Right (Right'First + (J1 + 1 - 1)).Key = Right (Right'First + (J0 - 1)).Key loop
               pragma Loop_Invariant (J1 in J0 .. RL - 1);
               pragma Loop_Invariant
                 (for all T in J0 .. J1 => Right (Right'First + (T - 1)).Key = Right (Right'First + (J0 - 1)).Key);
               pragma Loop_Invariant (OI <= Max_Out);
               pragma Loop_Invariant (Sorted_Left_Keys (Result, 1, OI));
               pragma Loop_Variant (Decreases => RL - J1);
               J1 := J1 + 1;
            end loop;

            JJ := J0;
            while JJ <= J1 loop
               pragma Loop_Invariant (JJ in J0 .. J1 + 1);
               pragma Loop_Invariant (OI <= Max_Out);
               pragma Loop_Invariant (Sorted_Left_Keys (Result, 1, OI));
               pragma Loop_Invariant
                 (OI = 0
                  or else Result (Result'First + (OI - 1)).Left.Key <= Left (Left'First + (I - 1)).Key);
               pragma Loop_Variant (Decreases => J1 + 1 - JJ);

               if OI < Max_Out then
                  Emit (Result, OI, Left (Left'First + (I - 1)), Right (Right'First + (JJ - 1)));
               end if;

               JJ := JJ + 1;
            end loop;

            J := J1 + 1;
            I := I + 1;
         end if;
      end loop;

      Last := OI;
   end Unique_Key_Join;

end Sort_Merge_Join;
