--  Own tests for Insert_Into_BST (see tests/SOURCES.txt).
--  After the inserts, Contains must agree with an own set, Size with its count, and the tree must have
--  exactly the shape of an own reference BST built by insertion (and be ordered).
pragma Ada_2022;
with Ada.Text_IO;
with Insert_Into_BST; use Insert_Into_BST;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;

   --  Park-Miller "minimal standard" generator (x := 16807 x mod (2**31 - 1)).
   Seed : Long_Long_Integer := 20_261_008;
   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Integer (Long_Long_Integer (Lo)
                      + Seed mod (Long_Long_Integer (Hi) - Long_Long_Integer (Lo) + 1));
   end Next;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Cases := Cases + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 5 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   --  Own reference BST: built by its own insertion (smaller to the left, larger to the right,
   --  a value already present is not inserted again), stored as value + child links.
   type Ref_Node is record V : Integer := 0; L, R : Natural := 0; end record;
   Ref : array (1 .. Capacity) of Ref_Node;
   Ref_Count : Natural := 0;
   procedure Ref_Insert (V : Integer) is
      P : Positive := 1;
   begin
      if Ref_Count = 0 then
         Ref_Count := 1; Ref (1) := (V, 0, 0); return;
      end if;
      loop
         if V = Ref (P).V then
            return;
         elsif V < Ref (P).V then
            if Ref (P).L = 0 then
               Ref_Count := Ref_Count + 1; Ref (Ref_Count) := (V, 0, 0); Ref (P).L := Ref_Count; return;
            end if;
            P := Ref (P).L;
         else
            if Ref (P).R = 0 then
               Ref_Count := Ref_Count + 1; Ref (Ref_Count) := (V, 0, 0); Ref (P).R := Ref_Count; return;
            end if;
            P := Ref (P).R;
         end if;
      end loop;
   end Ref_Insert;
   --  same shape: the subtree at slot S of X and at node R of the reference hold the same values in
   --  the same places; Seen counts the nodes of X that were visited
   Seen : Natural := 0;
   function Same_Shape (X : Tree; S : Index; R : Natural) return Boolean is
   begin
      if S = 0 or else R = 0 then
         return S = 0 and then R = 0;
      end if;
      Seen := Seen + 1;
      return Value_At (X, S) = Ref (R).V
        and then Same_Shape (X, Left_Of (X, S), Ref (R).L)
        and then Same_Shape (X, Right_Of (X, S), Ref (R).R);
   end Same_Shape;
   --  BST order checked on its own: every value of the subtree at S lies strictly in Lo .. Hi
   function Ordered_In (X : Tree; S : Index; Lo, Hi : Integer) return Boolean is
   begin
      return S = 0
        or else (Value_At (X, S) > Lo and then Value_At (X, S) < Hi
                 and then Ordered_In (X, Left_Of (X, S), Lo, Value_At (X, S))
                 and then Ordered_In (X, Right_Of (X, S), Value_At (X, S), Hi));
   end Ordered_In;
   Have : array (Value) of Boolean;
   X : Tree;
   N : Natural;
   Distinct : Natural;
   V : Value;
   Ok : Boolean;
begin
   for Iter in 1 .. 4_000 loop
      Have := [others => False];
      X := Empty;
      Ref_Count := 0;
      N := Next (0, Capacity);
      Distinct := 0;
      for I in 1 .. N loop
         --  first half of the runs: distinct values; second half: duplicates allowed (small range)
         if Iter <= 2_000 then
            loop
               V := Next (Value'First, Value'Last);
               exit when not Have (V);
            end loop;
         else
            V := Next (-12, 12);
         end if;
         exit when Size (X) = Capacity;
         Insert (X, V);
         Ref_Insert (V);
         if not Have (V) then Distinct := Distinct + 1; end if;
         Have (V) := True;
      end loop;
      Ok := Size (X) = Distinct;
      for W in Value loop
         if Contains (X, W) /= Have (W) then Ok := False; end if;
      end loop;
      Seen := 0;
      Ok := Ok and then Same_Shape (X, Root (X), (if Ref_Count = 0 then 0 else 1)) and then Seen = Size (X);
      Ok := Ok and then Ordered_In (X, Root (X), Integer'First, Integer'Last);
      Report (Ok, "random" & Iter'Image);
   end loop;
   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Cases'Image & " inputs (own set + own reference BST shape)");
end Own_Checks;
