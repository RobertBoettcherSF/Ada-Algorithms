--  Velvet — Ada 2023 educational package for Wikipedia "Velvet (algorithm)"
--  (Zerbino & Birney, Genome Research 2008): short-read de novo assembly via
--  de Bruijn graphs. Pedagogical subset: k-mer hashing, graph construction
--  with multiplicities, tip clipping, low-coverage edge removal, and contig
--  walks on unbranched paths. Not a full Tour Bus / Velvet reimplementation.
--  Alphabet ACGT; reverse-complement edges optional per read.

pragma Ada_2022;

package Velvet
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain / capacity
   ---------------------------------------------------------------------------

   type Real is digits 12;

   --  k-mer length k; nodes are (k-1)-mers. Educational upper bound.
   Max_K             : constant Positive := 31;
   Max_Read_Length   : constant Positive := 128;
   Max_Reads         : constant Positive := 64;
   Max_Nodes         : constant Positive := 256;
   Max_Edges         : constant Positive := 512;
   Max_Out_Degree    : constant Positive := 4;  -- A,C,G,T
   Max_Contigs       : constant Positive := 64;
   Max_Contig_Length : constant Positive := 512;

   subtype Kmer_Length is Positive range 2 .. Max_K;
   --  k >= 2 so that (k-1)-mer nodes have length >= 1.

   subtype Node_Index is Natural range 0 .. Max_Nodes;
   subtype Edge_Index is Natural range 0 .. Max_Edges;
   subtype Contig_Index is Natural range 0 .. Max_Contigs;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument  : exception;
   Capacity_Exceeded : exception;

   ---------------------------------------------------------------------------
   -- Contig result
   ---------------------------------------------------------------------------

   type Contig_Record is record
      Seq : String (1 .. Max_Contig_Length) := [others => ' '];
      Len : Natural := 0;
   end record;

   type Contig_Array is array (1 .. Max_Contigs) of Contig_Record;

   type Contig_List is record
      Count   : Contig_Index := 0;
      Contigs : Contig_Array;
   end record;

   ---------------------------------------------------------------------------
   -- Graph (opaque)
   ---------------------------------------------------------------------------

   type Graph is private;

   ---------------------------------------------------------------------------
   -- Construction
   ---------------------------------------------------------------------------

   function Build_Graph (K : Kmer_Length) return Graph
     with Global => null;
   --  Empty de Bruijn graph for word length K. Nodes will be (K-1)-mers;
   --  each observed k-mer becomes a directed edge prefix → suffix.

   function Get_K (G : Graph) return Kmer_Length
     with Global => null;
   --  Word length used when the graph was built.

   procedure Add_Read
     (G          : in out Graph;
      Read       : String;
      Include_RC : Boolean := True)
     with Global => null;
   --  Hash Read into k-mers; create/update nodes and edge multiplicities.
   --  Windows containing non-ACGT bases are skipped. If Include_RC, also
   --  hash the reverse complement (Velvet-style dual-strand hashing).
   --  Raises Invalid_Argument if Read'Length > Max_Read_Length;
   --  Capacity_Exceeded if Max_Nodes / Max_Edges would be exceeded.
   --  Empty or shorter-than-K reads are no-ops (no exception).

   ---------------------------------------------------------------------------
   -- Error handling (lite: tip clipping + coverage cutoff)
   ---------------------------------------------------------------------------

   procedure Remove_Tips
     (G              : in out Graph;
      Max_Tip_Length : Natural := 0)
     with Global => null;
   --  Remove short dead-end paths (tips): chains ending at a node with
   --  out-degree 0 or starting at in-degree 0, whose path length in nodes
   --  is <= Max_Tip_Length (default 0 → use 2*K, Velvet-style spirit).
   --  Then prune orphan edges/nodes. Educational tip clipping only.

   procedure Remove_Low_Coverage
     (G            : in out Graph;
      Min_Coverage : Natural)
     with Global => null;
   --  Delete edges whose multiplicity is strictly below Min_Coverage
   --  (erroneous-connection / coverage cutoff spirit). Prune isolates.

   ---------------------------------------------------------------------------
   -- Contig emission
   ---------------------------------------------------------------------------

   function Emit_Contigs (G : Graph) return Contig_List
     with Global => null;
   --  Collapse unbranched paths: walk maximal chains of nodes with
   --  in-degree <= 1 and out-degree <= 1; emit contig strings. Sequence
   --  starts with the first (k-1)-mer and appends the last base of each
   --  successive node along the path. Contigs shorter than K are omitted
   --  when possible alternatives exist; otherwise all non-empty paths
   --  of at least one node are reported (educational).

   function Contig_String (C : Contig_Record) return String
     with Global => null;
   --  Slice C.Seq (1 .. C.Len).

   ---------------------------------------------------------------------------
   -- Queries
   ---------------------------------------------------------------------------

   function Node_Count (G : Graph) return Natural
     with Global => null,
          Post => Node_Count'Result <= Max_Nodes;

   function Edge_Count (G : Graph) return Natural
     with Global => null,
          Post => Edge_Count'Result <= Max_Edges;

   function Contains_Node (G : Graph; Seq : String) return Boolean
     with Global => null;
   --  True if an alive node with exact (k-1)-mer Seq exists.

   function Edge_Multiplicity
     (G : Graph; From_Seq, To_Seq : String) return Natural
     with Global => null;
   --  Multiplicity of the directed edge From→To, or 0 if absent.

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Reverse_Complement (S : String) return String
     with Global => null;
   --  Watson–Crick reverse complement (A↔T, C↔G); non-ACGT left unchanged
   --  in place after reverse. Result length = S'Length.
   --  Raises Invalid_Argument if S'Length > Max_Read_Length.

   function Is_ACGT (C : Character) return Boolean
     with Global => null;
   --  True for A/C/G/T (case-insensitive).

   function Normalize_Base (C : Character) return Character
     with Global => null;
   --  Uppercase ACGT; raises Invalid_Argument for other characters.

   function Near (A, B : Real; Tol : Real := 1.0E-9) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  |A-B| <= Tol.

   function Contains_Substring (Haystack, Needle : String) return Boolean
     with Global => null;
   --  True if Needle occurs as a contiguous substring of Haystack
   --  (or Needle is empty). Used by tests for contig recovery checks.

private

   subtype Seq_Buffer is String (1 .. Max_K - 1);

   type Node_Record is record
      Seq     : Seq_Buffer := [others => ' '];
      Len     : Natural := 0;
      In_Deg  : Natural := 0;
      Out_Deg : Natural := 0;
      Alive   : Boolean := False;
      Visited : Boolean := False;  -- contig walk scratch
   end record;

   type Node_Array is array (1 .. Max_Nodes) of Node_Record;

   --  Sparse directed edges with multiplicity; Out_Slot indexes adjacency.
   type Edge_Record is record
      From, To : Node_Index := 0;
      Mult     : Natural := 0;
      Alive    : Boolean := False;
   end record;

   type Edge_Array is array (1 .. Max_Edges) of Edge_Record;

   --  Per-node outgoing edge indices (at most 4 bases).
   type Out_List is array (1 .. Max_Out_Degree) of Edge_Index;
   type Out_Table is array (1 .. Max_Nodes) of Out_List;
   type Out_Count_Array is array (1 .. Max_Nodes) of Natural;

   type Graph is record
      K          : Kmer_Length := 2;
      N_Nodes    : Node_Index := 0;
      N_Edges    : Edge_Index := 0;
      Nodes      : Node_Array;
      Edges      : Edge_Array;
      Outs       : Out_Table := [others => [others => 0]];
      Out_Counts : Out_Count_Array := [others => 0];
      Read_Count : Natural := 0;
   end record;

end Velvet;
