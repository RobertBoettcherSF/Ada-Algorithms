--  Combinatorial_Auction — Ada 2023 educational package for combinatorial
--  (multi-item package) auctions: bidders report values on bundles of
--  discrete items; the auctioneer solves the winner-determination problem
--  (WDP) — a set-packing integer programme — by exhaustive enumeration on
--  classroom-sized instances. Optional XOR bidding (at most one accepted
--  bid per bidder) and free disposal (items may remain unsold). Optional
--  Clarke/VCG payments for the WDP outcome are self-contained (no `with`
--  of the VCG sibling).
--  Reference: https://en.wikipedia.org/wiki/Combinatorial_auction
--  Sibling sheets (README only — do not `with`): Vickrey–Clarke–Groves,
--  Top Trading Cycle — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Combinatorial_Auction
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity (educational; 2^Max_Bids subset enumeration)
   ---------------------------------------------------------------------------

   --  Items encoded as bitmasks: bit (i−1) ⇔ item i. Cap keeps masks
   --  inside Natural and Popcount loops tiny.
   Max_Items : constant Positive := 12;

   --  Bids enumerated as a 0/1 subset mask of length Num_Bids ≤ Max_Bids.
   --  2^16 = 65_536 WDP candidates — fine for classroom demos.
   Max_Bids : constant Positive := 16;

   Max_Bidders : constant Positive := 16;

   ---------------------------------------------------------------------------
   -- Identifiers and numeric types
   ---------------------------------------------------------------------------

   type Item_Id is range 1 .. Max_Items;
   type Bid_Id is range 1 .. Max_Bids;
   type Bidder_Id is range 1 .. Max_Bidders;

   subtype Item_Count is Natural range 0 .. Max_Items;
   subtype Bid_Count is Natural range 0 .. Max_Bids;
   subtype Bidder_Count is Natural range 0 .. Max_Bidders;

   --  Bundle / item set: bit (i−1) set ⇔ item i is in the package.
   --  Valid masks for an N-item auction lie in 0 .. 2^N − 1.
   subtype Bundle_Mask is Natural;

   --  Which bids are selected: bit (k−1) set ⇔ bid k is accepted.
   subtype Bid_Subset is Natural;

   --  Reported bid values, welfare, and Clarke payments.
   subtype Money is Long_Float;

   type Bid is record
      Bidder : Bidder_Id   := 1;
      Bundle : Bundle_Mask := 0;
      Value  : Money       := 0.0;
   end record;

   type Bid_Array is array (Bid_Id range <>) of Bid;

   --  Classroom auction instance. Free disposal is always on: the
   --  auctioneer may retain items. When XOR_Bidding is True, at most
   --  one accepted bid may belong to any given bidder (XOR language).
   type Auction is record
      Num_Items   : Item_Count := 0;
      Num_Bids    : Bid_Count  := 0;
      Num_Bidders : Bidder_Count := 0;  -- highest bidder id that appears
      Bids        : Bid_Array (Bid_Id'First .. Bid_Id'Last) := [others => <>];
      XOR_Bidding : Boolean := False;
   end record;

   type Acceptance is array (Bid_Id) of Boolean;

   --  Bundle awarded to each bidder (OR of accepted bid bundles for that
   --  bidder). Unused bidder slots stay 0.
   type Bidder_Allocation is array (Bidder_Id) of Bundle_Mask;

   type Money_Vector is array (Bidder_Id) of Money;

   --  Optimal WDP outcome (ties broken by smallest Bid_Subset mask).
   type WDP_Result is record
      Accepted      : Acceptance := [others => False];
      Accepted_Mask : Bid_Subset := 0;
      Num_Accepted  : Bid_Count := 0;
      Welfare       : Money := 0.0;
      Alloc         : Bidder_Allocation := [others => 0];
      Sold_Mask     : Bundle_Mask := 0;  -- union of accepted bundles
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for Num_Items = 0 or > Max_Items, too many bids / bidders,
   --  bundle masks outside 0 .. 2^Num_Items − 1, bid indices out of
   --  range, empty / non-1-based bid arrays where required, Value < 0,
   --  Tol < 0, or an Opt that is not an optimal WDP result for VCG.

   ---------------------------------------------------------------------------
   -- Tolerances / Near
   ---------------------------------------------------------------------------

   Default_Tol : constant Money := 1.0E-9;

   function Near
     (A, B : Money; Tol : Money := Default_Tol) return Boolean
     with Global => null;
   --  |A − B| ≤ Tol. Tol must be ≥ 0 (else Invalid_Argument).

   ---------------------------------------------------------------------------
   -- Bitmask helpers
   ---------------------------------------------------------------------------

   function Item_Bit (I : Item_Id) return Bundle_Mask
     with Global => null;
   --  2^(I−1).

   function Bid_Bit (K : Bid_Id) return Bid_Subset
     with Global => null;
   --  2^(K−1).

   function Max_Mask (N : Item_Count) return Bundle_Mask
     with Global => null;
   --  2^N − 1 (all items). N = 0 → 0.

   function Mask_Valid
     (M : Bundle_Mask; Num_Items : Item_Count) return Boolean
     with Global => null;
   --  M ≤ Max_Mask (Num_Items).

   function Overlaps (A, B : Bundle_Mask) return Boolean
     with Global => null;
   --  (A and B) ≠ 0.

   function Contains (Outer, Inner : Bundle_Mask) return Boolean
     with Global => null;
   --  Every bit of Inner is set in Outer: (Outer and Inner) = Inner.

   function Union (A, B : Bundle_Mask) return Bundle_Mask
     with Global => null;

   function Intersection (A, B : Bundle_Mask) return Bundle_Mask
     with Global => null;

   function Popcount (M : Bundle_Mask) return Natural
     with Global => null;
   --  Number of set bits (items in the package).

   function Has_Item (M : Bundle_Mask; I : Item_Id) return Boolean
     with Global => null;

   function Add_Item (M : Bundle_Mask; I : Item_Id) return Bundle_Mask
     with Global => null;

   function Remove_Item (M : Bundle_Mask; I : Item_Id) return Bundle_Mask
     with Global => null;

   ---------------------------------------------------------------------------
   -- Auction construction / validation
   ---------------------------------------------------------------------------

   function Empty_Auction
     (Num_Items : Item_Count; XOR_Bidding : Boolean := False) return Auction
     with Global => null;
   --  Zero bids. Num_Items in 1 .. Max_Items (else Invalid_Argument).

   procedure Clear (A : in out Auction)
     with Global => null;
   --  Drop all bids; keep Num_Items and XOR_Bidding.

   procedure Add_Bid
     (A      : in out Auction;
      Bidder : Bidder_Id;
      Bundle : Bundle_Mask;
      Value  : Money)
     with Global => null;
   --  Append a bid. Raises if capacity exceeded, Bundle invalid for
   --  A.Num_Items, Value < 0, or A not well-started (Num_Items = 0).

   function Make_Auction
     (Num_Items   : Item_Count;
      Bids        : Bid_Array;
      XOR_Bidding : Boolean := False) return Auction
     with Global => null;
   --  Build from a 1-based Bid_Array. Raises on empty Num_Items, too
   --  many bids, invalid masks, Value < 0, or non-1-based bounds.

   function Is_Well_Formed (A : Auction) return Boolean
     with Global => null;
   --  Num_Items in 1 .. Max_Items, Num_Bids ≤ Max_Bids, every bid has a
   --  valid mask and Value ≥ 0, Num_Bidders is consistent with Bids.

   function Full_Mask (A : Auction) return Bundle_Mask
     with Global => null;
   --  Max_Mask (A.Num_Items).

   ---------------------------------------------------------------------------
   -- Feasibility / welfare of a candidate acceptance
   ---------------------------------------------------------------------------

   function Acceptance_From_Mask
     (Mask : Bid_Subset; Num_Bids : Bid_Count) return Acceptance
     with Global => null;
   --  Bits 0 .. Num_Bids−1 of Mask. Raises if Mask ≥ 2^Num_Bids
   --  (when Num_Bids > 0) or Num_Bids = 0 and Mask ≠ 0.

   function Mask_From_Acceptance
     (Acc : Acceptance; Num_Bids : Bid_Count) return Bid_Subset
     with Global => null;

   function Is_Feasible
     (A : Auction; Acc : Acceptance) return Boolean
     with Global => null;
   --  Accepted bundles are pairwise disjoint; if XOR_Bidding, at most
   --  one accepted bid per bidder. Acc slots beyond Num_Bids must be
   --  False.

   function Is_Feasible_Mask
     (A : Auction; Mask : Bid_Subset) return Boolean
     with Global => null;

   function Welfare (A : Auction; Acc : Acceptance) return Money
     with Global => null;
   --  Σ Value of accepted bids (does not check feasibility).

   function Welfare_Mask (A : Auction; Mask : Bid_Subset) return Money
     with Global => null;

   function Sold_Items (A : Auction; Acc : Acceptance) return Bundle_Mask
     with Global => null;
   --  Union of accepted bundles.

   function Allocation_Of
     (A : Auction; Acc : Acceptance) return Bidder_Allocation
     with Global => null;
   --  Per-bidder OR of accepted bundles.

   function Count_Accepted
     (Acc : Acceptance; Num_Bids : Bid_Count) return Bid_Count
     with Global => null;

   ---------------------------------------------------------------------------
   -- Winner determination (exhaustive subset enumeration)
   ---------------------------------------------------------------------------

   function Winner_Determination (A : Auction) return WDP_Result
     with Global => null;
   --  Maximise welfare over feasible bid subsets. Ties → smallest
   --  Accepted_Mask. Empty bid list → welfare 0, nothing sold.
   --  Requires Is_Well_Formed (else Invalid_Argument).

   function Solve (A : Auction) return WDP_Result
     with Global => null;
   --  Alias of Winner_Determination.

   function Is_Optimal
     (A : Auction; Acc : Acceptance; Tol : Money := Default_Tol)
     return Boolean
     with Global => null;
   --  Acc feasible and Welfare (Acc) Near the WDP optimum.

   ---------------------------------------------------------------------------
   -- Optional Clarke / VCG payments (self-contained; no VCG `with`)
   ---------------------------------------------------------------------------

   function VCG_Payments (A : Auction; Opt : WDP_Result) return Money_Vector
     with Global => null;
   --  Clarke pivot for each bidder i that appears in A:
   --    p_i = W_{-i} − (W* − v_i*),
   --  where W* is Opt.Welfare, v_i* is i's accepted value at Opt, and
   --  W_{-i} is the WDP welfare after dropping all of i's bids.
   --  Bidders with no accepted value pay 0 when not pivotal. Opt must
   --  match Winner_Determination (A) (else Invalid_Argument).

   function Drop_Bidder (A : Auction; B : Bidder_Id) return Auction
     with Global => null;
   --  Copy of A with every bid of bidder B removed (renumbered densely).

   ---------------------------------------------------------------------------
   -- Classic toy instances
   ---------------------------------------------------------------------------

   function Complementarity_Toy return Auction
     with Global => null;
   --  Two items. Bidder 1 bids 13 on the pair {1,2} (complements).
   --  Bidder 2 bids 6 on {1} and 6 on {2}. OR language. Efficient
   --  allocation awards both items to bidder 1 (welfare 13 > 12).

   function Substitutes_Toy return Auction
     with Global => null;
   --  Two substitute items; XOR_Bidding. Bidder 1 bids 5 on {1} and 5
   --  on {2}; bidder 2 bids 4 on the pair. Efficient: one singleton
   --  to bidder 1 (welfare 5); XOR blocks taking both of bidder 1's
   --  bids.

   function Airport_Slots_Toy return Auction
     with Global => null;
   --  Tiny Rassenti–Smith–Bulfin flavour: 3 landing slots, 3 airlines,
   --  XOR package bids for preferred pairs / singles.

   function Spectrum_Pair_Toy return Auction
     with Global => null;
   --  Two spectrum licences; three bidders with synergistic pair values
   --  under XOR bidding.

end Combinatorial_Auction;
