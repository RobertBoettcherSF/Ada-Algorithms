pragma Ada_2022;
--  Own checks for House-Robber-III-Lite (see tests/SOURCES.txt). No
--  expected value comes from the program:
--  * an own brute force over every choice (2 ** N of them, N <= 14) with
--    the flat rule "no robbed house has a robbed child" and flat sums;
--  * an own iterative dynamic program (houses in decreasing number, so
--    children before parents), for trees up to Max_Nodes;
--  * Best_Choice checked flat: independent, its flat sum is Max_Loot;
--  * an own shape check (walk from the root in preorder) against
--    Well_Formed, on seeded random trees and on random corruptions of them;
--  * the ghost lemma Lemma_Optimal run (assertions on) on random
--    independent choices.
with Ada.Text_IO;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with House_Robber_III_Lite; use House_Robber_III_Lite;

procedure Own_Checks with SPARK_Mode => Off is
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
      Name : constant String := "Ada-SPARK-House-Robber-III-Lite";
      H    : Unsigned_32 := 2_166_136_261;
   begin
      for C of Name loop
         H := (H xor Unsigned_32 (Character'Pos (C))) * 16_777_619;
      end loop;
      return Long_Long_Integer (H) mod 2_147_483_646 + 1;
   end Name_Hash;

   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : constant Long_Long_Integer := (if V = "" then Default else Long_Long_Integer'Value (V));
   begin
      Ada.Text_IO.Put_Line ("AA_SEED =" & S'Image & (if V = "" then " (default: FNV-1a of the folder name)" else " (from AA_SEED)"));
      return S;
   end AA_Seed;

   Seed : Long_Long_Integer := AA_Seed (Name_Hash);
   function Next return Natural is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Natural (Seed);
   end Next;

   --  A random tree of Size houses numbered from First in preorder.
   procedure Grow (T : in out Tree; First, Size : Natural) is
      Left_Size : Natural;
   begin
      if Size = 0 then
         return;
      end if;
      Left_Size := Next mod Size;
      T.Value (First) := (case Next mod 4 is when 0 => 0, when 1 => Max_Value, when others => Next mod (Max_Value + 1));
      T.Left (First) := (if Left_Size > 0 then First + 1 else 0);
      T.Right (First) := (if Size - 1 - Left_Size > 0 then First + 1 + Left_Size else 0);
      Grow (T, First + 1, Left_Size);
      Grow (T, First + 1 + Left_Size, Size - 1 - Left_Size);
   end Grow;

   --  Own shape check: walk from the root, each link must be 0 or the
   --  next house in preorder; every house is visited once.
   function Own_Shape (T : Tree) return Boolean is
      Next_House : Natural := 1;
      Ok         : Boolean := True;
      procedure Walk (I : Natural) is
      begin
         if not Ok then
            return;
         end if;
         if I /= Next_House or else I > T.N then
            Ok := False;
            return;
         end if;
         Next_House := Next_House + 1;
         if T.Left (I) /= 0 then
            Walk (T.Left (I));
         end if;
         if Ok and then T.Right (I) /= 0 then
            Walk (T.Right (I));
         end if;
      end Walk;
   begin
      if T.N = 0 then
         return True;
      end if;
      Walk (1);
      return Ok and then Next_House = T.N + 1;
   end Own_Shape;

   function Flat_Independent (T : Tree; S : Choice) return Boolean is
     (for all I in 1 .. T.N =>
        (if S (I) then (T.Left (I) = 0 or else not S (T.Left (I)))
                       and then (T.Right (I) = 0 or else not S (T.Right (I)))));

   function Flat_Sum (T : Tree; S : Choice) return Natural is
      Sum : Natural := 0;
   begin
      for I in 1 .. T.N loop
         if S (I) then
            Sum := Sum + T.Value (I);
         end if;
      end loop;
      return Sum;
   end Flat_Sum;

   function Brute (T : Tree) return Natural is
      Best : Natural := 0;
      S    : Choice (1 .. T.N);
   begin
      for Mask in 0 .. 2 ** T.N - 1 loop
         for I in 1 .. T.N loop
            S (I) := (Mask / 2 ** (I - 1)) mod 2 = 1;
         end loop;
         if Flat_Independent (T, S) then
            Best := Natural'Max (Best, Flat_Sum (T, S));
         end if;
      end loop;
      return Best;
   end Brute;

   --  Own iterative program: children have larger numbers.
   function Iterative (T : Tree) return Natural is
      Take, Skip : array (1 .. T.N + 1) of Natural := [others => 0];
   begin
      if T.N = 0 then
         return 0;
      end if;
      for I in reverse 1 .. T.N loop
         Take (I) := T.Value (I);
         Skip (I) := 0;
         declare
            Kids : constant array (1 .. 2) of Link := [T.Left (I), T.Right (I)];
         begin
            for C of Kids loop
               if C /= 0 then
                  Take (I) := Take (I) + Skip (C);
                  Skip (I) := Skip (I) + Natural'Max (Take (C), Skip (C));
               end if;
            end loop;
         end;
      end loop;
      return Natural'Max (Take (1), Skip (1));
   end Iterative;

   procedure Check (T : Tree; Small : Boolean; Label : String) is
      M : constant Natural := Max_Loot (T);
      C : constant Choice := Best_Choice (T);
   begin
      Report (M = Iterative (T), Label & " vs own iterative");
      if Small then
         Report (M = Brute (T), Label & " vs brute force");
      end if;
      Report (C'First = 1 and then C'Length = T.N, Label & " choice bounds");
      Report (Flat_Independent (T, C), Label & " choice independent");
      Report (Flat_Sum (T, C) = M, Label & " choice sum");
      if T.N >= 1 then
         --  A random independent choice: Lemma_Optimal runs its contracts.
         declare
            S : Choice (1 .. T.N);
         begin
            for I in 1 .. T.N loop
               S (I) := Next mod 3 = 0;
            end loop;
            for I in 1 .. T.N loop
               if S (I) then
                  if T.Left (I) /= 0 then
                     S (T.Left (I)) := False;
                  end if;
                  if T.Right (I) /= 0 then
                     S (T.Right (I)) := False;
                  end if;
               end if;
            end loop;
            Lemma_Optimal (T, S);
            Report (Flat_Sum (T, S) <= M, Label & " random choice not better");
         end;
      end if;
   end Check;

   Path : Tree (Max_Nodes);
begin
   for Round in 1 .. 600 loop
      declare
         N : constant Node_Count := (if Round <= 400 then Next mod 15 else Next mod (Max_Nodes + 1));
         T : Tree (N);
      begin
         Grow (T, 1, N);
         Report (Own_Shape (T) and then Well_Formed (T), "random tree shape" & Round'Image);
         Check (T, N <= 14, "random" & Round'Image);
         --  Corrupt one link: Well_Formed must agree with the own shape check.
         if N >= 1 then
            declare
               B : Tree := T;
               I : constant Index := 1 + Next mod N;
               V : constant Link := Next mod (N + 2);
            begin
               if Next mod 2 = 0 then
                  B.Left (I) := V;
               else
                  B.Right (I) := V;
               end if;
               Report (Well_Formed (B) = Own_Shape (B), "corrupted shape" & Round'Image);
               if Own_Shape (B) then
                  Check (B, N <= 14, "corrupted but valid" & Round'Image);
               end if;
            end;
         end if;
      end;
   end loop;

   --  Path shapes of Max_Nodes, left and right, all Max_Value.
   for Side in 1 .. 2 loop
      for I in 1 .. Max_Nodes loop
         Path.Value (I) := Max_Value;
         Path.Left (I) := (if Side = 1 and then I < Max_Nodes then I + 1 else 0);
         Path.Right (I) := (if Side = 2 and then I < Max_Nodes then I + 1 else 0);
      end loop;
      Check (Path, False, "path" & Side'Image);
      Report (Max_Loot (Path) = 500_000, "path total" & Side'Image);
   end loop;

   Ada.Text_IO.Put_Line ("own checks:" & Checked'Image & " checks," & Failures'Image & " failures");
   if Failures > 0 then
      raise Program_Error with "own checks failed";
   end if;
end Own_Checks;
