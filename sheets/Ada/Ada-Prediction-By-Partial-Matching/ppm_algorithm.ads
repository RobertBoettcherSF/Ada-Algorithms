with Ada.Unchecked_Deallocation;

package PPM_Algorithm is

   -- Variants mathematically identified in the Wikipedia article and standard literature
   type Estimation_Variant is 
     (Laplace_Estimator, -- PPM-A: Fixed pseudocount of 1
      PPMd_Estimator,    -- PPM-D: Ratio of unique to total (q / 2n)
      PPM_B_Estimator,   -- PPM-B: (c-1)/n with q/n escape
      PPM_C_Estimator);  -- PPM-C: c/(n+q) with q/(n+q) escape

   type Context_Order is range 0 .. 10_000;
   Order_Unbounded : constant Context_Order := 10_000; -- Used to represent PPM*

   -- Restrict to standard ASCII for fast, bounded memory arrays during modeling
   subtype Symbol is Character range Character'Val(0) .. Character'Val(127);
   type Symbol_String is array (Positive range <>) of Symbol;

   -- Using Float for calculating blended arithmetic modeling distribution
   type Probability is new Float range 0.0 .. 1.0;
   type Distribution is array (Symbol) of Probability;

   type Model_Result is record
      Probs       : Distribution := (others => 0.0);
      Escape_Prob : Probability := 0.0;
   end record;

   type Symbol_Counts is array (Symbol) of Natural;
   type Context_Model is record
      Counts         : Symbol_Counts := (others => 0);
      Total_Count    : Natural := 0;
      Unique_Symbols : Natural := 0;
   end record;

   -- Core operation
   procedure Update_Model (Model : in out Context_Model; S : Symbol);

   -- Probability Estimators for different variants
   procedure Estimate_Laplace (Model : in Context_Model; Result : out Model_Result);
   procedure Estimate_PPMd    (Model : in Context_Model; Result : out Model_Result);
   procedure Estimate_PPM_B   (Model : in Context_Model; Result : out Model_Result);
   procedure Estimate_PPM_C   (Model : in Context_Model; Result : out Model_Result);

   -- Trie node implementation for Context tree
   type Trie_Node;
   type Trie_Access is access Trie_Node;
   type Trie_Node_Children is array (Symbol) of Trie_Access;

   type Trie_Node is record
      Model    : Context_Model;
      Children : Trie_Node_Children := (others => null);
   end record;

   type PPM_Predictor is record
      Root        : Trie_Access;
      Max_Order   : Context_Order;
      Variant     : Estimation_Variant;
   end record;

   -- Instantiates the tree. Using Max_Order = Order_Unbounded operates as PPM*
   procedure Initialize_Predictor
     (Predictor : out PPM_Predictor;
      Order     : Context_Order;
      Variant   : Estimation_Variant);

   -- Integrates the observed string into the Context Trie
   procedure Update_Predictor
     (Predictor : in out PPM_Predictor;
      History   : in Symbol_String;
      Next_Sym  : in Symbol);

   -- Simulates an arithmetic coder's view by resolving/blending the context tree
   function Calculate_Blended_Distribution
     (Predictor : PPM_Predictor;
      History   : Symbol_String) return Distribution;

   -- Safe memory reclamation
   procedure Free_Predictor (Predictor : in out PPM_Predictor);

   -- String Helper
   function To_Symbol_String (S : String) return Symbol_String;

end PPM_Algorithm;
