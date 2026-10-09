--  Own tests for Split_Array_Largest_Sum (written for this repository;
--  see tests/SOURCES.txt). Assumption: Largest_Sum returns a sum that
--  is not the true optimum over all splits into at most Parts parts,
--  tries more than floor (log2 800) + 2 limits, or Greedy_Parts is not
--  the fewest parts for a limit.
--  Reference: every one of the 2 ** 7 = 128 cut sets (a cut may follow
--  each of the first 7 elements); the optimum is the least largest part
--  sum over the cut sets with at most Parts - 1 cuts, and the fewest
--  parts for a limit L is the least cut count + 1 over the cut sets whose
--  parts all sum to <= L.
--  Inputs: 3,000 random arrays (half from narrow value ranges) with
--  Greedy_Parts at 40 random limits each; Largest_Sum with every Parts
--  1 .. 8 on 150 of them and on all-equal arrays for 12 values (the
--  executed ghost proof loops make Largest_Sum slow under -gnata).
--  Random inputs: fixed default seed, printed at start; AA_SEED=<n>
--  overrides it.
pragma Ada_2022;
with Ada.Text_IO;
with Ada.Environment_Variables;
with Split_Array_Largest_Sum; use Split_Array_Largest_Sum;

procedure Own_Checks is
   procedure Put_Line (S : String) renames Ada.Text_IO.Put_Line;
   Failures   : Natural := 0;
   Checked    : Natural := 0;
   Max_Probes : Natural := 0;

   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : Long_Long_Integer := Default;
   begin
      if V /= "" then
         S := 1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646;
      end if;
      Put_Line ("AA_SEED =" & S'Image & (if V = "" then " (default)" else " (from AA_SEED)"));
      return S;
   end AA_Seed;

   Seed : Long_Long_Integer := AA_Seed (20261008);

   function Next (Lo, Hi : Integer) return Integer is
   begin
      Seed := (Seed * 16807) mod 2147483647;   --  Park-Miller minimal standard
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Next;

   procedure Report (Ok : Boolean; Label : String) is
   begin
      Checked := Checked + 1;
      if not Ok then
         Failures := Failures + 1;
         if Failures <= 10 then
            Put_Line ("  FAIL own check: " & Label);
         end if;
      end if;
   end Report;

   function Floor_Log2 (N : Positive) return Natural is
      K : Natural := 0;
      M : Positive := N;
   begin
      while M > 1 loop
         M := M / 2;
         K := K + 1;
      end loop;
      return K;
   end Floor_Log2;

   Bound : constant Natural := Floor_Log2 (Limit'Last) + 2;

   type Cut_Info is record
      Cuts    : Natural;   --  number of cuts
      Largest : Natural;   --  largest part sum
   end record;
   type Cut_Table is array (0 .. 127) of Cut_Info;

   --  Bit B - 1 of Mask set: a cut after element B.
   function All_Cuts (X : Input_Array) return Cut_Table is
      T : Cut_Table;
   begin
      for Mask in Cut_Table'Range loop
         declare
            Part, Big, Cuts : Natural := 0;
            M : Natural := Mask;
         begin
            for I in Index loop
               Part := Part + X (I);
               if I < Length and then M mod 2 = 1 then
                  Big := Natural'Max (Big, Part);
                  Part := 0;
                  Cuts := Cuts + 1;
               end if;
               if I < Length then
                  M := M / 2;
               end if;
            end loop;
            T (Mask) := (Cuts => Cuts, Largest => Natural'Max (Big, Part));
         end;
      end loop;
      return T;
   end All_Cuts;

   procedure Check (X : Input_Array; Label : String; Limits : Natural; Search : Boolean) is
      T : constant Cut_Table := All_Cuts (X);
   begin
      for P in Part_Count loop
         exit when not Search;
         declare
            R    : constant Sum_Result := Largest_Sum (X, P);
            Want : Natural := Natural'Last;
         begin
            for Mask in T'Range loop
               if T (Mask).Cuts <= P - 1 then
                  Want := Natural'Min (Want, T (Mask).Largest);
               end if;
            end loop;
            Report (R.Largest = Want, Label & " parts" & P'Image & " got" & R.Largest'Image
                    & " want" & Want'Image);
            Report (R.Probes <= Bound, Label & " parts" & P'Image & R.Probes'Image & " tries");
            Max_Probes := Natural'Max (Max_Probes, R.Probes);
         end;
      end loop;
      for Run in 1 .. Limits loop
         declare
            L     : constant Limit := Next (Max_Element (X), Total (X));
            Least : Natural := Natural'Last;
         begin
            for Mask in T'Range loop
               if T (Mask).Largest <= L then
                  Least := Natural'Min (Least, T (Mask).Cuts + 1);
               end if;
            end loop;
            Report (Greedy_Parts (X, L) = Least, Label & " Greedy_Parts at limit" & L'Image);
         end;
      end loop;
   end Check;
begin
   for V in Element loop
      Check ([others => V], "all" & V'Image, Limits => 0, Search => V mod 9 = 1);
   end loop;
   for Run in 1 .. 3000 loop
      declare
         Lo : constant Element := Next (1, 100);
         Hi : constant Element := (if Run mod 2 = 0 then Integer'Min (100, Lo + 5) else 100);
         X  : constant Input_Array := [for I in Index => Next (Integer'Min (Lo, Hi), Hi)];
      begin
         Check (X, "random" & Run'Image, Limits => 40, Search => Run mod 20 = 0);
      end;
   end loop;
   --  Up to 800 limits need 10 tries in the worst case.
   Report (Max_Probes = 10, "worst case tries" & Max_Probes'Image & ", expected 10");
   if Failures = 0 then
      Put_Line ("PASS own checks:" & Checked'Image
                & " checks (162 arrays x 8 part counts vs all 128 cut sets; Greedy_Parts at 120,000 limits; tries <= floor (log2 800) + 2, worst case 10)");
   else
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Checked'Image);
   end if;
end Own_Checks;
