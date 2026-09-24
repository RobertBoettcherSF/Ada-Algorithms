with Ada.Containers.Vectors;
with Ada.Containers.Hashed_Maps;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package Hash_Join is

   -- Core Data Types for Strong Typing
   type Key_Type is new Integer;
   
   type Left_Tuple is record
      Key  : Key_Type;
      Data : Unbounded_String;
   end record;
   
   type Right_Tuple is record
      Key  : Key_Type;
      Data : Unbounded_String;
   end record;
   
   type Joined_Tuple is record
      Key        : Key_Type;
      Left_Data  : Unbounded_String;
      Right_Data : Unbounded_String;
   end record;

   -- Relation Containers (Vectors representing database tables)
   package Relation_R is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Left_Tuple);
      
   package Relation_S is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Right_Tuple);
      
   package Relation_Joined is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Joined_Tuple);

   -- Exceptions
   Invalid_Partition_Count : exception;

   -- =========================================================================
   -- Classic Hash Join (In-Memory)
   -- Builds an in-memory hash table for Relation R, then probes with Relation S.
   -- =========================================================================
   function Classic_Hash_Join 
     (R : Relation_R.Vector; 
      S : Relation_S.Vector) return Relation_Joined.Vector;

   -- =========================================================================
   -- Grace Hash Join
   -- Partitions R and S into Num_Partitions using a hash function on the key.
   -- Simulates writing to disk, then performs Classic Hash Join on each partition.
   -- =========================================================================
   function Grace_Hash_Join 
     (R              : Relation_R.Vector; 
      S              : Relation_S.Vector;
      Num_Partitions : Natural) return Relation_Joined.Vector;

   -- =========================================================================
   -- Hybrid Hash Join
   -- Keeps Partition 0 of R in memory during the partition phase. Probes 
   -- Partition 0 of S immediately. Spills remaining partitions to "disk" and 
   -- joins them via Classic Hash Join.
   -- =========================================================================
   function Hybrid_Hash_Join 
     (R              : Relation_R.Vector; 
      S              : Relation_S.Vector;
      Num_Partitions : Natural) return Relation_Joined.Vector;

end Hash_Join;
