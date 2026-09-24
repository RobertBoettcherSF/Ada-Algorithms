package body Apriori is

   --  Bring the equality operator for the ordered set into visibility
   use type Item_Sets.Set;

   --  Internal container for managing intermediate combinations (Candidates)
   package Item_Set_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Item_Set,
      "=" => Item_Sets."=");

   --  Helper: Counts occurrences of a specific itemset in the given database.
   function Get_Support (DB : Database; Candidate : Item_Set) return Support_Count is
      Count : Natural := 0;
   begin
      for T of DB loop
         if Candidate.Is_Subset (T) then
            Count := Count + 1;
         end if;
      end loop;
      return Support_Count (Count);
   end Get_Support;

   --  Helper: Verifies if a given Candidate Set is present in a Vector of Item_Sets.
   function Contains_Candidate
     (Vec    : Item_Set_Vectors.Vector;
      Target : Item_Set) return Boolean
   is
   begin
      for V of Vec loop
         if V = Target then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Candidate;

   --  Helper: Verifies if a given Candidate Set is present in a Vector of Scored_Item_Sets.
   function Contains_Frequent
     (Vec    : Scored_Set_Vectors.Vector;
      Target : Item_Set) return Boolean
   is
   begin
      for V of Vec loop
         if V.Items = Target then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Frequent;

   --  Helper: The Apriori Pruning rule checks if all (K-1) subsets of the candidate
   --  are present in the previously discovered frequent itemsets (L_Prev).
   function Prune_Check
     (Candidate : Item_Set;
      L_Prev    : Scored_Set_Vectors.Vector) return Boolean
   is
   begin
      for E of Candidate loop
         declare
            Subset : Item_Set := Candidate;
         begin
            Subset.Exclude (E);
            if not Contains_Frequent (L_Prev, Subset) then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Prune_Check;

   --  Helper: Generates all proper, non-empty subsets for a given frequent itemset.
   --  Used to build Antecedent/Consequent pairs for association rules.
   function Get_All_Subsets (Set : Item_Set) return Item_Set_Vectors.Vector is
      Result   : Item_Set_Vectors.Vector;
      Count    : constant Natural := Natural (Set.Length);
      Elements : array (1 .. Count) of Item_Type;
      Idx      : Positive := 1;
   begin
      if Count < 2 then
         return Result;
      end if;

      for E of Set loop
         Elements (Idx) := E;
         Idx := Idx + 1;
      end loop;

      --  Iterate from 1 to (2^Count - 2) to skip 0 (empty set) and 2^N-1 (full set).
      for I in 1 .. 2**Count - 2 loop
         declare
            Sub : Item_Set;
            Val : Natural := I;
         begin
            for Bit in 0 .. Count - 1 loop
               if Val mod 2 = 1 then
                  Sub.Insert (Elements (Bit + 1));
               end if;
               Val := Val / 2;
            end loop;
            Result.Append (Sub);
         end;
      end loop;
      return Result;
   end Get_All_Subsets;

   --  Main Implementation: Apriori algorithm with absolute support.
   function Find_Frequent_Item_Sets
     (DB          : Database;
      Min_Support : Support_Count) return Frequent_Item_Sets
   is
      Result       : Frequent_Item_Sets;
      L_Prev       : Scored_Set_Vectors.Vector;
      Unique_Items : Item_Sets.Set;
      K            : Natural := 2;
   begin
      if Natural (DB.Length) = 0 then
         raise Empty_Database;
      end if;
      if Min_Support = 0 then
         raise Invalid_Min_Support;
      end if;

      --  Step 1: Determine L_1 (Frequent 1-itemsets)
      for T of DB loop
         for Item of T loop
            Unique_Items.Include (Item);
         end loop;
      end loop;

      for Item of Unique_Items loop
         declare
            Single : Item_Set;
            Sup    : Support_Count;
         begin
            Single.Insert (Item);
            Sup := Get_Support (DB, Single);
            if Sup >= Min_Support then
               L_Prev.Append (Scored_Item_Set'(Items => Single, Count => Sup));
               Result.Append (Scored_Item_Set'(Items => Single, Count => Sup));
            end if;
         end;
      end loop;

      --  Step 2: Iteratively find L_K for K >= 2
      loop
         exit when L_Prev.Is_Empty;

         declare
            C_k : Item_Set_Vectors.Vector;
            L_k : Scored_Set_Vectors.Vector;
         begin
            --  Candidate Generation (Apriori-Gen Join Step)
            for I in 1 .. L_Prev.Last_Index loop
               for J in I + 1 .. L_Prev.Last_Index loop
                  declare
                     S1 : constant Item_Set := L_Prev.Element (I).Items;
                     S2 : constant Item_Set := L_Prev.Element (J).Items;
                     U  : constant Item_Set := Item_Sets.Union (S1, S2);
                  begin
                     if Natural (U.Length) = K then
                        --  Candidate Pruning Step
                        if Prune_Check (U, L_Prev) then
                           if not Contains_Candidate (C_k, U) then
                              C_k.Append (U);
                           end if;
                        end if;
                     end if;
                  end;
               end loop;
            end loop;

            --  Candidate Counting & L_k Filtering
            for Candidate of C_k loop
               declare
                  Sup : constant Support_Count := Get_Support (DB, Candidate);
               begin
                  if Sup >= Min_Support then
                     L_k.Append (Scored_Item_Set'(Items => Candidate, Count => Sup));
                     Result.Append (Scored_Item_Set'(Items => Candidate, Count => Sup));
                  end if;
               end;
            end loop;

            L_Prev := L_k;
         end;
         K := K + 1;
      end loop;

      return Result;
   end Find_Frequent_Item_Sets;

   --  Overload: Apriori algorithm with relative support ratio.
   function Find_Frequent_Item_Sets
     (DB               : Database;
      Min_Support_Rate : Support_Ratio) return Frequent_Item_Sets
   is
      Min_Sup_Float : constant Float := Float (Min_Support_Rate) * Float (DB.Length);
      Min_Sup       : Support_Count;
   begin
      if Natural (DB.Length) = 0 then
         raise Empty_Database;
      end if;

      Min_Sup := Support_Count (Float'Ceiling (Min_Sup_Float));
      if Min_Sup = 0 and Min_Support_Rate > 0.0 then
         Min_Sup := 1;
      end if;

      return Find_Frequent_Item_Sets (DB, Min_Sup);
   end Find_Frequent_Item_Sets;

   --  Extracts strong association rules based on confidence thresholds.
   function Generate_Association_Rules
     (Freq_Sets      : Frequent_Item_Sets;
      DB_Size        : Positive;
      Min_Confidence : Confidence_Ratio) return Rule_List
   is
      Rules : Rule_List;
   begin
      if Natural (Freq_Sets.Length) = 0 then
         raise Empty_Item_Sets;
      end if;

      for Freq of Freq_Sets loop
         if Natural (Freq.Items.Length) >= 2 then
            declare
               Subsets : constant Item_Set_Vectors.Vector := Get_All_Subsets (Freq.Items);
            begin
               for Antecedent of Subsets loop
                  declare
                     Consequent : Item_Set := Freq.Items;
                     Ant_Count  : Support_Count := 0;
                  begin
                     for E of Antecedent loop
                        Consequent.Exclude (E);
                     end loop;

                     --  Locate Antecedent in Freq_Sets to grab its support count
                     for F of Freq_Sets loop
                        if F.Items = Antecedent then
                           Ant_Count := F.Count;
                           exit;
                        end if;
                     end loop;

                     if Ant_Count > 0 then
                        declare
                           Conf : constant Confidence_Ratio :=
                             Confidence_Ratio (Float (Freq.Count) / Float (Ant_Count));
                           Sup  : constant Support_Ratio :=
                             Support_Ratio (Float (Freq.Count) / Float (DB_Size));
                        begin
                           if Conf >= Min_Confidence then
                              Rules.Append
                                (Association_Rule'
                                   (Antecedent => Antecedent,
                                    Consequent => Consequent,
                                    Support    => Sup,
                                    Confidence => Conf));
                           end if;
                        end;
                     end if;
                  end;
               end loop;
            end;
         end if;
      end loop;

      return Rules;
   end Generate_Association_Rules;

   --  Derives maximal itemsets by rejecting any set that acts as a subset for another frequent set.
   function Find_Maximal_Item_Sets
     (Freq_Sets : Frequent_Item_Sets) return Frequent_Item_Sets
   is
      Result     : Frequent_Item_Sets;
      Is_Maximal : Boolean;
   begin
      for I in 1 .. Freq_Sets.Last_Index loop
         Is_Maximal := True;
         for J in 1 .. Freq_Sets.Last_Index loop
            if I /= J then
               if Freq_Sets.Element (I).Items.Is_Subset (Freq_Sets.Element (J).Items) then
                  Is_Maximal := False;
                  exit;
               end if;
            end if;
         end loop;
         if Is_Maximal then
            Result.Append (Freq_Sets.Element (I));
         end if;
      end loop;
      return Result;
   end Find_Maximal_Item_Sets;

   --  Derives closed itemsets by rejecting any set that has a superset with identical support.
   function Find_Closed_Item_Sets
     (Freq_Sets : Frequent_Item_Sets) return Frequent_Item_Sets
   is
      Result    : Frequent_Item_Sets;
      Is_Closed : Boolean;
   begin
      for I in 1 .. Freq_Sets.Last_Index loop
         Is_Closed := True;
         for J in 1 .. Freq_Sets.Last_Index loop
            if I /= J then
               if Freq_Sets.Element (I).Items.Is_Subset (Freq_Sets.Element (J).Items)
                 and then Freq_Sets.Element (I).Count = Freq_Sets.Element (J).Count
               then
                  Is_Closed := False;
                  exit;
               end if;
            end if;
         end loop;
         if Is_Closed then
            Result.Append (Freq_Sets.Element (I));
         end if;
      end loop;
      return Result;
   end Find_Closed_Item_Sets;

end Apriori;
