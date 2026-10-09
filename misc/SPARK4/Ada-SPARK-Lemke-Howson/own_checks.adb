pragma Ada_2022;
--  Own checks for Lemke-Howson (see tests/SOURCES.txt).
--  No expected value comes from the program:
--  * every result is checked by an own exact best-response check
--    (Big_Integer), for every starting label, and must be Found;
--  * for games with payoffs drawn from a wide range (generically
--    nondegenerate), the result must also be one of the equilibria found
--    by an own support enumeration (equal-size supports, the indifference
--    equations solved by Cramer's rule with determinants by Laplace
--    expansion), and their number must be odd;
--  * every 2 x 2 game with payoffs in 0 .. 2 (many ties: degenerate) and
--    seeded small-payoff games up to 5 x 5 get the best-response check.
with Ada.Text_IO;
with Ada.Environment_Variables;
with Interfaces; use Interfaces;
with Ada.Numerics.Big_Numbers.Big_Integers; use Ada.Numerics.Big_Numbers.Big_Integers;
with Lemke_Howson; use Lemke_Howson;

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
      Name : constant String := "Ada-SPARK-Lemke-Howson";
      H    : Unsigned_32 := 2_166_136_261;
   begin
      for C of Name loop
         H := (H xor Unsigned_32 (Character'Pos (C))) * 16_777_619;
      end loop;
      return Long_Long_Integer (H) mod 2_147_483_646 + 1;
   end Name_Hash;

   Seed : Long_Long_Integer;

   --  Park-Miller minimal standard generator.
   function Next return Long_Long_Integer is
   begin
      Seed := (Seed * 16_807) mod 2_147_483_647;
      return Seed;
   end Next;

   function Draw (Lo, Hi : Integer) return Integer is
     (Integer (Long_Long_Integer (Lo) + Next mod (Long_Long_Integer (Hi) - Long_Long_Integer (Lo) + 1)));

   function Big (V : Integer) return Big_Integer renames To_Big_Integer;
   Zero : constant Big_Integer := Big (0);

   --  Own exact check that E is a Nash equilibrium of (A, B).
   function Best_Responses (A, B : Payoff_Matrix; E : Exact_Equilibrium) return Boolean is
      M : constant Positive := A'Last (1);
      N : constant Positive := A'Last (2);
      SX, SY, Best : Big_Integer := Zero;
      PA : array (1 .. M) of Big_Integer := [others => Zero];
      PB : array (1 .. N) of Big_Integer := [others => Zero];
   begin
      for I in 1 .. M loop
         if E.X (I) < Zero then return False; end if;
         SX := SX + E.X (I);
      end loop;
      for J in 1 .. N loop
         if E.Y (J) < Zero then return False; end if;
         SY := SY + E.Y (J);
      end loop;
      if SX /= E.Dx or else SY /= E.Dy or else SX <= Zero or else SY <= Zero then
         return False;
      end if;
      for I in 1 .. M loop
         for J in 1 .. N loop
            PA (I) := PA (I) + Big (A (I, J)) * E.Y (J);
            PB (J) := PB (J) + Big (B (I, J)) * E.X (I);
         end loop;
      end loop;
      Best := PA (1);
      for I in 1 .. M loop
         if PA (I) > Best then Best := PA (I); end if;
      end loop;
      for I in 1 .. M loop
         if E.X (I) > Zero and then PA (I) /= Best then return False; end if;
      end loop;
      Best := PB (1);
      for J in 1 .. N loop
         if PB (J) > Best then Best := PB (J); end if;
      end loop;
      for J in 1 .. N loop
         if E.Y (J) > Zero and then PB (J) /= Best then return False; end if;
      end loop;
      return True;
   end Best_Responses;

   --  Support enumeration.
   type Sq is array (Positive range <>, Positive range <>) of Big_Integer;

   function Det (S : Sq) return Big_Integer is
      K : constant Natural := S'Length (1);
      Sum : Big_Integer := Zero;
   begin
      if K = 1 then
         return S (S'First (1), S'First (2));
      end if;
      for C in 1 .. K loop
         declare
            Minor : Sq (1 .. K - 1, 1 .. K - 1);
            T     : Big_Integer;
         begin
            for R in 2 .. K loop
               for CC in 1 .. K loop
                  if CC < C then
                     Minor (R - 1, CC) := S (R, CC);
                  elsif CC > C then
                     Minor (R - 1, CC - 1) := S (R, CC);
                  end if;
               end loop;
            end loop;
            if S (1, C) /= Zero then
               T := S (1, C) * Det (Minor);
               Sum := (if C mod 2 = 1 then Sum + T else Sum - T);
            end if;
         end;
      end loop;
      return Sum;
   end Det;

   type Index_Set is array (1 .. 5) of Boolean;
   type Num_Vector is array (1 .. 5) of Big_Integer;

   --  Solves sum over c in Cols of C (e, c) z_c = w for e in Rows, and
   --  sum z_c = 1 (C (e, c) given by Get).  Z (c) / D for c in Cols, the
   --  value W / D; D > 0.  Ok False when singular.
   generic
      with function Get (E, C : Positive) return Integer;
   procedure Solve (Rows, Cols : Index_Set; K : Positive; Z : out Num_Vector; W, D : out Big_Integer; Ok : out Boolean);
   procedure Solve (Rows, Cols : Index_Set; K : Positive; Z : out Num_Vector; W, D : out Big_Integer; Ok : out Boolean) is
      Mx : Sq (1 .. K + 1, 1 .. K + 1) := [others => [others => Zero]];
      RI, CI : array (1 .. K) of Positive;
      NR, NC : Natural := 0;
   begin
      Z := [others => Zero];
      for I in 1 .. 5 loop
         if Rows (I) then NR := NR + 1; RI (NR) := I; end if;
         if Cols (I) then NC := NC + 1; CI (NC) := I; end if;
      end loop;
      for E in 1 .. K loop
         for C in 1 .. K loop
            Mx (E, C) := Big (Get (RI (E), CI (C)));
         end loop;
         Mx (E, K + 1) := Big (-1);
      end loop;
      for C in 1 .. K loop
         Mx (K + 1, C) := Big (1);
      end loop;
      D := Det (Mx);
      Ok := D /= Zero;
      W := Zero;
      if not Ok then
         return;
      end if;
      --  Cramer: column c replaced by the right-hand side (0, .., 0, 1).
      for C in 1 .. K + 1 loop
         declare
            Mc : Sq := Mx;
         begin
            for E in 1 .. K + 1 loop
               Mc (E, C) := (if E = K + 1 then Big (1) else Zero);
            end loop;
            if C <= K then
               Z (CI (C)) := Det (Mc);
            else
               W := Det (Mc);
            end if;
         end;
      end loop;
      if D < Zero then
         D := -D;
         W := -W;
         for C in 1 .. 5 loop
            Z (C) := -Z (C);
         end loop;
      end if;
   end Solve;

   type Equilibrium_Record is record
      X, Y   : Num_Vector;
      Dx, Dy : Big_Integer;
   end record;
   type Equilibrium_List is array (1 .. 300) of Equilibrium_Record;

   procedure Enumerate (A, B : Payoff_Matrix; List : out Equilibrium_List; Count : out Natural) is
      M : constant Positive := A'Last (1);
      N : constant Positive := A'Last (2);
      function GA (E, C : Positive) return Integer is (A (E, C));   --  rows i, unknowns y_j
      function GB (E, C : Positive) return Integer is (B (C, E));   --  rows j, unknowns x_i
      procedure Solve_Y is new Solve (GA);
      procedure Solve_X is new Solve (GB);
      S1, S2 : Index_Set;
      K1, K2 : Natural;
      X, Y : Num_Vector;
      U, V, Dx, Dy : Big_Integer;
      Ok1, Ok2, Good : Boolean;
      S : Big_Integer;
   begin
      Count := 0;
      List := [others => (X | Y => [others => Zero], Dx | Dy => Zero)];
      for Mask1 in 1 .. 2 ** M - 1 loop
         for Mask2 in 1 .. 2 ** N - 1 loop
            K1 := 0;
            K2 := 0;
            for I in 1 .. 5 loop
               S1 (I) := I <= M and then (Mask1 / 2 ** (I - 1)) mod 2 = 1;
               S2 (I) := I <= N and then (Mask2 / 2 ** (I - 1)) mod 2 = 1;
               if S1 (I) then K1 := K1 + 1; end if;
               if S2 (I) then K2 := K2 + 1; end if;
            end loop;
            if K1 = K2 then
               Solve_Y (S1, S2, K1, Y, V, Dy, Ok1);
               Solve_X (S2, S1, K1, X, U, Dx, Ok2);
               Good := Ok1 and then Ok2;
               for I in 1 .. 5 loop
                  if Good and then S1 (I) and then X (I) <= Zero then Good := False; end if;
                  if Good and then S2 (I) and then Y (I) <= Zero then Good := False; end if;
               end loop;
               --  Outside the supports: no better reply.
               if Good then
                  for I in 1 .. M loop
                     if not S1 (I) then
                        S := Zero;
                        for J in 1 .. N loop
                           S := S + Big (A (I, J)) * Y (J);
                        end loop;
                        if S > V then Good := False; end if;
                     end if;
                  end loop;
                  for J in 1 .. N loop
                     if not S2 (J) then
                        S := Zero;
                        for I in 1 .. M loop
                           S := S + Big (B (I, J)) * X (I);
                        end loop;
                        if S > U then Good := False; end if;
                     end if;
                  end loop;
               end if;
               if Good then
                  Count := Count + 1;
                  List (Count) := (X => X, Y => Y, Dx => Dx, Dy => Dy);
               end if;
            end if;
         end loop;
      end loop;
   end Enumerate;

   function Member (E : Exact_Equilibrium; List : Equilibrium_List; Count : Natural) return Boolean is
   begin
      for K in 1 .. Count loop
         if (for all I in 1 .. E.M => E.X (I) * List (K).Dx = List (K).X (I) * E.Dx)
           and then (for all J in 1 .. E.N => E.Y (J) * List (K).Dy = List (K).Y (J) * E.Dy)
         then
            return True;
         end if;
      end loop;
      return False;
   end Member;

   procedure Check_Game (A, B : Payoff_Matrix; Enumerate_Too : Boolean; Name : String) is
      List  : Equilibrium_List;
      Count : Natural := 0;
   begin
      if Enumerate_Too then
         Enumerate (A, B, List, Count);
         Report (Count mod 2 = 1, Name & ": odd number of equilibria");
      end if;
      for D in 1 .. A'Last (1) + A'Last (2) loop
         declare
            E : constant Exact_Equilibrium := Find_Equilibrium (A, B, D);
         begin
            Report (E.Found and then Best_Responses (A, B, E), Name & " drop" & D'Image & ": best responses");
            if Enumerate_Too then
               Report (Member (E, List, Count), Name & " drop" & D'Image & ": in the support enumeration");
            end if;
         end;
      end loop;
   end Check_Game;

begin
   declare
      V : constant String := Ada.Environment_Variables.Value ("AA_SEED", "");
   begin
      Seed := (if V = "" then Name_Hash else Long_Long_Integer'Value (V));
      Ada.Text_IO.Put_Line ("AA_SEED =" & Seed'Image & (if V = "" then " (default: FNV-1a of the folder name)" else " (from AA_SEED)"));
   end;

   --  The reference itself, on games worked by hand: battle of the sexes
   --  has three equilibria ((1,0)/(1,0), (0,1)/(0,1), (3/5,2/5)/(2/5,3/5)),
   --  matching pennies one, rock-paper-scissors one (uniform).
   declare
      List  : Equilibrium_List;
      Count : Natural;
   begin
      Enumerate ([[3, 0], [0, 2]], [[2, 0], [0, 3]], List, Count);
      Report (Count = 3, "reference: battle of the sexes has 3");
      Report ((for some K in 1 .. Count => List (K).X (1) * 5 = 3 * List (K).Dx and then List (K).Y (1) * 5 = 2 * List (K).Dy),
              "reference: battle of the sexes mixed equilibrium");
      Enumerate ([[1, -1], [-1, 1]], [[-1, 1], [1, -1]], List, Count);
      Report (Count = 1 and then List (1).X (1) * 2 = List (1).Dx, "reference: pennies");
      Enumerate ([[0, -1, 1], [1, 0, -1], [-1, 1, 0]], [[0, 1, -1], [-1, 0, 1], [1, -1, 0]], List, Count);
      Report (Count = 1 and then List (1).Y (3) * 3 = List (1).Dy, "reference: rock-paper-scissors");
   end;

   --  Every 2 x 2 game with payoffs in 0 .. 2.
   for Code in 0 .. 3 ** 8 - 1 loop
      declare
         A, B : Payoff_Matrix (1 .. 2, 1 .. 2);
         C    : Natural := Code;
      begin
         for I in 1 .. 2 loop
            for J in 1 .. 2 loop
               A (I, J) := C mod 3; C := C / 3;
               B (I, J) := C mod 3; C := C / 3;
            end loop;
         end loop;
         Check_Game (A, B, False, "2x2 code" & Code'Image);
      end;
   end loop;

   --  Seeded small-payoff games (degenerate ones are common).
   for Game in 1 .. 1_500 loop
      declare
         M : constant Strategy_Count := Draw (1, 5);
         N : constant Strategy_Count := Draw (1, 5);
         H : constant Integer := Draw (1, 3);
         A, B : Payoff_Matrix (1 .. M, 1 .. N);
      begin
         for I in 1 .. M loop
            for J in 1 .. N loop
               A (I, J) := Draw (-H, H);
               B (I, J) := Draw (-H, H);
            end loop;
         end loop;
         Check_Game (A, B, False, "small game" & Game'Image);
      end;
   end loop;

   --  Seeded wide-range games, against the support enumeration.
   for Game in 1 .. 300 loop
      declare
         M : constant Strategy_Count := Draw (1, (if Game <= 200 then 4 else 5));
         N : constant Strategy_Count := Draw (1, (if Game <= 200 then 4 else 5));
         A, B : Payoff_Matrix (1 .. M, 1 .. N);
      begin
         for I in 1 .. M loop
            for J in 1 .. N loop
               A (I, J) := Draw (-1_000_000_000, 1_000_000_000);
               B (I, J) := Draw (-1_000_000_000, 1_000_000_000);
            end loop;
         end loop;
         Check_Game (A, B, True, "wide game" & Game'Image);
      end;
   end loop;

   Ada.Text_IO.Put_Line ("own checks:" & Checked'Image & " checks," & Failures'Image & " failures");
end Own_Checks;
