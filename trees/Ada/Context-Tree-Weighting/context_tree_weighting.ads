-- context_tree_weighting.ads
-- Specification for the Context Tree Weighting (CTW) algorithm.
-- Supports Preemptive/Static (Bounded Depth) and Zero-Order Variants.

package Context_Tree_Weighting is

   -- Strong typing for algorithm-specific data
   type Bit is range 0 .. 1;
   type Bit_Array is array (Positive range <>) of Bit;

   -- Opaque type to encapsulate the Context Tree state
   type Context_Tree is private;

   -- Exceptions
   Tree_Uninitialized : exception;
   Invalid_Depth      : exception;

   -- Initialize a new Context Tree with a given maximum context depth
   -- Variant: Bounded depth (Zero-M tree variant from Wikipedia)
   -- Using Max_Depth = 0 represents the Zero-Order memoryless variant
   function Initialize_Tree (Max_Depth : Natural) return Context_Tree;

   -- Free memory associated with the Context Tree to prevent leaks
   procedure Free_Tree (Tree : in out Context_Tree);

   -- Update the Context Tree with a new observed bit.
   -- Context contains the recent history (Context(Context'Last) is the most recent bit).
   procedure Update
     (Tree     : in out Context_Tree;
      Context  : in Bit_Array;
      Next_Bit : in Bit);

   -- Retrieve the weighted probability (P_w) of the sequence at the root
   function Get_Weighted_Probability (Tree : Context_Tree) return Long_Float;

   -- Retrieve the Krichevsky-Trofimov (K-T) estimated probability (P_e) at the root
   function Get_KT_Probability (Tree : Context_Tree) return Long_Float;

private

   type Node;
   type Node_Access is access Node;

   -- Node structure representing context states and keeping K-T counters
   type Node is record
      Count_0 : Natural := 0;
      Count_1 : Natural := 0;
      P_e     : Long_Float := 1.0; -- K-T Estimated Probability
      P_w     : Long_Float := 1.0; -- Weighted Probability
      Child_0 : Node_Access := null;
      Child_1 : Node_Access := null;
   end record;

   type Context_Tree is record
      Root           : Node_Access := null;
      Max_Depth      : Natural     := 0;
      Is_Initialized : Boolean     := False;
   end record;

end Context_Tree_Weighting;
