--  Nonblocking_Minimal_Spanning_Switch — Ada 2023 educational model of an
--  N×N switching fabric that is nonblocking, with a focus on minimal
--  crosspoint ideas from the Clos / spanning-switch family.
--
--  Two fabrics:
--    * Crossbar — N² crosspoints; strictly nonblocking (any free input can
--      reach any free output without rearranging existing calls).
--    * Spanning — educational 3-stage Clos C(n,m,r) with m = n (Slepian–
--      Duguid rearrangeably nonblocking). Fewer crosspoints than N² for
--      moderate N; a new call may require Rearrange_Connect.
--
--  Ports indexed from 1. Fixed educational arrays sized to Max_N (no
--  dynamic heap). Focus: clear semantics + tiny-N nonblocking checks, not
--  industrial Clos optimality proofs.
--  Reference: https://en.wikipedia.org/wiki/Nonblocking_minimal_spanning_switch
--  Clos sibling context: https://en.wikipedia.org/wiki/Clos_network
--  Part of the RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Nonblocking_Minimal_Spanning_Switch
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum fabric order N (ports 1 .. N on each side).
   Max_N : constant Positive := 32;

   ---------------------------------------------------------------------------
   -- Identifiers and fabric kinds
   ---------------------------------------------------------------------------

   type Port_Id is range 1 .. Max_N;

   --  Crossbar = full N×N matrix (strict). Spanning = Clos m = n (rearr.).
   type Fabric_Kind is (Crossbar, Spanning);

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for N = 0 or N > Max_N, port ids outside 1 .. Order(S),
   --  Connect / Rearrange_Connect when the requested ports are busy or
   --  (Crossbar only) when Can_Connect would be False, and Disconnect
   --  when the given input is not connected.

   ---------------------------------------------------------------------------
   -- Switch fabric
   ---------------------------------------------------------------------------

   type Switch is private;

   procedure Create
     (S : in out Switch; N : Positive; Kind : Fabric_Kind := Crossbar)
     with Global => null;
   --  Build an empty N×N fabric of the given Kind. All ports free.
   --  For Spanning, Clos parameters (n, m, r) with m = n are chosen so
   --  that n·r ≥ N (educational; unused inlets/outlets on the last
   --  stage switches stay idle). Raises Invalid_Argument when
   --  N > Max_N.

   function Order (S : Switch) return Natural
     with Global => null;
   --  Fabric order N; valid ports are 1 .. N (empty Create never leaves
   --  N = 0 — use Order = 0 only on a default Switch before Create).

   function Kind_Of (S : Switch) return Fabric_Kind
     with Global => null;
   --  Fabric kind established by Create (default Crossbar before Create).

   function Crosspoint_Count (S : Switch) return Natural
     with Global => null;
   --  Hardware crosspoint tally for the chosen construction:
   --    Crossbar  → N²
   --    Spanning  → 2·n·m·r + m·r²  (three-stage Clos)

   function Active_Connections (S : Switch) return Natural
     with Global => null;
   --  Number of currently established input→output calls (0 .. N).

   ---------------------------------------------------------------------------
   -- Connection API
   ---------------------------------------------------------------------------

   function Is_Connected (S : Switch; Input : Port_Id) return Boolean
     with Global => null;
   --  True when Input currently holds a call. Raises Invalid_Argument
   --  when Input is outside 1 .. Order(S) or Order(S) = 0.

   function Is_Output_Busy (S : Switch; Output : Port_Id) return Boolean
     with Global => null;
   --  True when Output is the destination of some active call.
   --  Raises Invalid_Argument when Output is outside 1 .. Order(S)
   --  or Order(S) = 0.

   function Connected_Output (S : Switch; Input : Port_Id) return Natural
     with Global => null;
   --  Destination port of Input's call, or 0 if Input is free.
   --  Raises Invalid_Argument when Input is outside 1 .. Order(S)
   --  or Order(S) = 0.

   function Can_Connect
     (S : Switch; Input, Output : Port_Id) return Boolean
     with Global => null;
   --  True if Input and Output are both free and a path exists without
   --  rearranging existing calls. Crossbar: free ports ⇒ True (strict).
   --  Spanning: free ports plus a free middle-stage route. Raises
   --  Invalid_Argument for bad ports / N = 0.

   procedure Connect
     (S : in out Switch; Input, Output : Port_Id)
     with Global => null;
   --  Establish Input→Output without rearranging other calls.
   --  Requires Can_Connect (S, Input, Output). Raises Invalid_Argument
   --  when ports are invalid or Can_Connect is False.

   procedure Rearrange_Connect
     (S : in out Switch; Input, Output : Port_Id)
     with Global => null;
   --  Establish Input→Output, rearranging existing middle-stage routes
   --  when necessary (no-op rearrange on Crossbar). Requires Input and
   --  Output free. On Spanning (m = n) any partial matching is always
   --  routable after rearrange. Raises Invalid_Argument when ports are
   --  invalid or either port is already busy.

   procedure Disconnect (S : in out Switch; Input : Port_Id)
     with Global => null;
   --  Tear down the call on Input (and free its output / middle path).
   --  Raises Invalid_Argument when Input is invalid or not connected.

   procedure Clear_Connections (S : in out Switch)
     with Global => null;
   --  Drop every active call; fabric parameters unchanged.

   ---------------------------------------------------------------------------
   -- Nonblocking verification helpers (educational, tiny N)
   ---------------------------------------------------------------------------

   function Is_Strictly_Nonblocking_Fabric (S : Switch) return Boolean
     with Global => null;
   --  True for Crossbar; False for Spanning (rearrangeably nonblocking
   --  only). Independent of current occupancy.

   function Clos_N (S : Switch) return Natural
     with Global => null;
   --  Clos inlet size n (0 on Crossbar).

   function Clos_M (S : Switch) return Natural
     with Global => null;
   --  Clos middle-switch count m (0 on Crossbar). Spanning ⇒ m = n.

   function Clos_R (S : Switch) return Natural
     with Global => null;
   --  Clos number of first/third-stage switches r (0 on Crossbar).

   function All_Free_Permutations_Routable_Without_Rearrange
     (S : Switch) return Boolean
     with Global => null;
   --  For the current set of free inputs F_in and free outputs F_out
   --  (|F_in| = |F_out| = k), return True iff every bijection
   --  π : F_in → F_out can be added on top of the existing calls
   --  without rearranging those existing calls (each π tried from the
   --  same snapshot). Vacuous True when k = 0. Intended for tiny N
   --  (enumerates k!). Crossbar always returns True when ports are
   --  free; Spanning may return False under partial occupancy.

   function Empty_Fabric_Is_Fully_Nonblocking (S : Switch) return Boolean
     with Global => null;
   --  Requires Active_Connections = 0. Crossbar: every permutation of
   --  1 .. N is connectable without rearrange (strict). Spanning: every
   --  permutation is connectable via Rearrange_Connect (rearrangeable).
   --  Enumerates N! — use only for N ≤ 5 in tests. Raises
   --  Invalid_Argument when the fabric is not empty or N = 0.

private

   subtype Stage_Index is Natural range 0 .. Max_N;
   subtype Middle_Index is Natural range 0 .. Max_N;

   type Out_Map is array (Port_Id) of Natural;
   --  Out_Map (Input) = Output port or 0 if free.

   type In_Map is array (Port_Id) of Natural;
   --  In_Map (Output) = Input port or 0 if free.

   type Middle_Of_Input is array (Port_Id) of Middle_Index;
   --  Which middle switch carries Input's call (0 if free / Crossbar).

   --  Link occupancy: First_Stage (fs) → Middle (m) and Middle → Third (ts).
   type Link_RM is array (1 .. Max_N, 1 .. Max_N) of Boolean;
   --  Used as (1 .. R, 1 .. M) and (1 .. M, 1 .. R) slices via Clos params.

   type Switch is record
      N         : Natural := 0;
      Kind      : Fabric_Kind := Crossbar;
      Active    : Natural := 0;
      --  Clos parameters (Spanning only; 0 on Crossbar)
      CN        : Natural := 0;  -- n
      CM        : Natural := 0;  -- m
      CR        : Natural := 0;  -- r
      Out_Of    : Out_Map := [others => 0];
      In_Of     : In_Map := [others => 0];
      Mid_Of    : Middle_Of_Input := [others => 0];
      FS_Mid    : Link_RM := [others => [others => False]];
      Mid_TS    : Link_RM := [others => [others => False]];
   end record;

end Nonblocking_Minimal_Spanning_Switch;
