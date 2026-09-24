with Ada.Containers.Ordered_Sets;
with Ada.Containers.Vectors;

package Association_Rules is

   -- Domain-specific strong types
   type Item_ID is new Positive;
   type Support_Value is new Float range 0.0 .. 1.0;
   type Metric_Value is new Float;

   -- Item sets representing transactions or groups of items
   package Item_Sets is new Ada.Containers.Ordered_Sets (Element_Type => Item_ID);
   subtype Item_Set is Item_Sets.Set;

   -- Vectors for lists of Item_Sets (used for combinations and frequent sets)
   package Item_Set_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Item_Set, "=" => Item_Sets."=");
   subtype Item_Set_List is Item_Set_Vectors.Vector;

   -- Database definition: A collection of Item_Sets (transactions)
   package Database_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Item_Set, "=" => Item_Sets."=");
   subtype Database is Database_Vectors.Vector;

   -- Association Rule definition (Antecedent -> Consequent)
   type Association_Rule is record
      Antecedent : Item_Set;
      Consequent : Item_Set;
   end record;

   package Rule_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Association_Rule);
   subtype Rule_List is Rule_Vectors.Vector;

   -- Specific Exceptions for edge cases and errors
   Zero_Support_Error       : exception;
   Perfect_Confidence_Error : exception;

   -- =========================================================================
   -- Association Rule Metrics
   -- =========================================================================

   -- Calculates the support (frequency proportion) of an itemset in the database.
   function Support (DB : Database; Set : Item_Set) return Support_Value
     with Pre => not DB.Is_Empty and then not Set.Is_Empty,
          Global => null;

   -- Calculates the confidence of a rule: Support(A U C) / Support(A)
   function Confidence (DB : Database; Rule : Association_Rule) return Support_Value
     with Pre => not DB.Is_Empty and then not Rule.Antecedent.Is_Empty and then not Rule.Consequent.Is_Empty,
          Global => null;

   -- Calculates the lift of a rule: Confidence(A -> C) / Support(C)
   function Lift (DB : Database; Rule : Association_Rule) return Metric_Value
     with Pre => not DB.Is_Empty and then not Rule.Antecedent.Is_Empty and then not Rule.Consequent.Is_Empty,
          Global => null;

   -- Calculates conviction: (1 - Support(C)) / (1 - Confidence(A -> C))
   function Conviction (DB : Database; Rule : Association_Rule) return Metric_Value
     with Pre => not DB.Is_Empty and then not Rule.Antecedent.Is_Empty and then not Rule.Consequent.Is_Empty,
          Global => null;

   -- Calculates leverage: Support(A U C) - (Support(A) * Support(C))
   function Leverage (DB : Database; Rule : Association_Rule) return Metric_Value
     with Pre => not DB.Is_Empty and then not Rule.Antecedent.Is_Empty and then not Rule.Consequent.Is_Empty,
          Global => null;

   -- =========================================================================
   -- Frequent Itemset Generation Algorithms
   -- =========================================================================

   -- The standard Apriori algorithm variant. Uses level-wise generation and pruning.
   function Apriori
     (DB : Database;
      Min_Support : Support_Value) return Item_Set_List
     with Pre => not DB.Is_Empty,
          Global => null;

   -- A Brute-Force alternative variant to find frequent itemsets.
   -- (Evaluates the full power set of all unique items present in the DB).
   function Brute_Force_Frequent_Itemsets
     (DB : Database;
      Min_Support : Support_Value) return Item_Set_List
     with Pre => not DB.Is_Empty,
          Global => null;

   -- =========================================================================
   -- Rule Generation
   -- =========================================================================

   -- Generates strong association rules from a list of frequent itemsets.
   function Generate_Rules
     (DB : Database;
      Frequent_Itemsets : Item_Set_List;
      Min_Confidence    : Support_Value) return Rule_List
     with Pre => not DB.Is_Empty,
          Global => null;

end Association_Rules;
