--  Own tests for Clone_Graph.Clone (written for this repository; see
--  tests/SOURCES.txt). Assumption: Clone copies the wrong set of nodes,
--  numbers them in some other order, or gets a label or a neighbour slot
--  wrong. Reference, independent of the package's queue: a recursive
--  depth-first search gives the set of nodes reachable from Start; the
--  result must copy exactly that set (Map /= 0), Map and Orig must be
--  inverse bijections between it and 1 .. Size, and every copy must have
--  the original's label and, slot by slot, the copy of the original's
--  neighbour (or an empty slot). The numbering is checked against the
--  breadth-first rule: copy 1 is Start, and for D >= 2 the first copy
--  that lists Orig (D), together with the first such slot, gives a key
--  that grows with D. Copy nodes after Size must be empty.
pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Environment_Variables;
with Clone_Graph; use Clone_Graph;

procedure Own_Checks is
   Failures : Natural := 0;
   Cases    : Natural := 0;
   --  Fixed default seed, printed at start; AA_SEED overrides it.
   subtype Seed_Range is Long_Long_Integer range 1 .. 2_147_483_646;
   Default_Seed : constant Seed_Range := 20_261_008;
   function Initial_Seed return Seed_Range is
     (if Ada.Environment_Variables.Exists ("AA_SEED")
      then Seed_Range'Value (Ada.Environment_Variables.Value ("AA_SEED"))
      else Default_Seed);
   Seed : Long_Long_Integer := Initial_Seed;
   function Next (Lo, Hi : Long_Long_Integer) return Integer is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Integer (Lo + Seed mod (Hi - Lo + 1));
   end Next;

   type Node_Set is array (Node_Id) of Boolean;

   procedure Reach (G : Graph; N : Node_Id; Seen : in out Node_Set) is
   begin
      if not Seen (N) then
         Seen (N) := True;
         for S in Slot loop
            if G (N).Neighbors (S) /= 0 then
               Reach (G, G (N).Neighbors (S), Seen);
            end if;
         end loop;
      end if;
   end Reach;

   function Check (G : Graph; Start : Node_Id; R : Clone_Result) return String is
      Seen  : Node_Set := [others => False];
      Count : Natural := 0;
      Prev_P, Prev_S : Natural := 0;
   begin
      Reach (G, Start, Seen);
      for N in Node_Id loop
         if Seen (N) then
            Count := Count + 1;
         end if;
         if Seen (N) /= (R.Map (N) /= 0) then
            return "copied set differs from the reachable set at node" & N'Image;
         end if;
      end loop;
      if R.Size /= Count then
         return "Size" & R.Size'Image & ", reachable" & Count'Image;
      end if;
      if R.Map (Start) /= 1 then
         return "Start not copy 1";
      end if;
      for N in Node_Id loop
         if R.Map (N) /= 0 and then R.Orig (R.Map (N)) /= N then
            return "Orig (Map (N)) /= N for node" & N'Image;
         end if;
      end loop;
      for D in Node_Id loop
         if D <= R.Size then
            if R.Orig (D) = 0 or else R.Map (R.Orig (D)) /= D then
               return "Map (Orig (D)) /= D for copy" & D'Image;
            end if;
            declare
               N : constant Node_Id := R.Orig (D);
            begin
               if R.Copy (D).Label /= G (N).Label then
                  return "label of copy" & D'Image;
               end if;
               for S in Slot loop
                  if R.Copy (D).Neighbors (S) /=
                    (if G (N).Neighbors (S) = 0 then 0
                     else R.Map (G (N).Neighbors (S)))
                  then
                     return "slot" & S'Image & " of copy" & D'Image;
                  end if;
               end loop;
            end;
            if D >= 2 then
               --  Breadth-first key: first copy listing Orig (D), first slot.
               declare
                  Key_P, Key_S : Natural := 0;
               begin
                  Find :
                  for P in 1 .. R.Size loop
                     for S in Slot loop
                        if G (R.Orig (P)).Neighbors (S) = R.Orig (D) then
                           Key_P := P;
                           Key_S := S;
                           exit Find;
                        end if;
                     end loop;
                  end loop Find;
                  if Key_P = 0 or else Key_P >= D
                    or else Key_P < Prev_P
                    or else (Key_P = Prev_P and then Key_S <= Prev_S)
                  then
                     return "copy" & D'Image & " out of breadth-first order";
                  end if;
                  Prev_P := Key_P;
                  Prev_S := Key_S;
               end;
            end if;
         else
            if R.Orig (D) /= 0 or else R.Copy (D) /= (0, [0, 0, 0, 0]) then
               return "copy node" & D'Image & " after Size not empty";
            end if;
         end if;
      end loop;
      return "";
   end Check;

   procedure Run (G : Graph; Start : Node_Id; What : String) is
      R : constant Clone_Result := Clone (G, Start);
      Msg : constant String := Check (G, Start, R);
   begin
      Cases := Cases + 1;
      if Msg /= "" then
         Failures := Failures + 1;
         if Failures <= 5 then
            Put_Line ("FAIL Clone (" & What & ", start" & Start'Image & "): " & Msg);
         end if;
      end if;
   end Run;

   G : Graph;
begin
   Put_Line ("own checks seed:" & Seed'Image & " (default"
             & Default_Seed'Image & "; set AA_SEED to override)");
   --  1. Every graph on nodes 1 .. 3 with two slots each (4 ** 6 = 4,096),
   --     from every start node; labels 1 .. 3, other nodes unreachable.
   for Code in 0 .. 4 ** 6 - 1 loop
      G := [others => (0, [0, 0, 0, 0])];
      for N in 1 .. 3 loop
         G (N).Label := N * 11;
         for S in 1 .. 2 loop
            G (N).Neighbors (S) := Code / 4 ** ((N - 1) * 2 + S - 1) mod 4;
         end loop;
      end loop;
      G (9) := (99, [1, 2, 3, 9]);   --  points into the graph, never reached
      for Start in 1 .. 3 loop
         Run (G, Start, "small" & Code'Image);
      end loop;
   end loop;
   --  2. 3,000 random 16-node graphs: random slot density (0 .. 100 %),
   --     random labels (including Integer'First / 'Last), random start.
   for K in 1 .. 3_000 loop
      declare
         Density : constant Integer := Next (0, 100);
      begin
         for N in Node_Id loop
            G (N).Label := (case Next (0, 9) is
                              when 0 => Integer'First,
                              when 1 => Integer'Last,
                              when others => Next (-1000, 1000));
            for S in Slot loop
               G (N).Neighbors (S) :=
                 (if Next (1, 100) <= Density then Next (1, Capacity) else 0);
            end loop;
         end loop;
         Run (G, Next (1, Capacity), "random" & K'Image);
      end;
   end loop;
   --  3. Shapes: a 16-node path (forward and backward), a star, the
   --     complete 4-out graph i -> i+1 .. i+4 (mod 16), all self-loops,
   --     no edges at all.
   for N in Node_Id loop
      G (N) := (N, [(if N < Capacity then N + 1 else 0), 0, 0, 0]);
   end loop;
   Run (G, 1, "path forward");
   Run (G, Capacity, "path end");
   for N in Node_Id loop
      G (N) := (N, [0, 0, 0, (if N > 1 then N - 1 else 0)]);
   end loop;
   Run (G, Capacity, "path backward");
   for N in Node_Id loop
      G (N) := (-N, (if N = 1 then [2, 3, 4, 5] elsif N <= 5 then [6 + 2 * (N - 2), 7 + 2 * (N - 2), 1, 0] else [1, 0, 0, 0]));
   end loop;
   Run (G, 1, "star");
   Run (G, 16, "star leaf");
   for N in Node_Id loop
      G (N) := (N * 3, [for S in Slot => (N + S - 1) mod Capacity + 1]);
   end loop;
   for Start in Node_Id loop
      Run (G, Start, "4-out circulant");
   end loop;
   for N in Node_Id loop
      G (N) := (N, [N, N, N, N]);
   end loop;
   Run (G, 5, "self-loops");
   G := [others => (7, [0, 0, 0, 0])];
   Run (G, 16, "no edges");

   if Failures > 0 then
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Cases'Image);
      raise Program_Error with "own checks failed";
   end if;
   Put_Line ("PASS own checks:" & Cases'Image
             & " clones (reachable set by DFS, bijection, labels, slots, BFS order)");
end Own_Checks;
