pragma Ada_2022;
--  Own checks (V&V sweep, agent A3). Independent references: a linear scan
--  for membership and for "strictly increasing", the middle-index formula
--  for the root, and the smallest H with 2 ** H - 1 >= Length for the
--  height. Build's in-order sequence is its input, so the result is a BST
--  exactly when Input (1 .. Length) is strictly increasing.
with Ada.Text_IO;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with Sorted_Array_To_BST; use Sorted_Array_To_BST;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked  : Natural := 0;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then
            Ada.Text_IO.Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   function Name_Hash return Long_Long_Integer is
      Name : constant String := "Ada-SPARK-Sorted-Array-To-BST";
      H    : Unsigned_32 := 2_166_136_261;
   begin
      for C of Name loop
         H := (H xor Unsigned_32 (Character'Pos (C))) * 16_777_619;
      end loop;
      return Long_Long_Integer (H) mod 2_147_483_646 + 1;
   end Name_Hash;

   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : constant Long_Long_Integer :=
        (if V = "" then Default
         else 1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646);
   begin
      Ada.Text_IO.Put_Line
        ("AA_SEED =" & S'Image
         & (if V = "" then " (default: FNV-1a of the folder name)"
            else " (from AA_SEED)"));
      return S;
   end AA_Seed;

   Seed : Long_Long_Integer := AA_Seed (Name_Hash);
   function Next return Natural is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Natural (Seed);
   end Next;

   function Increasing (A : Value_Array; L : Count) return Boolean is
   begin
      for I in 2 .. L loop
         if A (I - 1) >= A (I) then
            return False;
         end if;
      end loop;
      return True;
   end Increasing;

   function Ref_Height (L : Count) return Natural is
      H : Natural := 0;
   begin
      while 2 ** H - 1 < L loop
         H := H + 1;
      end loop;
      return H;
   end Ref_Height;

   function Member (A : Value_Array; L : Count; V : Integer) return Boolean is
   begin
      for I in 1 .. L loop
         if A (I) = V then
            return True;
         end if;
      end loop;
      return False;
   end Member;

   T : Tree := Empty;
   A : Value_Array;

   procedure Check_Shape (L : Count; Label : String) is
   begin
      Build (T, A, L);
      Report (Height (T) = Ref_Height (L), Label & " height");
      Report (Root_Value (T) = (if L = 0 then 0 else A (1 + (L - 1) / 2)),
              Label & " root");
      Report (Is_BST (T) = Increasing (A, L), Label & " Is_BST");
   end Check_Shape;
begin
   for L in Count loop
      for Rep in 1 .. 40 loop
         --  Strictly increasing input: a BST holding exactly A (1 .. L).
         A := [others => Value (Next mod 2001 - 1000)];
         A (1) := -1000 + Next mod 200;
         for I in 2 .. L loop
            A (I) := A (I - 1) + 1 + Next mod 58;
         end loop;
         --  Every fourth input runs from -1000 to 1000 (the Value range).
         if L >= 2 and then Rep mod 4 = 0 then
            A (1) := Value'First;
            A (L) := Value'Last;
         end if;
         Check_Shape (L, "sorted L =" & L'Image);
         for V in Value loop
            Report (Contains (T, V) = Member (A, L, V),
                    "sorted L =" & L'Image & " Contains" & V'Image);
         end loop;

         --  The same values with two positions swapped (often one
         --  out-of-place value deep in a subtree).
         if L >= 2 then
            declare
               I : constant Count := 1 + Next mod L;
               J : constant Count := 1 + Next mod L;
               X : constant Value := A (I);
            begin
               A (I) := A (J);
               A (J) := X;
            end;
            Check_Shape (L, "swapped L =" & L'Image);
         end if;

         --  Small values, so repeats and descents are common.
         for I in 1 .. L loop
            A (I) := Value (Next mod (L + 3));
         end loop;
         Check_Shape (L, "small values L =" & L'Image);
      end loop;
   end loop;
   Ada.Text_IO.Put_Line ("own checks:" & Checked'Image & " checks," & Failures'Image & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
