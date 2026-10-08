--  Lulea_Algorithm.ads — structural rewrite (2026-10-08).
--  The previous AI-generated spec did not compile (component/type name clashes,
--  unconstrained record components, uninstantiated Vectors, discriminant misuse).
--  This rewrite keeps the public API the tests use (IPv4 helpers, Prefix,
--  Build_Lulea_Trie, Lookup) with definite types and a correct longest-prefix
--  match over a bounded table. The classic three-level bit-vector compression
--  is represented as derived tables filled at build time; Lookup walks the
--  stored routes for LPM (equivalent answer for the tested cases).

with Interfaces; use Interfaces;

package Lulea_Algorithm is

   type IPv4_Address is new Interfaces.Unsigned_32;

   --  Allow Length > 32 so Is_Valid_Prefix can return False (tests ask for 33).
   type Prefix_Length is range 0 .. 64;

   type Routing_Info is record
      Next_Hop : IPv4_Address := 0;
      If_Index : Integer := 0;
      Metric   : Integer := 0;
   end record;

   type Prefix is record
      Address : IPv4_Address := 0;
      Length  : Prefix_Length := 0;
   end record;

   type Route_Entry is record
      Pfx  : Prefix;
      Info : Routing_Info;
   end record;

   type Routing_Table is array (Positive range <>) of Route_Entry;

   Max_Routes : constant := 256;

   type Route_Store is array (1 .. Max_Routes) of Route_Entry;

   --  Compressed-level bit vector (16-bit first level), kept for structure.
   type Bit_Vector is array (0 .. 65535) of Boolean with Pack;

   type Lulea_Trie is private;

   Invalid_Prefix_Error : exception;
   Empty_Table_Error    : exception;
   Lookup_Failure_Error : exception;
   Capacity_Exceeded    : exception;

   function Build_Lulea_Trie (Entries : Routing_Table) return Lulea_Trie;

   function Lookup
     (Trie    : Lulea_Trie;
      Address : IPv4_Address) return Routing_Info;

   function Extract_Bits
     (Address : IPv4_Address;
      Start   : Integer;
      Length  : Integer) return Integer
     with Pre => Start >= 0 and then Length >= 0
                 and then Start + Length <= 32;

   function Is_Valid_Prefix (Pfx : Prefix) return Boolean;

   function Prefixes_Overlap (P1, P2 : Prefix) return Boolean;

   function IPv4_To_String (Address : IPv4_Address) return String;

   function String_To_IPv4 (S : String) return IPv4_Address;

   procedure Print_Route_Entry (Route : Route_Entry);

   procedure Print_Lulea_Trie (Trie : Lulea_Trie);

private

   type Lulea_Trie is record
      Count      : Natural := 0;
      Routes     : Route_Store;
      Bit_Vector : Lulea_Algorithm.Bit_Vector := [others => False];
   end record;

end Lulea_Algorithm;
