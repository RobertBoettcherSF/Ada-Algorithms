--  Todd_Coxeter body — educational HLT-style coset enumeration.
--  Generators are lowercase; inverses are matching uppercase. The coset
--  table stores right actions; coincidences are merged with a queue and
--  a representative map (union-find style).

pragma Ada_2022;

package body Todd_Coxeter
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Character helpers
   ------------------------------------------------------------------

   function Is_Letter (C : Character) return Boolean is
     ((C in 'a' .. 'z') or else (C in 'A' .. 'Z'));

   function Is_Lower (C : Character) return Boolean is (C in 'a' .. 'z');

   function To_Lower (C : Character) return Character is
   begin
      if C in 'A' .. 'Z' then
         return Character'Val
           (Character'Pos (C) - Character'Pos ('A') + Character'Pos ('a'));
      end if;
      return C;
   end To_Lower;

   ------------------------------------------------------------------
   --  Make_Word / Make_Presentation
   ------------------------------------------------------------------

   function Make_Word (S : String) return Word is
      W : Word;
   begin
      if S'Length > Max_Word_Length then
         raise Invalid_Argument;
      end if;
      for C of S loop
         if not Is_Letter (C) then
            raise Invalid_Argument;
         end if;
      end loop;
      W.Length := S'Length;
      if S'Length > 0 then
         W.Letters (1 .. S'Length) := S;
      end if;
      return W;
   end Make_Word;

   function Make_Presentation
     (Gens     : String;
      Relators : Word_List) return Presentation
   is
      P : Presentation;
   begin
      if Gens'Length = 0 or else Gens'Length > Max_Generators then
         raise Invalid_Argument;
      end if;
      if Relators'Length > Max_Relators then
         raise Invalid_Argument;
      end if;

      for I in Gens'Range loop
         declare
            C : constant Character := Gens (I);
         begin
            if not Is_Lower (C) then
               raise Invalid_Argument;
            end if;
            for J in Gens'First .. I - 1 loop
               if Gens (J) = C then
                  raise Invalid_Argument;
               end if;
            end loop;
         end;
      end loop;

      P.Gen_Count := Gens'Length;
      P.Generators (1 .. Gens'Length) := Gens;
      P.Rel_Count := Relators'Length;
      for K in Relators'Range loop
         declare
            Off : constant Natural := K - Relators'First + 1;
         begin
            if not Word_Is_Valid (P, Relators (K)) then
               raise Invalid_Argument;
            end if;
            P.Relators (Off) := Relators (K);
         end;
      end loop;
      return P;
   end Make_Presentation;

   function Column_Of
     (Pres : Presentation;
      Gen  : Character) return Natural
   is
      Low : constant Character := To_Lower (Gen);
   begin
      for I in 1 .. Pres.Gen_Count loop
         if Pres.Generators (I) = Low then
            if Is_Lower (Gen) then
               return I;                         -- generator column
            else
               return Pres.Gen_Count + I;        -- inverse column
            end if;
         end if;
      end loop;
      return 0;
   end Column_Of;

   function Word_Is_Valid (Pres : Presentation; W : Word) return Boolean is
   begin
      if W.Length > Max_Word_Length then
         return False;
      end if;
      for I in 1 .. W.Length loop
         if Column_Of (Pres, W.Letters (I)) = 0 then
            return False;
         end if;
      end loop;
      return True;
   end Word_Is_Valid;

   function Action
     (R     : Result;
      Coset : Positive;
      Col   : Positive) return Coset_Id
   is
   begin
      if not R.Success
        or else Coset > R.Index
        or else Col > R.Columns
      then
         return 0;
      end if;
      return R.Table (Coset, Col);
   end Action;

   function Trace
     (R     : Result;
      Pres  : Presentation;
      Start : Positive;
      W     : Word) return Coset_Id
   is
      C : Coset_Id := Coset_Id (Start);
   begin
      if not R.Success or else Start > R.Index then
         return 0;
      end if;
      for I in 1 .. W.Length loop
         declare
            Col : constant Natural := Column_Of (Pres, W.Letters (I));
         begin
            if Col = 0 or else Col > R.Columns then
               return 0;
            end if;
            C := R.Table (C, Col);
            if C = 0 then
               return 0;
            end if;
         end;
      end loop;
      return C;
   end Trace;

   ------------------------------------------------------------------
   --  Enumeration engine (package-local)
   ------------------------------------------------------------------

   function Enumerate
     (Pres     : Presentation;
      Subgroup : Word_List;
      Limit    : Positive := Default_Max_Cosets) return Result
   is
      --  Working table over defined cosets 1 .. Defined. Live cosets are
      --  those with Rep (C) = C. Columns: 1 .. Gen_Count generators,
      --  Gen_Count+1 .. 2*Gen_Count inverses.
      Defined : Natural := 0;
      Live    : Natural := 0;
      Columns : Natural;
      Failed  : Boolean := False;

      Table : Coset_Table := [others => [others => 0]];
      Rep   : array (1 .. Default_Max_Cosets) of Coset_Id := [others => 0];

      --  Coincidence queue
      Q_Data  : array (1 .. Default_Max_Cosets) of Coset_Id := [others => 0];
      Q_Head  : Natural := 1;
      Q_Tail  : Natural := 0;

      R_Out : Result;

      function Inv_Col (Col : Positive) return Positive is
        (if Col <= Pres.Gen_Count then Col + Pres.Gen_Count
         else Col - Pres.Gen_Count);

      function Find (C : Coset_Id) return Coset_Id;

      procedure Enqueue (A, B : Coset_Id);
      procedure Process_Coincidences;
      procedure Define (Coset : Coset_Id; Col : Positive);
      procedure Deduce (Coset : Coset_Id; Col : Positive; Image : Coset_Id);
      procedure Scan_Word (Start : Coset_Id; W : Word; Close_To : Coset_Id);
      procedure Apply_Subgroup;
      procedure Fill_Deductions;
      function First_Undefined (Coset : out Coset_Id; Col : out Positive)
        return Boolean;
      function Table_Complete return Boolean;

      ------------------
      -- Find / coincide
      ------------------

      function Find (C : Coset_Id) return Coset_Id is
         X : Coset_Id := C;
         P : Coset_Id;
      begin
         if X = 0 then
            return 0;
         end if;
         while Rep (X) /= X loop
            X := Rep (X);
         end loop;
         --  Path compression
         P := C;
         while P /= X loop
            declare
               Nxt : constant Coset_Id := Rep (P);
            begin
               Rep (P) := X;
               P := Nxt;
            end;
         end loop;
         return X;
      end Find;

      procedure Enqueue (A, B : Coset_Id) is
         X : Coset_Id := Find (A);
         Y : Coset_Id := Find (B);
         T : Coset_Id;
      begin
         if X = 0 or else Y = 0 or else X = Y then
            return;
         end if;
         if X > Y then
            T := X;
            X := Y;
            Y := T;
         end if;
         --  Y merges into X (keep smaller representative)
         Rep (Y) := X;
         Live := Live - 1;
         Q_Tail := Q_Tail + 1;
         Q_Data (Q_Tail) := Y;
      end Enqueue;

      procedure Process_Coincidences is
      begin
         while Q_Head <= Q_Tail loop
            declare
               Dead : constant Coset_Id := Q_Data (Q_Head);
               Keep : constant Coset_Id := Find (Dead);
            begin
               Q_Head := Q_Head + 1;
               for Col in 1 .. Columns loop
                  declare
                     Img_Dead : constant Coset_Id := Table (Dead, Col);
                     Img_Keep : Coset_Id;
                  begin
                     Table (Dead, Col) := 0;
                     if Img_Dead /= 0 then
                        --  Clear reverse pointer from image if it pointed here
                        declare
                           IC   : constant Positive := Inv_Col (Col);
                           ImgR : constant Coset_Id := Find (Img_Dead);
                        begin
                           if ImgR /= 0 and then Table (ImgR, IC) = Dead then
                              Table (ImgR, IC) := 0;
                           end if;
                           Img_Keep := Table (Keep, Col);
                           if Img_Keep = 0 then
                              Table (Keep, Col) := ImgR;
                              if ImgR /= 0
                                and then Table (ImgR, IC) = 0
                              then
                                 Table (ImgR, IC) := Keep;
                              elsif ImgR /= 0
                                and then Find (Table (ImgR, IC)) /= Keep
                              then
                                 Enqueue (Keep, Find (Table (ImgR, IC)));
                              end if;
                           else
                              Enqueue (Find (Img_Keep), ImgR);
                           end if;
                        end;
                     end if;
                  end;
               end loop;
            end;
         end loop;
      end Process_Coincidences;

      procedure Deduce (Coset : Coset_Id; Col : Positive; Image : Coset_Id) is
         C  : constant Coset_Id := Find (Coset);
         Im : constant Coset_Id := Find (Image);
         IC : constant Positive := Inv_Col (Col);
         Cur : Coset_Id;
      begin
         if C = 0 or else Im = 0 then
            return;
         end if;
         Cur := Table (C, Col);
         if Cur = 0 then
            Table (C, Col) := Im;
         else
            Enqueue (Find (Cur), Im);
         end if;
         Cur := Table (Im, IC);
         if Cur = 0 then
            Table (Im, IC) := C;
         else
            Enqueue (Find (Cur), C);
         end if;
         Process_Coincidences;
      end Deduce;

      procedure Define (Coset : Coset_Id; Col : Positive) is
         C : constant Coset_Id := Find (Coset);
      begin
         if C = 0 or else Table (C, Col) /= 0 then
            return;
         end if;
         if Defined >= Limit then
            Failed := True;
            return;
         end if;
         Defined := Defined + 1;
         Live := Live + 1;
         Rep (Defined) := Coset_Id (Defined);
         Deduce (C, Col, Coset_Id (Defined));
      end Define;

      --  Scan word W from Start; the word equals identity in the group
      --  (relator) or must fix Start (subgroup generator, Close_To =
      --  Start). Two-sided fill: walk forward and backward, defining
      --  only when a single gap remains, else detecting coincidence.
      procedure Scan_Word
        (Start   : Coset_Id;
         W       : Word;
         Close_To : Coset_Id)
      is
         Len : constant Natural := W.Length;
      begin
         if Len = 0 then
            Enqueue (Start, Close_To);
            Process_Coincidences;
            return;
         end if;

         declare
            --  Forward partial products F (0) = Start, F (k) = Start * w1..wk
            F : array (0 .. Max_Word_Length) of Coset_Id := [others => 0];
            --  Backward: B (Len) = Close_To, B (k) = Close_To * (wk+1..wn)^{-1}
            B : array (0 .. Max_Word_Length) of Coset_Id := [others => 0];
            Cols : array (1 .. Max_Word_Length) of Natural := [others => 0];
            Changed : Boolean;
         begin
            for I in 1 .. Len loop
               Cols (I) := Column_Of (Pres, W.Letters (I));
               if Cols (I) = 0 then
                  raise Invalid_Argument;
               end if;
            end loop;

            F (0) := Find (Start);
            B (Len) := Find (Close_To);

            loop
               Changed := False;

               --  Forward sweep
               for I in 1 .. Len loop
                  declare
                     Src : constant Coset_Id := Find (F (I - 1));
                     Col : constant Positive := Cols (I);
                     Nxt : Coset_Id;
                  begin
                     if Src = 0 then
                        exit;
                     end if;
                     Nxt := Table (Src, Col);
                     if Nxt /= 0 then
                        Nxt := Find (Nxt);
                        if F (I) = 0 then
                           F (I) := Nxt;
                           Changed := True;
                        elsif Find (F (I)) /= Nxt then
                           Enqueue (Find (F (I)), Nxt);
                           Process_Coincidences;
                           F (I) := Find (F (I));
                           Changed := True;
                        end if;
                     end if;
                  end;
               end loop;

               --  Backward sweep
               for I in reverse 1 .. Len loop
                  declare
                     Dst : constant Coset_Id := Find (B (I));
                     Col : constant Positive := Cols (I);
                     IC  : constant Positive := Inv_Col (Col);
                     Prv : Coset_Id;
                  begin
                     if Dst = 0 then
                        exit;
                     end if;
                     Prv := Table (Dst, IC);
                     if Prv /= 0 then
                        Prv := Find (Prv);
                        if B (I - 1) = 0 then
                           B (I - 1) := Prv;
                           Changed := True;
                        elsif Find (B (I - 1)) /= Prv then
                           Enqueue (Find (B (I - 1)), Prv);
                           Process_Coincidences;
                           B (I - 1) := Find (B (I - 1));
                           Changed := True;
                        end if;
                     end if;
                  end;
               end loop;

               --  Single-gap deductions: F(i-1) known, B(i) known → define edge
               for I in 1 .. Len loop
                  declare
                     Src : constant Coset_Id := Find (F (I - 1));
                     Dst : constant Coset_Id := Find (B (I));
                     Col : constant Positive := Cols (I);
                  begin
                     if Src /= 0 and then Dst /= 0 then
                        if Table (Src, Col) = 0 then
                           Deduce (Src, Col, Dst);
                           Changed := True;
                        else
                           Enqueue (Find (Table (Src, Col)), Dst);
                           Process_Coincidences;
                        end if;
                        F (I) := Find (Dst);
                        B (I - 1) := Find (Src);
                     end if;
                  end;
               end loop;

               --  If forward reached the end, identify with Close_To
               if F (Len) /= 0 then
                  Enqueue (Find (F (Len)), Find (Close_To));
                  Process_Coincidences;
               end if;
               if B (0) /= 0 then
                  Enqueue (Find (B (0)), Find (Start));
                  Process_Coincidences;
               end if;

               exit when not Changed;
            end loop;
         end;
      end Scan_Word;

      --  Apply one subgroup generator word at coset 1: define
      --  intermediate cosets left-to-right, then force the last
      --  edge to close back to 1 (H h = H).
      procedure Apply_One_Subgroup_Word (W : Word) is
         C : Coset_Id;
      begin
         if W.Length = 0 then
            return;
         end if;
         C := 1;
         for I in 1 .. W.Length - 1 loop
            declare
               Col : constant Natural := Column_Of (Pres, W.Letters (I));
               C0  : Coset_Id;
               Img : Coset_Id;
            begin
               if Col = 0 then
                  raise Invalid_Argument;
               end if;
               C0 := Find (C);
               if C0 = 0 then
                  return;
               end if;
               if Table (C0, Col) = 0 then
                  Define (C0, Col);
                  if Failed then
                     return;
                  end if;
               end if;
               Img := Find (Table (Find (C0), Col));
               if Img = 0 then
                  Failed := True;
                  return;
               end if;
               C := Img;
            end;
         end loop;
         declare
            Col : constant Natural :=
              Column_Of (Pres, W.Letters (W.Length));
            C0  : constant Coset_Id := Find (C);
         begin
            if Col = 0 or else C0 = 0 then
               raise Invalid_Argument;
            end if;
            Deduce (C0, Col, 1);
         end;
      end Apply_One_Subgroup_Word;

      procedure Apply_Subgroup is
      begin
         for K in Subgroup'Range loop
            declare
               W : Word renames Subgroup (K);
            begin
               if not Word_Is_Valid (Pres, W) then
                  raise Invalid_Argument;
               end if;
               Apply_One_Subgroup_Word (W);
               if Failed then
                  return;
               end if;
            end;
         end loop;
      end Apply_Subgroup;

      procedure Fill_Deductions is
         Progress : Boolean;
      begin
         loop
            Progress := False;
            for C in 1 .. Defined loop
               if Rep (C) = Coset_Id (C) then
                  for R in 1 .. Pres.Rel_Count loop
                     declare
                        Before : constant Natural := Live;
                     begin
                        Scan_Word (Coset_Id (C), Pres.Relators (R), Coset_Id (C));
                        if Live /= Before then
                           Progress := True;
                        end if;
                     end;
                  end loop;
               end if;
               exit when Failed;
            end loop;
            exit when not Progress or else Failed;
         end loop;
      end Fill_Deductions;

      function First_Undefined
        (Coset : out Coset_Id;
         Col   : out Positive) return Boolean
      is
      begin
         for C in 1 .. Defined loop
            if Rep (C) = Coset_Id (C) then
               for J in 1 .. Columns loop
                  if Table (C, J) = 0 then
                     Coset := Coset_Id (C);
                     Col := J;
                     return True;
                  end if;
               end loop;
            end if;
         end loop;
         return False;
      end First_Undefined;

      function Table_Complete return Boolean is
         Dummy_C : Coset_Id;
         Dummy_J : Positive;
      begin
         return not First_Undefined (Dummy_C, Dummy_J);
      end Table_Complete;

   begin
      --  Validate presentation / limit / subgroup size
      if Pres.Gen_Count = 0 or else Pres.Gen_Count > Max_Generators then
         raise Invalid_Argument;
      end if;
      if Pres.Rel_Count > Max_Relators then
         raise Invalid_Argument;
      end if;
      if Subgroup'Length > Max_Subgroup_Gens then
         raise Invalid_Argument;
      end if;
      if Limit > Default_Max_Cosets then
         raise Invalid_Argument;
      end if;
      for I in 1 .. Pres.Gen_Count loop
         if not Is_Lower (Pres.Generators (I)) then
            raise Invalid_Argument;
         end if;
      end loop;
      for R in 1 .. Pres.Rel_Count loop
         if not Word_Is_Valid (Pres, Pres.Relators (R)) then
            raise Invalid_Argument;
         end if;
      end loop;

      Columns := 2 * Pres.Gen_Count;

      --  Coset 1 = H
      Defined := 1;
      Live := 1;
      Rep (1) := 1;

      Apply_Subgroup;
      Fill_Deductions;

      --  Define new cosets until the table closes or Limit is hit
      while not Failed and then not Table_Complete loop
         declare
            C : Coset_Id;
            J : Positive;
         begin
            if not First_Undefined (C, J) then
               exit;
            end if;
            Define (C, J);
            if Failed then
               exit;
            end if;
            Fill_Deductions;
         end;
      end loop;

      if Failed or else not Table_Complete then
         R_Out.Success := False;
         R_Out.Index := 0;
         R_Out.Columns := Columns;
         return R_Out;
      end if;

      --  Compact live cosets to 1 .. Live and rebuild the action table
      declare
         Old_To_New : array (1 .. Default_Max_Cosets) of Coset_Id :=
           [others => 0];
         Next_Id    : Natural := 0;
         New_Table  : Coset_Table := [others => [others => 0]];
      begin
         for C in 1 .. Defined loop
            if Rep (C) = Coset_Id (C) then
               Next_Id := Next_Id + 1;
               Old_To_New (C) := Coset_Id (Next_Id);
            end if;
         end loop;

         for C in 1 .. Defined loop
            if Rep (C) = Coset_Id (C) then
               declare
                  Nc : constant Coset_Id := Old_To_New (C);
               begin
                  for J in 1 .. Columns loop
                     declare
                        Img : constant Coset_Id := Find (Table (C, J));
                     begin
                        if Img = 0 then
                           R_Out.Success := False;
                           R_Out.Index := 0;
                           return R_Out;
                        end if;
                        New_Table (Nc, J) := Old_To_New (Img);
                     end;
                  end loop;
               end;
            end if;
         end loop;

         R_Out.Success := True;
         R_Out.Index := Next_Id;
         R_Out.Table := New_Table;
         R_Out.Columns := Columns;
      end;

      return R_Out;
   end Enumerate;

end Todd_Coxeter;
