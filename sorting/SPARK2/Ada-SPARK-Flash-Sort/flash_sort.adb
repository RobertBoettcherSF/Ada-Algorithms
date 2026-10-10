pragma Ada_2022;

package body Flash_Sort with SPARK_Mode => On is

   subtype Class_Id is Positive range 1 .. Classes;
   type Ends is array (Class_Id) of Natural;

   --  Class of X for the input range Lo .. Hi (Lo < Hi).
   function Cls (X, Lo, Hi : Value) return Class_Id
   with Pre => Lo < Hi and then X in Lo .. Hi;

   function Cls (X, Lo, Hi : Value) return Class_Id is
      Q : constant Natural := ((Classes - 1) * (X - Lo)) / (Hi - Lo);
   begin
      pragma Assert ((Classes - 1) * (X - Lo) <= (Classes - 1) * (Hi - Lo));
      pragma Assert (Q <= Classes - 1);
      return 1 + Q;
   end Cls;

   ---------------------------------------------------------------------------
   --  Permutation lemmas (ghost, proved)
   ---------------------------------------------------------------------------

   procedure Lemma_Occ_Frame (A, B : Input_Array; Last : Natural)
   with Ghost, Global => null,
        Pre                => Last <= Index'Last and then (for all K in 1 .. Last => A (K) = B (K)),
        Post               => (for all V in Value => Occ (A, V, Last) = Occ (B, V, Last)),
        Subprogram_Variant => (Decreases => Last);

   procedure Lemma_Occ_Frame (A, B : Input_Array; Last : Natural) is
   begin
      if Last > 0 then
         Lemma_Occ_Frame (A, B, Last - 1);
      end if;
   end Lemma_Occ_Frame;

   procedure Lemma_Occ_Set (A, B : Input_Array; K : Index; Last : Natural)
   with Ghost, Global => null,
        Pre                => Last in K .. Index'Last
                              and then (for all J in Index => (if J /= K then A (J) = B (J))),
        Post               => (for all V in Value =>
                                 Occ (B, V, Last) = Occ (A, V, Last) - (if A (K) = V then 1 else 0)
                                                    + (if B (K) = V then 1 else 0)),
        Subprogram_Variant => (Decreases => Last);

   procedure Lemma_Occ_Set (A, B : Input_Array; K : Index; Last : Natural) is
   begin
      if Last > K then
         Lemma_Occ_Set (A, B, K, Last - 1);
      else
         Lemma_Occ_Frame (A, B, K - 1);
      end if;
   end Lemma_Occ_Set;

   procedure Lemma_Swap (A, B : Input_Array; X, Y : Index)
   with Ghost, Global => null,
        Pre  => B (X) = A (Y) and then B (Y) = A (X)
                and then (for all J in Index => (if J /= X and then J /= Y then A (J) = B (J))),
        Post => Is_Perm (A, B);

   procedure Lemma_Swap (A, B : Input_Array; X, Y : Index) is
      C : constant Input_Array := [A with delta X => A (Y)];
   begin
      if X = Y then
         Lemma_Occ_Frame (A, B, Index'Last);
      else
         Lemma_Occ_Set (A, C, X, Index'Last);
         Lemma_Occ_Set (C, B, Y, Index'Last);
      end if;
   end Lemma_Swap;

   procedure Swap (A : in out Input_Array; X, Y : Index)
   with Global => null,
        Post   => A (X) = A'Old (Y) and then A (Y) = A'Old (X)
                  and then (for all J in Index => (if J /= X and then J /= Y then A (J) = A'Old (J)))
                  and then Is_Perm (A'Old, A);

   procedure Swap (A : in out Input_Array; X, Y : Index) is
      Before : constant Input_Array := A with Ghost;
      T      : constant Value := A (X);
   begin
      A (X) := A (Y);
      A (Y) := T;
      Lemma_Swap (Before, A, X, Y);
   end Swap;

   ---------------------------------------------------------------------------
   --  Class regions (ghost): region C is Start (C) .. E (C); its slots
   --  Start (C) .. L (C) are not placed yet, L (C) + 1 .. E (C) are.
   ---------------------------------------------------------------------------

   function In_Range (A : Input_Array; Lo, Hi : Value) return Boolean is
     (for all P in Index => A (P) in Lo .. Hi) with Ghost;

   function Regions_Ok (E : Ends) return Boolean is
     (E (1) <= E (2) and then E (2) <= E (3) and then E (3) = Index'Last) with Ghost;

   function Start (E : Ends; C : Class_Id) return Positive is
     (if C = 1 then 1 else E (C - 1) + 1)
   with Ghost, Pre => Regions_Ok (E);

   function Ends_Ok (E, L : Ends) return Boolean is
     (Regions_Ok (E) and then (for all C in Class_Id => L (C) in Start (E, C) - 1 .. E (C)))
   with Ghost;

   function Unplaced (P : Index; E, L : Ends) return Boolean is
     (for some C in Class_Id => P in Start (E, C) .. L (C))
   with Ghost, Pre => Ends_Ok (E, L);

   --  Unplaced slots among 1 .. P whose key has class C.
   function UC (A : Input_Array; Lo, Hi : Value; E, L : Ends; C : Class_Id; P : Natural) return Natural is
     (if P = 0 then 0
      else UC (A, Lo, Hi, E, L, C, P - 1)
           + (if Unplaced (P, E, L) and then Cls (A (P), Lo, Hi) = C then 1 else 0))
   with Ghost,
        Pre                => Lo < Hi and then In_Range (A, Lo, Hi) and then Ends_Ok (E, L) and then P <= Index'Last,
        Post               => UC'Result <= P,
        Subprogram_Variant => (Decreases => P);

   --  Keys of class C among A (1 .. P).
   function CC (A : Input_Array; Lo, Hi : Value; C : Class_Id; P : Natural) return Natural is
     (if P = 0 then 0
      else CC (A, Lo, Hi, C, P - 1) + (if Cls (A (P), Lo, Hi) = C then 1 else 0))
   with Ghost,
        Pre                => Lo < Hi and then In_Range (A, Lo, Hi) and then P <= Index'Last,
        Post               => CC'Result <= P,
        Subprogram_Variant => (Decreases => P);

   procedure Lemma_CC_Sum (A : Input_Array; Lo, Hi : Value; P : Natural)
   with Ghost, Global => null,
        Pre                => Lo < Hi and then In_Range (A, Lo, Hi) and then P <= Index'Last,
        Post               => CC (A, Lo, Hi, 1, P) + CC (A, Lo, Hi, 2, P) + CC (A, Lo, Hi, 3, P) = P,
        Subprogram_Variant => (Decreases => P);

   procedure Lemma_CC_Sum (A : Input_Array; Lo, Hi : Value; P : Natural) is
   begin
      if P > 0 then
         Lemma_CC_Sum (A, Lo, Hi, P - 1);
      end if;
   end Lemma_CC_Sum;

   --  With nothing placed, UC counts the whole class.
   procedure Lemma_UC_All (A : Input_Array; Lo, Hi : Value; E : Ends; P : Natural)
   with Ghost, Global => null,
        Pre                => Lo < Hi and then In_Range (A, Lo, Hi) and then Ends_Ok (E, E) and then P <= Index'Last,
        Post               => (for all C in Class_Id => UC (A, Lo, Hi, E, E, C, P) = CC (A, Lo, Hi, C, P)),
        Subprogram_Variant => (Decreases => P);

   procedure Lemma_UC_All (A : Input_Array; Lo, Hi : Value; E : Ends; P : Natural) is
   begin
      if P > 0 then
         Lemma_UC_All (A, Lo, Hi, E, P - 1);
         pragma Assert (Unplaced (P, E, E));
      end if;
   end Lemma_UC_All;

   --  An unplaced slot Q <= P of class C makes UC (C) >= 1.
   procedure Lemma_UC_Pos (A : Input_Array; Lo, Hi : Value; E, L : Ends; Q : Index; P : Natural)
   with Ghost, Global => null,
        Pre                => Lo < Hi and then In_Range (A, Lo, Hi) and then Ends_Ok (E, L) and then P <= Index'Last
                              and then Q <= P and then Unplaced (Q, E, L),
        Post               => UC (A, Lo, Hi, E, L, Cls (A (Q), Lo, Hi), P) >= 1,
        Subprogram_Variant => (Decreases => P);

   procedure Lemma_UC_Pos (A : Input_Array; Lo, Hi : Value; E, L : Ends; Q : Index; P : Natural) is
   begin
      if Q < P then
         Lemma_UC_Pos (A, Lo, Hi, E, L, Q, P - 1);
      end if;
   end Lemma_UC_Pos;

   --  Shrinking L only removes slots from the unplaced set.
   procedure Lemma_Shrink (E, L, L2 : Ends)
   with Ghost, Global => null,
        Pre  => Ends_Ok (E, L) and then Ends_Ok (E, L2) and then (for all D in Class_Id => L2 (D) <= L (D)),
        Post => (for all P in Index => (if Unplaced (P, E, L2) then Unplaced (P, E, L)));

   procedure Lemma_Shrink (E, L, L2 : Ends) is null;

   --  Lowering L (C) by one keeps every other slot's state.
   procedure Lemma_Keep (E, L, L2 : Ends; C : Class_Id; P : Index)
   with Ghost, Global => null,
        Pre  => Ends_Ok (E, L) and then Ends_Ok (E, L2) and then L2 (C) = L (C) - 1
                and then (for all D in Class_Id => (if D /= C then L2 (D) = L (D)))
                and then P /= L (C),
        Post => Unplaced (P, E, L2) = Unplaced (P, E, L);

   procedure Lemma_Keep (E, L, L2 : Ends; C : Class_Id; P : Index) is
   begin
      for D in Class_Id loop
         pragma Loop_Invariant (True);
         pragma Assert ((P in Start (E, D) .. L2 (D)) = (P in Start (E, D) .. L (D)));
      end loop;
   end Lemma_Keep;

   --  A slot that is not unplaced lies in the placed part of a region.
   procedure Lemma_Cover (E, L : Ends; P : Index)
   with Ghost, Global => null,
        Pre  => Ends_Ok (E, L),
        Post => (if not Unplaced (P, E, L) then (for some D in Class_Id => P in L (D) + 1 .. E (D)));

   procedure Lemma_Cover (E, L : Ends; P : Index) is
   begin
      if Unplaced (P, E, L) then
         return;
      end if;
      if P <= E (1) then
         pragma Assert (P in L (1) + 1 .. E (1));
      elsif P <= E (2) then
         pragma Assert (P in Start (E, 2) .. E (2));
         pragma Assert (P in L (2) + 1 .. E (2));
      else
         pragma Assert (P in Start (E, 3) .. E (3));
         pragma Assert (P in L (3) + 1 .. E (3));
      end if;
   end Lemma_Cover;

   --  An unplaced slot is in no placed part.
   procedure Lemma_Not_Placed (E, L : Ends; P : Index)
   with Ghost, Global => null,
        Pre  => Ends_Ok (E, L) and then Unplaced (P, E, L),
        Post => (for all D in Class_Id => P not in L (D) + 1 .. E (D));

   procedure Lemma_Not_Placed (E, L : Ends; P : Index) is
   begin
      if P <= E (1) then
         pragma Assert (P in Start (E, 1) .. L (1));
      elsif P <= E (2) then
         pragma Assert (P in Start (E, 2) .. L (2));
      else
         pragma Assert (P in Start (E, 3) .. L (3));
      end if;
   end Lemma_Not_Placed;

   --  One drop: B is A with slots J and T exchanged, T = L (C) for the
   --  class C of A (J), and L2 is L with L2 (C) = T - 1.
   procedure Lemma_UC_Step
     (A, B : Input_Array; Lo, Hi : Value; E, L, L2 : Ends; J, T : Index; C : Class_Id; P : Natural)
   with Ghost, Global => null,
        Pre                => Lo < Hi and then In_Range (A, Lo, Hi) and then In_Range (B, Lo, Hi)
                              and then Ends_Ok (E, L) and then P <= Index'Last
                              and then C = Cls (A (J), Lo, Hi) and then T = L (C) and then T >= Start (E, C)
                              and then Unplaced (J, E, L)
                              and then B (J) = A (T) and then B (T) = A (J)
                              and then (for all K in Index => (if K /= J and then K /= T then B (K) = A (K)))
                              and then L2 (C) = T - 1
                              and then (for all D in Class_Id => (if D /= C then L2 (D) = L (D)))
                              and then Ends_Ok (E, L2),
        Post               => (for all D in Class_Id =>
                                 UC (B, Lo, Hi, E, L2, D, P)
                                 = UC (A, Lo, Hi, E, L, D, P)
                                   + (if J <= P then (if Cls (A (T), Lo, Hi) = D then 1 else 0)
                                                     - (if Cls (A (J), Lo, Hi) = D then 1 else 0)
                                      else 0)
                                   - (if T <= P and then Cls (A (T), Lo, Hi) = D then 1 else 0)),
        Subprogram_Variant => (Decreases => P);

   procedure Lemma_UC_Step
     (A, B : Input_Array; Lo, Hi : Value; E, L, L2 : Ends; J, T : Index; C : Class_Id; P : Natural) is
   begin
      if P > 0 then
         Lemma_UC_Step (A, B, Lo, Hi, E, L, L2, J, T, C, P - 1);
         Lemma_Shrink (E, L, L2);
         pragma Assert (Unplaced (T, E, L));
         pragma Assert (not Unplaced (T, E, L2));
         if P = T then
            pragma Assert (for all D in Class_Id =>
                             UC (B, Lo, Hi, E, L2, D, P) = UC (B, Lo, Hi, E, L2, D, P - 1));
            pragma Assert (for all D in Class_Id =>
                             UC (A, Lo, Hi, E, L, D, P) = UC (A, Lo, Hi, E, L, D, P - 1)
                             + (if Cls (A (T), Lo, Hi) = D then 1 else 0));
         elsif P = J then
            Lemma_Keep (E, L, L2, C, J);
            pragma Assert (Unplaced (P, E, L2));
            pragma Assert (B (P) = A (T));
            pragma Assert (for all D in Class_Id =>
                             UC (B, Lo, Hi, E, L2, D, P) = UC (B, Lo, Hi, E, L2, D, P - 1)
                             + (if Cls (A (T), Lo, Hi) = D then 1 else 0));
            pragma Assert (for all D in Class_Id =>
                             UC (A, Lo, Hi, E, L, D, P) = UC (A, Lo, Hi, E, L, D, P - 1)
                             + (if Cls (A (J), Lo, Hi) = D then 1 else 0));
         else
            Lemma_Keep (E, L, L2, C, P);
            pragma Assert (Unplaced (P, E, L2) = Unplaced (P, E, L));
            pragma Assert (B (P) = A (P));
         end if;
      end if;
   end Lemma_UC_Step;

   --  A slot J past L (class of its key), with every slot below placed,
   --  is placed itself.
   procedure Lemma_Placed (A : Input_Array; Lo, Hi : Value; E, L : Ends; J : Index)
   with Ghost, Global => null,
        Pre  => Lo < Hi and then In_Range (A, Lo, Hi) and then Ends_Ok (E, L)
                and then (for all D in Class_Id => UC (A, Lo, Hi, E, L, D, Index'Last) = L (D) - Start (E, D) + 1)
                and then (for all P in 1 .. J - 1 => not Unplaced (P, E, L))
                and then J > L (Cls (A (J), Lo, Hi)),
        Post => not Unplaced (J, E, L);

   procedure Lemma_Placed (A : Input_Array; Lo, Hi : Value; E, L : Ends; J : Index) is null;

   ---------------------------------------------------------------------------

   procedure Sort_Traced
     (Input : Input_Array; Output : out Input_Array; Moves : out Move_Log; Count : out Natural)
   is
      A     : Input_Array := Input;
      Lo    : Value := A (1);
      Nmax  : Index := 1;
      L     : Ends := [others => 0];
      Nmove : Natural := 0;
      J, T  : Index;
      C     : Class_Id;
      Hi    : Value;
   begin
      Moves := [others => 1];
      Count := 0;
      for I in Index loop
         if A (I) < Lo then
            Lo := A (I);
         end if;
         if A (I) > A (Nmax) then
            Nmax := I;
         end if;
         pragma Loop_Invariant (for all P in 1 .. I => A (P) in Lo .. A (Nmax));
         pragma Loop_Invariant (Lo in A (1) | A (Nmax) or else (for some P in 1 .. I => A (P) = Lo));
      end loop;
      Hi := A (Nmax);
      if Lo = Hi then
         --  All keys equal: nothing to do.
         Output := A;
         return;
      end if;
      --  The maximum to slot 1 (Neubert does it after counting; the
      --  counts do not depend on the order).
      Swap (A, Nmax, 1);
      pragma Assert (In_Range (A, Lo, Hi));
      --  Class counts and prefix sums.
      for I in Index loop
         L (Cls (A (I), Lo, Hi)) := L (Cls (A (I), Lo, Hi)) + 1;
         pragma Loop_Invariant (for all D in Class_Id => L (D) = CC (A, Lo, Hi, D, I));
      end loop;
      Lemma_CC_Sum (A, Lo, Hi, Index'Last);
      L (2) := L (2) + L (1);
      L (3) := L (3) + L (2);
      declare
         E    : constant Ends := L with Ghost;
         Prev : Input_Array with Ghost;
         L0   : Ends with Ghost;
         U    : Index with Ghost;
      begin
         pragma Assert (Ends_Ok (E, L));
         Lemma_UC_All (A, Lo, Hi, E, Index'Last);
         pragma Assert (for all D in Class_Id => UC (A, Lo, Hi, E, L, D, Index'Last) = L (D) - Start (E, D) + 1);
         J := 1;
         while Nmove < Index'Last - 1 loop
            pragma Loop_Invariant (In_Range (A, Lo, Hi) and then Is_Perm (Input, A));
            pragma Loop_Invariant (Ends_Ok (E, L));
            pragma Loop_Invariant (Count = Nmove);
            pragma Loop_Invariant
              (Nmove + (L (1) - Start (E, 1) + 1) + (L (2) - Start (E, 2) + 1) + (L (3) - Start (E, 3) + 1) = Index'Last);
            pragma Loop_Invariant
              (for all D in Class_Id => UC (A, Lo, Hi, E, L, D, Index'Last) = L (D) - Start (E, D) + 1);
            pragma Loop_Invariant (for all P in 1 .. J - 1 => not Unplaced (P, E, L));
            pragma Loop_Invariant
              (for all D in Class_Id => (for all P in L (D) + 1 .. E (D) => Cls (A (P), Lo, Hi) = D));
            pragma Loop_Variant (Increases => Nmove);
            --  Some slot is still unplaced (at least two are).
            U := (if L (1) >= Start (E, 1) then L (1) elsif L (2) >= Start (E, 2) then L (2) else L (3));
            pragma Assert (Unplaced (U, E, L) and then J <= U);
            --  Skip placed slots: J is placed exactly when J > L (class of A (J)).
            while J > L (Cls (A (J), Lo, Hi)) loop
               pragma Loop_Invariant (J <= U);
               pragma Loop_Invariant (for all P in 1 .. J - 1 => not Unplaced (P, E, L));
               pragma Loop_Variant (Increases => J);
               Lemma_Placed (A, Lo, Hi, E, L, J);
               pragma Assert (not Unplaced (J, E, L));
               J := J + 1;
            end loop;
            Lemma_Cover (E, L, J);
            pragma Assert (J <= L (Cls (A (J), Lo, Hi)));
            pragma Assert (for all D in Class_Id => (if J in L (D) + 1 .. E (D) then Cls (A (J), Lo, Hi) = D));
            pragma Assert (Unplaced (J, E, L));
            --  Cycle from leader slot J: drop the key at J on L (class).
            loop
               C := Cls (A (J), Lo, Hi);
               Lemma_UC_Pos (A, Lo, Hi, E, L, J, Index'Last);
               T := L (C);
               Prev := A;
               L0 := L;
               Lemma_Not_Placed (E, L0, J);
               Swap (A, J, T);
               L (C) := T - 1;
               Lemma_UC_Step (Prev, A, Lo, Hi, E, L0, L, J, T, C, Index'Last);
               Lemma_Shrink (E, L0, L);
               pragma Assert (Cls (A (T), Lo, Hi) = C);
               pragma Assert (for all D in Class_Id =>
                                (for all P in L (D) + 1 .. E (D) =>
                                   P = T or else (P in L0 (D) + 1 .. E (D) and then P /= J)));
               pragma Assert (for all D in Class_Id =>
                                (for all P in L (D) + 1 .. E (D) => Cls (A (P), Lo, Hi) = D));
               if T /= J then
                  Lemma_Keep (E, L0, L, C, J);
               end if;
               Nmove := Nmove + 1;
               Count := Count + 1;
               Moves (Count) := T;
               pragma Loop_Invariant (In_Range (A, Lo, Hi) and then Is_Perm (Input, A));
               pragma Loop_Invariant (Ends_Ok (E, L));
               pragma Loop_Invariant (Count = Nmove and then Nmove > Nmove'Loop_Entry);
               pragma Loop_Invariant
                 (Nmove + (L (1) - Start (E, 1) + 1) + (L (2) - Start (E, 2) + 1) + (L (3) - Start (E, 3) + 1) = Index'Last);
               pragma Loop_Invariant
                 (for all D in Class_Id => UC (A, Lo, Hi, E, L, D, Index'Last) = L (D) - Start (E, D) + 1);
               pragma Loop_Invariant (for all P in 1 .. J - 1 => not Unplaced (P, E, L));
               pragma Loop_Invariant
                 (for all D in Class_Id => (for all P in L (D) + 1 .. E (D) => Cls (A (P), Lo, Hi) = D));
               pragma Loop_Invariant (T = J or else Unplaced (J, E, L));
               pragma Loop_Variant (Increases => Nmove);
               exit when T = J;
            end loop;
         end loop;
      end;
      --  Straight insertion from the top (Neubert's final pass), by
      --  adjacent exchanges.
      for I in reverse 1 .. Index'Last - 1 loop
         pragma Loop_Invariant (Is_Perm (Input, A));
         pragma Loop_Invariant (for all K in I + 1 .. Index'Last - 1 => A (K) <= A (K + 1));
         J := I;
         while J < Index'Last and then A (J + 1) < A (J) loop
            pragma Loop_Invariant (J in I .. Index'Last - 1);
            pragma Loop_Invariant (Is_Perm (Input, A));
            pragma Loop_Invariant (for all K in I .. J - 1 => A (K) <= A (K + 1));
            pragma Loop_Invariant (for all K in J + 1 .. Index'Last - 1 => A (K) <= A (K + 1));
            pragma Loop_Invariant (for all K in I .. J - 1 => A (K) < A (J));
            pragma Loop_Invariant (if J > I then A (J - 1) <= A (J + 1));
            pragma Loop_Variant (Increases => J);
            Swap (A, J, J + 1);
            J := J + 1;
         end loop;
         pragma Assert (for all K in J + 1 .. Index'Last - 1 => A (K) <= A (K + 1));
         pragma Assert (for all K in I .. J - 1 => A (K) <= A (K + 1));
         pragma Assert (J = Index'Last or else A (J) <= A (J + 1));
         pragma Assert (for all K in I .. Index'Last - 1 => A (K) <= A (K + 1));
      end loop;
      Output := A;
   end Sort_Traced;

   function Sort (Input : Input_Array) return Input_Array is
      Output : Input_Array;
      Moves  : Move_Log (1 .. Index'Last);
      Count  : Natural;
   begin
      Sort_Traced (Input, Output, Moves, Count);
      pragma Assert (Count <= Index'Last and then Moves (1) in Index);
      return Output;
   end Sort;
end Flash_Sort;
