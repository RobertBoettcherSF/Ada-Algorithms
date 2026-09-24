package body Association_Rules is

   -- -------------------------------------------------------------------------
   -- Helper procedure to generate the power set of a given Item_Set (excluding empty set)
   -- Used by Brute_Force and Generate_Rules
   -- -------------------------------------------------------------------------
   procedure Generate_Power_Set (Elements : Item_Set; Result : out Item_Set_List) is
      Items : array (1 .. Natural (Elements.Length)) of Item_ID;
      Idx   : Natural := 1;
   begin
      Result.Clear;
      
      -- We enforce a limit here as 2^N grows too quickly for naive brute force 
      pragma Assert (Items'Length < 31, "Item set too large for power set generation");

      for E of Elements loop
         Items (Idx) := E;
         Idx := Idx + 1;
      end loop;

      -- Iterate 1 to 2^N - 1 to extract all non-empty subsets
      for I in 1 .. (2**Items'Length) - 1 loop
         declare
            S   : Item_Set;
            Val : Natural := I;
         begin
            for J in Items'Range loop
               if Val mod 2 = 1 then
                  S.Insert (Items (J));
               end if;
               Val := Val / 2;
            end loop;
            Result.Append (S);
         end;
      end loop;
   end Generate_Power_Set;

   -- -------------------------------------------------------------------------
   -- Metrics Implementations
   -- -------------------------------------------------------------------------
   
   function Support (DB : Database; Set : Item_Set) return Support_Value is
      Count : Natural := 0;
   begin
      for Transaction of DB loop
         if Set.Is_Subset (Transaction) then
            Count := Count + 1;
         end if;
      end loop;
      
      return Support_Value (Float (Count) / Float (DB.Length));
   end Support;

   function Confidence (DB : Database; Rule : Association_Rule) return Support_Value is
      Ant_Sup   : constant Support_Value := Support (DB, Rule.Antecedent);
      Union_Set : Item_Set := Rule.Antecedent;
   begin
      if Ant_Sup = 0.0 then
         raise Zero_Support_Error with "Antecedent support is zero, cannot compute Confidence";
      end if;
      
      Union_Set.Union (Rule.Consequent);
      return Support (DB, Union_Set) / Ant_Sup;
   end Confidence;

   function Lift (DB : Database; Rule : Association_Rule) return Metric_Value is
      Ant_Sup   : constant Support_Value := Support (DB, Rule.Antecedent);
      Con_Sup   : constant Support_Value := Support (DB, Rule.Consequent);
      Union_Set : Item_Set := Rule.Antecedent;
   begin
      if Ant_Sup = 0.0 or else Con_Sup = 0.0 then
         raise Zero_Support_Error with "Zero support in antecedent or consequent";
      end if;
      
      Union_Set.Union (Rule.Consequent);
      return Metric_Value (Support (DB, Union_Set)) / Metric_Value (Ant_Sup * Con_Sup);
   end Lift;

   function Conviction (DB : Database; Rule : Association_Rule) return Metric_Value is
      Conf    : constant Support_Value := Confidence (DB, Rule);
      Con_Sup : constant Support_Value := Support (DB, Rule.Consequent);
   begin
      if Conf = 1.0 then
         raise Perfect_Confidence_Error with "Confidence is 1.0; Conviction is infinite";
      end if;
      
      return Metric_Value (1.0 - Float (Con_Sup)) / Metric_Value (1.0 - Float (Conf));
   end Conviction;

   function Leverage (DB : Database; Rule : Association_Rule) return Metric_Value is
      Ant_Sup   : constant Support_Value := Support (DB, Rule.Antecedent);
      Con_Sup   : constant Support_Value := Support (DB, Rule.Consequent);
      Union_Set : Item_Set := Rule.Antecedent;
   begin
      Union_Set.Union (Rule.Consequent);
      return Metric_Value (Support (DB, Union_Set)) - Metric_Value (Ant_Sup * Con_Sup);
   end Leverage;

   -- -------------------------------------------------------------------------
   -- Frequent Itemset Variants
   -- -------------------------------------------------------------------------

   function Apriori
     (DB : Database;
      Min_Support : Support_Value) return Item_Set_List
   is
      Result    : Item_Set_List;
      L_Prev    : Item_Set_List;
      L_Current : Item_Set_List;
      L1_Items  : Item_Set;
      
      -- Initial unique item gathering
      Unique_Items : Item_Set;
   begin
      -- 1. Identify all individual items in the database
      for Transaction of DB loop
         Unique_Items.Union (Transaction);
      end loop;

      -- 2. Construct L1 (Frequent 1-itemsets)
      for Item of Unique_Items loop
         declare
            S   : Item_Set;
            Sup : Support_Value;
         begin
            S.Insert (Item);
            Sup := Support (DB, S);
            if Sup >= Min_Support then
               L_Prev.Append (S);
               Result.Append (S);
               L1_Items.Insert (Item);
            end if;
         end;
      end loop;

      -- 3. Iteratively generate L_k from L_{k-1}
      while not L_Prev.Is_Empty loop
         L_Current.Clear;

         for I in 1 .. Natural (L_Prev.Length) loop
            declare
               Base_Set : constant Item_Set := L_Prev.Element (I);
               Max_Item : constant Item_ID  := Base_Set.Last_Element;
            begin
               -- Only append frequent items strictly greater than current max to ensure no duplicates
               for Single of L1_Items loop
                  if Single > Max_Item then
                     declare
                        Candidate : Item_Set := Base_Set;
                        All_Valid : Boolean := True;
                     begin
                        Candidate.Insert (Single);

                        -- PRUNING: Ensure all (k-1) subsets of Candidate exist in L_{k-1}
                        for Item_To_Drop of Candidate loop
                           declare
                              Subset : Item_Set := Candidate;
                           begin
                              Subset.Exclude (Item_To_Drop);
                              if not L_Prev.Contains (Subset) then
                                 All_Valid := False;
                                 exit;
                              end if;
                           end;
                        end loop;

                        -- If not pruned, verify its support against the Database
                        if All_Valid then
                           if Support (DB, Candidate) >= Min_Support then
                              L_Current.Append (Candidate);
                              Result.Append (Candidate);
                           end if;
                        end if;
                     end;
                  end if;
               end loop;
            end;
         end loop;

         L_Prev := L_Current;
      end loop;

      return Result;
   end Apriori;

   function Brute_Force_Frequent_Itemsets
     (DB : Database;
      Min_Support : Support_Value) return Item_Set_List
   is
      Result       : Item_Set_List;
      Unique_Items : Item_Set;
      Power_Set    : Item_Set_List;
   begin
      -- Extract all possible items
      for Transaction of DB loop
         Unique_Items.Union (Transaction);
      end loop;

      -- Generate all mathematical subsets
      Generate_Power_Set (Unique_Items, Power_Set);

      -- Check support for every single subset (exponential time complexity)
      for I in 1 .. Natural (Power_Set.Length) loop
         declare
            Candidate : constant Item_Set := Power_Set.Element (I);
         begin
            if Support (DB, Candidate) >= Min_Support then
               Result.Append (Candidate);
            end if;
         end;
      end loop;

      return Result;
   end Brute_Force_Frequent_Itemsets;

   -- -------------------------------------------------------------------------
   -- Rule Generation Algorithm
   -- -------------------------------------------------------------------------

   function Generate_Rules
     (DB : Database;
      Frequent_Itemsets : Item_Set_List;
      Min_Confidence    : Support_Value) return Rule_List
   is
      Result : Rule_List;
   begin
      for I in 1 .. Natural (Frequent_Itemsets.Length) loop
         declare
            FS : constant Item_Set := Frequent_Itemsets.Element (I);
         begin
            -- Rules require at least 2 items to form Antecedent -> Consequent
            if Natural (FS.Length) > 1 then
               declare
                  Subsets : Item_Set_List;
               begin
                  Generate_Power_Set (FS, Subsets);
                  
                  for J in 1 .. Natural (Subsets.Length) loop
                     declare
                        Ant : constant Item_Set := Subsets.Element (J);
                     begin
                        -- Ensure proper subset to leave something for the consequent
                        if Natural (Ant.Length) > 0 and then Natural (Ant.Length) < Natural (FS.Length) then
                           declare
                              Con : Item_Set := FS;
                              R   : Association_Rule;
                           begin
                              Con.Difference (Ant);
                              R.Antecedent := Ant;
                              R.Consequent := Con;
                              
                              if Confidence (DB, R) >= Min_Confidence then
                                 Result.Append (R);
                              end if;
                           end;
                        end if;
                     end;
                  end loop;
               end;
            end if;
         end;
      end loop;
      
      return Result;
   end Generate_Rules;

end Association_Rules;
