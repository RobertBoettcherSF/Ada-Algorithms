package Data_Flow_Analysis is
   pragma Preelaborate;

   -- Domain types for strong typing
   type Node_ID is new Positive;
   type Fact_ID is new Positive;

   -- Adjacency matrix for Control Flow Graph edges
   type Adjacency_Matrix is array (Node_ID range <>, Node_ID range <>) of Boolean;
   -- Matrix to hold data-flow facts (e.g., definitions, variables, expressions) per node
   type Fact_Matrix is array (Node_ID range <>, Fact_ID range <>) of Boolean;

   -- The Control Flow Graph (CFG) representation.
   -- Uses discriminants to strongly bind the graph size upon instantiation.
   type Control_Flow_Graph (Nodes : Node_ID; Facts : Fact_ID) is record
      Edges : Adjacency_Matrix (1 .. Nodes, 1 .. Nodes) := [others => [others => False]];
      Gen   : Fact_Matrix (1 .. Nodes, 1 .. Facts)      := [others => [others => False]];
      Kill  : Fact_Matrix (1 .. Nodes, 1 .. Facts)      := [others => [others => False]];
   end record;

   -- Exception raised when graph constraints or semantics are violated
   Graph_Conflict_Error : exception;

   -- -------------------------------------------------------------------------
   -- Graph Construction & Validation API
   -- -------------------------------------------------------------------------

   -- Add a directed edge from 'From' node to 'To' node
   procedure Add_Edge (CFG : in out Control_Flow_Graph; From, To : Node_ID)
     with Pre => From <= CFG.Nodes and then To <= CFG.Nodes;

   -- Add a generated fact to a specific node
   procedure Add_Gen (CFG : in out Control_Flow_Graph; Node : Node_ID; Fact : Fact_ID)
     with Pre => Node <= CFG.Nodes and then Fact <= CFG.Facts;

   -- Add a killed fact to a specific node
   procedure Add_Kill (CFG : in out Control_Flow_Graph; Node : Node_ID; Fact : Fact_ID)
     with Pre => Node <= CFG.Nodes and then Fact <= CFG.Facts;

   -- Validates that no node simultaneously generates and kills the same fact
   -- Raises Graph_Conflict_Error if a conflict is found.
   procedure Validate_Graph (CFG : Control_Flow_Graph);

   -- -------------------------------------------------------------------------
   -- Data-Flow Solvers (Iterative Worklist Approach)
   -- -------------------------------------------------------------------------
   
   -- 1. Reaching Definitions (Forward, May)
   -- Determines which definitions may reach a given point in the graph.
   procedure Solve_Reaching_Definitions
     (CFG      : in  Control_Flow_Graph;
      In_Sets  : out Fact_Matrix;
      Out_Sets : out Fact_Matrix)
     with Pre => In_Sets'First(1) = 1 and then In_Sets'Last(1) = CFG.Nodes and then
                 In_Sets'First(2) = 1 and then In_Sets'Last(2) = CFG.Facts and then
                 Out_Sets'First(1) = 1 and then Out_Sets'Last(1) = CFG.Nodes and then
                 Out_Sets'First(2) = 1 and then Out_Sets'Last(2) = CFG.Facts,
          Global => null;

   -- 2. Live Variables (Backward, May)
   -- Determines which variables may be read before their next write.
   procedure Solve_Live_Variables
     (CFG      : in  Control_Flow_Graph;
      In_Sets  : out Fact_Matrix;
      Out_Sets : out Fact_Matrix)
     with Pre => In_Sets'First(1) = 1 and then In_Sets'Last(1) = CFG.Nodes and then
                 In_Sets'First(2) = 1 and then In_Sets'Last(2) = CFG.Facts and then
                 Out_Sets'First(1) = 1 and then Out_Sets'Last(1) = CFG.Nodes and then
                 Out_Sets'First(2) = 1 and then Out_Sets'Last(2) = CFG.Facts,
          Global => null;

   -- 3. Available Expressions (Forward, Must)
   -- Determines which expressions must have already been computed.
   procedure Solve_Available_Expressions
     (CFG      : in  Control_Flow_Graph;
      In_Sets  : out Fact_Matrix;
      Out_Sets : out Fact_Matrix)
     with Pre => In_Sets'First(1) = 1 and then In_Sets'Last(1) = CFG.Nodes and then
                 In_Sets'First(2) = 1 and then In_Sets'Last(2) = CFG.Facts and then
                 Out_Sets'First(1) = 1 and then Out_Sets'Last(1) = CFG.Nodes and then
                 Out_Sets'First(2) = 1 and then Out_Sets'Last(2) = CFG.Facts,
          Global => null;

   -- 4. Very Busy Expressions (Backward, Must)
   -- Determines which expressions must be evaluated in the future.
   procedure Solve_Very_Busy_Expressions
     (CFG      : in  Control_Flow_Graph;
      In_Sets  : out Fact_Matrix;
      Out_Sets : out Fact_Matrix)
     with Pre => In_Sets'First(1) = 1 and then In_Sets'Last(1) = CFG.Nodes and then
                 In_Sets'First(2) = 1 and then In_Sets'Last(2) = CFG.Facts and then
                 Out_Sets'First(1) = 1 and then Out_Sets'Last(1) = CFG.Nodes and then
                 Out_Sets'First(2) = 1 and then Out_Sets'Last(2) = CFG.Facts,
          Global => null;

end Data_Flow_Analysis;
