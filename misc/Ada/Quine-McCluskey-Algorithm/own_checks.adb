--  Own checks (see tests/SOURCES.txt). Assume Quine_McCluskey is wrong or
--  does nothing; compare it with references that use different methods:
--  prime implicants by enumerating all 3**N cubes and testing the definition
--  (covers only on/don't-care points; widening any fixed position breaks
--  that), the minimum cover size by trying every subset of prime implicants
--  (N <= 3) or a branch-and-bound count (N = 4), and the helper functions
--  against their definitions. Every on/off/don't-care assignment for
--  N = 1 .. 3 (3**8 = 6,561 for N = 3) and 1,500 seeded random ones for N = 4.
pragma Ada_2022;
with Ada.Environment_Variables;
with Ada.Text_IO;
with Quine_McCluskey; use Quine_McCluskey;

procedure Own_Checks is
   use String_Vectors;
   type Kind is (Off, On, DC);
   type Truth is array (0 .. 15) of Kind;
   Max_Cubes : constant := 81;   --  3**4
   type Cube_Set is array (1 .. Max_Cubes) of Boolean;
   --  Random test inputs: fixed default seed, printed at start; AA_SEED=<n> overrides it.
   function AA_Seed (Default : Long_Long_Integer) return Long_Long_Integer is
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
      S : Long_Long_Integer := Default;
   begin
      if V /= "" then
         S := Long_Long_Integer (1 + abs (Long_Long_Integer'Value (V)) mod 2_147_483_646);
      end if;
      Ada.Text_IO.Put_Line ("AA_SEED =" & Long_Long_Integer'Image (S) & (if V = "" then " (default)" else " (from AA_SEED)"));
      return S;
   end AA_Seed;
   Seed : Long_Long_Integer := AA_Seed (20261008);
   Functions_Checked : Natural := 0;

   function Rand (N : Positive) return Natural is   --  Park-Miller, 0 .. N - 1
   begin
      Seed := (Seed * 16807) mod 2147483647;
      return Natural (Seed mod Long_Long_Integer (N));
   end Rand;

   function Cube (N : Positive; K : Natural) return String is   --  K-th cube, base 3
      R : String (1 .. N);
      V : Natural := K;
   begin
      for I in reverse R'Range loop
         R (I) := (case V mod 3 is when 0 => '0', when 1 => '1', when others => '-');
         V := V / 3;
      end loop;
      return R;
   end Cube;

   function Bit (N : Positive; M : Natural; I : Positive) return Character is   --  MSB first
     ((if (M / 2 ** (N - I)) mod 2 = 1 then '1' else '0'));

   function In_Cube (C : String; M : Natural) return Boolean is
   begin
      for I in C'Range loop
         if C (I) /= '-' and then C (I) /= Bit (C'Length, M, I) then
            return False;
         end if;
      end loop;
      return True;
   end In_Cube;

   function Implicant (C : String; F : Truth) return Boolean is
   begin
      for M in 0 .. 2 ** C'Length - 1 loop
         if In_Cube (C, M) and then F (M) = Off then
            return False;
         end if;
      end loop;
      return True;
   end Implicant;

   function Prime (C : String; F : Truth) return Boolean is
   begin
      if not Implicant (C, F) then
         return False;
      end if;
      for I in C'Range loop
         if C (I) /= '-' then
            declare
               W : String := C;
            begin
               W (I) := '-';
               if Implicant (W, F) then
                  return False;
               end if;
            end;
         end if;
      end loop;
      return True;
   end Prime;

   function Index_Of (C : String) return Natural is
      K : Natural := 0;
   begin
      for Ch of C loop
         K := 3 * K + (case Ch is when '0' => 0, when '1' => 1, when others => 2);
      end loop;
      return K + 1;
   end Index_Of;

   procedure Fail (What : String; N : Positive; F : Truth) is
      S : String (1 .. 2 ** N);
   begin
      for M in 0 .. 2 ** N - 1 loop
         S (M + 1) := (case F (M) is when Off => '0', when On => '1', when DC => 'x');
      end loop;
      Ada.Text_IO.Put_Line ("FAIL own check: " & What & ", N =" & N'Image & ", truth table (minterm 0 first) " & S);
      raise Program_Error;
   end Fail;

   --  smallest number of cubes from PIs (indices) that cover every On point
   function Min_Cover (N : Positive; F : Truth; PI : Cube_Set) return Natural is
      Best : Natural := Natural'Last;
      List : array (1 .. Max_Cubes) of Natural := [others => 0];
      Count : Natural := 0;
      procedure Search (Covered : Truth; Used : Natural) is
         First : Integer := -1;
      begin
         if Used >= Best then return; end if;
         for M in 0 .. 2 ** N - 1 loop
            if F (M) = On and then Covered (M) /= On then First := M; exit; end if;
         end loop;
         if First < 0 then Best := Used; return; end if;
         for J in 1 .. Count loop
            declare
               C : constant String := Cube (N, List (J) - 1);
               Next : Truth := Covered;
            begin
               if In_Cube (C, First) then
                  for M in 0 .. 2 ** N - 1 loop
                     if In_Cube (C, M) then Next (M) := On; end if;
                  end loop;
                  Search (Next, Used + 1);
               end if;
            end;
         end loop;
      end Search;
   begin
      for K in 1 .. 3 ** N loop
         if PI (K) then Count := Count + 1; List (Count) := K; end if;
      end loop;
      if N <= 3 then   --  every subset of the prime implicants
         for Mask in 0 .. 2 ** Count - 1 loop
            declare
               Covered : Truth := [others => Off];
               Size : Natural := 0;
               OK : Boolean := True;
            begin
               for J in 1 .. Count loop
                  if (Mask / 2 ** (J - 1)) mod 2 = 1 then
                     Size := Size + 1;
                     for M in 0 .. 2 ** N - 1 loop
                        if In_Cube (Cube (N, List (J) - 1), M) then Covered (M) := On; end if;
                     end loop;
                  end if;
               end loop;
               for M in 0 .. 2 ** N - 1 loop
                  OK := OK and then (F (M) /= On or else Covered (M) = On);
               end loop;
               if OK and then Size < Best then Best := Size; end if;
            end;
         end loop;
      else
         Search ([others => Off], 0);
      end if;
      return Best;
   end Min_Cover;

   procedure Check_Function (N : Positive; F : Truth) is
      On_Count, DC_Count : Natural := 0;
      PI : Cube_Set := [others => False];
   begin
      for M in 0 .. 2 ** N - 1 loop
         if F (M) = On then On_Count := On_Count + 1; end if;
         if F (M) = DC then DC_Count := DC_Count + 1; end if;
      end loop;
      declare
         Mins : Minterm_Array (1 .. On_Count);
         DCs  : Minterm_Array (1 .. DC_Count);
         I, J : Natural := 0;
      begin
         for M in 0 .. 2 ** N - 1 loop
            if F (M) = On then I := I + 1; Mins (I) := M; end if;
            if F (M) = DC then J := J + 1; DCs (J) := M; end if;
         end loop;
         --  reference prime implicants of On or DC (cubes that cover at least one
         --  point); with no minterm at all the code answers an empty list, which
         --  the spec leaves open, so that case only expects an empty list
         for K in 1 .. 3 ** N loop
            PI (K) := Prime (Cube (N, K - 1), F) and then On_Count > 0;
         end loop;
         declare
            Got : constant Implicant_List := Get_Prime_Implicants (N, Mins, DCs);
            Seen : Cube_Set := [others => False];
         begin
            for C of Got loop
               if C'Length /= N or else not PI (Index_Of (C)) or else Seen (Index_Of (C)) then
                  Fail ("Get_Prime_Implicants returned " & C & " (not a prime implicant, or twice)", N, F);
               end if;
               Seen (Index_Of (C)) := True;
            end loop;
            if Seen /= PI then
               Fail ("Get_Prime_Implicants missed a prime implicant", N, F);
            end if;
         end;
         declare
            Best : constant Natural := (if On_Count = 0 then 0 else Min_Cover (N, F, PI));
            procedure Check_Cover (L : Implicant_List; Name : String; Exact : Boolean) is
               Covered : Truth := [others => Off];
            begin
               for C of L loop
                  if C'Length /= N or else not PI (Index_Of (C)) then
                     Fail (Name & " used " & C & ", not a prime implicant", N, F);
                  end if;
                  for M in 0 .. 2 ** N - 1 loop
                     if In_Cube (C, M) then Covered (M) := On; end if;
                  end loop;
               end loop;
               for M in 0 .. 2 ** N - 1 loop
                  if F (M) = On and then Covered (M) /= On then
                     Fail (Name & " leaves minterm" & M'Image & " uncovered", N, F);
                  end if;
               end loop;
               if (Exact and then Natural (L.Length) /= Best) or else Natural (L.Length) < Best then
                  Fail (Name & " used" & L.Length'Image & " terms, minimum is" & Best'Image, N, F);
               end if;
            end Check_Cover;
         begin
            Check_Cover (Minimize_Exact (N, Mins, DCs), "Minimize_Exact", True);
            Check_Cover (Minimize_Greedy (N, Mins, DCs), "Minimize_Greedy", False);
         end;
      end;
      Functions_Checked := Functions_Checked + 1;
   end Check_Function;

   function Rejects (N : Positive; M, D : Minterm_Array) return Boolean is
   begin
      return Natural (Get_Prime_Implicants (N, M, D).Length) = Natural'Last;
   exception
      when Invalid_Input_Error => return True;
   end Rejects;

   F : Truth;
begin
   --  helpers against their definitions, all pairs of cubes of length 3
   for A in 0 .. 26 loop
      declare
         CA : constant String := Cube (3, A);
         Ones : Natural := 0;
      begin
         for Ch of CA loop if Ch = '1' then Ones := Ones + 1; end if; end loop;
         if Count_Ones (CA) /= Ones then Fail ("Count_Ones " & CA, 3, [others => Off]); end if;
         for M in 0 .. 7 loop
            if Covers (CA, M) /= In_Cube (CA, M) then Fail ("Covers " & CA, 3, [others => Off]); end if;
         end loop;
         for B in 0 .. 26 loop
            declare
               CB : constant String := Cube (3, B);
               Diff : Natural := 0;
               Same_Dashes : Boolean := True;
               W : String := CA;
            begin
               for I in 1 .. 3 loop
                  Same_Dashes := Same_Dashes and then ((CA (I) = '-') = (CB (I) = '-'));
                  if CA (I) /= '-' and then CB (I) /= '-' and then CA (I) /= CB (I) then
                     Diff := Diff + 1; W (I) := '-';
                  end if;
               end loop;
               --  only aligned cubes (same '-' positions) are combined in the method;
               --  the spec leaves Differs_By_One open for unaligned ones
               if Same_Dashes and then Differs_By_One (CA, CB) /= (Diff = 1) then
                  Fail ("Differs_By_One " & CA & " " & CB, 3, [others => Off]);
               end if;
               if Same_Dashes and then Diff = 1 and then Merge (CA, CB) /= W then
                  Fail ("Merge " & CA & " " & CB & " gave " & Merge (CA, CB), 3, [others => Off]);
               end if;
            end;
         end loop;
      end;
   end loop;

   for N in 1 .. 3 loop
      for Code in 0 .. 3 ** (2 ** N) - 1 loop
         declare
            V : Natural := Code;
         begin
            F := [others => Off];
            for M in 0 .. 2 ** N - 1 loop
               F (M) := Kind'Val (V mod 3);
               V := V / 3;
            end loop;
            Check_Function (N, F);
         end;
      end loop;
   end loop;
   for R in 1 .. 1_500 loop
      F := [others => Off];
      for M in 0 .. 15 loop
         F (M) := (case Rand (10) is when 0 .. 3 => Off, when 4 .. 8 => On, when others => DC);
      end loop;
      Check_Function (4, F);
   end loop;
   if not (Rejects (3, [8], Empty_Minterm_Array) and then Rejects (3, [1, 2], [2])
           and then Rejects (2, [1], [4]))
   then
      Ada.Text_IO.Put_Line ("FAIL own check: out-of-range or overlapping terms not rejected");
      raise Program_Error;
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Functions_Checked'Image
                         & " functions (cube enumeration, subset / branch-and-bound minimum covers)");
end Own_Checks;
