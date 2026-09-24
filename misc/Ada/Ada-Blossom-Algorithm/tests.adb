--  Standalone test suite for Blossom_Algorithm.

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Blossom_Algorithm; use Blossom_Algorithm;

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
   function V_Id (X : Positive) return Vertex_Id is (Vertex_Id (X));

   function Clear_Raises (N : Natural) return Boolean is
      G : Graph;
   begin
      Clear (G, N);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Clear_Raises;

   function Add_Raises
     (G : in out Graph; U, V : Vertex_Id) return Boolean
   is
   begin
      Add_Edge (G, U, V);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Add_Raises;

   function Oracle_Raises (G : Graph) return Boolean is
      R : Matching_Result;
   begin
      Matching_Oracle_Brute (G, R);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Oracle_Raises;

   function Edge_Query_Raises (G : Graph; Index : Positive) return Boolean is
      A, B : Vertex_Id;
   begin
      A := Edge_U (G, Index);
      B := Edge_V (G, Index);
      pragma Unreferenced (A, B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Edge_Query_Raises;

   procedure Agree_Oracle (G : Graph; Label : String) is
      R1, R2 : Matching_Result;
   begin
      Maximum_Matching (G, R1);
      Matching_Oracle_Brute (G, R2);
      Check (R1.Size = R2.Size, Label & " size agree");
      Check (Is_Valid_Matching (G, R1), Label & " blossom valid");
      Check (Is_Valid_Matching (G, R2), Label & " oracle valid");
   end Agree_Oracle;

   procedure Expect_Size (G : Graph; Expected : Natural; Label : String) is
      R : Matching_Result;
   begin
      Maximum_Matching (G, R);
      Check (R.Size = Expected, Label & " size");
      Check (Is_Valid_Matching (G, R), Label & " valid");
      Check (R.N = Vertex_Count (G), Label & " N");
   end Expect_Size;

   G : Graph;
   R : Matching_Result;

begin
   Put_Line ("Blossom_Algorithm test suite");
   Put_Line ("============================");

   ---------------------------------------------------------------------
   Section ("1. Empty / trivial");
   ---------------------------------------------------------------------
   Clear (G, Nat (0));
   Check (Vertex_Count (G) = 0, "N=0");
   Check (Edge_Count (G) = 0, "M=0");
   Maximum_Matching (G, R);
   Check (R.Size = 0, "empty matching 0");
   Check (Is_Valid_Matching (G, R), "empty valid");
   Matching_Oracle_Brute (G, R);
   Check (R.Size = 0, "oracle empty 0");

   Clear (G, Nat (1));
   Maximum_Matching (G, R);
   Check (R.Size = 0, "isolate size 0");
   Check (R.N = 1, "isolate N");
   Agree_Oracle (G, "isolate");

   Clear (G, Nat (4));
   Maximum_Matching (G, R);
   Check (R.Size = 0, "no-edge 4 size 0");
   Agree_Oracle (G, "noedge4");

   Clear (G, Nat (2));
   Add_Edge (G, 1, 2);
   Expect_Size (G, Nat (1), "single edge");
   Agree_Oracle (G, "single");

   ---------------------------------------------------------------------
   Section ("2. Triangle (matching size 1)");
   ---------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 1);
   Expect_Size (G, Nat (1), "triangle");
   Agree_Oracle (G, "triangle");
   Maximum_Matching (G, R);
   Check (R.Mate (1) = 0 or else R.Mate (R.Mate (1)) = 1, "tri mate");

   ---------------------------------------------------------------------
   Section ("3. Paths");
   ---------------------------------------------------------------------
   Clear (G, 2);
   Add_Edge (G, 1, 2);
   Expect_Size (G, Nat (1), "P2");
   Agree_Oracle (G, "P2");

   Clear (G, 3);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Expect_Size (G, Nat (1), "P3");
   Agree_Oracle (G, "P3");

   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Expect_Size (G, Nat (2), "P4");
   Agree_Oracle (G, "P4");

   Clear (G, 5);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 5);
   Expect_Size (G, Nat (2), "P5");
   Agree_Oracle (G, "P5");

   Clear (G, 6);
   for I in 1 .. 5 loop
      Add_Edge (G, V_Id (I), V_Id (I + 1));
   end loop;
   Expect_Size (G, Nat (3), "P6");
   Agree_Oracle (G, "P6");

   Clear (G, 7);
   for I in 1 .. 6 loop
      Add_Edge (G, V_Id (I), V_Id (I + 1));
   end loop;
   Expect_Size (G, Nat (3), "P7");
   Agree_Oracle (G, "P7");

   ---------------------------------------------------------------------
   Section ("4. Cycles (odd / even)");
   ---------------------------------------------------------------------
   for N in 3 .. 9 loop
      Clear (G, N);
      for I in 1 .. N - 1 loop
         Add_Edge (G, V_Id (I), V_Id (I + 1));
      end loop;
      Add_Edge (G, V_Id (N), 1);
      Expect_Size (G, Nat (N / 2), "C" & Natural'Image (N));
      Agree_Oracle (G, "C" & Natural'Image (N));
   end loop;

   ---------------------------------------------------------------------
   Section ("5. Complete graphs");
   ---------------------------------------------------------------------
   for N in 1 .. 8 loop
      Clear (G, N);
      for I in 1 .. N loop
         for J in I + 1 .. N loop
            Add_Edge (G, V_Id (I), V_Id (J));
         end loop;
      end loop;
      Expect_Size (G, Nat (N / 2), "K" & Natural'Image (N));
      Agree_Oracle (G, "K" & Natural'Image (N));
   end loop;

   ---------------------------------------------------------------------
   Section ("6. Stars");
   ---------------------------------------------------------------------
   Clear (G, 8);
   for J in 2 .. 8 loop
      Add_Edge (G, 1, V_Id (J));
   end loop;
   Expect_Size (G, Nat (1), "star8");
   Agree_Oracle (G, "star8");

   Clear (G, 5);
   for J in 2 .. 5 loop
      Add_Edge (G, 1, V_Id (J));
   end loop;
   Expect_Size (G, Nat (1), "star5");
   Agree_Oracle (G, "star5");

   ---------------------------------------------------------------------
   Section ("7. Classic blossom graphs");
   ---------------------------------------------------------------------
   --  Triangle plus two pendants: max matching 2.
   Clear (G, 5);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 1);
   Add_Edge (G, 1, 4);
   Add_Edge (G, 2, 5);
   Expect_Size (G, Nat (2), "tri+pend");
   Agree_Oracle (G, "tri+pend");

   --  Two triangles joined by a bridge: max matching 3.
   Clear (G, 6);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 1);
   Add_Edge (G, 4, 5);
   Add_Edge (G, 5, 6);
   Add_Edge (G, 6, 4);
   Add_Edge (G, 3, 4);
   Expect_Size (G, Nat (3), "2tri");
   Agree_Oracle (G, "2tri");

   --  Stem + blossom that forces contraction.
   Clear (G, 6);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 2, 4);
   Add_Edge (G, 4, 5);
   Add_Edge (G, 5, 3);
   Add_Edge (G, 3, 6);
   Expect_Size (G, Nat (3), "stem-blossom");
   Agree_Oracle (G, "stem-blossom");

   --  Nested-ish odd cycles.
   Clear (G, 7);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 1);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 5);
   Add_Edge (G, 5, 3);
   Add_Edge (G, 5, 6);
   Add_Edge (G, 6, 7);
   Expect_Size (G, Nat (3), "nested-odd");
   Agree_Oracle (G, "nested-odd");

   ---------------------------------------------------------------------
   Section ("8. Petersen graph (size 5)");
   ---------------------------------------------------------------------
   Clear (G, 10);
   --  Outer pentagon
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 5);
   Add_Edge (G, 5, 1);
   --  Spokes
   Add_Edge (G, 1, 6);
   Add_Edge (G, 2, 7);
   Add_Edge (G, 3, 8);
   Add_Edge (G, 4, 9);
   Add_Edge (G, 5, 10);
   --  Inner pentagram
   Add_Edge (G, 6, 8);
   Add_Edge (G, 8, 10);
   Add_Edge (G, 10, 7);
   Add_Edge (G, 7, 9);
   Add_Edge (G, 9, 6);
   Expect_Size (G, Nat (5), "Petersen");
   Agree_Oracle (G, "Petersen");

   ---------------------------------------------------------------------
   Section ("9. Parallel edges / duplicates");
   ---------------------------------------------------------------------
   Clear (G, 2);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 2);
   Check (Edge_Count (G) = 3, "parallel count");
   Expect_Size (G, Nat (1), "parallel P2");
   Agree_Oracle (G, "parallel");

   Clear (G, 3);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 1);
   Expect_Size (G, Nat (1), "parallel triangle");
   Agree_Oracle (G, "partri");

   ---------------------------------------------------------------------
   Section ("10. Mate-array consistency");
   ---------------------------------------------------------------------
   Clear (G, 6);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 5);
   Add_Edge (G, 5, 6);
   Add_Edge (G, 6, 1);
   Maximum_Matching (G, R);
   Check (R.Size = 3, "C6 size 3");
   for V in 1 .. 6 loop
      if R.Mate (V) /= 0 then
         Check (R.Mate (R.Mate (V)) = V, "mutual mate");
      end if;
   end loop;
   Check (Is_Valid_Matching (G, R), "C6 valid");

   ---------------------------------------------------------------------
   Section ("11. Oracle agreement batch");
   ---------------------------------------------------------------------
   for N in 1 .. 8 loop
      Clear (G, N);
      for I in 1 .. N - 1 loop
         Add_Edge (G, V_Id (I), V_Id (I + 1));
      end loop;
      Agree_Oracle (G, "path" & Natural'Image (N));
   end loop;

   for N in 3 .. 7 loop
      Clear (G, N);
      Add_Edge (G, 1, 2);
      Add_Edge (G, 2, 3);
      Add_Edge (G, 3, 1);
      for I in 4 .. N loop
         Add_Edge (G, V_Id (I), V_Id (I - 3));
      end loop;
      Agree_Oracle (G, "tripend" & Natural'Image (N));
   end loop;

   for N in 2 .. 6 loop
      Clear (G, N);
      for I in 1 .. N loop
         for J in I + 1 .. N loop
            if (I + J) mod 2 = 1 then
               Add_Edge (G, V_Id (I), V_Id (J));
            end if;
         end loop;
      end loop;
      Agree_Oracle (G, "bip-ish" & Natural'Image (N));
   end loop;

   ---------------------------------------------------------------------
   Section ("12. Edge inspectors");
   ---------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 3, 1);
   Check (Edge_U (G, 1) = 1, "e1 U");
   Check (Edge_V (G, 1) = 2, "e1 V");
   Check (Edge_U (G, 2) = 3, "e2 U");
   Check (Edge_V (G, 2) = 1, "e2 V");
   Check (Edge_Query_Raises (G, Nat (3)), "edge 3 raises");
   Check (Edge_Query_Raises (G, Nat (99)), "edge 99 raises");

   ---------------------------------------------------------------------
   Section ("13. Invalid_Argument");
   ---------------------------------------------------------------------
   Check (Clear_Raises (Nat (Max_Vertices + 1)), "Clear overflow");
   Check (not Clear_Raises (Nat (Max_Vertices)), "Clear max ok");
   Check (not Clear_Raises (Nat (0)), "Clear 0 ok");

   Clear (G, 2);
   Check (Add_Raises (G, V_Id (3), V_Id (1)), "Add U OOB");
   Check (Add_Raises (G, V_Id (1), V_Id (3)), "Add V OOB");
   Check (Add_Raises (G, V_Id (1), V_Id (1)), "Add self-loop");

   Clear (G, 0);
   Check (Add_Raises (G, V_Id (1), V_Id (2)), "Add on empty");

   Clear (G, Max_Oracle + 1);
   Check (Oracle_Raises (G), "oracle overflow");
   Clear (G, Max_Oracle);
   Check (not Oracle_Raises (G), "oracle at cap ok");

   Clear (G, 2);
   Add_Edge (G, 1, 2);
   Maximum_Matching (G, R);
   R.N := 1;
   Check (not Is_Valid_Matching (G, R), "bad N rejected");

   ---------------------------------------------------------------------
   Section ("14. Max_Edges overflow");
   ---------------------------------------------------------------------
   declare
      Tiny   : Graph;
      Raised : Boolean := False;
   begin
      Clear (Tiny, 2);
      for K in 1 .. Max_Edges loop
         Add_Edge (Tiny, 1, 2);
      end loop;
      Check (Edge_Count (Tiny) = Max_Edges, "filled Max_Edges");
      begin
         Add_Edge (Tiny, 1, 2);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Add beyond Max_Edges");
   end;

   ---------------------------------------------------------------------
   Section ("15. Disconnected components");
   ---------------------------------------------------------------------
   Clear (G, 7);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 3, 5);
   Add_Edge (G, 4, 5);
   Expect_Size (G, Nat (2), "two comps + isol");
   Agree_Oracle (G, "comps");

   ---------------------------------------------------------------------
   Section ("16. Clear resets edges");
   ---------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Clear (G, 2);
   Check (Edge_Count (G) = 0, "cleared edges");
   Check (Vertex_Count (G) = 2, "cleared N");
   Maximum_Matching (G, R);
   Check (R.Size = 0, "cleared matching 0");
   Add_Edge (G, 1, 2);
   Expect_Size (G, Nat (1), "after clear add");

   ---------------------------------------------------------------------
   Section ("17. Larger blossom-only graphs");
   ---------------------------------------------------------------------
   Clear (G, 32);
   for I in 1 .. 32 loop
      Add_Edge (G, V_Id (I), V_Id (1 + I mod 32));
   end loop;
   Expect_Size (G, Nat (16), "C32");

   Clear (G, 64);
   for I in 1 .. 32 loop
      Add_Edge (G, V_Id (I), V_Id (I + 32));
   end loop;
   Expect_Size (G, Nat (32), "n=64 matching");

   Clear (G, 100);
   for I in 1 .. 99 loop
      Add_Edge (G, V_Id (I), V_Id (I + 1));
   end loop;
   Expect_Size (G, Nat (50), "P100");

   Clear (G, 128);
   for I in 1 .. 64 loop
      Add_Edge (G, V_Id (2 * I - 1), V_Id (2 * I));
   end loop;
   Expect_Size (G, Nat (64), "n=128 perfect");

   ---------------------------------------------------------------------
   Section ("18. Random-ish deterministic families");
   ---------------------------------------------------------------------
   for Seed in 1 .. 16 loop
      declare
         N : constant Natural := 4 + (Seed mod 7);
      begin
         Clear (G, N);
         for I in 1 .. N loop
            for J in I + 1 .. N loop
               if ((I * 17 + J * 13 + Seed * 7) mod 5) < 2 then
                  Add_Edge (G, V_Id (I), V_Id (J));
               end if;
            end loop;
         end loop;
         Agree_Oracle (G, "rand" & Natural'Image (Seed));
      end;
   end loop;

   ---------------------------------------------------------------------
   Section ("19. Cap Max_Vertices smoke");
   ---------------------------------------------------------------------
   Clear (G, Max_Vertices);
   Check (Vertex_Count (G) = Max_Vertices, "Max_Vertices ok");
   Add_Edge (G, Vertex_Id (Max_Vertices), Vertex_Id (Max_Vertices - 1));
   Expect_Size (G, Nat (1), "Max_Vertices edge");

   Clear (G, Max_Vertices);
   for I in 1 .. Max_Vertices / 2 loop
      Add_Edge (G, V_Id (2 * I - 1), V_Id (2 * I));
   end loop;
   Expect_Size (G, Nat (Max_Vertices / 2), "Max_Vertices perfect");

   ---------------------------------------------------------------------
   Section ("20. Bipartite families (no blossom needed)");
   ---------------------------------------------------------------------
   for A in 1 .. 5 loop
      for B in 1 .. 5 loop
         Clear (G, A + B);
         for I in 1 .. A loop
            for J in 1 .. B loop
               if I = J or else I + J = A + 1 then
                  Add_Edge (G, V_Id (I), V_Id (A + J));
               end if;
            end loop;
         end loop;
         Agree_Oracle
           (G, "bip" & Natural'Image (A) & "x" & Natural'Image (B));
      end loop;
   end loop;

   ---------------------------------------------------------------------
   Section ("21. Odd wheels / fans");
   ---------------------------------------------------------------------
   --  Wheel W5: hub + C4. Matching size 2.
   Clear (G, 5);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 5);
   Add_Edge (G, 5, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 1, 4);
   Add_Edge (G, 1, 5);
   Expect_Size (G, Nat (2), "W5-ish");
   Agree_Oracle (G, "W5");

   --  K_{3,3} as general graph (vertices 1..6).
   Clear (G, 6);
   for I in 1 .. 3 loop
      for J in 4 .. 6 loop
         Add_Edge (G, V_Id (I), V_Id (J));
      end loop;
   end loop;
   Expect_Size (G, Nat (3), "K3,3");
   Agree_Oracle (G, "K33");

   ---------------------------------------------------------------------
   Section ("22. Forced long augmenting path");
   ---------------------------------------------------------------------
   Clear (G, 8);
   for I in 1 .. 7 loop
      Add_Edge (G, V_Id (I), V_Id (I + 1));
   end loop;
   Add_Edge (G, 1, 3);
   Add_Edge (G, 3, 5);
   Add_Edge (G, 5, 7);
   Expect_Size (G, Nat (4), "long path+chords");
   Agree_Oracle (G, "longaug");

   ---------------------------------------------------------------------
   Section ("23. Oracle at N=16");
   ---------------------------------------------------------------------
   Clear (G, Max_Oracle);
   for I in 1 .. Max_Oracle - 1 loop
      Add_Edge (G, V_Id (I), V_Id (I + 1));
   end loop;
   Expect_Size (G, Nat (Max_Oracle / 2), "P16");
   Agree_Oracle (G, "P16");

   Clear (G, Max_Oracle);
   for I in 1 .. Max_Oracle loop
      Add_Edge (G, V_Id (I), V_Id (1 + I mod Max_Oracle));
   end loop;
   Expect_Size (G, Nat (Max_Oracle / 2), "C16");
   Agree_Oracle (G, "C16");

   ---------------------------------------------------------------------
   Section ("24. Is_Valid_Matching rejects bad mates");
   ---------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2);
   Maximum_Matching (G, R);
   R.Mate (1) := 3;
   R.Mate (3) := 1;
   Check (not Is_Valid_Matching (G, R), "non-edge mate rejected");

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   New_Line;
   Put_Line ("============================");
   Put_Line
     ("Results: " & Natural'Image (Pass_Count)
      & " PASS," & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count = 0 and then Pass_Count >= 150 then
      Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Put_Line ("SOME FAILED OR TOO FEW");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
