with Ada.Containers.Ordered_Sets;
with Ada.Containers.Vectors;

package Apriori is

   --  Item_Type represents distinct items in a transaction database.
   subtype Item_Type is Positive;

   --  Item_Set represents a mathematical set of items.
   package Item_Sets is new Ada.Containers.Ordered_Sets (Element_Type => Item_Type);
   subtype Item_Set is Item_Sets.Set;

   --  Database represents the transaction list, each being an Item_Set.
   package Database_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Item_Set,
      "=" => Item_Sets."=");
   subtype Database is Database_Vectors.Vector;

   --  Domain types for algorithmic parameters and metrics.
   type Support_Count is new Natural;
   subtype Support_Ratio is Float range 0.0 .. 1.0;
   subtype Confidence_Ratio is Float range 0.0 .. 1.0;

   --  Scored_Item_Set couples an itemset with its observed support count.
   type Scored_Item_Set is record
      Items : Item_Set;
      Count : Support_Count;
   end record;

   --  Container for the generated frequent itemsets.
   package Scored_Set_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Scored_Item_Set);
   subtype Frequent_Item_Sets is Scored_Set_Vectors.Vector;

   --  Represents an inferred relationship Antecedent => Consequent.
   type Association_Rule is record
      Antecedent : Item_Set;
      Consequent : Item_Set;
      Support    : Support_Ratio;
      Confidence : Confidence_Ratio;
   end record;

   package Rule_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Association_Rule);
   subtype Rule_List is Rule_Vectors.Vector;

   --  Exceptions
   Invalid_Min_Support : exception;
   Empty_Database      : exception;
   Empty_Item_Sets     : exception;

   --  Extracts all frequent itemsets that meet the absolute minimum support.
   function Find_Frequent_Item_Sets
     (DB          : Database;
      Min_Support : Support_Count) return Frequent_Item_Sets
     with Pre => Natural (DB.Length) > 0 and Min_Support > 0;

   --  Extracts all frequent itemsets that meet the relative minimum support.
   function Find_Frequent_Item_Sets
     (DB               : Database;
      Min_Support_Rate : Support_Ratio) return Frequent_Item_Sets
     with Pre => Natural (DB.Length) > 0 and Min_Support_Rate > 0.0;

   --  Generates association rules from pre-calculated frequent itemsets.
   function Generate_Association_Rules
     (Freq_Sets      : Frequent_Item_Sets;
      DB_Size        : Positive;
      Min_Confidence : Confidence_Ratio) return Rule_List
     with Pre => Natural (Freq_Sets.Length) > 0;

   --  Filters frequent itemsets down to the maximal ones (no frequent supersets).
   function Find_Maximal_Item_Sets
     (Freq_Sets : Frequent_Item_Sets) return Frequent_Item_Sets;

   --  Filters frequent itemsets down to the closed ones (no supersets with identical support).
   function Find_Closed_Item_Sets
     (Freq_Sets : Frequent_Item_Sets) return Frequent_Item_Sets;

end Apriori;
