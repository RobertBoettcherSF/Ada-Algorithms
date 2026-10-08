pragma Ada_2022;
with Ada.Containers.Ordered_Sets;
with Ada.Containers.Vectors;

package Fp_Growth is

   --  Item_Type represents a unique identifier for an item in a transaction.
   subtype Item_Type is Positive;

   --  Item_Sets provides sorted mathematical sets of items.
   package Item_Sets is new Ada.Containers.Ordered_Sets (Element_Type => Item_Type);
   subtype Item_Set is Item_Sets.Set;

   --  Transaction_Database is an ordered list of Item_Sets (transactions).
   package Transaction_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Item_Set,
      "="          => Item_Sets."=");
   subtype Transaction_Database is Transaction_Vectors.Vector;

   --  Frequent_Itemset stores a discovered frequent pattern and its support count.
   type Frequent_Itemset is record
      Items   : Item_Set;
      Support : Natural;
   end record;

   package Itemset_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Frequent_Itemset);
   subtype Frequent_Itemset_List is Itemset_Vectors.Vector;

   --  Association_Rule represents a derived rule (Antecedent => Consequent).
   type Association_Rule is record
      Antecedent : Item_Set;
      Consequent : Item_Set;
      Support    : Natural;
      Confidence : Float;
   end record;

   package Rule_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Association_Rule);
   subtype Association_Rule_List is Rule_Vectors.Vector;

   --  Exceptions for invalid usage.
   Empty_Database_Error     : exception;
   Invalid_Threshold_Error  : exception;

   --  Core Algorithm: Mine frequent itemsets using the FP-Growth approach.
   --  Builds an in-memory FP-Tree and recursively mines conditional pattern bases.
   function Mine_Frequent_Itemsets
     (DB          : Transaction_Database;
      Min_Support : Positive) return Frequent_Itemset_List;

   --  Rule Generation Variant: Extract high-confidence association rules
   --  from an already mined list of frequent itemsets.
   function Generate_Association_Rules
     (Itemsets       : Frequent_Itemset_List;
      Min_Confidence : Float) return Association_Rule_List;

   --  Dynamic Variant: Full pipeline from raw database directly to rules.
   function Mine_Association_Rules
     (DB             : Transaction_Database;
      Min_Support    : Positive;
      Min_Confidence : Float) return Association_Rule_List;

end Fp_Growth;
