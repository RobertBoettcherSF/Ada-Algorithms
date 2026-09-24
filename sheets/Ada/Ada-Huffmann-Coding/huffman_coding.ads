-- huffman_coding.ads
-- Specification for Huffman Coding algorithm and its variants.
-- Implements Standard (Static) and Canonical Huffman, with stubs for Dynamic.

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Containers.Ordered_Maps;

package Huffman_Coding is

   -- Strong typing for algorithm-specific data
   type Frequency_Type is new Natural;
   
   -- We use Unbounded_String for varying length binary codes
   
   -- Container for character frequencies
   package Frequency_Maps is new Ada.Containers.Ordered_Maps
     (Key_Type => Character, Element_Type => Frequency_Type);
   subtype Frequency_Map is Frequency_Maps.Map;

   -- Container for symbol to binary code mapping
   package Code_Maps is new Ada.Containers.Ordered_Maps
     (Key_Type => Character, Element_Type => Unbounded_String);
   subtype Code_Map is Code_Maps.Map;

   -- Node structure for the Huffman Tree
   type Huffman_Node;
   type Tree_Access is access Huffman_Node;
   type Huffman_Node is record
      Symbol : Character := ASCII.NUL;
      Weight : Frequency_Type := 0;
      Left   : Tree_Access := null;
      Right  : Tree_Access := null;
   end record;

   -- Exceptions for error handling and edge cases
   Invalid_Tree     : exception;
   Empty_Input      : exception;
   Data_Error       : exception;
   Not_Implemented  : exception;

   -- =========================================================================
   -- Helper Functions
   -- =========================================================================
   
   -- Generates a frequency map from an input string
   function Get_Frequencies (Text : String) return Frequency_Map;

   -- =========================================================================
   -- Variant 1: Standard / Static Huffman Coding
   -- =========================================================================
   
   -- Builds the Huffman Tree using a Min-Priority logic based on frequencies
   function Build_Tree (Frequencies : Frequency_Map) return Tree_Access;
   
   -- Traverses the tree to generate prefix codes for each character
   function Generate_Codes (Tree : Tree_Access) return Code_Map;
   
   -- Encodes a plaintext string into a binary string ("10101...")
   function Encode (Text : String; Codes : Code_Map) return String;
   
   -- Decodes a binary string back to plaintext using the Huffman Tree
   function Decode (Encoded_Text : String; Tree : Tree_Access) return String;

   -- Safely deallocates the tree to prevent memory leaks
   procedure Free_Tree (Tree : in out Tree_Access);

   -- =========================================================================
   -- Variant 2: Canonical Huffman Coding
   -- =========================================================================
   
   -- Converts standard codes into Canonical Huffman codes by ordering 
   -- lengths and sequentially assigning values. 
   function Generate_Canonical_Codes (Standard_Codes : Code_Map) return Code_Map;

   -- =========================================================================
   -- Variant 3: Adaptive / Dynamic Huffman Coding (FGK / Vitter)
   -- =========================================================================
   -- Note: Full dynamic implementation requires complex real-time node swapping. 
   -- This acts as a placeholder demonstrating architectural capability for variants.
   procedure Encode_Adaptive (Text : String; Result : out Unbounded_String);

end Huffman_Coding;
