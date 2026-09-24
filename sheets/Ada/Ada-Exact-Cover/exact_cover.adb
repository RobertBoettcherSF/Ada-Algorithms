--  Exact_Cover body — bitset incidence + naive MRV backtracking.

pragma Ada_2022;

with Interfaces; use Interfaces;

package body Exact_Cover is

   ---------------------------------------------------------------------------
   -- Bit helpers
   ---------------------------------------------------------------------------

   function Element_Bit (E : Element_Id) return Bit_Set is
   begin
      return Shift_Left (Bit_Set'(1), Natural (E) - 1);
   end Element_Bit;

   function Subset_Bit (S : Subset_Id) return Bit_Set is
   begin
      return Shift_Left (Bit_Set'(1), Natural (S) - 1);
   end Subset_Bit;

   function Universe_Mask (Num_Elements : Element_Count) return Bit_Set is
   begin
      if Num_Elements = 0 then
         return 0;
      elsif Num_Elements = Max_Universe_Size then
         return Bit_Set'Last;
      else
         return Shift_Left (Bit_Set'(1), Natural (Num_Elements)) - 1;
      end if;
   end Universe_Mask;

   function Popcount (M : Bit_Set) return Natural is
      X : Bit_Set := M;
      N : Natural := 0;
   begin
      while X /= 0 loop
         N := N + 1;
         X := X and (X - 1);
      end loop;
      return N;
   end Popcount;

   function Bit_Is_Set (M : Bit_Set; E : Element_Id) return Boolean is
   begin
      return (M and Element_Bit (E)) /= 0;
   end Bit_Is_Set;

   function Clip_To_Universe
     (Mask : Bit_Set; Num_Elements : Element_Count) return Bit_Set
   is
   begin
      return Mask and Universe_Mask (Num_Elements);
   end Clip_To_Universe;

   ---------------------------------------------------------------------------
   -- Builders
   ---------------------------------------------------------------------------

   procedure Clear (Inst : out Instance) is
   begin
      Inst := (Num_Elements => 0, Num_Subsets => 0, Rows => [others => 0]);
   end Clear;

   procedure Set_Universe
     (Inst         : in out Instance;
      Num_Elements : Element_Count)
   is
   begin
      Inst.Num_Elements := Num_Elements;
      Inst.Num_Subsets  := 0;
      Inst.Rows         := [others => 0];
   end Set_Universe;

   procedure Add_Subset
     (Inst : in out Instance;
      Mask : Bit_Set)
   is
      Clipped : constant Bit_Set :=
        Clip_To_Universe (Mask, Inst.Num_Elements);
   begin
      if Inst.Num_Elements = 0 and then Mask /= 0 then
         raise Invalid_Argument;
      end if;
      if Inst.Num_Subsets = Max_Subset_Count then
         raise Capacity_Exceeded;
      end if;
      Inst.Num_Subsets := Inst.Num_Subsets + 1;
      Inst.Rows (Inst.Num_Subsets) := Clipped;
   end Add_Subset;

   procedure From_Incidence_Matrix
     (Inst   : out Instance;
      Matrix : Bool_Matrix)
   is
      R : constant Natural := Matrix'Length (1);
      C : constant Natural := Matrix'Length (2);
      M : Bit_Set;
   begin
      if R > Max_Subset_Count or else C > Max_Universe_Size then
         raise Capacity_Exceeded;
      end if;
      Clear (Inst);
      Inst.Num_Elements := Element_Count (C);
      for I in Matrix'Range (1) loop
         M := 0;
         for J in Matrix'Range (2) loop
            if Matrix (I, J) then
               M := M or Element_Bit
                 (Element_Id (J - Matrix'First (2) + 1));
            end if;
         end loop;
         Inst.Num_Subsets := Inst.Num_Subsets + 1;
         Inst.Rows (Inst.Num_Subsets) := M;
      end loop;
   end From_Incidence_Matrix;

   ---------------------------------------------------------------------------
   -- Classic examples
   ---------------------------------------------------------------------------

   procedure Build_Knuth_Example (Inst : out Instance) is
      M : constant Bool_Matrix (1 .. 6, 1 .. 7) :=
        [[True,  False, False, True,  False, False, True],
         [True,  False, False, True,  False, False, False],
         [False, False, False, True,  True,  False, True],
         [False, False, True,  False, True,  True,  False],
         [False, True,  True,  False, False, True,  True],
         [False, True,  False, False, False, False, True]];
   begin
      From_Incidence_Matrix (Inst, M);
   end Build_Knuth_Example;

   procedure Build_NOPE_Example (Inst : out Instance) is
      M : constant Bool_Matrix (1 .. 4, 1 .. 4) :=
        [[False, False, False, False],
         [True,  False, True,  False],
         [True,  True,  True,  False],
         [False, True,  False, True]];
   begin
      From_Incidence_Matrix (Inst, M);
   end Build_NOPE_Example;

   procedure Build_Partition_Toy (Inst : out Instance) is
      M : constant Bool_Matrix (1 .. 7, 1 .. 3) :=
        [[True,  False, False],
         [False, True,  False],
         [False, False, True],
         [True,  True,  False],
         [True,  False, True],
         [False, True,  True],
         [True,  True,  True]];
   begin
      From_Incidence_Matrix (Inst, M);
   end Build_Partition_Toy;

   ---------------------------------------------------------------------------
   -- Verification
   ---------------------------------------------------------------------------

   function Conflicts (A, B : Bit_Set) return Boolean is
   begin
      return (A and B) /= 0;
   end Conflicts;

   function Selection_Mask
     (Inst : Instance;
      Sel  : Selection) return Bit_Set
   is
      M : Bit_Set := 0;
   begin
      for K in 1 .. Sel.Length loop
         if Sel.Ids (K) <= Inst.Num_Subsets then
            M := M or Subset_Bit (Sel.Ids (K));
         end if;
      end loop;
      return M;
   end Selection_Mask;

   function Covered_Elements
     (Inst : Instance;
      Sel  : Selection) return Bit_Set
   is
      U   : Bit_Set := 0;
      Uni : constant Bit_Set := Universe_Mask (Inst.Num_Elements);
   begin
      for K in 1 .. Sel.Length loop
         declare
            Id : constant Subset_Id := Sel.Ids (K);
         begin
            if Id <= Inst.Num_Subsets then
               U := U or Inst.Rows (Id);
            end if;
         end;
      end loop;
      return U and Uni;
   end Covered_Elements;

   function Is_Partial_Cover
     (Inst : Instance;
      Sel  : Selection) return Boolean
   is
      Seen : Bit_Set := 0;
      Uni  : constant Bit_Set := Universe_Mask (Inst.Num_Elements);
   begin
      for K in 1 .. Sel.Length loop
         declare
            Id : constant Subset_Id := Sel.Ids (K);
            R  : Bit_Set;
         begin
            if Id > Inst.Num_Subsets then
               return False;
            end if;
            R := Inst.Rows (Id) and Uni;
            if Conflicts (Seen, R) then
               return False;
            end if;
            Seen := Seen or R;
         end;
      end loop;
      return True;
   end Is_Partial_Cover;

   function Is_Exact_Cover
     (Inst : Instance;
      Sel  : Selection) return Boolean
   is
   begin
      if not Is_Partial_Cover (Inst, Sel) then
         return False;
      end if;
      return Covered_Elements (Inst, Sel) = Universe_Mask (Inst.Num_Elements);
   end Is_Exact_Cover;

   function Cover_Count_Of
     (Inst : Instance;
      Sel  : Selection;
      E    : Element_Id) return Natural
   is
      N : Natural := 0;
   begin
      if E > Inst.Num_Elements then
         return 0;
      end if;
      for K in 1 .. Sel.Length loop
         declare
            Id : constant Subset_Id := Sel.Ids (K);
         begin
            if Id <= Inst.Num_Subsets
              and then Bit_Is_Set (Inst.Rows (Id), E)
            then
               N := N + 1;
            end if;
         end;
      end loop;
      return N;
   end Cover_Count_Of;

   ---------------------------------------------------------------------------
   -- Backtracking solver
   --
   -- Empty subsets (mask 0) never cover an element, so they are not chosen
   -- in the main MRV loop. When a full element-cover is found, every subset
   -- of the unused empty rows may be freely adjoined (Wikipedia NOPE).
   ---------------------------------------------------------------------------

   procedure Search
     (Inst           : Instance;
      Use_MRV        : Boolean;
      Collect        : Boolean;
      Cap            : Natural;
      Store          : access Selection_Array;
      First_Only     : Boolean;
      Found_One      : access Selection;
      Got_One        : access Boolean;
      Total          : in out Natural;
      Partial        : in out Selection;
      Covered        : in out Bit_Set;
      Used_Subsets   : in out Bit_Set)
   is
      Uni : constant Bit_Set := Universe_Mask (Inst.Num_Elements);

      procedure Emit_With_Empties is
         --  Depth-first over unused empty rows; each may be in or out.
         Empties : array (1 .. Max_Subset_Count) of Subset_Id;
         NE      : Natural := 0;

         procedure Expand (I : Natural) is
         begin
            if Total >= Cap then
               return;
            end if;
            if I > NE then
               Total := Total + 1;
               if First_Only and then Got_One /= null
                 and then not Got_One.all
               then
                  Got_One.all   := True;
                  Found_One.all := Partial;
               end if;
               if Collect and then Store /= null
                 and then Total <= Store.all'Last
               then
                  Store.all (Total) := Partial;
               end if;
               return;
            end if;
            --  Exclude Empties (I).
            Expand (I + 1);
            if Total >= Cap
              or else (First_Only and then Got_One /= null
                       and then Got_One.all)
            then
               return;
            end if;
            --  Include Empties (I).
            Partial.Length := Partial.Length + 1;
            Partial.Ids (Partial.Length) := Empties (I);
            Expand (I + 1);
            Partial.Length := Partial.Length - 1;
         end Expand;
      begin
         for S in 1 .. Inst.Num_Subsets loop
            if Inst.Rows (S) = 0
              and then (Used_Subsets and Subset_Bit (Subset_Id (S))) = 0
            then
               NE := NE + 1;
               Empties (NE) := Subset_Id (S);
            end if;
         end loop;
         Expand (1);
      end Emit_With_Empties;

      function Choose_Element return Natural is
         Uncov  : constant Bit_Set := Uni and not Covered;
         Best_E : Natural := 0;
         Best_C : Natural := Natural'Last;
         Cnt    : Natural;
      begin
         if Uncov = 0 then
            return 0;
         end if;
         if not Use_MRV then
            for E in 1 .. Inst.Num_Elements loop
               if Bit_Is_Set (Uncov, Element_Id (E)) then
                  return E;
               end if;
            end loop;
            return 0;
         end if;
         for E in 1 .. Inst.Num_Elements loop
            if Bit_Is_Set (Uncov, Element_Id (E)) then
               Cnt := 0;
               for S in 1 .. Inst.Num_Subsets loop
                  if Inst.Rows (S) /= 0
                    and then (Used_Subsets and Subset_Bit (Subset_Id (S))) = 0
                    and then Bit_Is_Set (Inst.Rows (S), Element_Id (E))
                    and then not Conflicts (Inst.Rows (S), Covered)
                  then
                     Cnt := Cnt + 1;
                  end if;
               end loop;
               if Cnt < Best_C then
                  Best_C := Cnt;
                  Best_E := E;
                  if Best_C = 0 then
                     return Best_E;
                  end if;
               end if;
            end if;
         end loop;
         return Best_E;
      end Choose_Element;

      procedure Recurse is
         E : constant Natural := Choose_Element;
      begin
         if Total >= Cap then
            return;
         end if;

         if E = 0 then
            Emit_With_Empties;
            return;
         end if;

         for S in 1 .. Inst.Num_Subsets loop
            if Inst.Rows (S) /= 0
              and then (Used_Subsets and Subset_Bit (Subset_Id (S))) = 0
              and then Bit_Is_Set (Inst.Rows (S), Element_Id (E))
              and then not Conflicts (Inst.Rows (S), Covered)
            then
               Partial.Length := Partial.Length + 1;
               Partial.Ids (Partial.Length) := Subset_Id (S);
               Covered := Covered or Inst.Rows (S);
               Used_Subsets := Used_Subsets or Subset_Bit (Subset_Id (S));

               Recurse;

               Used_Subsets := Used_Subsets xor Subset_Bit (Subset_Id (S));
               Covered := Covered xor Inst.Rows (S);
               Partial.Length := Partial.Length - 1;

               if Total >= Cap then
                  return;
               end if;
               if First_Only and then Got_One /= null and then Got_One.all then
                  return;
               end if;
            end if;
         end loop;
      end Recurse;

   begin
      Recurse;
   end Search;

   procedure Solve_Backtrack
     (Inst    : Instance;
      Found   : out Selection;
      Success : out Boolean;
      Use_MRV : Boolean := True)
   is
      Partial      : Selection;
      Covered      : Bit_Set := 0;
      Used_Subsets : Bit_Set := 0;
      Total        : Natural := 0;
      Got          : aliased Boolean := False;
      One          : aliased Selection;
   begin
      Found   := (Length => 0, Ids => [others => 1]);
      Success := False;
      Search
        (Inst         => Inst,
         Use_MRV      => Use_MRV,
         Collect      => False,
         Cap          => 1,
         Store        => null,
         First_Only   => True,
         Found_One    => One'Access,
         Got_One      => Got'Access,
         Total        => Total,
         Partial      => Partial,
         Covered      => Covered,
         Used_Subsets => Used_Subsets);
      if Got then
         Found   := One;
         Success := True;
      end if;
   end Solve_Backtrack;

   procedure Solve_All
     (Inst      : Instance;
      Solutions : out Selection_Array;
      Count     : out Natural;
      Cap       : Natural := Max_Solutions;
      Use_MRV   : Boolean := True)
   is
      Partial      : Selection;
      Covered      : Bit_Set := 0;
      Used_Subsets : Bit_Set := 0;
      Total        : Natural := 0;
      Limit        : constant Natural :=
        Natural'Min (Cap, Max_Solutions);
      Store        : aliased Selection_Array;
   begin
      Solutions := [others => (Length => 0, Ids => [others => 1])];
      Store     := Solutions;
      Search
        (Inst         => Inst,
         Use_MRV      => Use_MRV,
         Collect      => True,
         Cap          => Limit,
         Store        => Store'Access,
         First_Only   => False,
         Found_One    => null,
         Got_One      => null,
         Total        => Total,
         Partial      => Partial,
         Covered      => Covered,
         Used_Subsets => Used_Subsets);
      Count     := Total;
      Solutions := Store;
   end Solve_All;

   function Count_Covers
     (Inst    : Instance;
      Cap     : Natural := 256;
      Use_MRV : Boolean := True) return Natural
   is
      Partial      : Selection;
      Covered      : Bit_Set := 0;
      Used_Subsets : Bit_Set := 0;
      Total        : Natural := 0;
   begin
      Search
        (Inst         => Inst,
         Use_MRV      => Use_MRV,
         Collect      => False,
         Cap          => Cap,
         Store        => null,
         First_Only   => False,
         Found_One    => null,
         Got_One      => null,
         Total        => Total,
         Partial      => Partial,
         Covered      => Covered,
         Used_Subsets => Used_Subsets);
      return Total;
   end Count_Covers;

   ---------------------------------------------------------------------------
   -- Taxonomy
   ---------------------------------------------------------------------------

   function Classify (Kind : Method_Kind) return Method_Info is
   begin
      case Kind is
         when Naive_Backtrack =>
            return (Kind => Naive_Backtrack, Status => Implemented,
                    Implemented => True);
         when Algorithm_X =>
            return (Kind => Algorithm_X, Status => Forthcoming,
                    Implemented => False);
         when Dancing_Links =>
            return (Kind => Dancing_Links, Status => Forthcoming,
                    Implemented => False);
         when Integer_LP =>
            return (Kind => Integer_LP, Status => Forthcoming,
                    Implemented => False);
      end case;
   end Classify;

   function Method_Name (Kind : Method_Kind) return String is
   begin
      case Kind is
         when Naive_Backtrack => return "Naive_Backtrack";
         when Algorithm_X     => return "Algorithm_X";
         when Dancing_Links   => return "Dancing_Links";
         when Integer_LP      => return "Integer_LP";
      end case;
   end Method_Name;

   function Implemented (Kind : Method_Kind) return Boolean is
   begin
      return Classify (Kind).Implemented;
   end Implemented;

   function Forthcoming (Kind : Method_Kind) return Boolean is
   begin
      return Classify (Kind).Status = Forthcoming;
   end Forthcoming;

   function Method_Count return Natural is
   begin
      return Method_Kind'Pos (Method_Kind'Last)
        - Method_Kind'Pos (Method_Kind'First) + 1;
   end Method_Count;

   ---------------------------------------------------------------------------
   -- Example wrappers
   ---------------------------------------------------------------------------

   function Knuth_Example_Cover_Count return Natural is
      Inst : Instance;
   begin
      Build_Knuth_Example (Inst);
      return Count_Covers (Inst, Cap => 8);
   end Knuth_Example_Cover_Count;

   function NOPE_Example_Cover_Count return Natural is
      Inst : Instance;
   begin
      Build_NOPE_Example (Inst);
      return Count_Covers (Inst, Cap => 8);
   end NOPE_Example_Cover_Count;

end Exact_Cover;
