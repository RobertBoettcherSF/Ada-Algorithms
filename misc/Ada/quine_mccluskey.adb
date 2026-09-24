package body Quine_McCluskey is

   -- Converts a Natural minterm into a zero-padded binary string of Num_Vars bits
   function To_Binary (Val : Natural; Length : Positive) return String is
      Res  : String (1 .. Length) := (others => '0');
      Temp : Natural := Val;
   begin
      for I in reverse 1 .. Length loop
         if Temp mod 2 = 1 then
            Res (I) := '1';
         end if;
         Temp := Temp / 2;
      end loop;
      return Res;
   end To_Binary;

   function Count_Ones (S : String) return Natural is
      Count : Natural := 0;
   begin
      for C of S loop
         if C = '1' then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Ones;

   function Differs_By_One (S1, S2 : String) return Boolean is
      Diff_Count : Natural := 0;
   begin
      if S1'Length /= S2'Length then return False; end if;
      for I in S1'Range loop
         if S1 (I) /= S2 (I) then
            Diff_Count := Diff_Count + 1;
         end if;
      end loop;
      return Diff_Count = 1;
   end Differs_By_One;

   function Merge (S1, S2 : String) return String is
      Res : String := S1;
   begin
      for I in S1'Range loop
         if S1 (I) /= S2 (I) then
            Res (I) := '-';
         end if;
      end loop;
      return Res;
   end Merge;

   function Covers (PI : String; Minterm : Natural) return Boolean is
      Bin : String := To_Binary (Minterm, PI'Length);
   begin
      for I in PI'Range loop
         if PI (I) /= '-' and then PI (I) /= Bin (I) then
            return False;
         end if;
      end loop;
      return True;
   end Covers;
   
   -- Input Validation
   procedure Validate_Inputs (Num_Vars : Positive; Minterms, Dont_Cares : Minterm_Array) is
      Max_Val : Natural := (2 ** Num_Vars) - 1;
   begin
      for M of Minterms loop
         if M > Max_Val then raise Invalid_Input_Error; end if;
         for D of Dont_Cares loop
            if M = D then raise Invalid_Input_Error; end if; -- Overlap is invalid
         end loop;
      end loop;
      for D of Dont_Cares loop
         if D > Max_Val then raise Invalid_Input_Error; end if;
      end loop;
   end Validate_Inputs;

   -----------------------------------------------------------------------------
   -- Variant 1: Prime Implicant Generation
   -----------------------------------------------------------------------------
   function Get_Prime_Implicants 
     (Num_Vars   : Positive; 
      Minterms   : Minterm_Array; 
      Dont_Cares : Minterm_Array := Empty_Minterm_Array) return Implicant_List 
   is
      Current_Level : Implicant_List;
      Next_Level    : Implicant_List;
      Primes        : Implicant_List;
      Has_Merged    : array (1 .. 10000) of Boolean := (others => False);
   begin
      if Minterms'Length = 0 then return Primes; end if;
      Validate_Inputs (Num_Vars, Minterms, Dont_Cares);

      for M of Minterms loop
         Current_Level.Append (To_Binary (M, Num_Vars));
      end loop;
      for D of Dont_Cares loop
         Current_Level.Append (To_Binary (D, Num_Vars));
      end loop;

      loop
         Next_Level.Clear;
         for I in 1 .. Integer(Current_Level.Length) loop
            Has_Merged (I) := False;
         end loop;

         for I in 1 .. Integer(Current_Level.Length) loop
            for J in I + 1 .. Integer(Current_Level.Length) loop
               if Differs_By_One (Current_Level.Element (I), Current_Level.Element (J)) then
                  Has_Merged (I) := True;
                  Has_Merged (J) := True;
                  declare
                     Merged_Str : constant String := Merge (Current_Level.Element (I), Current_Level.Element (J));
                  begin
                     if not Next_Level.Contains (Merged_Str) then
                        Next_Level.Append (Merged_Str);
                     end if;
                  end;
               end if;
            end loop;
         end loop;

         for I in 1 .. Integer(Current_Level.Length) loop
            if not Has_Merged (I) then
               if not Primes.Contains (Current_Level.Element (I)) then
                  Primes.Append (Current_Level.Element (I));
               end if;
            end if;
         end loop;

         exit when Next_Level.Is_Empty;
         Current_Level := Next_Level;
      end loop;

      return Primes;
   end Get_Prime_Implicants;

   -----------------------------------------------------------------------------
   -- Variant 2 & 3: Prime Implicant Chart Minimization Logic
   -----------------------------------------------------------------------------
   package Integer_Vectors is new Ada.Containers.Vectors 
     (Index_Type => Positive, Element_Type => Natural);
   subtype Target_List is Integer_Vectors.Vector;

   function Solve_Chart (PIs : Implicant_List; Targets : Target_List; Exact : Boolean) return Implicant_List is
      Solution : Implicant_List;
      Remaining_Targets : Target_List := Targets;
      Active_PIs : Implicant_List := PIs;
   begin
      if Integer(Targets.Length) = 0 then return Solution; end if;

      -- 1. Find Essential Prime Implicants
      -- Replaced `for of` iterator loops with integer indexes to avoid cursor tampering locks
      declare
         Progress : Boolean := True;
      begin
         while Progress and Integer(Remaining_Targets.Length) > 0 loop
            Progress := False;
            for I in 1 .. Integer(Remaining_Targets.Length) loop
               declare
                  T : Natural := Remaining_Targets.Element(I);
                  Cover_Count : Natural := 0;
                  Last_Cover_PI_Index : Integer := 0;
               begin
                  for J in 1 .. Integer(Active_PIs.Length) loop
                     if Covers (Active_PIs.Element(J), T) then
                        Cover_Count := Cover_Count + 1;
                        Last_Cover_PI_Index := J;
                     end if;
                  end loop;

                  if Cover_Count = 1 then
                     declare
                        Last_Cover_PI : String := Active_PIs.Element(Last_Cover_PI_Index);
                        New_Remaining : Target_List;
                        New_Active : Implicant_List;
                     begin
                        Solution.Append (Last_Cover_PI);
                        Progress := True;
                        
                        for RT_Idx in 1 .. Integer(Remaining_Targets.Length) loop
                           if not Covers (Last_Cover_PI, Remaining_Targets.Element(RT_Idx)) then
                              New_Remaining.Append (Remaining_Targets.Element(RT_Idx));
                           end if;
                        end loop;
                        Remaining_Targets := New_Remaining;
                        
                        for P_Idx in 1 .. Integer(Active_PIs.Length) loop
                           if Active_PIs.Element(P_Idx) /= Last_Cover_PI then
                              New_Active.Append(Active_PIs.Element(P_Idx));
                           end if;
                        end loop;
                        Active_PIs := New_Active;
                     end;
                     exit;
                  end if;
               end;
            end loop;
         end loop;
      end;

      if Integer(Remaining_Targets.Length) = 0 then
         return Solution;
      end if;

      -- 2. Solve Cyclic Core
      if Exact then
         declare
            Min_Cover : Natural := Natural'Last;
            Best_Cover : Implicant_List;
            
            procedure Recursive_Search (Current_Remaining : Target_List; Current_PIs : Implicant_List; Current_Sol : Implicant_List) is
               Target_To_Cover : Natural;
            begin
               if Integer(Current_Remaining.Length) = 0 then
                  if Integer(Current_Sol.Length) < Min_Cover then
                     Min_Cover := Integer(Current_Sol.Length);
                     Best_Cover := Current_Sol;
                  end if;
                  return;
               end if;
               
               if Integer(Current_Sol.Length) >= Min_Cover then return; end if;

               Target_To_Cover := Current_Remaining.Element(1);
               for I in 1 .. Integer(Current_PIs.Length) loop
                  declare
                     P : String := Current_PIs.Element(I);
                  begin
                     if Covers (P, Target_To_Cover) then
                        declare
                           Next_Remaining : Target_List;
                           Next_Sol : Implicant_List := Current_Sol;
                           Next_PIs : Implicant_List;
                        begin
                           for J in 1 .. Integer(Current_Remaining.Length) loop
                              if not Covers (P, Current_Remaining.Element(J)) then 
                                 Next_Remaining.Append(Current_Remaining.Element(J)); 
                              end if;
                           end loop;
                           for J in 1 .. Integer(Current_PIs.Length) loop
                              if Current_PIs.Element(J) /= P then 
                                 Next_PIs.Append(Current_PIs.Element(J)); 
                              end if;
                           end loop;
                           Next_Sol.Append (P);
                           Recursive_Search (Next_Remaining, Next_PIs, Next_Sol);
                        end;
                     end if;
                  end;
               end loop;
            end Recursive_Search;
         begin
            Recursive_Search (Remaining_Targets, Active_PIs, Solution);
            return Best_Cover;
         end;
      else
         while Integer(Remaining_Targets.Length) > 0 loop
            if Integer(Active_PIs.Length) = 0 then exit; end if;
            declare
               Best_PI_Index : Integer := 1;
               Max_Covered : Natural := 0;
            begin
               for I in 1 .. Integer(Active_PIs.Length) loop
                  declare
                     P : String := Active_PIs.Element(I);
                     Count : Natural := 0;
                  begin
                     for J in 1 .. Integer(Remaining_Targets.Length) loop
                        if Covers (P, Remaining_Targets.Element(J)) then Count := Count + 1; end if;
                     end loop;
                     if Count > Max_Covered then
                        Max_Covered := Count;
                        Best_PI_Index := I;
                     end if;
                  end;
               end loop;

               declare
                  Best_PI : String := Active_PIs.Element(Best_PI_Index);
                  New_Remaining : Target_List;
               begin
                  Solution.Append (Best_PI);
                  for J in 1 .. Integer(Remaining_Targets.Length) loop
                     if not Covers (Best_PI, Remaining_Targets.Element(J)) then 
                        New_Remaining.Append (Remaining_Targets.Element(J)); 
                     end if;
                  end loop;
                  Remaining_Targets := New_Remaining;
               end;
            end;
         end loop;
         return Solution;
      end if;
   end Solve_Chart;

   function Minimize_Greedy 
     (Num_Vars   : Positive; 
      Minterms   : Minterm_Array; 
      Dont_Cares : Minterm_Array := Empty_Minterm_Array) return Implicant_List 
   is
      PIs : Implicant_List := Get_Prime_Implicants (Num_Vars, Minterms, Dont_Cares);
      Targets : Target_List;
   begin
      for M of Minterms loop Targets.Append (M); end loop;
      return Solve_Chart (PIs, Targets, Exact => False);
   end Minimize_Greedy;

   function Minimize_Exact 
     (Num_Vars   : Positive; 
      Minterms   : Minterm_Array; 
      Dont_Cares : Minterm_Array := Empty_Minterm_Array) return Implicant_List 
   is
      PIs : Implicant_List := Get_Prime_Implicants (Num_Vars, Minterms, Dont_Cares);
      Targets : Target_List;
   begin
      for M of Minterms loop Targets.Append (M); end loop;
      return Solve_Chart (PIs, Targets, Exact => True);
   end Minimize_Exact;

end Quine_McCluskey;
