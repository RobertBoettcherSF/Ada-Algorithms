-- tarski_kuratowski.adb
-- Implementation of the Tarski-Kuratowski Algorithm

package body Tarski_Kuratowski is

   -----------------------------------------------------------------------------
   -- Evaluate_Arithmetical
   -- Analyzes the prefix for Arithmetical Hierarchy (Σ^0_n, Π^0_n, Δ^0_n)
   -----------------------------------------------------------------------------
   function Evaluate_Arithmetical (Prefix : Quantifier_Prefix) return Complexity_Bound is
      Current_Level : Natural := 0;
      Current_Class : Complexity_Class := Class_Delta;
      Last_Q_Type   : Quantifier_Type;
   begin
      -- Base Case: Quantifier-free formulas are Δ^0_0
      if Prefix'Length = 0 then
         return (Class => Class_Delta, Level => 0, V_Order => First_Order);
      end if;

      for I in Prefix'Range loop
         -- Validate strict Arithmetical constraint
         if Prefix(I).V_Order = Second_Order then
            raise Invalid_Hierarchy_Prefix with "Second_Order quantifier found in Arithmetical evaluation.";
         end if;

         if Current_Level = 0 then
            -- Initialize first block
            Last_Q_Type := Prefix(I).Q_Type;
            Current_Level := 1;
            if Last_Q_Type = Existential then
               Current_Class := Class_Sigma;
            else
               Current_Class := Class_Pi;
            end if;
         elsif Prefix(I).Q_Type /= Last_Q_Type then
            -- Alternation found: increase level and collapse blocks
            Last_Q_Type := Prefix(I).Q_Type;
            Current_Level := Current_Level + 1;
         end if;
         -- Note: Identical consecutive quantifiers (e.g., Exists Exists) 
         -- are automatically collapsed (level does not increase).
      end loop;

      return (Class => Current_Class, Level => Current_Level, V_Order => First_Order);
   end Evaluate_Arithmetical;

   -----------------------------------------------------------------------------
   -- Evaluate_Analytical
   -- Analyzes the prefix for Analytical Hierarchy (Σ^1_n, Π^1_n, Δ^1_n)
   -----------------------------------------------------------------------------
   function Evaluate_Analytical (Prefix : Quantifier_Prefix) return Complexity_Bound is
      Current_Level      : Natural := 0;
      Current_Class      : Complexity_Class := Class_Delta;
      Last_Q_Type        : Quantifier_Type;
      Found_Second_Order : Boolean := False;
   begin
      if Prefix'Length = 0 then
         return (Class => Class_Delta, Level => 1, V_Order => Second_Order); -- Empty is Δ^1_1 generally
      end if;

      for I in Prefix'Range loop
         -- In the analytical hierarchy, we ONLY count alternations of Second_Order quantifiers.
         -- First_Order quantifiers do not push a formula higher in the analytical hierarchy.
         if Prefix(I).V_Order = Second_Order then
            if not Found_Second_Order then
               -- First Second_Order quantifier encountered
               Found_Second_Order := True;
               Last_Q_Type := Prefix(I).Q_Type;
               Current_Level := 1;
               if Last_Q_Type = Existential then
                  Current_Class := Class_Sigma;
               else
                  Current_Class := Class_Pi;
               end if;
            elsif Prefix(I).Q_Type /= Last_Q_Type then
               -- Alternation of Second_Order quantifiers
               Last_Q_Type := Prefix(I).Q_Type;
               Current_Level := Current_Level + 1;
            end if;
         end if;
      end loop;

      -- If the formula was purely arithmetical but passed to the analytical evaluator,
      -- it bounds to Δ^1_1
      if not Found_Second_Order then
         return (Class => Class_Delta, Level => 1, V_Order => Second_Order);
      end if;

      return (Class => Current_Class, Level => Current_Level, V_Order => Second_Order);
   end Evaluate_Analytical;

   -----------------------------------------------------------------------------
   -- Get_Upper_Bound
   -- Dynamic routing based on prefix content
   -----------------------------------------------------------------------------
   function Get_Upper_Bound (Prefix : Quantifier_Prefix) return Complexity_Bound is
      Has_Second_Order : Boolean := False;
   begin
      -- Scan for domain to choose the correct variant
      for I in Prefix'Range loop
         if Prefix(I).V_Order = Second_Order then
            Has_Second_Order := True;
            exit;
         end if;
      end loop;

      if Has_Second_Order then
         return Evaluate_Analytical (Prefix);
      else
         return Evaluate_Arithmetical (Prefix);
      end if;
   end Get_Upper_Bound;

end Tarski_Kuratowski;
