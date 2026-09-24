package body Dfa_Minimization is

   ------------------
   -- Validate_Dfa --
   ------------------

   function Validate_Dfa (Dfa : DFA_Type) return Boolean is
   begin
      pragma Warnings (Off, "condition can only be");
      if Dfa.Num_States = 0 or else Dfa.Num_States > Max_States_Count then
         return False;
      end if;

      if Dfa.Num_Symbols > Max_Symbols_Count then
         return False;
      end if;
      pragma Warnings (On, "condition can only be");

      if Dfa.Initial >= State_Range (Dfa.Num_States) then
         return False;
      end if;

      for S in 0 .. State_Range (Dfa.Num_States - 1) loop
         for Sym in 0 .. Symbol_Range (Dfa.Num_Symbols - 1) loop
            if Dfa.Transitions (S, Sym) >= State_Range (Dfa.Num_States) then
               return False;
            end if;
         end loop;
      end loop;

      return True;
   end Validate_Dfa;

   --------------------
   -- Minimize_Moore --
   --------------------

   function Minimize_Moore (Dfa : DFA_Type) return DFA_Type is
      type Partition_Array is array (State_Range) of State_Range;

      Current_Partition : Partition_Array := [others => 0];
      New_Partition     : Partition_Array := [others => 0];
      Changed           : Boolean := True;

      First_Accept     : State_Range := State_Range'Last;
      First_Reject     : State_Range := State_Range'Last;
      Has_Accept       : Boolean := False;
      Has_Reject       : Boolean := False;

      N                : constant Natural := Natural (Dfa.Num_States);
      Sym_Count        : constant Natural := Natural (Dfa.Num_Symbols);
   begin
      for I in 0 .. N - 1 loop
         if Dfa.Finals (I) then
            if not Has_Accept then
               First_Accept := I;
               Has_Accept := True;
            end if;
         else
            if not Has_Reject then
               First_Reject := I;
               Has_Reject := True;
            end if;
         end if;
      end loop;

      for I in 0 .. N - 1 loop
         if Dfa.Finals (I) then
            Current_Partition (I) := (if Has_Accept then First_Accept else I);
         else
            Current_Partition (I) := (if Has_Reject then First_Reject else I);
         end if;
      end loop;

      if not Has_Accept or else not Has_Reject then
         for I in 0 .. N - 1 loop
            Current_Partition (I) := 0;
         end loop;
      end if;

      while Changed loop
         Changed := False;

         for I in 0 .. N - 1 loop
            New_Partition (I) := I;
            for J in 0 .. I - 1 loop
               if Current_Partition (I) = Current_Partition (J) then
                  declare
                     Equivalent : Boolean := True;
                  begin
                     if Sym_Count > 0 then
                        for Sym in 0 .. Sym_Count - 1 loop
                           declare
                              Target_I : constant State_Range := Dfa.Transitions (I, Sym);
                              Target_J : constant State_Range := Dfa.Transitions (J, Sym);
                           begin
                              if Current_Partition (Target_I) /= Current_Partition (Target_J) then
                                 Equivalent := False;
                                 exit;
                              end if;
                           end;
                        end loop;
                     end if;

                     if Equivalent then
                        New_Partition (I) := New_Partition (J);
                        exit;
                     end if;
                  end;
               end if;
            end loop;
         end loop;

         for I in 0 .. N - 1 loop
            if Current_Partition (I) /= New_Partition (I) then
               Changed := True;
               exit;
            end if;
         end loop;

         if Changed then
            Current_Partition := New_Partition;
         end if;
      end loop;

      declare
         Mapping        : array (State_Range) of State_Range := [others => State_Range'Last];
         New_Num_States : State_Count_Range := 0;
      begin
         for I in 0 .. N - 1 loop
            declare
               Rep : constant State_Range := Current_Partition (I);
            begin
               if Mapping (Rep) = State_Range'Last then
                  Mapping (Rep) := State_Range (New_Num_States);
                  New_Num_States := New_Num_States + 1;
               end if;
            end;
         end loop;

         declare
            Min_Dfa : DFA_Type (Num_States => New_Num_States, Num_Symbols => Dfa.Num_Symbols);
         begin
            Min_Dfa.Initial := Mapping (Current_Partition (Dfa.Initial));
            Min_Dfa.Finals := [others => False];
            Min_Dfa.Transitions := [others => [others => 0]];

            for I in 0 .. N - 1 loop
               declare
                  New_Src : constant State_Range := Mapping (Current_Partition (I));
               begin
                  if Dfa.Finals (I) then
                     Min_Dfa.Finals (New_Src) := True;
                  end if;

                  if Sym_Count > 0 then
                     for Sym in 0 .. Symbol_Range (Sym_Count - 1) loop
                        declare
                           Target     : constant State_Range := Dfa.Transitions (I, Sym);
                           New_Target : constant State_Range := Mapping (Current_Partition (Target));
                        begin
                           Min_Dfa.Transitions (New_Src, Sym) := New_Target;
                        end;
                     end loop;
                  end if;
               end;
            end loop;

            return Min_Dfa;
         end;
      end;
   end Minimize_Moore;

end Dfa_Minimization;
