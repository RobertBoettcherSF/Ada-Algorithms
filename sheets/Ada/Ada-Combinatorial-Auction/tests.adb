--  Standalone test suite for Combinatorial_Auction.

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Combinatorial_Auction; use Combinatorial_Auction;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Condition : Boolean; Message : String) is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   --  Non-static views (avoid -gnatwa constant-condition warnings).
   function Nat (X : Natural) return Natural is (X);
   function Ic (X : Natural) return Item_Count is (Item_Count (X));
   function Bc (X : Natural) return Bid_Count is (Bid_Count (X));
   function Mo (X : Money) return Money is (X);
   function Bm (X : Natural) return Bundle_Mask is (Bundle_Mask (X));
   function Iid (X : Positive) return Item_Id is (Item_Id (X));
   function Bidr (X : Positive) return Bidder_Id is (Bidder_Id (X));
   function Bidk (X : Positive) return Bid_Id is (Bid_Id (X));

   function Near_Raises (Tol : Money) return Boolean is
      Unused : Boolean;
   begin
      Unused := Near (0.0, 0.0, Tol);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Near_Raises;

   function Empty_Raises (N : Item_Count) return Boolean is
      Unused : Auction;
      pragma Unreferenced (Unused);
   begin
      declare
         A : constant Auction := Empty_Auction (N);
         pragma Unreferenced (A);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Empty_Raises;

   function Add_Raises
     (A : in out Auction; Bidder : Bidder_Id; Bundle : Bundle_Mask; V : Money)
     return Boolean
   is
   begin
      Add_Bid (A, Bidder, Bundle, V);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Add_Raises;

   function Make_Raises
     (N : Item_Count; Bids : Bid_Array) return Boolean
   is
      Unused : Auction;
      pragma Unreferenced (Unused);
   begin
      declare
         A : constant Auction := Make_Auction (N, Bids);
         pragma Unreferenced (A);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Make_Raises;

   function Acc_Mask_Raises (Mask : Bid_Subset; N : Bid_Count) return Boolean is
      Unused : Acceptance;
      pragma Unreferenced (Unused);
   begin
      declare
         Acc : constant Acceptance := Acceptance_From_Mask (Mask, N);
         pragma Unreferenced (Acc);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Acc_Mask_Raises;

   function WDP_Raises (A : Auction) return Boolean is
      Unused : WDP_Result;
      pragma Unreferenced (Unused);
   begin
      declare
         R : constant WDP_Result := Winner_Determination (A);
         pragma Unreferenced (R);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end WDP_Raises;

   function VCG_Raises (A : Auction; Opt : WDP_Result) return Boolean is
      Unused : Money_Vector;
      pragma Unreferenced (Unused);
   begin
      declare
         P : constant Money_Vector := VCG_Payments (A, Opt);
         pragma Unreferenced (P);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end VCG_Raises;

   function Welfare_Mask_Raises
     (A : Auction; Mask : Bid_Subset) return Boolean
   is
      Unused : Money;
      pragma Unreferenced (Unused);
   begin
      declare
         W : constant Money := Welfare_Mask (A, Mask);
         pragma Unreferenced (W);
      begin
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
   end Welfare_Mask_Raises;

begin
   ---------------------------------------------------------------------------
   Section ("Near / tolerances");
   ---------------------------------------------------------------------------
   Check (Near (Mo (1.0), Mo (1.0)), "Near equal");
   Check (Near (Mo (1.0), Mo (1.0 + 1.0E-12)), "Near tiny eps");
   Check (not Near (Mo (1.0), Mo (2.0)), "Near far");
   Check (Near_Raises (Mo (-1.0)), "Near neg tol raises");
   Check (Near (Mo (0.0), Mo (0.5), Mo (0.5)), "Near custom tol");

   ---------------------------------------------------------------------------
   Section ("Bitmask helpers");
   ---------------------------------------------------------------------------
   Check (Item_Bit (Iid (1)) = Bm (1), "Item_Bit 1");
   Check (Item_Bit (Iid (2)) = Bm (2), "Item_Bit 2");
   Check (Item_Bit (Iid (3)) = Bm (4), "Item_Bit 3");
   Check (Item_Bit (Iid (4)) = Bm (8), "Item_Bit 4");
   Check (Bid_Bit (Bidk (1)) = 1, "Bid_Bit 1");
   Check (Bid_Bit (Bidk (3)) = 4, "Bid_Bit 3");
   Check (Max_Mask (Ic (0)) = Bm (0), "Max_Mask 0");
   Check (Max_Mask (Ic (1)) = Bm (1), "Max_Mask 1");
   Check (Max_Mask (Ic (3)) = Bm (7), "Max_Mask 3");
   Check (Max_Mask (Ic (4)) = Bm (15), "Max_Mask 4");
   Check (Mask_Valid (Bm (0), Ic (3)), "Mask_Valid empty");
   Check (Mask_Valid (Bm (7), Ic (3)), "Mask_Valid full");
   Check (not Mask_Valid (Bm (8), Ic (3)), "Mask_Valid overflow");
   Check (Overlaps (Bm (1), Bm (3)), "Overlaps yes");
   Check (not Overlaps (Bm (1), Bm (2)), "Overlaps no");
   Check (Contains (Bm (7), Bm (5)), "Contains yes");
   Check (not Contains (Bm (1), Bm (3)), "Contains no");
   Check (Union (Bm (1), Bm (2)) = Bm (3), "Union");
   Check (Intersection (Bm (3), Bm (2)) = Bm (2), "Intersection");
   Check (Popcount (Bm (0)) = Nat (0), "Popcount 0");
   Check (Popcount (Bm (7)) = Nat (3), "Popcount 7");
   Check (Popcount (Bm (10)) = Nat (2), "Popcount 10");
   Check (Has_Item (Bm (5), Iid (1)), "Has_Item bit0");
   Check (Has_Item (Bm (5), Iid (3)), "Has_Item bit2");
   Check (not Has_Item (Bm (5), Iid (2)), "Has_Item miss");
   Check (Add_Item (Bm (1), Iid (2)) = Bm (3), "Add_Item");
   Check (Remove_Item (Bm (7), Iid (2)) = Bm (5), "Remove_Item");
   Check (Remove_Item (Bm (1), Iid (1)) = Bm (0), "Remove_Item clear");
   Check (Remove_Item (Bm (4), Iid (1)) = Bm (4), "Remove_Item absent");

   ---------------------------------------------------------------------------
   Section ("Auction construction");
   ---------------------------------------------------------------------------
   declare
      A : Auction := Empty_Auction (Ic (3));
   begin
      Check (A.Num_Items = Ic (3), "Empty items=3");
      Check (A.Num_Bids = Bc (0), "Empty bids=0");
      Check (A.Num_Bidders = 0, "Empty bidders=0");
      Check (not A.XOR_Bidding, "Empty XOR false");
      Check (Is_Well_Formed (A), "Empty well-formed");
      Check (Full_Mask (A) = Bm (7), "Full_Mask 3");
      Add_Bid (A, Bidr (1), Item_Bit (Iid (1)), Mo (2.0));
      Check (A.Num_Bids = Bc (1), "Add_Bid count");
      Check (A.Num_Bidders = 1, "Add_Bid bidders");
      Check (A.Bids (Bidk (1)).Value = Mo (2.0), "Add_Bid value");
      Clear (A);
      Check (A.Num_Bids = Bc (0), "Clear bids");
      Check (A.Num_Items = Ic (3), "Clear keeps items");
   end;

   Check (Empty_Raises (Ic (0)), "Empty_Auction 0 raises");
   Check (Empty_Auction (Ic (2), True).XOR_Bidding, "Empty XOR true");

   declare
      A : Auction := Empty_Auction (Ic (2));
      Bids : constant Bid_Array :=
        [1 => (Bidr (1), Item_Bit (Iid (1)), Mo (3.0)),
         2 => (Bidr (2), Item_Bit (Iid (2)), Mo (4.0))];
      B : constant Auction := Make_Auction (Ic (2), Bids);
   begin
      Check (B.Num_Bids = Bc (2), "Make_Auction 2 bids");
      Check (B.Num_Bidders = 2, "Make_Auction 2 bidders");
      Check (Is_Well_Formed (B), "Make well-formed");
      Check (Add_Raises (A, Bidr (1), Bm (4), Mo (1.0)), "bad mask raises");
      Check (Add_Raises (A, Bidr (1), Bm (1), Mo (-1.0)), "neg value raises");
   end;

   declare
      Bad : constant Bid_Array (2 .. 2) :=
        [2 => (Bidr (1), Bm (1), Mo (1.0))];
   begin
      Check (Make_Raises (Ic (1), Bad), "non-1-based raises");
   end;
   Check (Make_Raises (Ic (0), Bid_Array'(1 .. 0 => <>)), "Make 0 items");

   ---------------------------------------------------------------------------
   Section ("Feasibility / welfare");
   ---------------------------------------------------------------------------
   declare
      A : Auction := Empty_Auction (Ic (3));
      Acc : Acceptance := [others => False];
   begin
      Add_Bid (A, Bidr (1), Union (Item_Bit (Iid (1)), Item_Bit (Iid (2))), Mo (5.0));
      Add_Bid (A, Bidr (2), Item_Bit (Iid (2)), Mo (3.0));
      Add_Bid (A, Bidr (2), Item_Bit (Iid (3)), Mo (2.0));
      Acc (Bidk (1)) := True;
      Check (Is_Feasible (A, Acc), "solo package feasible");
      Check (Near (Welfare (A, Acc), Mo (5.0)), "welfare package");
      Acc (Bidk (2)) := True;
      Check (not Is_Feasible (A, Acc), "overlap infeasible");
      Acc := [others => False];
      Acc (Bidk (2)) := True;
      Acc (Bidk (3)) := True;
      Check (Is_Feasible (A, Acc), "disjoint singles");
      Check (Near (Welfare (A, Acc), Mo (5.0)), "welfare 3+2");
      Check (Sold_Items (A, Acc) = (Union (Item_Bit (Iid (2)), Item_Bit (Iid (3)))),
             "sold 2|3");
      Check (Allocation_Of (A, Acc) (2) =
               (Union (Item_Bit (Iid (2)), Item_Bit (Iid (3)))),
             "alloc bidder 2");
      Check (Count_Accepted (Acc, A.Num_Bids) = Bc (2), "count 2");
      Check (Is_Feasible_Mask (A, 6), "mask 6 = bids 2+3");
      Check (not Is_Feasible_Mask (A, 3), "mask 3 overlap");
      Check (Near (Welfare_Mask (A, 1), Mo (5.0)), "Welfare_Mask 1");
      Check (Acc_Mask_Raises (8, Bc (3)), "mask too big raises");
      Check (Acc_Mask_Raises (1, Bc (0)), "mask with 0 bids raises");
      Check (Welfare_Mask_Raises (A, 8), "Welfare_Mask OOR");
   end;

   declare
      A : Auction := Empty_Auction (Ic (2), XOR_Bidding => True);
      Acc : Acceptance := [others => False];
   begin
      Add_Bid (A, Bidr (1), Item_Bit (Iid (1)), Mo (5.0));
      Add_Bid (A, Bidr (1), Item_Bit (Iid (2)), Mo (5.0));
      Acc (Bidk (1)) := True;
      Acc (Bidk (2)) := True;
      Check (not Is_Feasible (A, Acc), "XOR blocks two bids same bidder");
      Acc (Bidk (2)) := False;
      Check (Is_Feasible (A, Acc), "XOR one bid ok");
   end;

   declare
      A : Auction := Empty_Auction (Ic (2));
      Acc : Acceptance := [others => False];
   begin
      Add_Bid (A, Bidr (1), Bm (1), Mo (1.0));
      Acc (Bidk (1)) := True;
      Acc (Bidk (5)) := True;  -- beyond Num_Bids
      Check (not Is_Feasible (A, Acc), "extra Acc slot false required");
   end;

   ---------------------------------------------------------------------------
   Section ("Winner determination: empty / single");
   ---------------------------------------------------------------------------
   declare
      A : constant Auction := Empty_Auction (Ic (2));
      R : constant WDP_Result := Solve (A);
   begin
      Check (Near (R.Welfare, Mo (0.0)), "empty W=0");
      Check (R.Num_Accepted = Bc (0), "empty none accepted");
      Check (R.Sold_Mask = Bm (0), "empty sold 0");
      Check (R.Accepted_Mask = 0, "empty mask 0");
   end;

   declare
      A : Auction := Empty_Auction (Ic (1));
      R : WDP_Result;
   begin
      Add_Bid (A, Bidr (1), Item_Bit (Iid (1)), Mo (7.5));
      R := Winner_Determination (A);
      Check (Near (R.Welfare, Mo (7.5)), "single bid W");
      Check (R.Accepted (Bidk (1)), "single accepted");
      Check (R.Alloc (Bidr (1)) = Item_Bit (Iid (1)), "single alloc");
      Check (Is_Optimal (A, R.Accepted), "single optimal");
   end;

   declare
      Bad : Auction;  -- Num_Items = 0
   begin
      Check (WDP_Raises (Bad), "ill-formed WDP raises");
   end;

   ---------------------------------------------------------------------------
   Section ("Complementarity_Toy");
   ---------------------------------------------------------------------------
   declare
      A : constant Auction := Complementarity_Toy;
      R : constant WDP_Result := Solve (A);
      Acc_Both2 : Acceptance := [others => False];
   begin
      Check (A.Num_Items = Ic (2), "comp items");
      Check (A.Num_Bids = Bc (3), "comp 3 bids");
      Check (not A.XOR_Bidding, "comp OR");
      Check (Near (R.Welfare, Mo (13.0)), "comp W=13");
      Check (R.Accepted (Bidk (1)), "comp accept package");
      Check (not R.Accepted (Bidk (2)) and not R.Accepted (Bidk (3)), "comp reject singles");
      Check (R.Alloc (Bidr (1)) = Full_Mask (A), "comp all to 1");
      Acc_Both2 (Bidk (2)) := True;
      Acc_Both2 (Bidk (3)) := True;
      Check (Is_Feasible (A, Acc_Both2), "comp both2 feasible");
      Check (Near (Welfare (A, Acc_Both2), Mo (12.0)), "comp both2=12");
      Check (not Is_Optimal (A, Acc_Both2), "comp both2 not optimal");
      Check (Is_Optimal (A, R.Accepted), "comp opt flag");
   end;

   ---------------------------------------------------------------------------
   Section ("Substitutes_Toy");
   ---------------------------------------------------------------------------
   declare
      A : constant Auction := Substitutes_Toy;
      R : constant WDP_Result := Solve (A);
   begin
      Check (A.XOR_Bidding, "sub XOR");
      Check (Near (R.Welfare, Mo (5.0)), "sub W=5");
      Check (R.Num_Accepted = Bc (1), "sub one bid");
      --  Tie between bid1 and bid2 (both value 5); smallest mask → bid 1.
      Check (R.Accepted (Bidk (1)), "sub tie → bid 1");
      Check (not R.Accepted (Bidk (2)), "sub not bid 2");
      Check (not R.Accepted (Bidk (3)), "sub not pair");
      Check (R.Accepted_Mask = 1, "sub mask=1");
   end;

   ---------------------------------------------------------------------------
   Section ("Airport_Slots_Toy");
   ---------------------------------------------------------------------------
   declare
      A : constant Auction := Airport_Slots_Toy;
      R : constant WDP_Result := Solve (A);
   begin
      Check (A.Num_Items = Ic (3), "air items");
      Check (A.Num_Bids = Bc (6), "air 6 bids");
      Check (A.XOR_Bidding, "air XOR");
      Check (Near (R.Welfare, Mo (15.0)), "air W=15");
      --  Airline1 pair dawn+noon (bid1) + airline2 dusk (bid4).
      Check (R.Accepted (Bidk (1)), "air accept A1 pair");
      Check (R.Accepted (Bidk (4)), "air accept A2 dusk");
      Check (Popcount (R.Sold_Mask) = Nat (3), "air all sold");
      Check (R.Alloc (Bidr (1)) = (Union (Item_Bit (Iid (1)), Item_Bit (Iid (2)))),
             "air alloc 1");
      Check (R.Alloc (Bidr (2)) = Item_Bit (Iid (3)), "air alloc 2");
      Check (R.Alloc (Bidr (3)) = Bm (0), "air 3 gets nothing");
   end;

   ---------------------------------------------------------------------------
   Section ("Spectrum_Pair_Toy");
   ---------------------------------------------------------------------------
   declare
      A : constant Auction := Spectrum_Pair_Toy;
      R : constant WDP_Result := Solve (A);
   begin
      Check (Near (R.Welfare, Mo (16.0)), "spec W=16");
      Check (R.Accepted (Bidk (1)), "spec pair to B1");
      Check (R.Alloc (Bidr (1)) = Full_Mask (A), "spec all to 1");
      Check (Popcount (R.Sold_Mask) = Nat (2), "spec both sold");
   end;

   ---------------------------------------------------------------------------
   Section ("Free disposal / partial cover");
   ---------------------------------------------------------------------------
   declare
      A : Auction := Empty_Auction (Ic (3));
      R : WDP_Result;
   begin
      Add_Bid (A, Bidr (1), Item_Bit (Iid (1)), Mo (10.0));
      --  Items 2,3 remain unsold — free disposal.
      R := Solve (A);
      Check (Near (R.Welfare, Mo (10.0)), "partial W");
      Check (R.Sold_Mask = Item_Bit (Iid (1)), "partial sold");
      Check (not Has_Item (R.Sold_Mask, Iid (2)), "item2 free");
      Check (not Has_Item (R.Sold_Mask, Iid (3)), "item3 free");
   end;

   ---------------------------------------------------------------------------
   Section ("Tie-break smallest mask");
   ---------------------------------------------------------------------------
   declare
      A : Auction := Empty_Auction (Ic (2));
      R : WDP_Result;
   begin
      Add_Bid (A, Bidr (1), Item_Bit (Iid (1)), Mo (5.0));
      Add_Bid (A, Bidr (2), Item_Bit (Iid (1)), Mo (5.0));
      R := Solve (A);
      Check (Near (R.Welfare, Mo (5.0)), "tie W");
      Check (R.Accepted_Mask = 1, "tie prefers bid 1");
      Check (R.Accepted (Bidk (1)) and not R.Accepted (Bidk (2)), "tie accept first");
   end;

   ---------------------------------------------------------------------------
   Section ("Zero-value bid / empty bundle");
   ---------------------------------------------------------------------------
   declare
      A : Auction := Empty_Auction (Ic (2));
      R : WDP_Result;
   begin
      Add_Bid (A, Bidr (1), Bm (0), Mo (0.0));
      Add_Bid (A, Bidr (2), Item_Bit (Iid (1)), Mo (3.0));
      R := Solve (A);
      --  Empty bundle never overlaps; zero value does not beat leaving it out
      --  under smallest-mask tie when welfare equal — accepting only bid2
      --  has mask 2; accepting both has welfare 3 and mask 3. Prefer mask 2.
      Check (Near (R.Welfare, Mo (3.0)), "zero empty W=3");
      Check (R.Accepted_Mask = 2, "prefer not taking zero empty");
   end;

   ---------------------------------------------------------------------------
   Section ("VCG_Payments complementarity");
   ---------------------------------------------------------------------------
   declare
      A : constant Auction := Complementarity_Toy;
      R : constant WDP_Result := Solve (A);
      P : constant Money_Vector := VCG_Payments (A, R);
      --  Without bidder 1: accept both of 2 → W=12.
      --  At opt, others get 0, v1*=13, so p1 = 12 - 0 = 12.
      --  Without bidder 2: only bid1 → W=13; others at opt = 13; p2 = 13-13=0.
   begin
      Check (Near (P (Bidr (1)), Mo (12.0)), "VCG p1=12");
      Check (Near (P (Bidr (2)), Mo (0.0)), "VCG p2=0");
      Check (Near (P (Bidr (3)), Mo (0.0)), "VCG unused 0");
   end;

   declare
      A : constant Auction := Substitutes_Toy;
      R : constant WDP_Result := Solve (A);
      P : constant Money_Vector := VCG_Payments (A, R);
      --  Opt: bid1 to bidder1, W=5. Without 1: pair to 2 → W=4.
      --  Others at opt = 0; p1 = 4 - 0 = 4. Without 2: still W=5; p2=0.
   begin
      Check (Near (P (Bidr (1)), Mo (4.0)), "sub VCG p1=4");
      Check (Near (P (Bidr (2)), Mo (0.0)), "sub VCG p2=0");
   end;

   declare
      A : constant Auction := Complementarity_Toy;
      Bad_Opt : WDP_Result := Solve (A);
   begin
      Bad_Opt.Welfare := Bad_Opt.Welfare + 1.0;
      Check (VCG_Raises (A, Bad_Opt), "VCG bad Opt raises");
   end;

   ---------------------------------------------------------------------------
   Section ("Drop_Bidder");
   ---------------------------------------------------------------------------
   declare
      A : constant Auction := Complementarity_Toy;
      D1 : constant Auction := Drop_Bidder (A, Bidr (1));
      D2 : constant Auction := Drop_Bidder (A, Bidr (2));
   begin
      Check (D1.Num_Bids = Bc (2), "drop1 leaves 2");
      Check (D2.Num_Bids = Bc (1), "drop2 leaves 1");
      Check (Near (Solve (D1).Welfare, Mo (12.0)), "drop1 W=12");
      Check (Near (Solve (D2).Welfare, Mo (13.0)), "drop2 W=13");
   end;

   ---------------------------------------------------------------------------
   Section ("Multi-bidder OR packing");
   ---------------------------------------------------------------------------
   declare
      A : Auction := Empty_Auction (Ic (4));
      R : WDP_Result;
   begin
      Add_Bid (A, Bidr (1), Union (Item_Bit (Iid (1)), Item_Bit (Iid (2))), Mo (8.0));
      Add_Bid (A, Bidr (2), Item_Bit (Iid (3)), Mo (3.0));
      Add_Bid (A, Bidr (3), Item_Bit (Iid (4)), Mo (4.0));
      Add_Bid (A, Bidr (4), Union (Item_Bit (Iid (2)), Item_Bit (Iid (3))), Mo (9.0));
      R := Solve (A);
      --  Best: bid1 (8) + bid2 (3) + bid3 (4) = 15 (all four items).
      --  Alternative bid4 (9) + bid3 (4) = 13 is worse.
      Check (Near (R.Welfare, Mo (15.0)), "pack W=15");
      Check (R.Accepted (Bidk (1)) and R.Accepted (Bidk (2))
               and R.Accepted (Bidk (3)), "pack bids 1+2+3");
      Check (not R.Accepted (Bidk (4)), "pack not bid4");
   end;

   ---------------------------------------------------------------------------
   Section ("Acceptance mask round-trip");
   ---------------------------------------------------------------------------
   declare
      Acc : Acceptance := [others => False];
      M   : Bid_Subset;
      Acc2 : Acceptance;
   begin
      Acc (Bidk (1)) := True;
      Acc (Bidk (3)) := True;
      M := Mask_From_Acceptance (Acc, Bc (4));
      Check (M = 5, "mask from acc =5");
      Acc2 := Acceptance_From_Mask (M, Bc (4));
      Check (Acc2 (Bidk (1)) and Acc2 (Bidk (3)) and not Acc2 (Bidk (2)) and not Acc2 (Bidk (4)),
             "round-trip bits");
      Check (Mask_From_Acceptance
               (Acceptance_From_Mask (0, Bc (0)), Bc (0)) = 0,
             "empty round-trip");
   end;

   ---------------------------------------------------------------------------
   Section ("Is_Well_Formed negatives");
   ---------------------------------------------------------------------------
   declare
      A : Auction := Empty_Auction (Ic (2));
   begin
      A.Bids (Bidk (1)) := (Bidr (1), Bm (7), Mo (1.0));  -- mask too big
      A.Num_Bids := 1;
      A.Num_Bidders := 1;
      Check (not Is_Well_Formed (A), "bad mask not well-formed");
   end;
   declare
      A : Auction := Empty_Auction (Ic (2));
   begin
      Add_Bid (A, Bidr (2), Bm (1), Mo (1.0));
      A.Num_Bidders := 1;  -- inconsistent (actual hi=2)
      Check (not Is_Well_Formed (A), "bidder count mismatch");
   end;
   declare
      A : Auction := Empty_Auction (Ic (2));
   begin
      Add_Bid (A, Bidr (1), Bm (1), Mo (1.0));
      A.Bids (Bidk (1)).Value := Mo (-0.5);
      Check (not Is_Well_Formed (A), "neg value not well-formed");
   end;

   ---------------------------------------------------------------------------
   Section ("Capacity edge: many small bids");
   ---------------------------------------------------------------------------
   declare
      A : Auction := Empty_Auction (Ic (8));
      R : WDP_Result;
   begin
      --  8 disjoint single-item bids value 1..8; optimum takes all, W=36.
      for I in 1 .. 8 loop
         Add_Bid
           (A, Bidr (I), Item_Bit (Iid (I)), Mo (Money (I)));
      end loop;
      R := Solve (A);
      Check (Near (R.Welfare, Mo (36.0)), "8 singles W=36");
      Check (R.Num_Accepted = Bc (8), "8 accepted");
      Check (R.Sold_Mask = Max_Mask (Ic (8)), "all 8 sold");
   end;

   ---------------------------------------------------------------------------
   Section ("Fill Max_Bids then reject");
   ---------------------------------------------------------------------------
   declare
      A : Auction := Empty_Auction (Ic (1));
      Ok : Boolean := True;
   begin
      for K in 1 .. Max_Bids loop
         Add_Bid (A, Bidr (1), Item_Bit (Iid (1)), Mo (1.0));
      end loop;
      Check (A.Num_Bids = Bc (Max_Bids), "filled Max_Bids");
      Check (Add_Raises (A, Bidr (1), Item_Bit (Iid (1)), Mo (1.0)),
             "over Max_Bids raises");
      --  XOR would allow only one; without XOR all overlap → take best one.
      declare
         R : constant WDP_Result := Solve (A);
      begin
         Check (Near (R.Welfare, Mo (1.0)), "overlapping identical W=1");
         Check (R.Num_Accepted = Bc (1), "one of many");
         Check (R.Accepted_Mask = 1, "smallest mask among ties");
      end;
      pragma Unreferenced (Ok);
   end;

   ---------------------------------------------------------------------------
   Section ("Airport VCG smoke");
   ---------------------------------------------------------------------------
   declare
      A : constant Auction := Airport_Slots_Toy;
      R : constant WDP_Result := Solve (A);
      P : constant Money_Vector := VCG_Payments (A, R);
      Sum_P : Money := 0.0;
   begin
      for B in 1 .. A.Num_Bidders loop
         Sum_P := Sum_P + P (Bidr (Positive (B)));
         Check (P (Bidr (Positive (B))) >= Mo (-1.0E-9), "air p nonnegative-ish");
      end loop;
      Check (Sum_P > Mo (0.0), "air some revenue");
      --  Recompute WDP equals R
      Check (Near (Solve (A).Welfare, R.Welfare), "air solve stable");
   end;

   ---------------------------------------------------------------------------
   Section ("Solve alias");
   ---------------------------------------------------------------------------
   declare
      A : constant Auction := Spectrum_Pair_Toy;
      R1 : constant WDP_Result := Winner_Determination (A);
      R2 : constant WDP_Result := Solve (A);
   begin
      Check (R1.Accepted_Mask = R2.Accepted_Mask, "Solve alias mask");
      Check (Near (R1.Welfare, R2.Welfare), "Solve alias W");
   end;

   ---------------------------------------------------------------------------
   Section ("Is_Optimal tol raise");
   ---------------------------------------------------------------------------
   declare
      A : constant Auction := Complementarity_Toy;
      R : constant WDP_Result := Solve (A);
      function Opt_Raises return Boolean is
         Unused : Boolean;
      begin
         Unused := Is_Optimal (A, R.Accepted, Mo (-0.1));
         return False;
      exception
         when Invalid_Argument =>
            return True;
      end Opt_Raises;
   begin
      Check (Opt_Raises, "Is_Optimal neg tol");
      Check (Is_Optimal (A, R.Accepted, Mo (1.0E-6)), "Is_Optimal loose tol");
   end;

   ---------------------------------------------------------------------------
   Section ("Item_Bit / Full_Mask across sizes");
   ---------------------------------------------------------------------------
   for N in 1 .. 10 loop
      declare
         A : constant Auction := Empty_Auction (Ic (N));
         M : constant Bundle_Mask := Full_Mask (A);
      begin
         Check (Popcount (M) = Nat (N),
                "Full_Mask pop N=" & Item_Count'Image (Ic (N)));
         Check (Mask_Valid (M, Ic (N)),
                "Full valid N=" & Item_Count'Image (Ic (N)));
      end;
   end loop;

   for I in 1 .. 12 loop
      Check (Popcount (Item_Bit (Iid (I))) = Nat (1),
             "Item_Bit pop I=" & Item_Id'Image (Iid (I)));
   end loop;

   ---------------------------------------------------------------------------
   Section ("Enumerator sanity: all subsets counted");
   ---------------------------------------------------------------------------
   declare
      A : Auction := Empty_Auction (Ic (2));
      Feasible : Natural := 0;
   begin
      Add_Bid (A, Bidr (1), Item_Bit (Iid (1)), Mo (1.0));
      Add_Bid (A, Bidr (2), Item_Bit (Iid (2)), Mo (1.0));
      Add_Bid (A, Bidr (3), Union (Item_Bit (Iid (1)), Item_Bit (Iid (2))), Mo (1.5));
      for Mask in Bid_Subset range 0 .. 7 loop
         if Is_Feasible_Mask (A, Mask) then
            Feasible := Feasible + 1;
         end if;
      end loop;
      --  ∅, {1}, {2}, {1,2}, {3} = 5 feasible; {1,3},{2,3},{1,2,3} overlap.
      Check (Feasible = Nat (5), "3-bid feasible count=5");
      Check (Near (Solve (A).Welfare, Mo (2.0)), "1+2 beats package 1.5");
   end;

   ---------------------------------------------------------------------------
   Section ("XOR vs OR same bids");
   ---------------------------------------------------------------------------
   declare
      Bids : constant Bid_Array :=
        [1 => (Bidr (1), Item_Bit (Iid (1)), Mo (3.0)),
         2 => (Bidr (1), Item_Bit (Iid (2)), Mo (3.0))];
      Or_A  : constant Auction := Make_Auction (Ic (2), Bids, False);
      Xor_A : constant Auction := Make_Auction (Ic (2), Bids, True);
   begin
      Check (Near (Solve (Or_A).Welfare, Mo (6.0)), "OR takes both");
      Check (Near (Solve (Xor_A).Welfare, Mo (3.0)), "XOR takes one");
      Check (Solve (Xor_A).Accepted_Mask = 1, "XOR tie mask 1");
   end;

   ---------------------------------------------------------------------------
   Section ("VCG single-item second-price flavour");
   ---------------------------------------------------------------------------
   declare
      --  One item, three bids 10,7,3 from distinct bidders — like Vickrey.
      A : Auction := Empty_Auction (Ic (1));
      R : WDP_Result;
      P : Money_Vector;
   begin
      Add_Bid (A, Bidr (1), Item_Bit (Iid (1)), Mo (10.0));
      Add_Bid (A, Bidr (2), Item_Bit (Iid (1)), Mo (7.0));
      Add_Bid (A, Bidr (3), Item_Bit (Iid (1)), Mo (3.0));
      R := Solve (A);
      P := VCG_Payments (A, R);
      Check (Near (R.Welfare, Mo (10.0)), "SPA W=10");
      Check (R.Accepted (Bidk (1)), "SPA winner 1");
      Check (Near (P (Bidr (1)), Mo (7.0)), "SPA p1=second price");
      Check (Near (P (Bidr (2)), Mo (0.0)), "SPA p2=0");
      Check (Near (P (Bidr (3)), Mo (0.0)), "SPA p3=0");
   end;

   ---------------------------------------------------------------------------
   Section ("Add_Bid on zero-item auction");
   ---------------------------------------------------------------------------
   declare
      A : Auction;  -- default Num_Items=0
   begin
      Check (Add_Raises (A, Bidr (1), Bm (0), Mo (1.0)),
             "Add on empty items raises");
   end;

   ---------------------------------------------------------------------------
   Section ("Allocation_Of multi");
   ---------------------------------------------------------------------------
   declare
      A : Auction := Empty_Auction (Ic (4), XOR_Bidding => False);
      Acc : Acceptance := [others => False];
      Alloc : Bidder_Allocation;
   begin
      Add_Bid (A, Bidr (1), Item_Bit (Iid (1)), Mo (1.0));
      Add_Bid (A, Bidr (1), Item_Bit (Iid (2)), Mo (1.0));
      Add_Bid (A, Bidr (2), Union (Item_Bit (Iid (3)), Item_Bit (Iid (4))), Mo (2.0));
      Acc (Bidk (1)) := True;
      Acc (Bidk (2)) := True;
      Acc (Bidk (3)) := True;
      Alloc := Allocation_Of (A, Acc);
      Check (Alloc (Bidr (1)) = (Union (Item_Bit (Iid (1)), Item_Bit (Iid (2)))),
             "OR alloc bidder1");
      Check (Alloc (Bidr (2)) = (Union (Item_Bit (Iid (3)), Item_Bit (Iid (4)))),
             "alloc bidder2");
      Check (Alloc (Bidr (3)) = Bm (0), "alloc unused");
   end;

   ---------------------------------------------------------------------------
   Section ("Spectrum VCG");
   ---------------------------------------------------------------------------
   declare
      A : constant Auction := Spectrum_Pair_Toy;
      R : constant WDP_Result := Solve (A);
      P : constant Money_Vector := VCG_Payments (A, R);
      --  Without B1: best is B2 on A (7) + B3 on B (8) = 15.
      --  Others at opt = 0; p1 = 15.
   begin
      Check (Near (P (Bidr (1)), Mo (15.0)), "spec VCG p1=15");
      Check (Near (P (Bidr (2)), Mo (0.0)), "spec VCG p2=0");
      Check (Near (P (Bidr (3)), Mo (0.0)), "spec VCG p3=0");
   end;

   ---------------------------------------------------------------------------
   Section ("Batch mask validity 0..15 for N=4");
   ---------------------------------------------------------------------------
   for M in 0 .. 15 loop
      Check (Mask_Valid (Bm (M), Ic (4)),
             "valid4 M=" & Natural'Image (M));
   end loop;
   Check (not Mask_Valid (Bm (16), Ic (4)), "16 invalid for N=4");
   Check (Mask_Valid (Bm (16), Ic (5)), "16 valid for N=5");

   ---------------------------------------------------------------------------
   Section ("Contains / Union algebra");
   ---------------------------------------------------------------------------
   Check (Contains (Bm (15), Bm (0)), "contains empty");
   Check (Contains (Bm (15), Bm (15)), "contains self");
   Check (Union (Bm (0), Bm (0)) = Bm (0), "union empty");
   Check (Intersection (Bm (15), Bm (0)) = Bm (0), "inter empty");
   Check (not Overlaps (Bm (0), Bm (7)), "no overlap empty");

   ---------------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------------

   New_Line;
   Put_Line ("=================================");
   Put_Line
     ("Results: " & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count = 0 then
      Put_Line ("ALL PASSED");
   else
      Put_Line ("SOME FAILED");
   end if;

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
