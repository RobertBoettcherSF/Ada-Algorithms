--  Combinatorial_Auction body — classroom WDP by subset enumeration.

pragma Ada_2022;

with Interfaces;

package body Combinatorial_Auction
  with SPARK_Mode => Off
is

   subtype U32 is Interfaces.Unsigned_32;
   use type Interfaces.Unsigned_32;

   -------------------------------------------------------------------------
   -- Local helpers
   -------------------------------------------------------------------------

   function Power2 (E : Natural) return Natural is
      R : Natural := 1;
   begin
      for I in 1 .. E loop
         R := R * 2;
      end loop;
      return R;
   end Power2;

   function To_U (X : Natural) return U32 is (U32 (X));
   function From_U (X : U32) return Natural is (Natural (X));

   function Bit_Or (A, B : Natural) return Natural is
     (From_U (To_U (A) or To_U (B)));

   function Bit_And (A, B : Natural) return Natural is
     (From_U (To_U (A) and To_U (B)));

   function Abs_Diff (X, Y : Money) return Money is
     (if X >= Y then X - Y else Y - X);

   function Accepted_Value_Of
     (A : Auction; Acc : Acceptance; B : Bidder_Id) return Money
   is
      S : Money := 0.0;
   begin
      for K in 1 .. A.Num_Bids loop
         if Acc (Bid_Id (K)) and then A.Bids (Bid_Id (K)).Bidder = B then
            S := S + A.Bids (Bid_Id (K)).Value;
         end if;
      end loop;
      return S;
   end Accepted_Value_Of;

   function Build_Result
     (A : Auction; Mask : Bid_Subset; W : Money) return WDP_Result
   is
      R   : WDP_Result;
      Acc : constant Acceptance :=
        Acceptance_From_Mask (Mask, A.Num_Bids);
   begin
      R.Accepted      := Acc;
      R.Accepted_Mask := Mask;
      R.Num_Accepted  := Count_Accepted (Acc, A.Num_Bids);
      R.Welfare       := W;
      R.Alloc         := Allocation_Of (A, Acc);
      R.Sold_Mask     := Sold_Items (A, Acc);
      return R;
   end Build_Result;

   -------------------------------------------------------------------------
   -- Near
   -------------------------------------------------------------------------

   function Near
     (A, B : Money; Tol : Money := Default_Tol) return Boolean
   is
   begin
      if Tol < 0.0 then
         raise Invalid_Argument with "Near: Tol < 0";
      end if;
      return Abs_Diff (A, B) <= Tol;
   end Near;

   -------------------------------------------------------------------------
   -- Bitmask helpers
   -------------------------------------------------------------------------

   function Item_Bit (I : Item_Id) return Bundle_Mask is
     (Power2 (Natural (I) - 1));

   function Bid_Bit (K : Bid_Id) return Bid_Subset is
     (Power2 (Natural (K) - 1));

   function Max_Mask (N : Item_Count) return Bundle_Mask is
   begin
      if N = 0 then
         return 0;
      end if;
      return Power2 (Natural (N)) - 1;
   end Max_Mask;

   function Mask_Valid
     (M : Bundle_Mask; Num_Items : Item_Count) return Boolean
   is
     (M <= Max_Mask (Num_Items));

   function Overlaps (A, B : Bundle_Mask) return Boolean is
     (Bit_And (A, B) /= 0);

   function Contains (Outer, Inner : Bundle_Mask) return Boolean is
     (Bit_And (Outer, Inner) = Inner);

   function Union (A, B : Bundle_Mask) return Bundle_Mask is
     (Bit_Or (A, B));

   function Intersection (A, B : Bundle_Mask) return Bundle_Mask is
     (Bit_And (A, B));

   function Popcount (M : Bundle_Mask) return Natural is
      X : U32 := To_U (M);
      C : Natural := 0;
   begin
      while X /= 0 loop
         if (X and 1) = 1 then
            C := C + 1;
         end if;
         X := Interfaces.Shift_Right (X, 1);
      end loop;
      return C;
   end Popcount;

   function Has_Item (M : Bundle_Mask; I : Item_Id) return Boolean is
     (Bit_And (M, Item_Bit (I)) /= 0);

   function Add_Item (M : Bundle_Mask; I : Item_Id) return Bundle_Mask is
     (Bit_Or (M, Item_Bit (I)));

   function Remove_Item (M : Bundle_Mask; I : Item_Id) return Bundle_Mask is
     (M - Bit_And (M, Item_Bit (I)));

   -------------------------------------------------------------------------
   -- Auction construction
   -------------------------------------------------------------------------

   function Empty_Auction
     (Num_Items : Item_Count; XOR_Bidding : Boolean := False) return Auction
   is
      A : Auction;
   begin
      if Num_Items = 0 then
         raise Invalid_Argument with "Empty_Auction: Num_Items = 0";
      end if;
      A.Num_Items   := Num_Items;
      A.Num_Bids    := 0;
      A.Num_Bidders := 0;
      A.XOR_Bidding := XOR_Bidding;
      A.Bids        := [others => <>];
      return A;
   end Empty_Auction;

   procedure Clear (A : in out Auction) is
   begin
      A.Num_Bids    := 0;
      A.Num_Bidders := 0;
      A.Bids        := [others => <>];
   end Clear;

   procedure Add_Bid
     (A      : in out Auction;
      Bidder : Bidder_Id;
      Bundle : Bundle_Mask;
      Value  : Money)
   is
   begin
      if A.Num_Items = 0 then
         raise Invalid_Argument with "Add_Bid: auction has Num_Items = 0";
      end if;
      if A.Num_Bids = Max_Bids then
         raise Invalid_Argument with "Add_Bid: Max_Bids exceeded";
      end if;
      if not Mask_Valid (Bundle, A.Num_Items) then
         raise Invalid_Argument with "Add_Bid: invalid bundle mask";
      end if;
      if Value < 0.0 then
         raise Invalid_Argument with "Add_Bid: Value < 0";
      end if;
      A.Num_Bids := A.Num_Bids + 1;
      A.Bids (Bid_Id (A.Num_Bids)) :=
        (Bidder => Bidder, Bundle => Bundle, Value => Value);
      if Bidder_Count (Bidder) > A.Num_Bidders then
         A.Num_Bidders := Bidder_Count (Bidder);
      end if;
   end Add_Bid;

   function Make_Auction
     (Num_Items   : Item_Count;
      Bids        : Bid_Array;
      XOR_Bidding : Boolean := False) return Auction
   is
      A : Auction;
   begin
      if Num_Items = 0 then
         raise Invalid_Argument with "Make_Auction: Num_Items = 0";
      end if;
      if Bids'Length = 0 then
         return Empty_Auction (Num_Items, XOR_Bidding);
      end if;
      if Bids'First /= 1 then
         raise Invalid_Argument with "Make_Auction: bids not 1-based";
      end if;
      if Bids'Length > Max_Bids then
         raise Invalid_Argument with "Make_Auction: too many bids";
      end if;
      A := Empty_Auction (Num_Items, XOR_Bidding);
      for K in Bids'Range loop
         Add_Bid (A, Bids (K).Bidder, Bids (K).Bundle, Bids (K).Value);
      end loop;
      return A;
   end Make_Auction;

   function Is_Well_Formed (A : Auction) return Boolean is
      Hi : Bidder_Count := 0;
   begin
      if A.Num_Items = 0 then
         return False;
      end if;
      for K in 1 .. A.Num_Bids loop
         declare
            B : Bid renames A.Bids (Bid_Id (K));
         begin
            if not Mask_Valid (B.Bundle, A.Num_Items) then
               return False;
            end if;
            if B.Value < 0.0 then
               return False;
            end if;
            if Bidder_Count (B.Bidder) > Hi then
               Hi := Bidder_Count (B.Bidder);
            end if;
         end;
      end loop;
      return A.Num_Bidders = Hi;
   end Is_Well_Formed;

   function Full_Mask (A : Auction) return Bundle_Mask is
   begin
      if A.Num_Items = 0 then
         raise Invalid_Argument with "Full_Mask: Num_Items = 0";
      end if;
      return Max_Mask (A.Num_Items);
   end Full_Mask;

   -------------------------------------------------------------------------
   -- Feasibility / welfare
   -------------------------------------------------------------------------

   function Acceptance_From_Mask
     (Mask : Bid_Subset; Num_Bids : Bid_Count) return Acceptance
   is
      Acc   : Acceptance := [others => False];
      Limit : Bid_Subset;
   begin
      if Num_Bids = 0 then
         if Mask /= 0 then
            raise Invalid_Argument with
              "Acceptance_From_Mask: nonzero mask with 0 bids";
         end if;
         return Acc;
      end if;
      Limit := Power2 (Natural (Num_Bids));
      if Mask >= Limit then
         raise Invalid_Argument with
           "Acceptance_From_Mask: mask out of range";
      end if;
      for K in 1 .. Num_Bids loop
         Acc (Bid_Id (K)) := Bit_And (Mask, Bid_Bit (Bid_Id (K))) /= 0;
      end loop;
      return Acc;
   end Acceptance_From_Mask;

   function Mask_From_Acceptance
     (Acc : Acceptance; Num_Bids : Bid_Count) return Bid_Subset
   is
      M : Bid_Subset := 0;
   begin
      for K in 1 .. Num_Bids loop
         if Acc (Bid_Id (K)) then
            M := Bit_Or (M, Bid_Bit (Bid_Id (K)));
         end if;
      end loop;
      return M;
   end Mask_From_Acceptance;

   function Is_Feasible
     (A : Auction; Acc : Acceptance) return Boolean
   is
      Used : Bundle_Mask := 0;
      Seen : array (Bidder_Id) of Boolean := [others => False];
   begin
      if A.Num_Bids < Max_Bids then
         for K in Bid_Id (A.Num_Bids + 1) .. Bid_Id'Last loop
            if Acc (K) then
               return False;
            end if;
         end loop;
      end if;

      for K in 1 .. A.Num_Bids loop
         if Acc (Bid_Id (K)) then
            declare
               B : Bid renames A.Bids (Bid_Id (K));
            begin
               if Overlaps (Used, B.Bundle) then
                  return False;
               end if;
               Used := Union (Used, B.Bundle);
               if A.XOR_Bidding then
                  if Seen (B.Bidder) then
                     return False;
                  end if;
                  Seen (B.Bidder) := True;
               end if;
            end;
         end if;
      end loop;
      return True;
   end Is_Feasible;

   function Is_Feasible_Mask
     (A : Auction; Mask : Bid_Subset) return Boolean
   is
   begin
      if A.Num_Bids = 0 then
         return Mask = 0;
      end if;
      if Mask >= Power2 (Natural (A.Num_Bids)) then
         return False;
      end if;
      return Is_Feasible (A, Acceptance_From_Mask (Mask, A.Num_Bids));
   end Is_Feasible_Mask;

   function Welfare (A : Auction; Acc : Acceptance) return Money is
      S : Money := 0.0;
   begin
      for K in 1 .. A.Num_Bids loop
         if Acc (Bid_Id (K)) then
            S := S + A.Bids (Bid_Id (K)).Value;
         end if;
      end loop;
      return S;
   end Welfare;

   function Welfare_Mask (A : Auction; Mask : Bid_Subset) return Money is
   begin
      if A.Num_Bids = 0 then
         return 0.0;
      end if;
      if Mask >= Power2 (Natural (A.Num_Bids)) then
         raise Invalid_Argument with "Welfare_Mask: mask out of range";
      end if;
      return Welfare (A, Acceptance_From_Mask (Mask, A.Num_Bids));
   end Welfare_Mask;

   function Sold_Items (A : Auction; Acc : Acceptance) return Bundle_Mask is
      U : Bundle_Mask := 0;
   begin
      for K in 1 .. A.Num_Bids loop
         if Acc (Bid_Id (K)) then
            U := Union (U, A.Bids (Bid_Id (K)).Bundle);
         end if;
      end loop;
      return U;
   end Sold_Items;

   function Allocation_Of
     (A : Auction; Acc : Acceptance) return Bidder_Allocation
   is
      Alloc : Bidder_Allocation := [others => 0];
   begin
      for K in 1 .. A.Num_Bids loop
         if Acc (Bid_Id (K)) then
            declare
               B : Bid renames A.Bids (Bid_Id (K));
            begin
               Alloc (B.Bidder) := Union (Alloc (B.Bidder), B.Bundle);
            end;
         end if;
      end loop;
      return Alloc;
   end Allocation_Of;

   function Count_Accepted
     (Acc : Acceptance; Num_Bids : Bid_Count) return Bid_Count
   is
      C : Bid_Count := 0;
   begin
      for K in 1 .. Num_Bids loop
         if Acc (Bid_Id (K)) then
            C := C + 1;
         end if;
      end loop;
      return C;
   end Count_Accepted;

   -------------------------------------------------------------------------
   -- Winner determination
   -------------------------------------------------------------------------

   function Winner_Determination (A : Auction) return WDP_Result is
      Best_Mask : Bid_Subset := 0;
      Best_W    : Money := 0.0;
      Found     : Boolean := False;
      Limit     : Bid_Subset;
   begin
      if not Is_Well_Formed (A) then
         raise Invalid_Argument with
           "Winner_Determination: auction not well-formed";
      end if;

      if A.Num_Bids = 0 then
         return Build_Result (A, 0, 0.0);
      end if;

      Limit := Power2 (Natural (A.Num_Bids));
      for Mask in Bid_Subset range 0 .. Limit - 1 loop
         if Is_Feasible_Mask (A, Mask) then
            declare
               W : constant Money := Welfare_Mask (A, Mask);
            begin
               if (not Found)
                 or else W > Best_W + Default_Tol
                 or else (Near (W, Best_W) and then Mask < Best_Mask)
               then
                  Best_W    := W;
                  Best_Mask := Mask;
                  Found     := True;
               end if;
            end;
         end if;
      end loop;

      return Build_Result (A, Best_Mask, Best_W);
   end Winner_Determination;

   function Solve (A : Auction) return WDP_Result is
     (Winner_Determination (A));

   function Is_Optimal
     (A : Auction; Acc : Acceptance; Tol : Money := Default_Tol)
     return Boolean
   is
      Opt : WDP_Result;
   begin
      if Tol < 0.0 then
         raise Invalid_Argument with "Is_Optimal: Tol < 0";
      end if;
      if not Is_Feasible (A, Acc) then
         return False;
      end if;
      Opt := Winner_Determination (A);
      return Near (Welfare (A, Acc), Opt.Welfare, Tol);
   end Is_Optimal;

   -------------------------------------------------------------------------
   -- Drop bidder / VCG
   -------------------------------------------------------------------------

   function Drop_Bidder (A : Auction; B : Bidder_Id) return Auction is
      R : Auction;
   begin
      if not Is_Well_Formed (A) then
         raise Invalid_Argument with "Drop_Bidder: auction not well-formed";
      end if;
      R := Empty_Auction (A.Num_Items, A.XOR_Bidding);
      for K in 1 .. A.Num_Bids loop
         if A.Bids (Bid_Id (K)).Bidder /= B then
            Add_Bid
              (R,
               A.Bids (Bid_Id (K)).Bidder,
               A.Bids (Bid_Id (K)).Bundle,
               A.Bids (Bid_Id (K)).Value);
         end if;
      end loop;
      return R;
   end Drop_Bidder;

   function VCG_Payments
     (A : Auction; Opt : WDP_Result) return Money_Vector
   is
      P       : Money_Vector := [others => 0.0];
      Check   : constant WDP_Result := Winner_Determination (A);
      Present : array (Bidder_Id) of Boolean := [others => False];
   begin
      if not Near (Check.Welfare, Opt.Welfare)
        or else Check.Accepted_Mask /= Opt.Accepted_Mask
      then
         raise Invalid_Argument with
           "VCG_Payments: Opt is not the WDP optimum for A";
      end if;

      for K in 1 .. A.Num_Bids loop
         Present (A.Bids (Bid_Id (K)).Bidder) := True;
      end loop;

      for B in Bidder_Id loop
         if Present (B) then
            declare
               A_Without : constant Auction := Drop_Bidder (A, B);
               W_Without : constant Money :=
                 Winner_Determination (A_Without).Welfare;
               V_Star    : constant Money :=
                 Accepted_Value_Of (A, Opt.Accepted, B);
               Others_At_Opt : constant Money := Opt.Welfare - V_Star;
            begin
               P (B) := W_Without - Others_At_Opt;
            end;
         end if;
      end loop;
      return P;
   end VCG_Payments;

   -------------------------------------------------------------------------
   -- Toy instances
   -------------------------------------------------------------------------

   function Complementarity_Toy return Auction is
      A : Auction := Empty_Auction (2, XOR_Bidding => False);
   begin
      Add_Bid (A, 1, Bit_Or (Item_Bit (1), Item_Bit (2)), 13.0);
      Add_Bid (A, 2, Item_Bit (1), 6.0);
      Add_Bid (A, 2, Item_Bit (2), 6.0);
      return A;
   end Complementarity_Toy;

   function Substitutes_Toy return Auction is
      A : Auction := Empty_Auction (2, XOR_Bidding => True);
   begin
      Add_Bid (A, 1, Item_Bit (1), 5.0);
      Add_Bid (A, 1, Item_Bit (2), 5.0);
      Add_Bid (A, 2, Bit_Or (Item_Bit (1), Item_Bit (2)), 4.0);
      return A;
   end Substitutes_Toy;

   function Airport_Slots_Toy return Auction is
      A : Auction := Empty_Auction (3, XOR_Bidding => True);
   begin
      Add_Bid (A, 1, Bit_Or (Item_Bit (1), Item_Bit (2)), 10.0);
      Add_Bid (A, 1, Item_Bit (1), 4.0);
      Add_Bid (A, 2, Bit_Or (Item_Bit (2), Item_Bit (3)), 9.0);
      Add_Bid (A, 2, Item_Bit (3), 5.0);
      Add_Bid (A, 3, Bit_Or (Item_Bit (1), Item_Bit (3)), 8.0);
      Add_Bid (A, 3, Item_Bit (2), 6.0);
      return A;
   end Airport_Slots_Toy;

   function Spectrum_Pair_Toy return Auction is
      A : Auction := Empty_Auction (2, XOR_Bidding => True);
   begin
      Add_Bid (A, 1, Bit_Or (Item_Bit (1), Item_Bit (2)), 16.0);
      Add_Bid (A, 1, Item_Bit (1), 5.0);
      Add_Bid (A, 1, Item_Bit (2), 5.0);
      Add_Bid (A, 2, Bit_Or (Item_Bit (1), Item_Bit (2)), 10.0);
      Add_Bid (A, 2, Item_Bit (1), 7.0);
      Add_Bid (A, 3, Item_Bit (2), 8.0);
      return A;
   end Spectrum_Pair_Toy;

end Combinatorial_Auction;
