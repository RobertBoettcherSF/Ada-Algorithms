package body Dfa_Minimization is

   function Is_Valid_Dfa (D : DFA) return Boolean is
   begin
      if D.Num_States = 0 then
         return False;
      end if;
      if D.Num_Symbols = 0 then
         return False;
      end if;
      if Natural (D.Initial_State) >= Natural (D.Num_States) then
         return False;
      end if;
      for S in 0 .. D.Num_States - 1 loop
         for Sym in 0 .. D.Num_Symbols - 1 loop
            if Natural (D.Transitions (State_Id (S), Symbol_Id (Sym))) >= Natural (D.Num_States) then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Valid_Dfa;

   function Remove_Unreachable_States (Original : DFA) return DFA is
      Reachable : State_Set := [others => False];
      Queue     : array (0 .. Max_States - 1) of State_Id;
      Head      : Natural := 0;
      Tail      : Natural := 0;
      Curr      : State_Id;
      Next_St   : State_Id;
      New_Map   : array (State_Id) of State_Id := [others => 0];
      Count     : State_Count := 0;
      Result    : DFA := (Num_States    => 0,
                          Num_Symbols   => Original.Num_Symbols,
                          Initial_State => 0,
                          Accepting     => [others => False],
                          Transitions   => [others => [others => 0]]);
   begin
      -- BFS to find reachable states
      Queue (Tail) := Original.Initial_State;
      Tail := Tail + 1;
      Reachable (Original.Initial_State) := True;

      while Head < Tail loop
         Curr := Queue (Head);
         Head := Head + 1;
         for Sym in 0 .. Original.Num_Symbols - 1 loop
            Next_St := Original.Transitions (Curr, Symbol_Id (Sym));
            if not Reachable (Next_St) then
               Reachable (Next_St) := True;
               Queue (Tail) := Next_St;
               Tail := Tail + 1;
            end if;
         end loop;
      end loop;

      -- Map old states to new dense states
      for S in 0 .. Original.Num_States - 1 loop
         if Reachable (State_Id (S)) then
            New_Map (State_Id (S)) := State_Id (Count);
            Count := Count + 1;
         end if;
      end loop;

      if Count = 0 then
         raise Invalid_Dfa;
      end if;

      Result.Num_States := Count;
      Result.Initial_State := New_Map (Original.Initial_State);

      for S in 0 .. Original.Num_States - 1 loop
         declare
            St : constant State_Id := State_Id (S);
         begin
            if Reachable (St) then
               if Original.Accepting (St) then
                  Result.Accepting (New_Map (St)) := True;
               end if;
               for Sym in 0 .. Original.Num_Symbols - 1 loop
                  declare
                     Sym_Id : constant Symbol_Id := Symbol_Id (Sym);
                     Dest   : constant State_Id := Original.Transitions (St, Sym_Id);
                  begin
                     Result.Transitions (New_Map (St), Sym_Id) := New_Map (Dest);
                  end;
               end loop;
            end if;
         end;
      end loop;

      return Result;
   end Remove_Unreachable_States;

   -- Moore's Algorithm Implementation
   function Minimize_Moore (Original : DFA) return DFA is
      Clean_Orig : constant DFA := Remove_Unreachable_States (Original);
      N          : constant State_Count := Clean_Orig.Num_States;
      K          : constant Symbol_Count := Clean_Orig.Num_Symbols;
      
      type Partition_Array is array (State_Id) of State_Id;
      Current_P  : Partition_Array := [others => 0];
      Num_Blocks : State_Id := 0;
      Changed    : Boolean;
   begin
      -- Initial partition: separate accepting and non-accepting states
      declare
         Max_B : State_Id := 0;
      begin
         for S in 0 .. N - 1 loop
            declare
               St : constant State_Id := State_Id (S);
            begin
               if Clean_Orig.Accepting (St) then
                  Current_P (St) := 1;
                  if 1 > Max_B then
                     Max_B := 1;
                  end if;
               else
                  Current_P (St) := 0;
               end if;
            end;
         end loop;
         Num_Blocks := Max_B + 1;
      end;

      loop
         Changed := False;
         -- Refine partition
         declare
            New_Blocks : Partition_Array := [others => 0];
            Next_Num_B : State_Id := 0;
            
            type State_Trans_Array is array (Symbol_Id) of State_Id;
            type Signature_Record is record
               Accepting : Boolean;
               Block     : State_Id;
               Trans     : State_Trans_Array;
            end record;
            
            Sigs : array (State_Id) of Signature_Record :=
              [others => (Accepting => False, Block => 0, Trans => [others => 0])];
         begin
            for S in 0 .. N - 1 loop
               declare
                  St  : constant State_Id := State_Id (S);
                  Sig : Signature_Record;
               begin
                  Sig.Accepting := Clean_Orig.Accepting (St);
                  Sig.Block := Current_P (St);
                  for Sym in 0 .. K - 1 loop
                     declare
                        Sym_Id : constant Symbol_Id := Symbol_Id (Sym);
                        Dest   : constant State_Id := Clean_Orig.Transitions (St, Sym_Id);
                     begin
                        Sig.Trans (Sym_Id) := Current_P (Dest);
                     end;
                  end loop;
                  
                  declare
                     Found_Id : State_Id := State_Id'Last;
                  begin
                     for Prev in 0 .. State_Id (S) - 1 loop
                        declare
                           P_St  : constant State_Id := State_Id (Prev);
                           Match : Boolean := (Sigs (P_St).Accepting = Sig.Accepting and then
                                               Sigs (P_St).Block = Sig.Block);
                        begin
                           if Match then
                              for Sym in 0 .. K - 1 loop
                                 if Sigs (P_St).Trans (Symbol_Id (Sym)) /= Sig.Trans (Symbol_Id (Sym)) then
                                    Match := False;
                                    exit;
                                 end if;
                              end loop;
                           end if;
                           if Match then
                              Found_Id := New_Blocks (P_St);
                              exit;
                           end if;
                        end;
                     end loop;
                     
                     if Found_Id = State_Id'Last then
                        New_Blocks (St) := Next_Num_B;
                        Sigs (St) := Sig;
                        Next_Num_B := Next_Num_B + 1;
                     else
                        New_Blocks (St) := Found_Id;
                        Sigs (St) := Sig;
                     end if;
                  end;
               end;
            end loop;

            if Next_Num_B /= Num_Blocks then
               Changed := True;
               Num_Blocks := Next_Num_B;
               Current_P := New_Blocks;
            end if;
         end;

         exit when not Changed;
      end loop;

      -- Construct minimized DFA from Current_P blocks
      declare
         Result         : DFA := (Num_States    => State_Count (Num_Blocks),
                                  Num_Symbols   => K,
                                  Initial_State => Current_P (Clean_Orig.Initial_State),
                                  Accepting     => [others => False],
                                  Transitions   => [others => [others => 0]]);
         Representative : array (State_Id) of State_Id := [others => 0];
         Rep_Found      : array (State_Id) of Boolean := [others => False];
      begin
         for S in 0 .. N - 1 loop
            declare
               St   : constant State_Id := State_Id (S);
               B_Id : constant State_Id := Current_P (St);
            begin
               if Clean_Orig.Accepting (St) then
                  Result.Accepting (B_Id) := True;
               end if;
               if not Rep_Found (B_Id) then
                  Representative (B_Id) := St;
                  Rep_Found (B_Id) := True;
               end if;
            end;
         end loop;

         for B in 0 .. Num_Blocks - 1 loop
            declare
               B_Id : constant State_Id := State_Id (B);
               Rep  : constant State_Id := Representative (B_Id);
            begin
               for Sym in 0 .. K - 1 loop
                  declare
                     Sym_Id : constant Symbol_Id := Symbol_Id (Sym);
                     Dest   : constant State_Id := Clean_Orig.Transitions (Rep, Sym_Id);
                  begin
                     Result.Transitions (B_Id, Sym_Id) := Current_P (Dest);
                  end;
               end loop;
            end;
         end loop;

         return Result;
      end;
   end Minimize_Moore;

   -- Hopcroft's Algorithm Implementation
   function Minimize_Hopcroft (Original : DFA) return DFA is
      Clean_Orig : constant DFA := Remove_Unreachable_States (Original);
      N          : constant State_Count := Clean_Orig.Num_States;
      K          : constant Symbol_Count := Clean_Orig.Num_Symbols;

      type Set_Array is array (0 .. Max_States - 1) of State_Set;
      
      P      : Set_Array := [others => [others => False]];
      P_Size : Natural := 2;
      
      W      : Set_Array := [others => [others => False]];
      W_Size : Natural := 2;

      function Intersect (S1, S2 : State_Set) return State_Set is
         Res : State_Set := [others => False];
      begin
         for I in 0 .. N - 1 loop
            Res (State_Id (I)) := S1 (State_Id (I)) and S2 (State_Id (I));
         end loop;
         return Res;
      end Intersect;

      function Difference (S1, S2 : State_Set) return State_Set is
         Res : State_Set := [others => False];
      begin
         for I in 0 .. N - 1 loop
            Res (State_Id (I)) := S1 (State_Id (I)) and not S2 (State_Id (I));
         end loop;
         return Res;
      end Difference;

      function Is_Empty (S : State_Set) return Boolean is
      begin
         for I in 0 .. N - 1 loop
            if S (State_Id (I)) then
               return False;
            end if;
         end loop;
         return True;
      end Is_Empty;

      function Cardinality (S : State_Set) return Natural is
         Cnt : Natural := 0;
      begin
         for I in 0 .. N - 1 loop
            if S (State_Id (I)) then
               Cnt := Cnt + 1;
            end if;
         end loop;
         return Cnt;
      end Cardinality;

      function Predecessors (A : State_Set; Sym : Symbol_Id) return State_Set is
         Res : State_Set := [others => False];
      begin
         for I in 0 .. N - 1 loop
            declare
               St   : constant State_Id := State_Id (I);
               Dest : constant State_Id := Clean_Orig.Transitions (St, Sym);
            begin
               if A (Dest) then
                  Res (St) := True;
               end if;
            end;
         end loop;
         return Res;
      end Predecessors;
   begin
      declare
         F_Set : State_Set := [others => False];
         Not_F : State_Set := [others => False];
      begin
         for I in 0 .. N - 1 loop
            declare
               St : constant State_Id := State_Id (I);
            begin
               if Clean_Orig.Accepting (St) then
                  F_Set (St) := True;
               else
                  Not_F (St) := True;
               end if;
            end;
         end loop;

         if not Is_Empty (F_Set) then
            P (0) := F_Set;
            W (0) := F_Set;
            if not Is_Empty (Not_F) then
               P (1) := Not_F;
               W (1) := Not_F;
               P_Size := 2;
               W_Size := 2;
            else
               P_Size := 1;
               W_Size := 1;
            end if;
         else
            P (0) := Not_F;
            W (0) := Not_F;
            P_Size := 1;
            W_Size := 1;
         end if;
      end;

      while W_Size > 0 loop
         W_Size := W_Size - 1;
         declare
            A : constant State_Set := W (W_Size);
         begin
            for Sym_Idx in 0 .. K - 1 loop
               declare
                  Sym : constant Symbol_Id := Symbol_Id (Sym_Idx);
                  X   : constant State_Set := Predecessors (A, Sym);
               begin
                  declare
                     Curr_P      : constant Set_Array := P;
                     Curr_P_Size : constant Natural := P_Size;
                  begin
                     for Y_Idx in 0 .. Curr_P_Size - 1 loop
                        declare
                           Y        : constant State_Set := Curr_P (Y_Idx);
                           X_Int_Y  : constant State_Set := Intersect (X, Y);
                           Y_Diff_X : constant State_Set := Difference (Y, X);
                        begin
                           if not Is_Empty (X_Int_Y) and not Is_Empty (Y_Diff_X) then
                              for P_Idx in 0 .. P_Size - 1 loop
                                 declare
                                    Eq : Boolean := True;
                                 begin
                                    for I in 0 .. N - 1 loop
                                       if P (P_Idx) (State_Id (I)) /= Y (State_Id (I)) then
                                          Eq := False;
                                          exit;
                                       end if;
                                    end loop;
                                    if Eq then
                                       P (P_Idx) := X_Int_Y;
                                       P (P_Size) := Y_Diff_X;
                                       P_Size := P_Size + 1;

                                       declare
                                          Found_In_W  : Boolean := False;
                                          W_Match_Idx : Natural := 0;
                                       begin
                                          for W_Idx in 0 .. W_Size - 1 loop
                                             declare
                                                W_Eq : Boolean := True;
                                             begin
                                                for I in 0 .. N - 1 loop
                                                   if W (W_Idx) (State_Id (I)) /= Y (State_Id (I)) then
                                                      W_Eq := False;
                                                      exit;
                                                   end if;
                                                end loop;
                                                if W_Eq then
                                                   Found_In_W := True;
                                                   W_Match_Idx := W_Idx;
                                                   exit;
                                                end if;
                                             end;
                                          end loop;

                                          if Found_In_W then
                                             W (W_Match_Idx) := X_Int_Y;
                                             W (W_Size) := Y_Diff_X;
                                             W_Size := W_Size + 1;
                                          else
                                             if Cardinality (X_Int_Y) <= Cardinality (Y_Diff_X) then
                                                W (W_Size) := X_Int_Y;
                                                W_Size := W_Size + 1;
                                             else
                                                W (W_Size) := Y_Diff_X;
                                                W_Size := W_Size + 1;
                                             end if;
                                          end if;
                                       end;
                                       exit;
                                    end if;
                                 end;
                              end loop;
                           end if;
                        end;
                     end loop;
                  end;
               end;
            end loop;
         end;
      end loop;

      declare
         Result         : DFA := (Num_States    => State_Count (P_Size),
                                  Num_Symbols   => K,
                                  Initial_State => 0,
                                  Accepting     => [others => False],
                                  Transitions   => [others => [others => 0]]);
         State_To_Block : array (State_Id) of State_Id := [others => 0];
         Rep_State      : array (State_Id) of State_Id := [others => 0];
      begin
         for B_Idx in 0 .. P_Size - 1 loop
            declare
               B_Id      : constant State_Id := State_Id (B_Idx);
               Rep       : State_Id := 0;
               Found_Rep : Boolean := False;
            begin
               for I in 0 .. N - 1 loop
                  declare
                     St : constant State_Id := State_Id (I);
                  begin
                     if P (B_Idx) (St) then
                        State_To_Block (St) := B_Id;
                        if not Found_Rep then
                           Rep := St;
                           Found_Rep := True;
                        end if;
                     end if;
                  end;
               end loop;
               Rep_State (B_Id) := Rep;
               if Clean_Orig.Accepting (Rep) then
                  Result.Accepting (B_Id) := True;
               end if;
            end;
         end loop;

         Result.Initial_State := State_To_Block (Clean_Orig.Initial_State);

         for B_Idx in 0 .. P_Size - 1 loop
            declare
               B_Id : constant State_Id := State_Id (B_Idx);
               Rep  : constant State_Id := Rep_State (B_Id);
            begin
               for Sym_Idx in 0 .. K - 1 loop
                  declare
                     Sym  : constant Symbol_Id := Symbol_Id (Sym_Idx);
                     Dest : constant State_Id := Clean_Orig.Transitions (Rep, Sym);
                  begin
                     Result.Transitions (B_Id, Sym) := State_To_Block (Dest);
                  end;
               end loop;
            end;
         end loop;

         return Result;
      end;
   end Minimize_Hopcroft;

   -- Brzozowski's Algorithm Implementation
   function Minimize_Brzozowski (Original : DFA) return DFA is
      Clean_Orig : constant DFA := Remove_Unreachable_States (Original);
      K          : constant Symbol_Count := Clean_Orig.Num_Symbols;

      type Nfa_Transition_Table is array (State_Id, Symbol_Id) of State_Set;

      function Powerset_Construct (NFA_States_Count : State_Count;
                                   NFA_Initial      : State_Set;
                                   NFA_Accepting    : State_Set;
                                   NFA_Trans        : Nfa_Transition_Table) return DFA is
         type Subset_Array is array (0 .. Max_States - 1) of State_Set;
         Subsets      : Subset_Array := [others => [others => False]];
         Sub_Count    : Natural := 0;
         
         Trans_Table  : Transition_Table := [others => [others => 0]];
         Is_Accepting : State_Set := [others => False];
         
         Head         : Natural := 0;
         Tail         : Natural := 0;

         function Sets_Equal (S1, S2 : State_Set) return Boolean is
         begin
            for I in 0 .. NFA_States_Count - 1 loop
               if S1 (State_Id (I)) /= S2 (State_Id (I)) then
                  return False;
               end if;
            end loop;
            return True;
         end Sets_Equal;

         function Find_Or_Add_Subset (S : State_Set) return State_Id is
         begin
            for I in 0 .. Sub_Count - 1 loop
               if Sets_Equal (Subsets (I), S) then
                  return State_Id (I);
               end if;
            end loop;
            Subsets (Sub_Count) := S;
            declare
               New_Id : constant State_Id := State_Id (Sub_Count);
            begin
               Sub_Count := Sub_Count + 1;
               Is_Accepting (New_Id) := False;
               for I in 0 .. NFA_States_Count - 1 loop
                  if S (State_Id (I)) and then NFA_Accepting (State_Id (I)) then
                     Is_Accepting (New_Id) := True;
                     exit;
                  end if;
               end loop;
               return New_Id;
            end;
         end Find_Or_Add_Subset;
      begin
         Subsets (0) := NFA_Initial;
         Sub_Count := 1;
         
         for I in 0 .. NFA_States_Count - 1 loop
            if NFA_Initial (State_Id (I)) and then NFA_Accepting (State_Id (I)) then
               Is_Accepting (0) := True;
               exit;
            end if;
         end loop;

         Tail := 1;

         while Head < Tail loop
            declare
               Curr_Id  : constant State_Id := State_Id (Head);
               Curr_Set : constant State_Set := Subsets (Head);
            begin
               Head := Head + 1;
               for Sym_Idx in 0 .. K - 1 loop
                  declare
                     Sym      : constant Symbol_Id := Symbol_Id (Sym_Idx);
                     Next_Set : State_Set := [others => False];
                  begin
                     for I in 0 .. NFA_States_Count - 1 loop
                        declare
                           St : constant State_Id := State_Id (I);
                        begin
                           if Curr_Set (St) then
                              for Dest_I in 0 .. NFA_States_Count - 1 loop
                                 if NFA_Trans (St, Sym) (State_Id (Dest_I)) then
                                    Next_Set (State_Id (Dest_I)) := True;
                                 end if;
                              end loop;
                           end if;
                        end;
                     end loop;

                     declare
                        Dest_Id : constant State_Id := Find_Or_Add_Subset (Next_Set);
                     begin
                        Trans_Table (Curr_Id, Sym) := Dest_Id;
                     end;
                  end;
               end loop;
            end;
         end loop;

         return (Num_States    => State_Count (Sub_Count),
                 Num_Symbols   => K,
                 Initial_State => 0,
                 Accepting     => Is_Accepting,
                 Transitions   => Trans_Table);
      end Powerset_Construct;

      NFA_Trans : Nfa_Transition_Table := [others => [others => [others => False]]];
      NFA_Init  : State_Set := [others => False];
      NFA_Acc   : State_Set := [others => False];
      N         : constant State_Count := Clean_Orig.Num_States;
   begin
      for I in 0 .. N - 1 loop
         declare
            St : constant State_Id := State_Id (I);
         begin
            if Clean_Orig.Accepting (St) then
               NFA_Init (St) := True;
            end if;
            for Sym_Idx in 0 .. K - 1 loop
               declare
                  Sym  : constant Symbol_Id := Symbol_Id (Sym_Idx);
                  Dest : constant State_Id := Clean_Orig.Transitions (St, Sym);
               begin
                  NFA_Trans (Dest, Sym) (St) := True;
               end;
            end loop;
         end;
      end loop;

      NFA_Acc (Clean_Orig.Initial_State) := True;

      declare
         Interm_Dfa   : constant DFA := Powerset_Construct (N, NFA_Init, NFA_Acc, NFA_Trans);
         Clean_Interm : constant DFA := Remove_Unreachable_States (Interm_Dfa);
         
         Int_N        : constant State_Count := Clean_Interm.Num_States;
         Int_K        : constant Symbol_Count := Clean_Interm.Num_Symbols;
         
         Int_NFA_Trans : Nfa_Transition_Table := [others => [others => [others => False]]];
         Int_NFA_Init  : State_Set := [others => False];
         Int_NFA_Acc   : State_Set := [others => False];
      begin
         for I in 0 .. Int_N - 1 loop
            declare
               St : constant State_Id := State_Id (I);
            begin
               if Clean_Interm.Accepting (St) then
                  Int_NFA_Init (St) := True;
               end if;
               for Sym_Idx in 0 .. Int_K - 1 loop
                  declare
                     Sym  : constant Symbol_Id := Symbol_Id (Sym_Idx);
                     Dest : constant State_Id := Clean_Interm.Transitions (St, Sym);
                  begin
                     Int_NFA_Trans (Dest, Sym) (St) := True;
                  end;
               end loop;
            end;
         end loop;

         Int_NFA_Acc (Clean_Interm.Initial_State) := True;

         return Remove_Unreachable_States (Powerset_Construct (Int_N, Int_NFA_Init, Int_NFA_Acc, Int_NFA_Trans));
      end;
   end Minimize_Brzozowski;

end Dfa_Minimization;
