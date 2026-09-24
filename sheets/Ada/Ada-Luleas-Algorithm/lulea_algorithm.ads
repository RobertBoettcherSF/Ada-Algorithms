--  Lulea_Algorithm.ads
--  
--  Package specification for the Luleå Algorithm implementation.
--  Implements the Luleå Algorithm for efficient IPv4 routing table lookups.
--  
--  Author: Vibe Code (Mistral AI)
--  Date: 2025
--  
--  Description:
--  The Luleå Algorithm is a technique for storing and searching internet routing tables
--  efficiently. It uses a compressed trie structure to perform longest prefix matching
--  (LPM) for IPv4 addresses with minimal memory usage (~4-5 bytes per entry).
--  
--  This package includes:
--  - Original Luleå Algorithm (static, memory-efficient)
--  - Sundström's 2x Speedup variant (optimized)
--  - Hybrid Tree LPM variant (supports dynamic updates and IPv6)
--  
--  Key Components:
--  - Bit Vector: 65,536 bits (1 bit per 16-bit prefix)
--  - Base Indexes: For every 64-bit subsequence in the bit vector
--  - Code Words: 16-bit values (10-bit value + 6-bit offset)
--  - Maptable: 678 rows × variable columns for 16-bit bitmask combinations
--  - Chunks: For Levels 2 and 3 (8-bit prefix matching)

with Ada.Containers.Vectors;
with Interfaces; use Interfaces;

package Lulea_Algorithm is

   -- ========================================================================
   --  Custom Types for Luleå Algorithm
   -- ========================================================================

   -- IPv4 Address: 32-bit unsigned integer
   type IPv4_Address is mod 2**32;

   -- Prefix Length (0-32 bits)
   type Prefix_Length is range 0 .. 32;

   -- Routing Information (e.g., next hop, interface)
   type Routing_Info is record
      Next_Hop : IPv4_Address;
      If_Index : Integer;
      Metric   : Integer;
   end record;

   -- Prefix: Combines an IPv4 address with its length
   type Prefix is record
      Address : IPv4_Address;
      Length  : Prefix_Length;
   end record;

   -- Routing Table Entry: Prefix + Routing Info
   type Route_Entry is record
      Prefix      : Prefix;
      Info        : Routing_Info;
   end record;

   -- Array of Routing Entries (for input/output)
   type Routing_Table is array (Positive range <>) of Route_Entry;

   -- Bit Vector: 65,536 bits (1 bit per 16-bit prefix)
   type Bit_Vector is array (0 .. 65535) of Boolean;

   -- Base Index Array: For every 64-bit subsequence in the bit vector
   type Base_Index_Array is array (0 .. 1023) of Integer;

   -- Code Word: 10-bit value + 6-bit offset
   type Code_Word is record
      Value  : Integer range 0 .. 1023;  -- 10 bits
      Offset : Integer range 0 .. 63;    -- 6 bits
   end record;

   -- Code Word Array: For every 16-bit subsequence in the bit vector
   type Code_Word_Array is array (0 .. 4095) of Code_Word;

   -- Maptable: 678 rows × 16 columns (for 16-bit bitmask combinations)
   type Maptable_Array is array (0 .. 677, 0 .. 15) of Integer;

   -- Datum: Either routing info or pointer to second-level structure
   type Datum_Type is (Direct, Pointer);
   type Datum is record
      Kind : Datum_Type;
      case Kind is
         when Direct =>
            Info : Routing_Info;
         when Pointer =>
            Index : Integer;  -- Points to second-level structure
      end case;
   end record;

   -- Datum Array: For first-level non-zero bits
   type Datum_Array is array (Positive range <>) of Datum;

   -- Chunk: For second/third-level structures (8-bit prefix matching)
   type Chunk is record
      Routing_Infos : Ada.Containers.Vectors.Vector;
      Is_Indexed    : Boolean;  -- True if using indexed structure
      -- If Is_Indexed = True, use sub-structure (not implemented here for simplicity)
   end record;

   -- Chunk Array Type
   type Chunk_Array is array (Positive range <>) of Chunk;

   -- Luleå Trie Structure (3 levels)
   type Lulea_Trie is record
      Bit_Vector      : Bit_Vector;
      Base_Indexes    : Base_Index_Array;
      Code_Words      : Code_Word_Array;
      Maptable        : Maptable_Array;
      Data           : Datum_Array;
      Second_Level   : Chunk_Array;
      Third_Level    : Chunk_Array;
   end record;

   -- ========================================================================
   --  Exceptions
   -- ========================================================================

   -- Raised when a prefix is invalid (e.g., length > 32)
   Invalid_Prefix_Error : exception;

   -- Raised when the routing table is empty
   Empty_Routing_Table_Error : exception;

   -- Raised when a lookup fails (no matching prefix)
   Lookup_Failure_Error : exception;

   -- Raised when preprocessing fails (e.g., overlapping prefixes cannot be split)
   Preprocessing_Error : exception;

   -- ========================================================================
   --  Subprogram Declarations
   -- ========================================================================

   -- ========================================================================
   --  Preprocessing Functions
   -- ========================================================================

   -- Splits a larger prefix into smaller non-overlapping prefixes
   -- Input: The prefix to split, the smaller prefix causing the overlap
   -- Output: Array of smaller prefixes that do not overlap with the smaller prefix
   function Split_Prefix (
      Large_Prefix : Prefix;
      Small_Prefix : Prefix)
      return Routing_Table;

   -- Completes the prefix tree by adding dummy entries for missing ranges
   -- Input: Routing table with existing entries
   -- Output: Completed routing table with dummy entries
   function Complete_Tree (
      Entries : Routing_Table)
      return Routing_Table;

   -- Preprocesses the routing table (splits overlapping prefixes and completes the tree)
   -- Input: Original routing table
   -- Output: Preprocessed routing table
   function Preprocess_Routing_Table (
      Entries : Routing_Table)
      return Routing_Table;

   -- ========================================================================
   --  Core Luleå Algorithm Functions
   -- ========================================================================

   -- Builds the Luleå Trie from a preprocessed routing table
   -- Input: Preprocessed routing table
   -- Output: Constructed Luleå Trie
   function Build_Lulea_Trie (
      Entries : Routing_Table)
      return Lulea_Trie;

   -- Looks up the longest prefix match for a given IPv4 address
   -- Input: Luleå Trie, IPv4 address
   -- Output: Routing info for the longest matching prefix
   function Lookup (
      Trie    : Lulea_Trie;
      Address : IPv4_Address)
      return Routing_Info;

   -- ========================================================================
   --  Variant Implementations
   -- ========================================================================

   -- Original Luleå Algorithm (static, memory-efficient)
   package Original_Lulea is
      function Build_Trie (
         Entries : Routing_Table)
         return Lulea_Trie;

      function Lookup (
         Trie    : Lulea_Trie;
         Address : IPv4_Address)
         return Routing_Info;
   end Original_Lulea;

   -- Sundström's 2x Speedup variant (optimized for speed)
   package Sundstrom_Lulea is
      -- Cache array types
      type Cache_Array is array (0 .. 1023) of Routing_Info;
      type Cache_Valid_Array is array (0 .. 1023) of Boolean;
      type Optimized_Lulea_Trie is record
         Trie : Lulea_Trie;
         -- Additional optimizations (e.g., cached lookups)
         Cache_Size : Integer := 1024;
         Cache      : Cache_Array;
         Cache_Valid : Cache_Valid_Array := (others => False);
      end record;

      function Build_Trie (
         Entries : Routing_Table)
         return Optimized_Lulea_Trie;

      function Lookup (
         Trie    : Optimized_Lulea_Trie;
         Address : IPv4_Address)
         return Routing_Info;
   end Sundstrom_Lulea;

   -- Hybrid Tree LPM variant (supports dynamic updates and IPv6)
   package Hybrid_Lulea is
      type Hybrid_Lulea_Trie is record
         Trie : Lulea_Trie;
         -- Additional fields for dynamic updates and IPv6 support
         Supports_IPv6 : Boolean := False;
         Dynamic_Updates_Enabled : Boolean := False;
      end record;

      function Build_Trie (
         Entries : Routing_Table;
         Enable_IPv6 : Boolean := False;
         Enable_Dynamic_Updates : Boolean := False)
         return Hybrid_Lulea_Trie;

      function Lookup (
         Trie    : Hybrid_Lulea_Trie;
         Address : IPv4_Address)
         return Routing_Info;

      -- Dynamic update: Add a new routing entry
      procedure Add_Entry (
         Trie    : in out Hybrid_Lulea_Trie;
         Route   : Route_Entry);

      -- Dynamic update: Remove a routing entry
      procedure Remove_Entry (
         Trie    : in out Hybrid_Lulea_Trie;
         Prefix  : Prefix);
   end Hybrid_Lulea;

   -- ========================================================================
   --  Helper Functions
   -- ========================================================================

   -- Extracts the first N bits of an IPv4 address
   function Extract_Bits (
      Address : IPv4_Address;
      Start   : Integer;
      Length  : Integer)
      return Integer;

   -- Computes the base index for a given 10-bit segment of the address
   function Compute_Base_Index (
      Trie     : Lulea_Trie;
      Segment  : Integer)
      return Integer;

   -- Computes the offset for a given 12-bit segment of the address
   function Compute_Offset (
      Trie     : Lulea_Trie;
      Segment  : Integer)
      return Integer;

   -- Computes the maptable value for a given 16-bit segment of the address
   function Compute_Maptable_Value (
      Trie     : Lulea_Trie;
      Segment  : Integer)
      return Integer;

   -- Checks if a prefix is valid (length <= 32)
   function Is_Valid_Prefix (
      Prefix : Prefix)
      return Boolean;

   -- Checks if two prefixes overlap
   function Prefixes_Overlap (
      P1, P2 : Prefix)
      return Boolean;

   -- ========================================================================
   --  Utility Functions
   -- ========================================================================

   -- Converts an IPv4 address to a dotted-decimal string
   function IPv4_To_String (
      Address : IPv4_Address)
      return String;

   -- Converts a dotted-decimal string to an IPv4 address
   function String_To_IPv4 (
      S : String)
      return IPv4_Address;

   -- Prints a routing entry
   procedure Print_Route_Entry (
      Route : Route_Entry);

   -- Prints the Luleå Trie (for debugging)
   procedure Print_Lulea_Trie (
      Trie : Lulea_Trie);

end Lulea_Algorithm;
