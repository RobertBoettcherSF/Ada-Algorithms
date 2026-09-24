--  Knuth_Bendix_Completion body — shortlex string rewriting + completion.

pragma Ada_2022;

package body Knuth_Bendix_Completion is

   -------------------------------------------------------------------------
   -- Local helpers
   -------------------------------------------------------------------------

   function Slice (W : Word) return String is
   begin
      return W.Text (1 .. W.Len);
   end Slice;

   function Equal (A, B : Word) return Boolean is
   begin
      return A.Len = B.Len and then Slice (A) = Slice (B);
   end Equal;

   --  Concatenate with capacity check.
   function Cat (A, B : Word) return Word is
      R : Word;
   begin
      if A.Len + B.Len > Max_Word_Len then
         raise Invalid_Argument with "concatenation exceeds Max_Word_Len";
      end if;
      R.Len := A.Len + B.Len;
      if A.Len > 0 then
         R.Text (1 .. A.Len) := A.Text (1 .. A.Len);
      end if;
      if B.Len > 0 then
         R.Text (A.Len + 1 .. R.Len) := B.Text (1 .. B.Len);
      end if;
      return R;
   end Cat;

   function Cat3 (A, B, C : Word) return Word is
   begin
      return Cat (Cat (A, B), C);
   end Cat3;

   --  Substring W[From .. From+Len-1] as a Word (1-based).
   function Sub (W : Word; From : Positive; Len : Natural) return Word is
      R : Word;
   begin
      if Len = 0 then
         return R;
      end if;
      if From + Len - 1 > W.Len then
         raise Invalid_Argument with "Sub out of range";
      end if;
      R.Len := Len;
      R.Text (1 .. Len) := W.Text (From .. From + Len - 1);
      return R;
   end Sub;

   function Prefix (W : Word; Len : Natural) return Word is
   begin
      return Sub (W, 1, Len);
   end Prefix;

   function Suffix (W : Word; Len : Natural) return Word is
   begin
      if Len = 0 then
         return Word'(Len => 0, Text => [others => ' ']);
      end if;
      return Sub (W, W.Len - Len + 1, Len);
   end Suffix;

   -------------------------------------------------------------------------
   -- Constructors
   -------------------------------------------------------------------------

   function To_Word (S : String) return Word is
      W : Word;
   begin
      if S'Length > Max_Word_Len then
         raise Invalid_Argument with "word longer than Max_Word_Len";
      end if;
      W.Len := S'Length;
      if S'Length > 0 then
         W.Text (1 .. S'Length) := S;
      end if;
      return W;
   end To_Word;

   function Image (W : Word) return String is
   begin
      return Slice (W);
   end Image;

   function Make_Equation (Left, Right : String) return Equation is
   begin
      return (Left => To_Word (Left), Right => To_Word (Right));
   end Make_Equation;

   function Make_Rule (Left, Right : String) return Rule is
      L : constant Word := To_Word (Left);
      R : constant Word := To_Word (Right);
   begin
      if L.Len = 0 then
         raise Invalid_Argument with "rule LHS must be nonempty";
      end if;
      return (LHS => L, RHS => R);
   end Make_Rule;

   -------------------------------------------------------------------------
   -- Shortlex
   -------------------------------------------------------------------------

   function Shortlex_Less (A, B : Word) return Boolean is
   begin
      if A.Len < B.Len then
         return True;
      elsif A.Len > B.Len then
         return False;
      else
         --  Equal length: lexicographic on Character order.
         return Slice (A) < Slice (B);
      end if;
   end Shortlex_Less;

   function Shortlex_Less (A, B : String) return Boolean is
   begin
      return Shortlex_Less (To_Word (A), To_Word (B));
   end Shortlex_Less;

   function Orient (A, B : Word) return Rule is
   begin
      if Equal (A, B) then
         raise Invalid_Argument with "cannot orient equal words";
      elsif Shortlex_Less (A => B, B => A) then
         if A.Len = 0 then
            raise Invalid_Argument with "oriented LHS empty";
         end if;
         return (LHS => A, RHS => B);
      elsif Shortlex_Less (A, B) then
         if B.Len = 0 then
            raise Invalid_Argument with "oriented LHS empty";
         end if;
         return (LHS => B, RHS => A);
      else
         --  Unreachable if Shortlex is a total order on words.
         raise Invalid_Argument with "incomparable words";
      end if;
   end Orient;

   function Orient (A, B : String) return Rule is
   begin
      return Orient (To_Word (A), To_Word (B));
   end Orient;

   -------------------------------------------------------------------------
   -- Rewrite
   -------------------------------------------------------------------------

   --  Does Rules(K).LHS match W starting at Position?
   function Matches
     (W : Word; Position : Positive; LHS : Word) return Boolean
   with SPARK_Mode => On
   is
   begin
      if LHS.Len = 0 then
         return False;
      end if;
      if Position + LHS.Len - 1 > W.Len then
         return False;
      end if;
      return W.Text (Position .. Position + LHS.Len - 1)
        = LHS.Text (1 .. LHS.Len);
   end Matches;

   procedure Rewrite_Step
     (W       : in out Word;
      Rules   : Rule_Array;
      Changed : out Boolean)
   is
      Pos : Positive;
   begin
      Changed := False;
      if W.Len = 0 or else Rules'Length = 0 then
         return;
      end if;

      Pos := 1;
      while Pos <= W.Len loop
         for R of Rules loop
            if R.LHS.Len > 0 and then Matches (W, Pos, R.LHS) then
               declare
                  Before : constant Word := Prefix (W, Pos - 1);
                  After  : constant Word :=
                    Suffix (W, W.Len - (Pos + R.LHS.Len - 1));
                  New_W  : Word;
               begin
                  if Before.Len + R.RHS.Len + After.Len > Max_Word_Len then
                     raise Invalid_Argument
                       with "rewrite would exceed Max_Word_Len";
                  end if;
                  New_W := Cat3 (Before, R.RHS, After);
                  W := New_W;
                  Changed := True;
                  return;
               end;
            end if;
         end loop;
         Pos := Pos + 1;
      end loop;
   end Rewrite_Step;

   function Reduce (W : Word; Rules : Rule_Array) return Word is
      Cur     : Word := W;
      Changed : Boolean;
      Guard   : Natural := 0;
   begin
      loop
         Rewrite_Step (Cur, Rules, Changed);
         exit when not Changed;
         Guard := Guard + 1;
         if Guard > Max_Steps_Cap * Max_Word_Len then
            --  Safety against non-terminating rule sets (e.g. hand-built).
            raise Invalid_Argument with "reduction did not terminate";
         end if;
      end loop;
      return Cur;
   end Reduce;

   function Reduce (W : String; Rules : Rule_Array) return String is
   begin
      return Image (Reduce (To_Word (W), Rules));
   end Reduce;

   function Normal_Form (W : Word; Rules : Rule_Array) return Word is
   begin
      return Reduce (W, Rules);
   end Normal_Form;

   function Normal_Form (W : String; Rules : Rule_Array) return String is
   begin
      return Reduce (W, Rules);
   end Normal_Form;

   function Equivalent (A, B : Word; Rules : Rule_Array) return Boolean is
   begin
      return Equal (Normal_Form (A, Rules), Normal_Form (B, Rules));
   end Equivalent;

   function Equivalent (A, B : String; Rules : Rule_Array) return Boolean is
   begin
      return Equivalent (To_Word (A), To_Word (B), Rules);
   end Equivalent;

   -------------------------------------------------------------------------
   -- Critical pairs
   -------------------------------------------------------------------------

   Max_Pairs_Per_Call : constant Positive := 64;

   procedure Append_Pair
     (Store : in out Critical_Pair_Array;
      Last  : in out Natural;
      U, V  : Word)
   is
   begin
      if Equal (U, V) then
         return;
      end if;
      if Last >= Store'Last then
         return;
      end if;
      Last := Last + 1;
      Store (Last) := (U => U, V => V);
   end Append_Pair;

   --  Proper overlap: LHS_I = A·B, LHS_J = B·C with A,B,C all nonempty.
   --  Peak A·B·C  →  (RHS_I · C)  vs  (A · RHS_J).
   procedure Overlaps
     (RI, RJ : Rule;
      Store  : in out Critical_Pair_Array;
      Last   : in out Natural)
   is
      LI : constant Word := RI.LHS;
      LJ : constant Word := RJ.LHS;
   begin
      --  Overlap length O: 1 .. min(LI.Len, LJ.Len) - 0, but require proper
      --  (A and C nonempty) ⇒ O < LI.Len and O < LJ.Len, O >= 1.
      for O in 1 .. Natural'Min (LI.Len, LJ.Len) loop
         if O < LI.Len and then O < LJ.Len then
            if Suffix (LI, O).Len = O
              and then Equal (Suffix (LI, O), Prefix (LJ, O))
            then
               declare
                  A : constant Word := Prefix (LI, LI.Len - O);
                  C : constant Word := Suffix (LJ, LJ.Len - O);
                  U : constant Word := Cat (RI.RHS, C);
                  V : constant Word := Cat (A, RJ.RHS);
               begin
                  Append_Pair (Store, Last, U, V);
               end;
            end if;
         end if;
      end loop;
   end Overlaps;

   --  Inclusion: LJ occurs as a factor inside LI (strictly shorter), or vice
   --  versa. Peak = longer LHS. Two rewrites: whole rule vs inner rule.
   procedure Inclusions
     (RI, RJ : Rule;
      Store  : in out Critical_Pair_Array;
      Last   : in out Natural)
   is
      procedure One_Way (Outer, Inner : Rule) is
         L_Out : constant Word := Outer.LHS;
         L_In  : constant Word := Inner.LHS;
      begin
         if L_In.Len = 0 or else L_In.Len >= L_Out.Len then
            return;
         end if;
         for Pos in 1 .. L_Out.Len - L_In.Len + 1 loop
            if Matches (L_Out, Pos, L_In) then
               declare
                  A : constant Word := Prefix (L_Out, Pos - 1);
                  C : constant Word :=
                    Suffix (L_Out, L_Out.Len - (Pos + L_In.Len - 1));
                  --  Via outer: RHS_outer
                  --  Via inner: A · RHS_inner · C
                  U : constant Word := Outer.RHS;
                  V : constant Word := Cat3 (A, Inner.RHS, C);
               begin
                  Append_Pair (Store, Last, U, V);
               end;
            end if;
         end loop;
      end One_Way;
   begin
      One_Way (RI, RJ);
      if RI.LHS.Len /= RJ.LHS.Len
        or else not Equal (RI.LHS, RJ.LHS)
      then
         One_Way (RJ, RI);
      end if;
   end Inclusions;

   function Critical_Pairs
     (Rules : Rule_Array;
      I, J  : Positive) return Critical_Pair_Array
   is
      Buf  : Critical_Pair_Array (1 .. Max_Pairs_Per_Call);
      Last : Natural := 0;
      RI, RJ : Rule;
   begin
      if I not in Rules'Range or else J not in Rules'Range then
         raise Invalid_Argument with "rule index out of range";
      end if;
      RI := Rules (I);
      RJ := Rules (J);
      if RI.LHS.Len = 0 or else RJ.LHS.Len = 0 then
         raise Invalid_Argument with "empty LHS in critical pairs";
      end if;

      Overlaps (RI, RJ, Buf, Last);
      Inclusions (RI, RJ, Buf, Last);

      declare
         Result : Critical_Pair_Array (1 .. Last);
      begin
         for K in 1 .. Last loop
            Result (K) := Buf (K);
         end loop;
         return Result;
      end;
   end Critical_Pairs;

   -------------------------------------------------------------------------
   -- Local confluence check
   -------------------------------------------------------------------------

   function Is_Locally_Confluent (Rules : Rule_Array) return Boolean is
   begin
      if Rules'Length = 0 then
         return True;
      end if;
      for I in Rules'Range loop
         for J in I .. Rules'Last loop
            declare
               Pairs : constant Critical_Pair_Array :=
                 Critical_Pairs (Rules, I, J);
            begin
               for P of Pairs loop
                  if not Equal
                    (Normal_Form (P.U, Rules), Normal_Form (P.V, Rules))
                  then
                     return False;
                  end if;
               end loop;
            end;
         end loop;
      end loop;
      return True;
   end Is_Locally_Confluent;

   -------------------------------------------------------------------------
   -- Completion
   -------------------------------------------------------------------------

   function Rule_Equal (A, B : Rule) return Boolean is
   begin
      return Equal (A.LHS, B.LHS) and then Equal (A.RHS, B.RHS);
   end Rule_Equal;

   function Has_Same_LHS (Rules : Rule_Array; Last : Natural; R : Rule)
     return Boolean
   is
   begin
      for K in 1 .. Last loop
         if Equal (Rules (K).LHS, R.LHS) then
            return True;
         end if;
      end loop;
      return False;
   end Has_Same_LHS;

   --  Inter-reduce: replace each RHS by its NF w.r.t. other rules; drop rules
   --  whose LHS is reducible by another rule (collapse), re-orienting the
   --  residual equation when needed.
   procedure Inter_Reduce
     (Store : in out Rule_Array;
      Last  : in out Natural)
   is
      Changed : Boolean := True;
      Guard   : Natural := 0;
   begin
      while Changed and then Guard < Max_Steps_Cap loop
         Changed := False;
         Guard   := Guard + 1;

         --  Compose: reduce each RHS.
         for K in 1 .. Last loop
            declare
               Rest : Rule_Array (1 .. Last - 1);
               N      : Natural := 0;
               New_RHS : Word;
            begin
               for J in 1 .. Last loop
                  if J /= K then
                     N := N + 1;
                     Rest (N) := Store (J);
                  end if;
               end loop;
               New_RHS := Reduce (Store (K).RHS, Rest (1 .. N));
               if not Equal (New_RHS, Store (K).RHS) then
                  Store (K).RHS := New_RHS;
                  Changed := True;
               end if;
            end;
         end loop;

         --  Collapse: if LHS reducible by another rule, replace by residual.
         declare
            K : Natural := 1;
         begin
            while K <= Last loop
               declare
                  Rest : Rule_Array (1 .. Last - 1);
                  N      : Natural := 0;
                  Red    : Word;
               begin
                  for J in 1 .. Last loop
                     if J /= K then
                        N := N + 1;
                        Rest (N) := Store (J);
                     end if;
                  end loop;
                  Red := Reduce (Store (K).LHS, Rest (1 .. N));
                  if not Equal (Red, Store (K).LHS) then
                     declare
                        RHS_NF : constant Word :=
                          Reduce (Store (K).RHS, Rest (1 .. N));
                     begin
                        --  Remove rule K.
                        for J in K .. Last - 1 loop
                           Store (J) := Store (J + 1);
                        end loop;
                        Last := Last - 1;
                        Changed := True;
                        if not Equal (Red, RHS_NF) then
                           declare
                              New_R : constant Rule := Orient (Red, RHS_NF);
                              Dup   : Boolean := False;
                           begin
                              for J in 1 .. Last loop
                                 if Rule_Equal (Store (J), New_R)
                                   or else Equal (Store (J).LHS, New_R.LHS)
                                 then
                                    Dup := True;
                                    exit;
                                 end if;
                              end loop;
                              if not Dup and then Last < Store'Last then
                                 Last := Last + 1;
                                 Store (Last) := New_R;
                              end if;
                           end;
                        end if;
                        --  Do not advance K; slot now holds next rule.
                     end;
                  else
                     K := K + 1;
                  end if;
               end;
            end loop;
         end;
      end loop;
   end Inter_Reduce;

   function Complete
     (Equations : Equation_Array;
      Max_Rules : Positive := Max_Rules_Cap;
      Max_Steps : Positive := Max_Steps_Cap) return Complete_Result
   with SPARK_Mode => Off
   is
      Store : Rule_Array (1 .. Max_Rules_Cap);
      Last  : Natural := 0;
      Steps : Natural := 0;


      function Make_Success return Complete_Result is
         R : Complete_Result (Kind => Success, Count => Rule_Count (Last));
      begin
         for K in 1 .. Last loop
            R.Rules (K) := Store (K);
         end loop;
         R.Steps_Used := Steps;
         return R;
      end Make_Success;

      function Make_Fail return Complete_Result is
         R : Complete_Result
           (Kind => Did_Not_Complete, Count => Rule_Count (Last));
      begin
         for K in 1 .. Last loop
            R.Rules (K) := Store (K);
         end loop;
         R.Steps_Used := Steps;
         return R;
      end Make_Fail;

      procedure Try_Add (Raw : Rule) is
         L : Word;
         R : Word;
         Oriented : Rule;
      begin
         L := Reduce (Raw.LHS, Store (1 .. Last));
         R := Reduce (Raw.RHS, Store (1 .. Last));
         if Equal (L, R) then
            return;
         end if;
         Oriented := Orient (L, R);
         if Has_Same_LHS (Store (1 .. Last), Last, Oriented) then
            return;
         end if;
         for K in 1 .. Last loop
            if Rule_Equal (Store (K), Oriented) then
               return;
            end if;
         end loop;
         if Last >= Max_Rules then
            raise Constraint_Error;  --  signal bound to caller
         end if;
         Last := Last + 1;
         Store (Last) := Oriented;
      end Try_Add;

   begin
      if Equations'Length = 0 then
         raise Invalid_Argument with "empty equation set";
      end if;
      if Max_Rules > Max_Rules_Cap then
         raise Invalid_Argument with "Max_Rules out of range";
      end if;
      if Max_Steps > Max_Steps_Cap then
         raise Invalid_Argument with "Max_Steps out of range";
      end if;

      --  Seed rules from equations.
      for E of Equations loop
         declare
            L : constant Word := E.Left;
            R : constant Word := E.Right;
         begin
            if not Equal (L, R) then
               begin
                  Try_Add ((LHS => L, RHS => R));
               exception
                  when Constraint_Error =>
                     return Make_Fail;
               end;
            end if;
         end;
      end loop;

      if Last = 0 then
         --  All equations were trivial identities.
         return Make_Success;
      end if;

      Inter_Reduce (Store, Last);

      --  Main critical-pair loop. Re-scan all pairs each round (educational;
      --  not the most efficient worklist, but clear and correct at this scale).
      declare
         Progress : Boolean := True;
      begin
         while Progress loop
            Progress := False;
            Inter_Reduce (Store, Last);

            declare
               I : Natural := 1;
            begin
               Outer :
               while I <= Last loop
                  declare
                     J : Natural := I;
                  begin
                     while J <= Last loop
                        Steps := Steps + 1;
                        if Steps > Max_Steps then
                           return Make_Fail;
                        end if;

                        declare
                           Pairs : constant Critical_Pair_Array :=
                             Critical_Pairs (Store (1 .. Last), I, J);
                           Before : constant Natural := Last;
                        begin
                           for P of Pairs loop
                              declare
                                 U : constant Word :=
                                   Normal_Form (P.U, Store (1 .. Last));
                                 V : constant Word :=
                                   Normal_Form (P.V, Store (1 .. Last));
                              begin
                                 if not Equal (U, V) then
                                    begin
                                       Try_Add ((LHS => U, RHS => V));
                                    exception
                                       when Constraint_Error =>
                                          return Make_Fail;
                                    end;
                                    if Last > Before then
                                       Progress := True;
                                    end if;
                                 end if;
                              end;
                           end loop;
                        end;

                        --  If rules were added/collapsed, restart scan.
                        if Progress then
                           exit Outer;
                        end if;
                        J := J + 1;
                     end loop;
                  end;
                  I := I + 1;
               end loop Outer;
            end;
         end loop;
      end;

      Inter_Reduce (Store, Last);
      return Make_Success;
   end Complete;

end Knuth_Bendix_Completion;
